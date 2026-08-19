local _, ns = ...

local Constants = ns:GetModule("Core.Constants")
local Database = ns:GetModule("Core.Database")
local EventBus = ns:GetModule("Core.EventBus")
local Registry = ns:GetModule("Encounters.Registry")
local SetupRegistry = ns:GetModule("Encounters.SetupRegistry")
local RaidWarning = ns:GetModule("Services.RaidWarningService")
local Messages = ns:GetModule("Services.MessageService")
local Assignments = ns:GetModule("Services.AssignmentService")
local Setup = ns:GetModule("Services.SetupService")
local Timeline = ns:GetModule("Services.TimelineService")
local Encounter = ns:GetModule("Services.EncounterService")
local UI = ns:GetModule("UI.MainFrame")
local SettingsUI = ns:GetModule("UI.SettingsFrame")
local AssignmentUI = ns:GetModule("UI.AssignmentFrame")
local Launchers = ns:GetModule("UI.AssignmentLaunchers")
local SetupCard = ns:GetModule("UI.SetupCard")
local App = ns:GetModule("Core.App")

local Integration = {
    setupCard = nil,
    setupExtraHeight = 72,
    setupHeightApplied = false,
}

local function canEditAssignments()
    if Encounter:IsActive() then return false, "Assignments are available outside active encounters." end
    if type(InCombatLockdown) == "function" and InCombatLockdown() then
        return false, "Assignments are pre-pull only. Leave combat before editing the plan."
    end
    if Database:HasNewerSchema() then return false, "Assignments were created by a newer Raid Lead Assist version. Update the addon before editing them." end
    return true
end

local function callContextSafety()
    if not Encounter:IsActive() then return true end
    if not Encounter:HasKnownEncounter() then
        return false, "Active encounter is not verified; Raid Warning plans and calls are disabled until a supported pull is identified."
    end

    local liveEncounter = Encounter.currentEncounter
    if type(liveEncounter) ~= "table" or liveEncounter.key ~= App.activeBossKey then
        return false, "Active boss does not match the selected Raid Lead Assist profile; Raid Warning plans and calls are disabled."
    end

    local liveDifficulty = Encounter:GetDifficultyKey()
    if not liveDifficulty or liveDifficulty ~= App.activeDifficultyKey then
        return false, "Active encounter difficulty is not a verified Normal, Heroic, or Mythic profile; Raid Warning plans and calls are disabled."
    end

    if not Registry:GetProfile(App.activeBossKey, liveDifficulty) then
        return false, "The active encounter has no matching Raid Lead Assist profile; Raid Warning plans and calls are disabled."
    end

    return true
end

local function dynamicWarning(callKey)
    local base = Messages:GetCallWarning(App.activeBossKey, App.activeDifficultyKey, callKey)
    local warning, complete, reason = Assignments:BuildCallWarning(base, App.activeBossKey, App.activeDifficultyKey, callKey)
    if complete == false then return reason or "Complete required assignments before this call." end
    return warning or base
end

local function refreshDynamicCallText()
    local profile = Registry:GetProfile(App.activeBossKey, App.activeDifficultyKey)
    local calls = type(profile) == "table" and type(profile.calls) == "table" and profile.calls or nil
    if not calls then return end

    for index = 1, #calls do
        local call = calls[index]
        local button = UI.callButtons and UI.callButtons[index]
        if button then
            local action, complete = Assignments:BuildCallAction(call.action, App.activeBossKey, App.activeDifficultyKey, call.key)
            button:SetActionText(complete == false and "Complete required assignment" or (action or call.action))
            button.warningResolver = dynamicWarning
        end
    end
end

local function refreshCallAvailability()
    local callsEnabled, reason = callContextSafety()
    local planEnabled = callsEnabled and not Encounter:IsActive()
    local profile = Registry:GetProfile(App.activeBossKey, App.activeDifficultyKey)
    local calls = type(profile) == "table" and type(profile.calls) == "table" and profile.calls or nil

    local explanationFrame = UI.explanationButton and UI.explanationButton.frame
    if explanationFrame and type(explanationFrame.SetEnabled) == "function" then explanationFrame:SetEnabled(planEnabled) end

    for index = 1, #(UI.callButtons or {}) do
        local button = UI.callButtons[index]
        local frame = button and button.frame
        if frame and type(frame.SetEnabled) == "function" then
            if calls then
                local call = calls[index]
                local assignmentReady = true
                if call then assignmentReady = Assignments:IsCallReady(App.activeBossKey, App.activeDifficultyKey, call.key) end
                frame:SetEnabled(callsEnabled and assignmentReady == true and call ~= nil)
            else
                -- Partial test/recovery profiles may expose only callsByKey. Context safety
                -- remains authoritative; full runtime profiles always provide ordered calls.
                frame:SetEnabled(callsEnabled)
            end
        end
    end

    UI.callsDisabledReason = callsEnabled and nil or reason
    UI.planDisabledReason = planEnabled and nil or (Encounter:IsActive() and "Boss Plan is pre-pull only." or reason)
    return callsEnabled, reason
end

local function refreshSetupCard(nativeHeightReset)
    if not UI.frame or not UI.timeline or not UI.explanationTitle then return end

    if nativeHeightReset then Integration.setupHeightApplied = false end
    if Integration.setupHeightApplied then
        UI.frame:SetHeight(math.max(1, UI.frame:GetHeight() - Integration.setupExtraHeight))
        Integration.setupHeightApplied = false
    end

    if not Integration.setupCard then Integration.setupCard = SetupCard:Create(UI.frame) end

    UI.explanationTitle:ClearAllPoints()
    if not SetupRegistry:HasSetup(App.activeBossKey, App.activeDifficultyKey) then
        Integration.setupCard:Hide()
        UI.explanationTitle:SetPoint("TOPLEFT", UI.timeline.frame, "BOTTOMLEFT", 0, -16)
        return
    end

    local layout = SetupRegistry:GetLayout(App.activeBossKey, App.activeDifficultyKey)
    local ready = Setup:IsReady(App.activeBossKey, App.activeDifficultyKey)
    local card = Integration.setupCard

    card.frame:ClearAllPoints()
    card.frame:SetPoint("TOPLEFT", UI.timeline.frame, "BOTTOMLEFT", 0, -12)
    card.frame:SetPoint("RIGHT", UI.timeline.frame, "RIGHT", 0, 0)
    card.frame:SetEnabled(not Encounter:IsActive())
    card:SetLayout(layout, ready, function()
        if Encounter:IsActive() then
            ns:Print("Pre-pull Setup is locked during an active encounter.")
            return
        end
        Setup:Toggle(App.activeBossKey, App.activeDifficultyKey)
        refreshSetupCard(false)
    end)

    UI.explanationTitle:SetPoint("TOPLEFT", card.frame, "BOTTOMLEFT", 0, -16)
    UI.frame:SetHeight(UI.frame:GetHeight() + Integration.setupExtraHeight)
    Integration.setupHeightApplied = true
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

local function refreshAssignmentSurface()
    refreshDynamicCallText()
    refreshCallAvailability()
end

local originalInitialize = App.Initialize
function App:Initialize(...)
    originalInitialize(self, ...)

    Assignments:Initialize(self.db)
    Setup:Initialize()
    AssignmentUI:Initialize(self.db, {
        canOpen = canEditAssignments,
        onAnnounce = announceAssignments,
    })
    Launchers:Attach(UI, SettingsUI, openAssignments)
    refreshAssignmentSurface()
    refreshSetupCard(true)

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
    if changed then
        Assignments:ResetRuntime()
        refreshAssignmentSurface()
        refreshSetupCard(true)
    end
    return changed
end

local originalSelectDifficulty = App.SelectDifficulty
function App:SelectDifficulty(key, automatic)
    local changed = originalSelectDifficulty(self, key, automatic)
    if changed then
        Assignments:ResetRuntime()
        refreshAssignmentSurface()
        refreshSetupCard(true)
    end
    return changed
end

local originalSendExplanation = App.SendExplanation
function App:SendExplanation()
    if Encounter:IsActive() then
        ns:Print("Boss Plan is pre-pull only.")
        return false
    end
    local safe, reason = callContextSafety()
    if not safe then
        ns:Print(reason)
        return false
    end
    return originalSendExplanation(self)
end

function App:SendCall(callKey)
    local safe, reason = callContextSafety()
    if not safe then
        ns:Print(reason)
        return false
    end

    local profile = Registry:GetProfile(self.activeBossKey, self.activeDifficultyKey)
    local call = profile and profile.callsByKey[callKey]
    if not call then return false end

    local assignmentReady, assignmentReason = Assignments:IsCallReady(self.activeBossKey, self.activeDifficultyKey, callKey)
    if not assignmentReady then
        ns:Print((assignmentReason or "Required assignment is missing.") .. " Complete it before using this call.")
        return false
    end

    local now = GetTime()
    if (self.manualLockUntil[callKey] or 0) > now then return false end

    local baseWarning = Messages:GetCallWarning(self.activeBossKey, self.activeDifficultyKey, callKey)
    local warning, assignmentComplete, renderReason = Assignments:BuildCallWarning(baseWarning, self.activeBossKey, self.activeDifficultyKey, callKey)
    if assignmentComplete == false or not warning then
        ns:Print(renderReason or "Required assignment text could not be rendered; call not sent.")
        return false
    end

    if RaidWarning:Send(warning) then
        self.manualLockUntil[callKey] = now + Constants.MANUAL_CLICK_LOCK_SECONDS
        Timeline:AcknowledgeCall(callKey)
        self.visualCalledUntil[callKey] = now + Constants.CALLED_FEEDBACK_SECONDS
        UI:SetCallState(callKey, Constants.CallState.CALLED)
        Assignments:AdvanceCall(self.activeBossKey, self.activeDifficultyKey, callKey)
        refreshDynamicCallText()
        return true
    end
    return false
end

local function refreshForActiveEncounter()
    Assignments:ResetRuntime()
    AssignmentUI:CloseForEncounter()
    refreshAssignmentSurface()
    refreshSetupCard(false)
    local enabled, reason = refreshCallAvailability()
    if not enabled then ns:Print(reason) end
end

EventBus:On("ASSIGNMENTS_CHANGED", Integration, function(_, bossKey, difficultyKey)
    if bossKey == App.activeBossKey and difficultyKey == App.activeDifficultyKey then refreshAssignmentSurface() end
end)
EventBus:On("ENCOUNTER_STARTED", Integration, refreshForActiveEncounter)
EventBus:On("ENCOUNTER_RECOVERED", Integration, refreshForActiveEncounter)

EventBus:On("ENCOUNTER_ENDED", Integration, function()
    Assignments:ResetRuntime()
    refreshAssignmentSurface()
    refreshSetupCard(false)
end)

ns:RegisterModule("Core.AssignmentIntegration", Integration)
