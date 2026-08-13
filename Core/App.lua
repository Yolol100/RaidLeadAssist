local addonName, ns = ...

local Constants = ns:GetModule("Core.Constants")
local Database = ns:GetModule("Core.Database")
local EventBus = ns:GetModule("Core.EventBus")
local Registry = ns:GetModule("Encounters.Registry")
local RaidWarning = ns:GetModule("Services.RaidWarningService")
local Messages = ns:GetModule("Services.MessageService")
local Audio = ns:GetModule("Services.AudioService")
local Timeline = ns:GetModule("Services.TimelineService")
local Encounter = ns:GetModule("Services.EncounterService")
local UI = ns:GetModule("UI.MainFrame")
local SettingsUI = ns:GetModule("UI.SettingsFrame")

local App = {
    activeBossKey = nil,
    manualLockUntil = {},
    visualCalledUntil = {},
    audioStates = {},
    timingAllowed = true,
}

local function resetTransientState(owner)
    owner.audioStates = {}
    owner.manualLockUntil = {}
    owner.visualCalledUntil = {}
end

local function settingsAvailability()
    if Encounter:IsActive() then
        return false, "Settings are available outside active encounters."
    end
    if Database:HasNewerSchema() then
        return false, "Settings were created by a newer Raid Lead Assist version. Update the addon before editing them."
    end
    return true
end

function App:Initialize()
    Database:Initialize()
    self.db = Database:Get()
    if not Registry:Get(self.db.selectedBossKey) then
        local firstEncounter = Registry:GetOrdered()[1]
        self.db.selectedBossKey = firstEncounter and firstEncounter.key or "nekzali"
    end
    self.activeBossKey = self.db.selectedBossKey

    Messages:Initialize(self.db)
    Audio:Initialize(self.db)
    Timeline:SetEncounter(self.activeBossKey)
    Timeline:Initialize()
    Encounter:Initialize()
    if Encounter:IsActive() then
        self.timingAllowed = Encounter:IsHeroic()
    end

    UI:Initialize(self.db, {
        onBossSelected = function(key) self:SelectBoss(key, false) end,
        onExplanation = function() self:SendExplanation() end,
        onCall = function(callKey) self:SendCall(callKey) end,
        onUpdate = function() self:UpdateTiming() end,
        onSettings = function() SettingsUI:Open(self.activeBossKey) end,
    })

    SettingsUI:Initialize(self.db, {
        getProviderSummary = function() return Timeline:GetProviderSummary() end,
        canOpen = settingsAvailability,
    })
    local settingsEnabled, settingsReason = settingsAvailability()
    UI:SetSettingsEnabled(settingsEnabled, settingsReason)

    EventBus:On("ENCOUNTER_SELECTED", self, function(owner, key)
        owner:SelectBoss(key, true)
    end)
    EventBus:On("ENCOUNTER_STARTED", self, function(owner, _, difficultyID)
        RaidWarning:CancelBriefing()
        resetTransientState(owner)
        owner.timingAllowed = difficultyID == Constants.HEROIC_DIFFICULTY_ID
        UI:SetSettingsEnabled(false, "Settings are available outside active encounters.")
        SettingsUI:CloseForEncounter()
        if not owner.timingAllowed then
            ns:Print("Heroic profile only: automatic timing disabled; manual buttons remain available.")
        end
    end)
    EventBus:On("ENCOUNTER_ENDED", self, function(owner)
        RaidWarning:CancelBriefing()
        resetTransientState(owner)
        owner.timingAllowed = true
        local settingsEnabled, settingsReason = settingsAvailability()
        UI:SetSettingsEnabled(settingsEnabled, settingsReason)
        Timeline:Reset()
        UI:ResetCallStates()
    end)
    EventBus:On("ZONE_STATUS_CHANGED", self, function(owner, inRaid)
        if owner.db.forceShown or inRaid then UI:Show() else UI:Hide() end
    end)
    EventBus:On("TIMELINE_PROVIDER_CHANGED", self, function(_, providerSummary)
        SettingsUI:RefreshProviderSummary(providerSummary)
    end)

    self:RegisterSlashCommands()

    if self.db.forceShown or Encounter:IsInRaidInstance() then UI:Show() else UI:Hide() end

    C_Timer.After(1, function()
        Timeline:RefreshProviders()
    end)

    if Database:HasNewerSchema() then
        ns:Print("Saved settings came from a newer Raid Lead Assist version. Known fields were read safely; the newer schema marker was preserved.")
    end

    ns:Print("Loaded. Shift-drag the header to move. /rla for commands.")
end

function App:SelectBoss(key, automatic)
    local encounter = Registry:Get(key)
    if not encounter then return end

    RaidWarning:CancelBriefing()
    self.activeBossKey = key
    self.db.selectedBossKey = key
    resetTransientState(self)
    Timeline:SetEncounter(key, automatic)
    UI:SetEncounter(key)
    UI:ResetCallStates()

    if automatic then UI:Show() end
end

function App:SendExplanation()
    local encounter = Registry:Get(self.activeBossKey)
    if encounter then RaidWarning:SendBriefing(Messages:GetExplanation(self.activeBossKey)) end
end

function App:SendCall(callKey)
    local encounter = Registry:Get(self.activeBossKey)
    local call = encounter and encounter.callsByKey[callKey]
    if not call then return end

    local now = GetTime()
    if (self.manualLockUntil[callKey] or 0) > now then return end

    if RaidWarning:Send(Messages:GetCallWarning(self.activeBossKey, callKey)) then
        self.manualLockUntil[callKey] = now + Constants.MANUAL_CLICK_LOCK_SECONDS
        Timeline:AcknowledgeCall(callKey)
        self.visualCalledUntil[callKey] = now + Constants.CALLED_FEEDBACK_SECONDS
        UI:SetCallState(callKey, Constants.CallState.CALLED)
    end
end

function App:UpdateTiming()
    local encounter = Registry:Get(self.activeBossKey)
    if not encounter then return end

    if not self.timingAllowed then
        for index = 1, #encounter.calls do
            local call = encounter.calls[index]
            local state = (self.visualCalledUntil[call.key] or 0) > GetTime()
                and Constants.CallState.CALLED
                or Constants.CallState.IDLE
            UI:SetCallState(call.key, state)
        end
        UI.timeline:SetIdle()
        return
    end

    for index = 1, #encounter.calls do
        local call = encounter.calls[index]
        local _, remaining = Timeline:GetTimerForCall(call.key)
        local state = Constants.CallState.IDLE

        if (self.visualCalledUntil[call.key] or 0) > GetTime() then
            state = Constants.CallState.CALLED
        elseif remaining then
            if remaining <= Constants.PRESS_SECONDS then
                state = Constants.CallState.PRESS
            elseif remaining <= Constants.PREPARE_SECONDS then
                state = Constants.CallState.PREPARE
            end
        elseif (self.manualLockUntil[call.key] or 0) > GetTime() then
            state = Constants.CallState.CALLED
        end

        UI:SetCallState(call.key, state)
    end

    local timer, remaining = Timeline:GetNextTimer()
    if not timer or not remaining then
        UI.timeline:SetIdle()
        return
    end

    UI.timeline:SetTimer(timer, remaining)

    local state = Constants.CallState.IDLE
    if remaining <= Constants.PRESS_SECONDS then
        state = Constants.CallState.PRESS
    elseif remaining <= Constants.PREPARE_SECONDS then
        state = Constants.CallState.PREPARE
    end
    UI.timeline:SetState(state)

    local occurrenceKey = table.concat({ timer.call.key, tostring(timer.occurrenceID or timer.sourceID) }, ":")
    local audioKey = occurrenceKey .. ":" .. state
    if state == Constants.CallState.PREPARE and not self.audioStates[audioKey] then
        self.audioStates[audioKey] = true
        Audio:Prepare(timer.call)
    elseif state == Constants.CallState.PRESS and not self.audioStates[audioKey] then
        self.audioStates[audioKey] = true
        Audio:Press(timer.call)
    end
end

function App:RegisterSlashCommands()
    SLASH_RAIDLEADASSIST1 = "/rla"
    SlashCmdList.RAIDLEADASSIST = function(message)
        local command, argument = message:match("^(%S*)%s*(.-)$")
        command = command:lower()

        if command == "show" then
            self.db.forceShown = true
            UI:Show()
        elseif command == "hide" then
            self.db.forceShown = false
            UI:Hide()
        elseif command == "toggle" then
            if UI:IsShown() then UI:Hide() else UI:Show() end
        elseif command == "resetpos" then
            Database:ResetPosition()
            UI.frame:ClearAllPoints()
            local pos = self.db.position
            UI.frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
        elseif command == "audio" then
            argument = argument:lower()
            if argument == "on" then self.db.audioEnabled = true end
            if argument == "off" then self.db.audioEnabled = false end
            ns:Print("Audio: " .. (self.db.audioEnabled and "on" or "off"))
        elseif command == "settings" then
            SettingsUI:Open(self.activeBossKey)
        elseif command == "provider" then
            local summary = Timeline:GetProviderSummary()
            ns:Print("Timer sources: " .. (summary ~= "" and summary or "none"))
        elseif command == "status" then
            local summary = Timeline:GetProviderSummary()
            local difficultyID = Encounter:GetDifficultyID()
            ns:Print(("v%s | boss=%s | encounter=%s | difficulty=%s | timing=%s | providers=%s | db=%s"):format(
                tostring(ns.version),
                tostring(self.activeBossKey or "none"),
                Encounter:IsActive() and "active" or "idle",
                tostring(difficultyID or "none"),
                self.timingAllowed and "on" or "off",
                summary ~= "" and summary or "none",
                tostring(self.db.schemaVersion or "unknown")
            ))
        else
            ns:Print("/rla show | hide | toggle | settings | resetpos | audio on|off | provider | status")
        end
    end
end

local bootstrap = CreateFrame("Frame")
bootstrap:RegisterEvent("ADDON_LOADED")
bootstrap:SetScript("OnEvent", function(_, _, loadedAddon)
    if loadedAddon ~= addonName then return end
    bootstrap:UnregisterEvent("ADDON_LOADED")
    App:Initialize()
end)

ns:RegisterModule("Core.App", App)
