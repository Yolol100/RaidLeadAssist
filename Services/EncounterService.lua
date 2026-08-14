local _, ns = ...

local Constants = ns:GetModule("Core.Constants")
local EventBus = ns:GetModule("Core.EventBus")
local Registry = ns:GetModule("Encounters.Registry")

local EncounterService = {
    currentEncounter = nil,
    currentDifficultyID = nil,
}

function EncounterService:Initialize()
    self.frame = CreateFrame("Frame")
    self.frame:SetScript("OnEvent", function(_, eventName, ...)
        self:OnEvent(eventName, ...)
    end)
    self.frame:RegisterEvent("ENCOUNTER_START")
    self.frame:RegisterEvent("ENCOUNTER_END")
    self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

    if self:IsNativeEncounterInProgress() then
        local _, _, difficultyID = GetInstanceInfo()
        self.currentDifficultyID = difficultyID
    end
end

function EncounterService:OnEvent(eventName, ...)
    if eventName == "ENCOUNTER_START" then
        local encounterID, encounterName, difficultyID = ...
        self.currentEncounter = Registry:FindByEncounterID(encounterID)
            or Registry:FindByEncounterName(encounterName)
        self.currentDifficultyID = difficultyID

        if self.currentEncounter then
            EventBus:Emit("ENCOUNTER_SELECTED", self.currentEncounter.key, true)
        end
        -- Always notify the app that a pull started. Unknown encounters must
        -- explicitly disable automatic timing instead of leaving the previous
        -- supported encounter's timer state active.
        EventBus:Emit("ENCOUNTER_STARTED", encounterID, difficultyID)
        return
    end

    if eventName == "ENCOUNTER_END" then
        self.currentEncounter = nil
        self.currentDifficultyID = nil
        EventBus:Emit("ENCOUNTER_ENDED")
        return
    end

    EventBus:Emit("ZONE_STATUS_CHANGED", self:IsInRaidInstance())
end

function EncounterService:IsInRaidInstance()
    local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    return instanceID == Constants.INSTANCE_ID
end

function EncounterService:IsNativeEncounterInProgress()
    if not C_InstanceEncounter or type(C_InstanceEncounter.IsEncounterInProgress) ~= "function" then
        return false
    end

    local ok, active = pcall(C_InstanceEncounter.IsEncounterInProgress)
    return ok and active == true
end

function EncounterService:IsActive()
    return self.currentEncounter ~= nil or self:IsNativeEncounterInProgress()
end

function EncounterService:HasKnownEncounter()
    return self.currentEncounter ~= nil
end

function EncounterService:GetDifficultyID()
    if self.currentDifficultyID ~= nil then return self.currentDifficultyID end
    if self:IsNativeEncounterInProgress() then
        local _, _, difficultyID = GetInstanceInfo()
        return difficultyID
    end
end

function EncounterService:GetDifficultyKey()
    return Constants.DIFFICULTY_KEY_BY_ID[self:GetDifficultyID()]
end

function EncounterService:IsSupportedDifficulty()
    return self:GetDifficultyKey() ~= nil
end

function EncounterService:IsNormal()
    return self:GetDifficultyID() == Constants.NORMAL_DIFFICULTY_ID
end

function EncounterService:IsHeroic()
    return self:GetDifficultyID() == Constants.HEROIC_DIFFICULTY_ID
end

function EncounterService:IsMythic()
    return self:GetDifficultyID() == Constants.MYTHIC_DIFFICULTY_ID
end

ns:RegisterModule("Services.EncounterService", EncounterService)
