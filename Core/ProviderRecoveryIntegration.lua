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
-- Day-one Venomous Abyss source review on 2026-08-19 confirmed that every
-- current DBM raid module can enter a DBM-owned hardcoded timeline and then
-- fail closed back to Blizzard when live timeline routing stops matching its
-- reviewed source. DBM_IgnoreBlizzAPI is the public authority state already
-- consumed by RLA: only while it is asserted may a timer from one of these
-- fallback-capable modules remain exact. Once DBM resumes Blizzard, DBM bars
-- for the encounter are preview-only unless another direct provider proves
-- exact timing independently.
--
-- These encounter IDs and the DBM core/boss-module fingerprints are locked in
-- docs/UPSTREAM_BASELINES.json. Future source drift therefore forces another
-- semantic review instead of silently expanding the exact-timing trust boundary.
local DBM_BLIZZARD_FALLBACK_ENCOUNTERS = {
    [3420] = true, -- Sszorak
    [3421] = true, -- The Twin Fangs
    [3429] = true, -- The Coiled Altar
    [3445] = true, -- Entombed Sentinels
    [3455] = true, -- Vashnik the Malignant
    [3470] = true, -- Nek'zali the Soulcoiler
    [3492] = true, -- Ula'tek
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
