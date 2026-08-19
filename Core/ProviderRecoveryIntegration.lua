local _, ns = ...

local Constants = ns:GetModule("Core.Constants")
local EventBus = ns:GetModule("Core.EventBus")
local Timeline = ns:GetModule("Services.TimelineService")
local Encounter = ns:GetModule("Services.EncounterService")

local Integration = {
    generation = 0,
}

-- Bossmods can expose Blizzard Encounter Timeline data through their own public
-- timer callbacks. That must not upgrade unknown/approximate native timing into
-- an actionable "exact" RLA timer merely because the callback came from a
-- higher-priority provider.
--
-- BigWigs' nil-module StartBar bridge does not expose Blizzard's isApproximate
-- metadata, so that bridge is always preview-only. Direct BigWigs_Timer events
-- keep their explicit isApproximate value in BigWigsProvider.
--
-- DBM's current Lost Explorers source (2026-08-19 post-unlock) intentionally
-- uses Blizzard fallback on Heroic/Mythic and whenever hardcoded timers are not
-- active. DBM_IgnoreBlizzAPI is the public authority signal used by RLA already:
-- only while it is true can those encounter timers remain exact. The upstream
-- fingerprint is locked in docs/UPSTREAM_BASELINES.json, so future source drift
-- forces a fresh semantic review before this exception can silently go stale.
local DBM_BLIZZARD_FALLBACK_ENCOUNTERS = {
    [3497] = true, -- The Lost Explorers
}

local function dbmOwnsHardcodedTimeline()
    return _G.DBM ~= nil
        and type(DBM.Options) == "table"
        and DBM.Options.IgnoreBlizzAPI == true
end

function Integration:ApplyProviderPrecisionPolicy(providerName, data)
    if type(data) ~= "table" then return data end

    if providerName == "BigWigs" and data.bridge == "Blizzard" then
        data.precision = "approximate"
        return data
    end

    local encounterID = type(data.encounterID) == "number" and data.encounterID or nil
    if providerName == "DBM"
        and encounterID
        and DBM_BLIZZARD_FALLBACK_ENCOUNTERS[encounterID]
        and not dbmOwnsHardcodedTimeline() then
        data.precision = "approximate"
    end

    return data
end

local originalProviderTimerStarted = Timeline.ProviderTimerStarted
Timeline.ProviderTimerStarted = function(self, providerName, timerID, data)
    Integration:ApplyProviderPrecisionPolicy(providerName, data)
    return originalProviderTimerStarted(self, providerName, timerID, data)
end

local function seedActiveBossmods()
    if not Encounter:IsActive() or Encounter:HasKnownEncounter() then return false end

    local seeded = false
    for _, providerName in ipairs(Constants.PROVIDER_PRIORITY) do
        local provider = (Timeline.activeProviders or {})[providerName]
        if provider and type(provider.SeedEncounterHint) == "function" then
            local ok, result = pcall(provider.SeedEncounterHint, provider)
            if ok and result == true then
                seeded = true
                if Encounter:HasKnownEncounter() then return true end
            end
        end
    end
    return seeded
end

function Integration:ScheduleRecoveryProbe()
    self.generation = self.generation + 1
    local generation = self.generation

    local function probe(attempt)
        if generation ~= self.generation then return end
        if not Encounter:IsActive() or Encounter:HasKnownEncounter() then return end

        seedActiveBossmods()
        if not Encounter:HasKnownEncounter() and attempt < 3 then
            C_Timer.After(1, function() probe(attempt + 1) end)
        end
    end

    C_Timer.After(0, function() probe(1) end)
end

EventBus:On("TIMELINE_PROVIDER_CHANGED", Integration, function(owner)
    owner:ScheduleRecoveryProbe()
end)

EventBus:On("ENCOUNTER_STARTED", Integration, function(owner)
    -- A normal ENCOUNTER_START already carries authoritative boss identity. Cancel
    -- any queued reload-recovery probe so it cannot do redundant work afterward.
    owner.generation = owner.generation + 1
end)

EventBus:On("ENCOUNTER_ENDED", Integration, function(owner)
    owner.generation = owner.generation + 1
end)

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function()
    Integration:ScheduleRecoveryProbe()
end)
Integration.frame = frame

ns:RegisterModule("Core.ProviderRecoveryIntegration", Integration)
