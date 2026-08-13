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
    nextOccurrenceID = 0,
}

local providers = {
    BigWigs = ns:GetModule("Services.Providers.BigWigs"),
    DBM = ns:GetModule("Services.Providers.DBM"),
    Blizzard = ns:GetModule("Services.Providers.Blizzard"),
}

local providerRank = {}
for index, name in ipairs(Constants.PROVIDER_PRIORITY) do
    providerRank[name] = index
end

local function timerID(providerName, sourceID)
    return providerName .. "|" .. tostring(sourceID)
end

local function isFiniteNumber(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function validSourceID(sourceID)
    return not Util.IsSecret(sourceID) and (type(sourceID) == "string" or type(sourceID) == "number")
end

local function effectiveProviderRank(timer)
    if timer and timer.bridge == "Blizzard" then return providerRank.Blizzard or 999 end
    return providerRank[timer and timer.providerName] or 999
end

local function sourceClass(timer)
    if timer and timer.bridge == "Blizzard" then return "Blizzard" end
    return timer and timer.providerName or nil
end

local function isBetterCandidate(candidate, candidateRemaining, current, currentRemaining)
    if not current then return true end

    if candidate.occurrenceID and candidate.occurrenceID == current.occurrenceID then
        return effectiveProviderRank(candidate) < effectiveProviderRank(current)
    end

    return candidateRemaining < currentRemaining
end

local function isSameOccurrence(candidate, existing)
    if not candidate or not existing or candidate.call ~= existing.call then return false end

    if candidate.nativeEventID ~= nil and existing.nativeEventID ~= nil
        and candidate.nativeEventID == existing.nativeEventID then
        return true
    end

    if sourceClass(candidate) == sourceClass(existing) then return false end

    local delta = math.abs((existing.expiration or 0) - (candidate.expiration or 0))
    return delta <= Constants.DUPLICATE_TIMER_TOLERANCE
end

function TimelineService:Initialize()
    self:RefreshProviders()

    self.discoveryFrame = self.discoveryFrame or CreateFrame("Frame")
    self.discoveryFrame:RegisterEvent("ADDON_LOADED")
    self.discoveryFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.discoveryFrame:SetScript("OnEvent", function(_, eventName, loadedAddon)
        if eventName == "ADDON_LOADED" and loadedAddon ~= "BigWigs" and loadedAddon ~= "DBM-Core" then
            return
        end
        C_Timer.After(0, function() self:RefreshProviders() end)
    end)
end

function TimelineService:RefreshProviders()
    local changed = false

    for name, provider in pairs(providers) do
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
                -- Seed existing native timeline events only after the provider is
                -- active, otherwise ProviderTimerStarted would correctly reject them.
                if type(provider.SeedExistingEvents) == "function" then
                    pcall(provider.SeedExistingEvents, provider)
                end
                changed = true
            else
                -- Start may have registered only part of its callbacks before
                -- failing. Always give the adapter a bounded cleanup chance.
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
            changed = true
        end
    end

    if changed then
        EventBus:Emit("TIMELINE_PROVIDER_CHANGED", self:GetProviderSummary())
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
    if blizzard and type(blizzard.SeedExistingEvents) == "function" then
        pcall(blizzard.SeedExistingEvents, blizzard)
    end
end

function TimelineService:Reset()
    table.wipe(self.timers)
    self.nextOccurrenceID = 0
    EventBus:Emit("TIMELINE_CHANGED")
end

function TimelineService:MatchTimer(timer)
    if not self.encounterKey then return end
    timer.call = Registry:MatchCall(self.encounterKey, timer.key, timer.name)
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
end

function TimelineService:RemapRecentTimers()
    local now = GetTime()
    self.nextOccurrenceID = 0

    for id, timer in pairs(self.timers) do
        if not timer.startedAt or now - timer.startedAt > Constants.ENCOUNTER_REMAP_WINDOW_SECONDS then
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
    if not isFiniteNumber(data.duration) or data.duration <= 0 then return end

    local id = timerID(providerName, sourceID)
    local now = GetTime()
    local timer = self.timers[id] or { id = id }
    timer.sourceID = tostring(sourceID)
    timer.providerName = providerName
    timer.key = data.key
    timer.name = data.name
    timer.icon = data.icon
    timer.duration = data.duration
    timer.nativeEventID = data.nativeEventID
    timer.bridge = data.bridge
    timer.startedAt = now
    timer.expiration = now + data.duration
    timer.paused = false
    timer.pausedRemaining = nil
    timer.acknowledged = false
    timer.occurrenceID = nil

    self:MatchTimer(timer)

    self:AssignOccurrence(timer)

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
    EventBus:Emit("TIMELINE_CHANGED")
end

function TimelineService:ProviderTimerPaused(providerName, sourceID, paused)
    if not self.activeProviders[providerName] or not validSourceID(sourceID) then return end

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

function TimelineService:GetNextTimer()
    self:PruneExpiredTimers()
    local bestTimer, bestRemaining

    for _, timer in pairs(self.timers) do
        if timer.call and not timer.acknowledged then
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

function TimelineService:GetTimerForCall(callKey)
    self:PruneExpiredTimers()
    local bestTimer, bestRemaining

    for _, timer in pairs(self.timers) do
        if timer.call and timer.call.key == callKey and not timer.acknowledged then
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

function TimelineService:AcknowledgeCall(callKey)
    local selected = self:GetTimerForCall(callKey)
    if not selected or selected.acknowledged then return false end

    for _, timer in pairs(self.timers) do
        if timer.call and timer.call.key == callKey and not timer.acknowledged then
            if timer.occurrenceID == selected.occurrenceID then
                timer.acknowledged = true
            end
        end
    end

    EventBus:Emit("TIMELINE_CHANGED")
    return true
end

function TimelineService:GetProviderSummary()
    local active = {}
    for _, name in ipairs(Constants.PROVIDER_PRIORITY) do
        if self.activeProviders[name] then active[#active + 1] = name end
    end
    return table.concat(active, ", ")
end

ns:RegisterModule("Services.TimelineService", TimelineService)
