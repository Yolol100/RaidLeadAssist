local _, ns = ...

local Constants = ns:GetModule("Core.Constants")
local EventBus = ns:GetModule("Core.EventBus")
local Timeline = ns:GetModule("Services.TimelineService")
local Encounter = ns:GetModule("Services.EncounterService")

local Integration = {
    generation = 0,
}

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
