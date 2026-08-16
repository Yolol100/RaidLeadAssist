local _, ns = ...

local Constants = ns:GetModule("Core.Constants")
local EventBus = ns:GetModule("Core.EventBus")
local Registry = ns:GetModule("Encounters.Registry")
local Util = ns:GetModule("Core.Util")

local TimelineService = {
    encounterKey = nil,
    timers = {},
    activeProviders = {},
    providerFailures = {},
    recentAcknowledgements = {},
    blizzardSuppressionSources = {},
    nextOccurrenceID = 0,
}

local providers = {
    BigWigs = ns:GetModule("Services.Providers.BigWigs"),
    DBM = ns:GetModule("Services.Providers.DBM"),
    Blizzard = ns:GetModule("Services.Providers.Blizzard"),
}

local addonDiagnostics = {
    BigWigs = {
        core = "BigWigs",
        pack = "BigWigs_TheVenomousAbyss",
        packLabel = "Venomous pack",
    },
    DBM = {
        core = "DBM-Core",
        pack = "DBM-Raids-Midnight",
        packLabel = "Midnight raid pack",
    },
}

local watchedAddons = {
    BigWigs = true,
    ["BigWigs_TheVenomousAbyss"] = true,
    ["DBM-Core"] = true,
    ["DBM-Raids-Midnight"] = true,
}

local providerRank = {}
for index, name in ipairs(Constants.PROVIDER_PRIORITY) do
    providerRank[name] = index
end

local function timerID(providerName, sourceID)
    return providerName .. "|" .. tostring(sourceID)
end

local function isFiniteNumber(value)
    if Util.IsSecret(value) then return false end
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function validSourceID(sourceID)
    return not Util.IsSecret(sourceID) and (type(sourceID) == "string" or type(sourceID) == "number")
end

local function publicValue(value)
    if Util.IsSecret(value) then return nil end
    return value
end

local function normalizeTimerCount(value)
    if not isFiniteNumber(value) or value <= 0 or value ~= math.floor(value) then return nil end
    return value
end

local function normalizeEncounterID(value)
    if Util.IsSecret(value) then return nil, true end
    if value == nil then return nil, false end
    if type(value) == "string" then value = tonumber(value) end
    if not isFiniteNumber(value) or value <= 0 or value ~= math.floor(value) then return nil, true end
    return value, false
end

local function countsConflict(first, second)
    return first ~= nil and second ~= nil and first ~= second
end

local function normalizePrecision(value, providerName, bridge)
    value = publicValue(value)
    bridge = publicValue(bridge)
    if value == Constants.TimerPrecision.NATIVE
        or value == Constants.TimerPrecision.EXACT
        or value == Constants.TimerPrecision.APPROXIMATE then
        return value
    end
    if bridge == "Blizzard" or providerName == "Blizzard" then
        return Constants.TimerPrecision.NATIVE
    end
    return Constants.TimerPrecision.EXACT
end

local function precisionRank(timer)
    if timer and timer.precision == Constants.TimerPrecision.APPROXIMATE then return 2 end
    return 1
end

local function effectiveProviderRank(timer)
    if timer and timer.bridge == "Blizzard" then return providerRank.Blizzard or 999 end
    return providerRank[timer and timer.providerName] or 999
end

local function sourceClass(timer)
    if timer and timer.bridge == "Blizzard" then return "Blizzard" end
    return timer and timer.providerName or nil
end

local function acknowledgementSource(timer)
    if not timer then return nil end
    if timer.bridge == "Blizzard" then return "BigWigs:Blizzard" end
    return timer.providerName
end

local function isBlizzardRepresentation(providerName, dataOrTimer)
    return providerName == "Blizzard"
        or (type(dataOrTimer) == "table" and dataOrTimer.bridge == "Blizzard")
end

local function addonMetadata(addonName, field)
    local api = C_AddOns and C_AddOns.GetAddOnMetadata or _G.GetAddOnMetadata
    if type(api) ~= "function" then return nil end
    local ok, value = pcall(api, addonName, field)
    if not ok or Util.IsSecret(value) or value == nil or value == "" then return nil end
    return tostring(value)
end

local function addonLoaded(addonName)
    local api = C_AddOns and C_AddOns.IsAddOnLoaded or _G.IsAddOnLoaded
    if type(api) ~= "function" then return false end
    local ok, loaded = pcall(api, addonName)
    return ok and loaded == true
end

local function isBetterCandidate(candidate, candidateRemaining, current, currentRemaining)
    if not current then return true end

    if candidate.occurrenceID and candidate.occurrenceID == current.occurrenceID then
        local candidatePrecision = precisionRank(candidate)
        local currentPrecision = precisionRank(current)
        if candidatePrecision ~= currentPrecision then return candidatePrecision < currentPrecision end

        local candidateProvider = effectiveProviderRank(candidate)
        local currentProvider = effectiveProviderRank(current)
        if candidateProvider ~= currentProvider then return candidateProvider < currentProvider end
        return candidateRemaining < currentRemaining
    end

    if candidateRemaining ~= currentRemaining then return candidateRemaining < currentRemaining end
    local candidatePrecision = precisionRank(candidate)
    local currentPrecision = precisionRank(current)
    if candidatePrecision ~= currentPrecision then return candidatePrecision < currentPrecision end
    return effectiveProviderRank(candidate) < effectiveProviderRank(current)
end

local function isSameOccurrence(candidate, existing)
    if not candidate or not existing or candidate.call ~= existing.call then return false end

    -- Never let an expired representation drag a freshly started mechanic into
    -- the previous occurrence merely because their end times happen to be close.
    if existing.paused ~= true and isFiniteNumber(existing.expiration) and existing.expiration <= GetTime() then
        return false
    end

    -- A shared Blizzard timeline event is the strongest identity signal. Count
    -- metadata is secondary because one provider can legitimately omit or mislabel it.
    if candidate.nativeEventID ~= nil and existing.nativeEventID ~= nil
        and candidate.nativeEventID == existing.nativeEventID then
        return true
    end

    -- DBM timerCount and BigWigs counter describe mechanic occurrence. When both
    -- providers publish a count and disagree, never collapse those timers solely
    -- because their expirations happen to fall within the duplicate tolerance.
    if countsConflict(candidate.count, existing.count) then return false end

    if sourceClass(candidate) == sourceClass(existing) then return false end

    local delta = math.abs((existing.expiration or 0) - (candidate.expiration or 0))
    return delta <= Constants.DUPLICATE_TIMER_TOLERANCE
end

function TimelineService:IsActionable(timer)
    return timer ~= nil
        and timer.precision ~= Constants.TimerPrecision.APPROXIMATE
        and timer.faded ~= true
end

function TimelineService:IsBlizzardSuppressed()
    return next(self.blizzardSuppressionSources) ~= nil
end

function TimelineService:SetBlizzardSuppressedByProvider(sourceName, suppressed)
    if type(sourceName) ~= "string" or sourceName == "" or Util.IsSecret(suppressed) then return false end

    local hadSource = self.blizzardSuppressionSources[sourceName] == true
    local wantsSource = suppressed == true
    if hadSource == wantsSource then return false end

    if wantsSource then
        self.blizzardSuppressionSources[sourceName] = true
    else
        self.blizzardSuppressionSources[sourceName] = nil
    end

    local nowSuppressed = self:IsBlizzardSuppressed()
    local changedTimers = false

    if nowSuppressed then
        for id, timer in pairs(self.timers) do
            if isBlizzardRepresentation(timer.providerName, timer) then
                self.timers[id] = nil
                changedTimers = true
            end
        end
    else
        local blizzard = self.activeProviders.Blizzard
        if blizzard and type(blizzard.SeedExistingEvents) == "function" then
            pcall(blizzard.SeedExistingEvents, blizzard)
        end
    end

    EventBus:Emit("TIMELINE_PROVIDER_CHANGED", self:GetProviderDiagnostics())
    if changedTimers then EventBus:Emit("TIMELINE_CHANGED") end
    return true
end

function TimelineService:RefreshProviderAuthority(providerName)
    local provider = self.activeProviders[providerName]
    if not provider or type(provider.RefreshAuthority) ~= "function" then return false end
    local ok, changed = pcall(provider.RefreshAuthority, provider)
    return ok and changed == true
end

function TimelineService:RefreshProviderAuthorities()
    local changed = false
    for _, name in ipairs(Constants.PROVIDER_PRIORITY) do
        if self:RefreshProviderAuthority(name) then changed = true end
    end
    return changed
end

function TimelineService:GetSelectedEncounterID()
    if not self.encounterKey or type(Registry.Get) ~= "function" then return nil end
    local encounter = Registry:Get(self.encounterKey)
    local encounterID = encounter and encounter.encounterID or nil
    return normalizeEncounterID(encounterID)
end

function TimelineService:EncounterIDMatchesCurrent(encounterID)
    local normalized, invalid = normalizeEncounterID(encounterID)
    if invalid or not normalized then return false end
    local selected = self:GetSelectedEncounterID()
    return selected ~= nil and selected == normalized
end

function TimelineService:ProviderEncounterHint(providerName, encounterID)
    if Util.IsSecret(providerName) or Util.IsSecret(encounterID) then return false end
    if type(providerName) ~= "string" then return false end

    if type(encounterID) == "string" then encounterID = tonumber(encounterID) end
    if type(encounterID) ~= "number" then return false end

    EventBus:Emit("PROVIDER_ENCOUNTER_HINT", providerName, encounterID)
    return true
end

function TimelineService:Initialize()
    self:RefreshProviders()

    self.discoveryFrame = self.discoveryFrame or CreateFrame("Frame")
    self.discoveryFrame:RegisterEvent("ADDON_LOADED")
    self.discoveryFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.discoveryFrame:SetScript("OnEvent", function(_, eventName, loadedAddon)
        if eventName == "ADDON_LOADED" and not watchedAddons[loadedAddon] then return end
        C_Timer.After(0, function()
            self:RefreshProviders()
            EventBus:Emit("TIMELINE_PROVIDER_CHANGED", self:GetProviderDiagnostics())
        end)
    end)
end

function TimelineService:RefreshProviders()
    local changed = false

    -- Provider activation follows the same explicit order used for timer
    -- selection. Do not let Lua table iteration decide which authority starts
    -- first during reload or load-on-demand recovery.
    for _, name in ipairs(Constants.PROVIDER_PRIORITY) do
        local provider = providers[name]
        local available = false
        if provider and type(provider.IsAvailable) == "function" then
            local ok, result = pcall(provider.IsAvailable, provider)
            available = ok and result == true
        end

        if available and not self.activeProviders[name] then
            local ok, started = pcall(provider.Start, provider, self)
            if ok and started == true then
                self.activeProviders[name] = provider
                self.providerFailures[name] = nil
                if type(provider.SeedExistingEvents) == "function"
                    and not (name == "Blizzard" and self:IsBlizzardSuppressed()) then
                    pcall(provider.SeedExistingEvents, provider)
                end
                changed = true
            else
                pcall(provider.Stop, provider)
                self.activeProviders[name] = nil
                self:ProviderReset(name)
                if not self.providerFailures[name] then
                    self.providerFailures[name] = true
                    ns:Print(name .. " timer integration unavailable; using another timer source or manual calls.")
                end
            end
        elseif not available and self.activeProviders[name] then
            pcall(provider.Stop, provider)
            self.activeProviders[name] = nil
            self:ProviderReset(name)
            if name == "DBM" then self:SetBlizzardSuppressedByProvider("DBM", false) end
            changed = true
        end
    end

    self:RefreshProviderAuthorities()
    if changed then
        EventBus:Emit("TIMELINE_PROVIDER_CHANGED", self:GetProviderDiagnostics())
    end
end

function TimelineService:SetEncounter(encounterKey, preserveRecentTimers)
    self.encounterKey = encounterKey
    if preserveRecentTimers then
        self:RemapRecentTimers()
    else
        self:Reset()
    end

    local blizzard = self.activeProviders.Blizzard
    if not self:IsBlizzardSuppressed() and blizzard and type(blizzard.SeedExistingEvents) == "function" then
        pcall(blizzard.SeedExistingEvents, blizzard)
    end
end

function TimelineService:Reset()
    table.wipe(self.timers)
    table.wipe(self.recentAcknowledgements)
    self.nextOccurrenceID = 0
    EventBus:Emit("TIMELINE_CHANGED")
end

function TimelineService:MatchTimer(timer)
    if not self.encounterKey then return end
    timer.call = Registry:MatchCall(self.encounterKey, timer.key, timer.name)
end

function TimelineService:PruneRecentAcknowledgements()
    local now = GetTime()
    for callKey, acknowledgement in pairs(self.recentAcknowledgements) do
        if not acknowledgement.expiresAt or acknowledgement.expiresAt <= now then
            self.recentAcknowledgements[callKey] = nil
        end
    end
end

function TimelineService:IsRecentlyAcknowledged(timer)
    if not timer or not timer.call or not timer.expiration then return false end
    self:PruneRecentAcknowledgements()
    local acknowledgement = self.recentAcknowledgements[timer.call.key]
    if not acknowledgement then return false end

    -- Recent acknowledgement memory exists for a representation that arrives
    -- late from another provider. The same provider starting again after an
    -- explicit stop is a new lifecycle boundary and must be allowed to re-arm.
    local source = acknowledgementSource(timer)
    if source and acknowledgement.sources and acknowledgement.sources[source] then
        return false
    end

    if countsConflict(timer.count, acknowledgement.count) then return false end
    return math.abs(timer.expiration - acknowledgement.expiration) <= Constants.DUPLICATE_TIMER_TOLERANCE
end

function TimelineService:AssignOccurrence(timer)
    timer.occurrenceID = nil
    if not timer.call then return end

    for _, existing in pairs(self.timers) do
        if existing ~= timer and existing.occurrenceID and isSameOccurrence(timer, existing) then
            timer.occurrenceID = existing.occurrenceID
            timer.acknowledged = existing.acknowledged == true
            return
        end
    end

    self.nextOccurrenceID = self.nextOccurrenceID + 1
    timer.occurrenceID = self.nextOccurrenceID
    if self:IsRecentlyAcknowledged(timer) then timer.acknowledged = true end
end

function TimelineService:RemapRecentTimers()
    local now = GetTime()
    self.nextOccurrenceID = 0
    table.wipe(self.recentAcknowledgements)

    for id, timer in pairs(self.timers) do
        if timer.encounterID and not self:EncounterIDMatchesCurrent(timer.encounterID) then
            self.timers[id] = nil
        elseif not timer.startedAt or now - timer.startedAt > Constants.ENCOUNTER_REMAP_WINDOW_SECONDS then
            self.timers[id] = nil
        else
            timer.call = nil
            timer.acknowledged = false
            timer.occurrenceID = nil
            self:MatchTimer(timer)
        end
    end

    for _, timer in pairs(self.timers) do
        self:AssignOccurrence(timer)
    end

    EventBus:Emit("TIMELINE_CHANGED")
end

function TimelineService:ProviderTimerStarted(providerName, sourceID, data)
    if not self.activeProviders[providerName] or type(data) ~= "table" or not validSourceID(sourceID) then return end

    -- DBM can stop emitting its public timer feed when the user disables boss
    -- bars while DBM itself still has IgnoreBlizzAPI set. A native Blizzard
    -- event is the execution boundary where stale suppression must be reconciled
    -- before that fallback event is accepted or rejected.
    if isBlizzardRepresentation(providerName, data) then
        self:RefreshProviderAuthority("DBM")
    end
    if self:IsBlizzardSuppressed() and isBlizzardRepresentation(providerName, data) then return end
    if Util.IsSecret(data.faded) or not isFiniteNumber(data.duration) or data.duration <= 0 then return end

    local encounterID, invalidEncounterID = normalizeEncounterID(data.encounterID)
    if invalidEncounterID then return end
    if encounterID and not self:EncounterIDMatchesCurrent(encounterID) then return end

    local id = timerID(providerName, sourceID)
    local now = GetTime()
    local existing = self.timers[id]
    local previousOccurrenceID
    local previousAcknowledged = false
    local previousCallKey
    local previousCount

    -- Bossmods can refresh/correct a live bar by sending another Begin/Start for
    -- the same source ID instead of an Update callback. Preserve the occurrence
    -- and acknowledgement while that old bar is still live; an explicit stop,
    -- expiry, call change, or explicit mechanic-count change is a new boundary.
    if existing and (existing.paused == true
        or (isFiniteNumber(existing.expiration) and existing.expiration > now)) then
        previousOccurrenceID = existing.occurrenceID
        previousAcknowledged = existing.acknowledged == true
        previousCallKey = existing.call and existing.call.key or nil
        previousCount = existing.count
    end

    local timer = existing or { id = id }
    timer.sourceID = tostring(sourceID)
    timer.providerName = providerName
    timer.key = publicValue(data.key)
    timer.name = publicValue(data.name)
    timer.icon = publicValue(data.icon)
    timer.count = normalizeTimerCount(data.count)
    timer.encounterID = encounterID
    timer.duration = data.duration
    timer.nativeEventID = publicValue(data.nativeEventID)
    timer.bridge = publicValue(data.bridge)
    timer.precision = normalizePrecision(data.precision, providerName, timer.bridge)
    timer.faded = data.faded == true
    timer.startedAt = now
    timer.expiration = now + data.duration
    timer.paused = false
    timer.pausedRemaining = nil
    timer.acknowledged = false
    timer.occurrenceID = nil

    self:MatchTimer(timer)
    local matchedCallKey = timer.call and timer.call.key or nil
    if previousOccurrenceID and previousCallKey ~= nil and matchedCallKey == previousCallKey
        and not countsConflict(previousCount, timer.count) then
        timer.occurrenceID = previousOccurrenceID
        timer.acknowledged = previousAcknowledged
    else
        self:AssignOccurrence(timer)
    end

    self.timers[id] = timer
    EventBus:Emit("TIMELINE_CHANGED")
end

function TimelineService:ProviderTimerUpdated(providerName, sourceID, elapsed, total)
    if not self.activeProviders[providerName] or not validSourceID(sourceID) then return end
    if not isFiniteNumber(elapsed) or not isFiniteNumber(total) or elapsed < 0 or total <= 0 then return end

    local timer = self.timers[timerID(providerName, sourceID)]
    if not timer then return end

    local now = GetTime()
    local remaining = math.max(0, total - elapsed)
    timer.duration = total
    timer.startedAt = now - elapsed
    timer.expiration = now + remaining
    if timer.paused then timer.pausedRemaining = remaining end

    -- A provider update adjusts the same live bar. Its occurrence identity must
    -- stay stable so PREPARE/PRESS audio and acknowledgement state cannot re-arm.
    if not timer.occurrenceID and timer.call then self:AssignOccurrence(timer) end
    EventBus:Emit("TIMELINE_CHANGED")
end

function TimelineService:ProviderTimerFaded(providerName, sourceID, faded)
    if not self.activeProviders[providerName] or not validSourceID(sourceID) or Util.IsSecret(faded) then return end

    local timer = self.timers[timerID(providerName, sourceID)]
    if not timer then return end

    local nextFaded = faded == true
    if timer.faded == nextFaded then return end
    timer.faded = nextFaded

    -- Fading is a presentation/actionability change, not a new timer occurrence.
    -- Keep expiration, occurrence identity and acknowledgement untouched so an
    -- unfade cannot replay PREPARE/PRESS for the same mechanic.
    EventBus:Emit("TIMELINE_CHANGED")
end

function TimelineService:ProviderTimerPaused(providerName, sourceID, paused)
    if not self.activeProviders[providerName] or not validSourceID(sourceID) or Util.IsSecret(paused) then return end

    local timer = self.timers[timerID(providerName, sourceID)]
    if not timer then return end

    if paused and not timer.paused then
        timer.pausedRemaining = self:GetRemaining(timer)
        timer.paused = true
    elseif not paused and timer.paused then
        timer.expiration = GetTime() + (timer.pausedRemaining or 0)
        timer.pausedRemaining = nil
        timer.paused = false
    end

    EventBus:Emit("TIMELINE_CHANGED")
end

function TimelineService:ProviderTimerStopped(providerName, sourceID)
    if not validSourceID(sourceID) then return end
    self.timers[timerID(providerName, sourceID)] = nil
    EventBus:Emit("TIMELINE_CHANGED")
end

function TimelineService:ProviderReset(providerName)
    local prefix = providerName .. "|"
    local changed = false

    for id in pairs(self.timers) do
        if id:sub(1, #prefix) == prefix then
            self.timers[id] = nil
            changed = true
        end
    end

    if changed then EventBus:Emit("TIMELINE_CHANGED") end
end

function TimelineService:GetRemaining(timer)
    if timer.paused then return timer.pausedRemaining end

    if timer.providerName == "Blizzard" then
        local provider = self.activeProviders.Blizzard
        if provider and provider.GetRemaining then
            local remaining = provider:GetRemaining(timer)
            if remaining ~= nil then return remaining end
        end
    end

    return math.max(0, timer.expiration - GetTime())
end

function TimelineService:PruneExpiredTimers()
    local now = GetTime()
    local changed = false

    for id, timer in pairs(self.timers) do
        if not timer.paused and timer.expiration
            and now > timer.expiration + Constants.TIMER_EXPIRY_GRACE_SECONDS then
            local remaining = self:GetRemaining(timer)
            if not remaining or remaining <= 0 then
                self.timers[id] = nil
                changed = true
            end
        end
    end

    if changed then EventBus:Emit("TIMELINE_CHANGED") end
end

local function selectNextTimer(self, actionableOnly)
    self:PruneExpiredTimers()
    local bestTimer, bestRemaining

    for _, timer in pairs(self.timers) do
        if timer.call and not timer.acknowledged and (not actionableOnly or self:IsActionable(timer)) then
            local remaining = self:GetRemaining(timer)
            if type(remaining) == "number" and remaining > 0
                and isBetterCandidate(timer, remaining, bestTimer, bestRemaining) then
                bestTimer = timer
                bestRemaining = remaining
            end
        end
    end

    return bestTimer, bestRemaining
end

local function selectTimerForCall(self, callKey, actionableOnly)
    self:PruneExpiredTimers()
    local bestTimer, bestRemaining

    for _, timer in pairs(self.timers) do
        if timer.call and timer.call.key == callKey and not timer.acknowledged
            and (not actionableOnly or self:IsActionable(timer)) then
            local remaining = self:GetRemaining(timer)
            if type(remaining) == "number" and remaining > 0
                and isBetterCandidate(timer, remaining, bestTimer, bestRemaining) then
                bestTimer = timer
                bestRemaining = remaining
            end
        end
    end

    return bestTimer, bestRemaining
end

function TimelineService:GetNextTimer()
    return selectNextTimer(self, false)
end

function TimelineService:GetNextActionableTimer()
    return selectNextTimer(self, true)
end

function TimelineService:GetTimerForCall(callKey)
    return selectTimerForCall(self, callKey, false)
end

function TimelineService:GetActionableTimerForCall(callKey)
    return selectTimerForCall(self, callKey, true)
end

function TimelineService:AcknowledgeCall(callKey)
    local selected = self:GetActionableTimerForCall(callKey)
    if not selected then selected = self:GetTimerForCall(callKey) end
    if not selected or selected.acknowledged then return false end

    local now = GetTime()
    local selectedRemaining = self:GetRemaining(selected)
    local selectedExpiration = now + (type(selectedRemaining) == "number" and selectedRemaining or 0)
    local acknowledgedSources = {}

    for _, timer in pairs(self.timers) do
        if timer.call and timer.call.key == callKey and not timer.acknowledged then
            local sameOccurrence = timer == selected
                or timer.occurrenceID == selected.occurrenceID
                or isSameOccurrence(timer, selected)
            if sameOccurrence then
                timer.acknowledged = true
                local source = acknowledgementSource(timer)
                if source then acknowledgedSources[source] = true end
            end
        end
    end

    self.recentAcknowledgements[callKey] = {
        expiration = selectedExpiration,
        expiresAt = now + Constants.RECENT_ACKNOWLEDGEMENT_SECONDS,
        count = selected.count,
        sources = acknowledgedSources,
    }

    EventBus:Emit("TIMELINE_CHANGED")
    return true
end

local function providerIsUsable(self, name)
    local provider = self.activeProviders[name]
    if not provider then return false end

    if name == "Blizzard" then
        return not self:IsBlizzardSuppressed()
    end

    local spec = addonDiagnostics[name]
    if spec and not addonMetadata(spec.pack, "Version") then return false end

    if type(provider.CanSupplyBossTimers) == "function" then
        local ok, canSupply = pcall(provider.CanSupplyBossTimers, provider)
        if not ok or canSupply ~= true then return false end
    end

    return true
end

function TimelineService:GetProviderSummary()
    self:RefreshProviderAuthorities()
    local active = {}
    for _, name in ipairs(Constants.PROVIDER_PRIORITY) do
        if providerIsUsable(self, name) then active[#active + 1] = name end
    end
    return table.concat(active, ", ")
end

function TimelineService:HasUsableTimingSource()
    return self:GetProviderSummary() ~= ""
end

function TimelineService:GetProviderDiagnostics()
    local active = {}

    for _, name in ipairs(Constants.PROVIDER_PRIORITY) do
        local provider = self.activeProviders[name]
        if provider then
            if name == "Blizzard" then
                active[#active + 1] = "Blizzard native"
            else
                local spec = addonDiagnostics[name]
                local coreVersion = spec and addonMetadata(spec.core, "Version") or nil
                local label = name .. (coreVersion and (" " .. coreVersion) or "")
                if spec then
                    local packVersion = addonMetadata(spec.pack, "Version")
                    local packState
                    if packVersion then
                        packState = addonLoaded(spec.pack) and "loaded" or "installed/not loaded"
                        label = label .. (" [%s %s%s]"):format(
                            spec.packLabel,
                            packState,
                            packVersion ~= coreVersion and (" " .. packVersion) or ""
                        )
                    else
                        label = label .. (" [%s missing]"):format(spec.packLabel)
                    end
                end

                if type(provider.CanSupplyBossTimers) == "function" then
                    local ok, canSupply = pcall(provider.CanSupplyBossTimers, provider)
                    if ok and canSupply ~= true then
                        label = label .. " [boss timer feed disabled]"
                    end
                end
                active[#active + 1] = label
            end
        end
    end

    if self:IsBlizzardSuppressed() then
        local sources = {}
        for sourceName in pairs(self.blizzardSuppressionSources) do sources[#sources + 1] = sourceName end
        table.sort(sources)
        active[#active + 1] = "Blizzard timers suppressed by " .. table.concat(sources, "+")
    end

    return table.concat(active, "; ")
end

ns:RegisterModule("Services.TimelineService", TimelineService)
