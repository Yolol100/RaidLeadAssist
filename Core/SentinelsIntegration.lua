local _, ns = ...

local Theme = ns:GetModule("UI.Theme")
local UI = ns:GetModule("UI.MainFrame")
local SentinelsPanel = ns:GetModule("UI.SentinelsPanel")

local originalInitialize = UI.Initialize
local originalSetEncounter = UI.SetEncounter
local originalSetCallState = UI.SetCallState
local originalResetCallStates = UI.ResetCallStates

local function sentinelsHeight(panelHeight)
    local height = 28
    height = height + Theme.dropdownHeight
    height = height + 7 + Theme.difficultyTabHeight
    height = height + 8 + Theme.timelineHeight
    height = height + 16 + Theme.sectionTitleHeight + 7 + Theme.explanationButtonHeight
    height = height + 16 + panelHeight
    return height + Theme.padding
end

local function setGenericCallsVisible(owner, visible)
    if owner.callTitle then owner.callTitle:SetShown(visible) end
    for _, button in ipairs(owner.callButtons or {}) do
        button.frame:SetShown(visible and button.call ~= nil)
    end
end

local function refreshSentinelsPanel(owner)
    if not owner.sentinelsPanel or not owner.currentEncounter then return end

    if owner.currentEncounter.key ~= "sentinels" then
        owner.sentinelsPanel:Hide()
        setGenericCallsVisible(owner, true)
        return
    end

    local Registry = ns:GetModule("Encounters.Registry")
    local profile = Registry:GetProfile("sentinels", owner.currentDifficultyKey)
    if not profile then return end

    setGenericCallsVisible(owner, false)
    owner.sentinelsPanel:Configure(profile)
    owner.sentinelsPanel.frame:ClearAllPoints()
    owner.sentinelsPanel.frame:SetPoint("TOPLEFT", owner.explanationButton.frame, "BOTTOMLEFT", 0, -16)
    owner.sentinelsPanel.frame:SetPoint("RIGHT", owner.dropdown.frame, "RIGHT", 0, 0)
    owner.sentinelsPanel:Show()
    owner.frame:SetHeight(sentinelsHeight(owner.sentinelsPanel.height))
end

function UI:Initialize(database, callbacks)
    originalInitialize(self, database, callbacks)
    self.sentinelsPanel = SentinelsPanel:Create(self.frame, self)
    self.frame:HookScript("OnUpdate", function(_, elapsed)
        if self.sentinelsPanel then self.sentinelsPanel:UpdateHealth(elapsed) end
    end)
    refreshSentinelsPanel(self)
end

function UI:SetEncounter(encounterKey)
    originalSetEncounter(self, encounterKey)
    refreshSentinelsPanel(self)
end

function UI:SetCallState(callKey, state)
    if self.currentEncounter and self.currentEncounter.key == "sentinels" and self.sentinelsPanel then
        if self.sentinelsPanel:SetCallState(callKey, state) then return end
    end
    originalSetCallState(self, callKey, state)
end

function UI:ResetCallStates()
    originalResetCallStates(self)
    if self.sentinelsPanel then self.sentinelsPanel:ResetCallStates() end
end

ns:RegisterModule("Core.SentinelsIntegration", {})
