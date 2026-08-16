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
    activeDifficultyKey = "heroic",
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

local function settingsAreOpen()
    return SettingsUI.frame and type(SettingsUI.frame.IsShown) == "function" and SettingsUI.frame:IsShown()
end

function App:IsAutomaticTimingEnabled()
    return self.timingAllowed == true and self.db and self.db.automaticTimingEnabled ~= false
end

local function profileUsesAutomaticTiming(profile)
    if type(profile) ~= "table" or type(profile.calls) ~= "table" then return false end
    for index = 1, #profile.calls do
        if profile.calls[index].timing ~= false then return true end
    end
    return false
end

local function currentTimerTrafficSummary()
    local totals = {}
    for _, timer in pairs(Timeline.timers or {}) do
        local label
        if timer.providerName == "BigWigs" and timer.bridge == "Blizzard" then
            label = "BigWigs -> Blizzard"
        elseif timer.providerName == "Blizzard" then
            label = "Blizzard native"
        elseif timer.providerName == "DBM" then
            label = "DBM direct"
        elseif timer.providerName == "BigWigs" then
            label = "BigWigs direct"
        end
        if label then
            local item = totals[label] or { active = 0, matched = 0 }
            item.active = item.active + 1
            if timer.call then item.matched = item.matched + 1 end
            totals[label] = item
        end
    end

    local parts = {}
    for _, label in ipairs({ "DBM direct", "BigWigs direct", "BigWigs -> Blizzard", "Blizzard native" }) do
        local item = totals[label]
        if item then
            parts[#parts + 1] = ("%s %d active/%d matched"):format(label, item.active, item.matched)
        end
    end
    return table.concat(parts, "; ")
end

function App:PrintDoctor()
    local encounter = Registry:Get(self.activeBossKey)
    local profile = Registry:GetProfile(self.activeBossKey, self.activeDifficultyKey)
    local canWarn = RaidWarning:CanSend()
    local inRaidInstance = Encounter:IsInRaidInstance()
    local ready = true

    if Database:HasNewerSchema() or not encounter or not profile then ready = false end
    if not inRaidInstance or not canWarn then ready = false end
    if Encounter:IsActive() and (not Encounter:HasKnownEncounter() or not Encounter:GetDifficultyKey()) then ready = false end
    local profileUsesTiming = profileUsesAutomaticTiming(profile)
    if self.db.automaticTimingEnabled ~= false and profileUsesTiming and Timeline:GetProviderSummary() == "" then ready = false end
    if Audio:GetDiagnostics() == "unavailable" and Audio:IsEnabled() then ready = false end

    ns:Print(("Doctor: %s | v%s | db=%s | boss=%s | profile=%s"):format(
        ready and "READY" or "CHECK",
        tostring(ns.version),
        tostring(self.db.schemaVersion or "unknown"),
        tostring(self.activeBossKey or "none"),
        tostring(self.activeDifficultyKey or "none")
    ))
    ns:Print(("Context: raid=%s | encounter=%s | verified=%s | /rw=%s"):format(
        inRaidInstance and "yes" or "no",
        Encounter:IsActive() and "active" or "idle",
        Encounter:HasKnownEncounter() and "yes" or "no",
        canWarn and "ready" or "needs raid leader/assistant"
    ))
    ns:Print(("Automatic timing: user=%s | profile=%s | runtime=%s | audio=%s"):format(
        self.db.automaticTimingEnabled ~= false and "on" or "off",
        profileUsesTiming and "timed" or "manual-only",
        self.timingAllowed and "allowed" or "blocked",
        Audio:GetDiagnostics()
    ))

    local providers = Timeline:GetProviderDiagnostics()
    ns:Print("Providers: " .. (providers ~= "" and providers or "manual only"))
    local observed = currentTimerTrafficSummary()
    ns:Print("Active timer traffic: " .. (observed ~= "" and observed or "none"))
    ns:Print("Tested bossmod contracts: DBM 12.1.3; BigWigs v419.2")
    if encounter and encounter.strategyStatus then ns:Print("Strategy: " .. encounter.strategyStatus) end
end

function App:Initialize()
    Database:Initialize()
    self.db = Database:Get()

    if not Registry:Get(self.db.selectedBossKey) then
        local firstEncounter = Registry:GetOrdered()[1]
        self.db.selectedBossKey = firstEncounter and firstEncounter.key or "nekzali"
    end
    if not Constants.DIFFICULTIES[self.db.selectedDifficultyKey] then self.db.selectedDifficultyKey = "heroic" end

    self.activeBossKey = self.db.selectedBossKey
    self.activeDifficultyKey = self.db.selectedDifficultyKey
    Registry:SetActiveDifficulty(self.activeDifficultyKey)

    Messages:Initialize(self.db)
    Audio:Initialize(self.db)
    Timeline:SetEncounter(self.activeBossKey)
    Timeline:Initialize()
    Encounter:Initialize()

    if Encounter:IsActive() then
        local difficultyKey = Encounter:GetDifficultyKey()
        if difficultyKey then
            self.activeDifficultyKey = difficultyKey
            self.db.selectedDifficultyKey = difficultyKey
            Registry:SetActiveDifficulty(difficultyKey)
            Timeline:SetEncounter(self.activeBossKey)
        end

        self.timingAllowed = difficultyKey ~= nil and Encounter:HasKnownEncounter()
        if not Encounter:HasKnownEncounter() then
            ns:Print("Encounter already in progress after reload: calls and automatic timing stay disabled until the active boss is verified by WoW plus BigWigs/DBM, or until the next pull.")
        elseif not difficultyKey then
            ns:Print("This encounter difficulty has no Raid Lead Assist profile; automatic timing is disabled.")
        end
    end

    UI:Initialize(self.db, {
        onBossSelected = function(key) self:SelectBoss(key, false) end,
        onDifficultySelected = function(key) self:SelectDifficulty(key, false) end,
        onExplanation = function() self:SendExplanation() end,
        onCall = function(callKey) self:SendCall(callKey) end,
        onUpdate = function() self:UpdateTiming() end,
        onSettings = function() SettingsUI:Open(self.activeBossKey) end,
    })
    UI:SetDifficulty(self.activeDifficultyKey)
    UI:SetDifficultyLocked(Encounter:IsActive())

    SettingsUI:Initialize(self.db, {
        getProviderSummary = function() return Timeline:GetProviderDiagnostics() end,
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

        local difficultyKey = Constants.DIFFICULTY_KEY_BY_ID[difficultyID]
        if not Encounter:HasKnownEncounter() then
            owner.timingAllowed = false
            Timeline:Reset()
            ns:Print("This encounter has no Raid Lead Assist profile; calls and automatic timing are disabled for this pull.")
        elseif difficultyKey then
            owner:SelectDifficulty(difficultyKey, true)
            owner.timingAllowed = true
        else
            owner.timingAllowed = false
            Timeline:Reset()
            ns:Print("Only Normal, Heroic, and Mythic profiles are supported; calls and automatic timing are disabled.")
        end

        UI:SetDifficultyLocked(true)
        UI:SetSettingsEnabled(false, "Settings are available outside active encounters.")
        SettingsUI:CloseForEncounter()
    end)
    EventBus:On("ENCOUNTER_RECOVERED", self, function(owner, _, difficultyID, providerName)
        local difficultyKey = Constants.DIFFICULTY_KEY_BY_ID[difficultyID]
        if not difficultyKey or not Encounter:HasKnownEncounter() then return end

        RaidWarning:CancelBriefing()
        resetTransientState(owner)
        owner:SelectDifficulty(difficultyKey, true)
        owner.timingAllowed = true
        UI:SetDifficultyLocked(true)
        UI:SetSettingsEnabled(false, "Settings are available outside active encounters.")
        SettingsUI:CloseForEncounter()
        UI:ResetCallStates()
        ns:Print(("Recovered active %s encounter after reload using a verified %s encounter hint; timing restored."):format(
            tostring(owner.activeBossKey or "boss"),
            tostring(providerName or "bossmod")
        ))
    end)
    EventBus:On("ENCOUNTER_ENDED", self, function(owner)
        RaidWarning:CancelBriefing()
        resetTransientState(owner)
        owner.timingAllowed = true
        UI:SetDifficultyLocked(false)
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

function App:SelectDifficulty(key, automatic)
    if not Constants.DIFFICULTIES[key] then return false end

    if not automatic and Encounter:IsActive() then
        local liveDifficulty = Encounter:GetDifficultyKey()
        if liveDifficulty then
            ns:Print("Difficulty is locked to " .. Constants.DIFFICULTIES[liveDifficulty].name .. " during this encounter.")
            UI:SetDifficulty(liveDifficulty)
        else
            ns:Print("Difficulty changes are locked during an active encounter.")
            UI:SetDifficulty(self.activeDifficultyKey)
        end
        return false
    end

    if not automatic and key ~= self.activeDifficultyKey and settingsAreOpen() then
        ns:Print("Close Settings before changing difficulty so an open Raid Warning draft cannot move to another profile.")
        UI:SetDifficulty(self.activeDifficultyKey)
        return false
    end

    RaidWarning:CancelBriefing()
    self.activeDifficultyKey = key
    self.db.selectedDifficultyKey = key
    Registry:SetActiveDifficulty(key)
    resetTransientState(self)
    Timeline:SetEncounter(self.activeBossKey, automatic == true)
    UI:SetDifficulty(key)
    UI:ResetCallStates()
    return true
end

function App:SelectBoss(key, automatic)
    local encounter = Registry:Get(key)
    local profile = Registry:GetProfile(key, self.activeDifficultyKey)
    if not encounter or not profile then return false end

    if not automatic and Encounter:IsActive() and Encounter:HasKnownEncounter() then
        ns:Print("Boss selection is locked to the active encounter.")
        return false
    end

    RaidWarning:CancelBriefing()
    self.activeBossKey = key
    self.db.selectedBossKey = key
    resetTransientState(self)
    Timeline:SetEncounter(key, automatic)
    UI:SetEncounter(key)
    UI:ResetCallStates()

    if automatic then UI:Show() end
    return true
end

function App:SendExplanation()
    local profile = Registry:GetProfile(self.activeBossKey, self.activeDifficultyKey)
    if profile then RaidWarning:SendBriefing(Messages:GetExplanation(self.activeBossKey, self.activeDifficultyKey)) end
end

function App:SendCall(callKey)
    local profile = Registry:GetProfile(self.activeBossKey, self.activeDifficultyKey)
    local call = profile and profile.callsByKey[callKey]
    if not call then return end

    local now = GetTime()
    if (self.manualLockUntil[callKey] or 0) > now then return end

    if RaidWarning:Send(Messages:GetCallWarning(self.activeBossKey, self.activeDifficultyKey, callKey)) then
        self.manualLockUntil[callKey] = now + Constants.MANUAL_CLICK_LOCK_SECONDS
        Timeline:AcknowledgeCall(callKey)
        self.visualCalledUntil[callKey] = now + Constants.CALLED_FEEDBACK_SECONDS
        UI:SetCallState(callKey, Constants.CallState.CALLED)
    end
end

function App:UpdateTiming()
    local profile = Registry:GetProfile(self.activeBossKey, self.activeDifficultyKey)
    if not profile then return end

    if not self:IsAutomaticTimingEnabled() then
        for index = 1, #profile.calls do
            local call = profile.calls[index]
            local state = (self.visualCalledUntil[call.key] or 0) > GetTime()
                and Constants.CallState.CALLED
                or Constants.CallState.IDLE
            UI:SetCallState(call.key, state)
        end
        UI.timeline:SetIdle("AUTO TIMING OFF")
        return
    end

    for index = 1, #profile.calls do
        local call = profile.calls[index]
        local _, remaining = Timeline:GetActionableTimerForCall(call.key)
        local state = Constants.CallState.IDLE

        if (self.visualCalledUntil[call.key] or 0) > GetTime() then
            state = Constants.CallState.CALLED
        elseif remaining then
            state = Constants.GetCallState(call, remaining, true)
        elseif (self.manualLockUntil[call.key] or 0) > GetTime() then
            state = Constants.CallState.CALLED
        end

        UI:SetCallState(call.key, state)
    end

    if not profileUsesAutomaticTiming(profile) then
        UI.timeline:SetIdle("MANUAL CALLS ONLY")
        return
    end

    local timer, remaining = Timeline:GetNextActionableTimer()
    if not timer then timer, remaining = Timeline:GetNextTimer() end
    if not timer or not remaining then
        UI.timeline:SetIdle()
        return
    end

    UI.timeline:SetTimer(timer, remaining)

    local state = Constants.GetCallState(timer.call, remaining, Timeline:IsActionable(timer))
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
        elseif command == "timing" then
            argument = argument:lower()
            if argument == "on" then self.db.automaticTimingEnabled = true end
            if argument == "off" then self.db.automaticTimingEnabled = false end
            if SettingsUI.RefreshTimingButton then SettingsUI:RefreshTimingButton() end
            ns:Print("Automatic timing: " .. (self.db.automaticTimingEnabled and "on" or "off"))
        elseif command == "difficulty" then
            argument = argument:lower()
            if not self:SelectDifficulty(argument, false) then
                ns:Print("Difficulty: normal | heroic | mythic")
            end
        elseif command == "settings" then
            SettingsUI:Open(self.activeBossKey)
        elseif command == "provider" then
            local summary = Timeline:GetProviderDiagnostics()
            ns:Print("Timer sources: " .. (summary ~= "" and summary or "none"))
            local observed = currentTimerTrafficSummary()
            ns:Print("Active timer traffic: " .. (observed ~= "" and observed or "none"))
        elseif command == "doctor" then
            self:PrintDoctor()
        elseif command == "status" then
            local summary = Timeline:GetProviderSummary()
            local difficultyID = Encounter:GetDifficultyID()
            ns:Print(("v%s | boss=%s | profile=%s | encounter=%s | difficulty=%s | timing=%s | providers=%s | db=%s"):format(
                tostring(ns.version),
                tostring(self.activeBossKey or "none"),
                tostring(self.activeDifficultyKey or "none"),
                Encounter:IsActive() and "active" or "idle",
                tostring(difficultyID or "none"),
                self:IsAutomaticTimingEnabled() and "on" or (self.db.automaticTimingEnabled == false and "user-off" or "blocked"),
                summary ~= "" and summary or "none",
                tostring(self.db.schemaVersion or "unknown")
            ))
        else
            ns:Print("/rla show | hide | toggle | settings | difficulty normal|heroic|mythic | resetpos | audio on|off | timing on|off | provider | doctor | status")
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
