local _, ns = ...

local Constants = ns:GetModule("Core.Constants")
local Database = ns:GetModule("Core.Database")
local EventBus = ns:GetModule("Core.EventBus")
local Registry = ns:GetModule("Encounters.Registry")
local RaidWarning = ns:GetModule("Services.RaidWarningService")
local Messages = ns:GetModule("Services.MessageService")
local Assignments = ns:GetModule("Services.AssignmentService")
local Timeline = ns:GetModule("Services.TimelineService")
local Encounter = ns:GetModule("Services.EncounterService")
local UI = ns:GetModule("UI.MainFrame")
local SettingsUI = ns:GetModule("UI.SettingsFrame")
local AssignmentUI = ns:GetModule("UI.AssignmentFrame")
local Launchers = ns:GetModule("UI.AssignmentLaunchers")
local App = ns:GetModule("Core.App")

local Integration = {}

local function canEditAssignments()
    if Encounter:IsActive() then return false, "Assignments are available outside active encounters." end
    if Database:HasNewerSchema() then return false, "Assignments were created by a newer Raid Lead Assist version. Update the addon before editing them." end
    return true
end

local function openAssignments()
    AssignmentUI:Open(App.activeBossKey, App.activeDifficultyKey)
end

local function announceAssignments(bossKey, difficultyKey)
    local lines = Assignments:GetPlanLines(bossKey, difficultyKey)
    if #lines == 0 then
        ns:Print("No assignments are filled in for this boss and difficulty.")
        return false
    end
    return RaidWarning:SendBriefing(lines)
end

local originalInitialize = App.Initialize
function App:Initialize(...)
    originalInitialize(self, ...)

    Assignments:Initialize(self.db)
    AssignmentUI:Initialize(self.db, {
        canOpen = canEditAssignments,
        onAnnounce = announceAssignments,
    })
    Launchers:Attach(UI, SettingsUI, openAssignments)

    local originalSlash = SlashCmdList.RAIDLEADASSIST
    SlashCmdList.RAIDLEADASSIST = function(message)
        local command = type(message) == "string" and (message:match("^(%S*)") or ""):lower() or ""
        if command == "assign" or command == "assignments" then
            openAssignments()
        elseif originalSlash then
            originalSlash(message)
        end
    end
end

local originalSelectBoss = App.SelectBoss
function App:SelectBoss(key, automatic)
    local changed = originalSelectBoss(self, key, automatic)
    if changed then Assignments:ResetRuntime() end
    return changed
end

local originalSelectDifficulty = App.SelectDifficulty
function App:SelectDifficulty(key, automatic)
    local changed = originalSelectDifficulty(self, key, automatic)
    if changed then Assignments:ResetRuntime() end
    return changed
end

function App:SendCall(callKey)
    local profile = Registry:GetProfile(self.activeBossKey, self.activeDifficultyKey)
    local call = profile and profile.callsByKey[callKey]
    if not call then return end

    local now = GetTime()
    if (self.manualLockUntil[callKey] or 0) > now then return end

    local baseWarning = Messages:GetCallWarning(self.activeBossKey, self.activeDifficultyKey, callKey)
    local warning = Assignments:BuildCallWarning(baseWarning, self.activeBossKey, self.activeDifficultyKey, callKey)
    if RaidWarning:Send(warning) then
        self.manualLockUntil[callKey] = now + Constants.MANUAL_CLICK_LOCK_SECONDS
        Timeline:AcknowledgeCall(callKey)
        self.visualCalledUntil[callKey] = now + Constants.CALLED_FEEDBACK_SECONDS
        UI:SetCallState(callKey, Constants.CallState.CALLED)
        Assignments:AdvanceCall(self.activeBossKey, self.activeDifficultyKey, callKey)
    end
end

EventBus:On("ENCOUNTER_STARTED", Integration, function()
    Assignments:ResetRuntime()
    AssignmentUI:CloseForEncounter()
end)

EventBus:On("ENCOUNTER_ENDED", Integration, function()
    Assignments:ResetRuntime()
end)

ns:RegisterModule("Core.AssignmentIntegration", Integration)
