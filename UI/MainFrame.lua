local _, ns = ...

local Constants = ns:GetModule("Core.Constants")
local Registry = ns:GetModule("Encounters.Registry")
local Theme = ns:GetModule("UI.Theme")
local Dropdown = ns:GetModule("UI.Dropdown")
local TimelineBar = ns:GetModule("UI.TimelineBar")
local CallButton = ns:GetModule("UI.CallButton")
local Messages = ns:GetModule("Services.MessageService")

local MainFrame = {
    callButtons = {},
    difficultyTabs = {},
    currentEncounter = nil,
    currentDifficultyKey = "heroic",
    difficultyLocked = false,
    settingsEnabled = true,
}

local function createSectionTitle(parent, text)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont(Theme.font, 15, "OUTLINE")
    label:SetTextColor(1, 1, 1, 1)
    label:SetText(text)
    label:SetJustifyH("LEFT")
    label:SetHeight(Theme.sectionTitleHeight)
    return label
end

local function calculateCallStackHeight(callCount)
    if callCount <= 0 then return 0 end
    return (callCount * Theme.callButtonHeight) + (math.max(0, callCount - 1) * Theme.gap)
end

local function calculateHeight(callCount)
    local height = 28
    height = height + Theme.dropdownHeight
    height = height + 7 + Theme.difficultyTabHeight
    height = height + 8 + Theme.timelineHeight
    height = height + 14 + Theme.sectionTitleHeight + 6 + Theme.explanationButtonHeight
    height = height + 14 + Theme.sectionTitleHeight + 6
    height = height + calculateCallStackHeight(callCount)
    return height + Theme.padding
end

local function calculateVisibleHeight(callCount)
    local desired = calculateHeight(callCount)
    local parentHeight = UIParent and UIParent.GetHeight and UIParent:GetHeight()
    if type(parentHeight) ~= "number" or parentHeight <= 0 then return desired end

    local scale = MainFrame.database and tonumber(MainFrame.database.uiScale) or 1
    scale = math.max(0.70, math.min(1.10, scale))
    local minimum = calculateHeight(1)
    local screenCap = math.max(minimum, (parentHeight - 48) / scale)
    return math.min(desired, screenCap)
end

local function setBackdropColor(frame, color)
    frame:SetBackdropColor(color[1], color[2], color[3], color[4] or 1)
end

local function clampUIScale(value)
    return math.max(0.70, math.min(1.10, value))
end

function MainFrame:SetUIScale(scale)
    if not self.frame or not self.database then return end
    scale = clampUIScale(tonumber(scale) or 1)
    scale = math.floor((scale * 20) + 0.5) / 20
    self.database.uiScale = scale
    self.frame:SetScale(scale)
    if self.currentEncounter then self:SetEncounter(self.currentEncounter.key) end
end

function MainFrame:SetSettingsEnabled(enabled, reason)
    self.settingsEnabled = enabled == true
    self.settingsDisabledReason = self.settingsEnabled and nil or reason
    if not self.frame or not self.frame.settingsButton then return end

    self.frame.settingsButton:SetEnabled(true)
    if self.settingsEnabled then
        self.frame.settingsButton.text:SetTextColor(Theme.colors.muted[1], Theme.colors.muted[2], Theme.colors.muted[3], 1)
    else
        self.frame.settingsButton.text:SetTextColor(0.34, 0.40, 0.36, 1)
    end
end

function MainFrame:RefreshDifficultyTabs()
    for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
        local tab = self.difficultyTabs[difficultyKey]
        if tab then
            local selected = difficultyKey == self.currentDifficultyKey
            if selected then
                setBackdropColor(tab, Theme.colors.venomDark)
                tab:SetBackdropBorderColor(Theme.colors.venom[1], Theme.colors.venom[2], Theme.colors.venom[3], 1)
                tab.text:SetTextColor(1, 1, 1, 1)
            else
                setBackdropColor(tab, Theme.colors.surface)
                tab:SetBackdropBorderColor(Theme.colors.border[1], Theme.colors.border[2], Theme.colors.border[3], 1)
                local color = self.difficultyLocked and Theme.colors.muted or Theme.colors.text
                tab.text:SetTextColor(color[1], color[2], color[3], 1)
            end
            tab:SetEnabled(not self.difficultyLocked)
        end
    end

    if self.frame and self.frame.raidLabel then
        local info = Constants.DIFFICULTIES[self.currentDifficultyKey]
        local suffix = info and (" \194\183 " .. info.label) or ""
        self.frame.raidLabel:SetText(Constants.RAID_NAME .. suffix)
    end
end

function MainFrame:SetDifficultyLocked(locked)
    self.difficultyLocked = locked == true
    self:RefreshDifficultyTabs()
end

function MainFrame:SetDifficulty(difficultyKey)
    if not Constants.DIFFICULTIES[difficultyKey] then return false end
    self.currentDifficultyKey = difficultyKey
    self:RefreshDifficultyTabs()
    if self.currentEncounter then self:SetEncounter(self.currentEncounter.key) end
    return true
end

function MainFrame:EnsureCallButtons(count)
    while #self.callButtons < count do
        local index = #self.callButtons + 1
        local button = CallButton:Create(self.callContent)
        button.frame:SetPoint("LEFT", self.callContent, "LEFT", 0, 0)
        button.frame:SetPoint("RIGHT", self.callContent, "RIGHT", 0, 0)
        if index == 1 then
            button.frame:SetPoint("TOP", self.callContent, "TOP", 0, 0)
        else
            button.frame:SetPoint("TOP", self.callButtons[index - 1].frame, "BOTTOM", 0, -Theme.gap)
        end
        button.frame:Hide()
        self.callButtons[index] = button
    end
end

function MainFrame:Initialize(database, callbacks)
    self.database = database
    self.callbacks = callbacks
    self.currentDifficultyKey = Constants.DIFFICULTIES[database.selectedDifficultyKey] and database.selectedDifficultyKey or "heroic"

    local frame = CreateFrame("Frame", "RaidLeadAssistMainFrame", UIParent, "BackdropTemplate")
    frame:SetWidth(Theme.width)
    frame:SetBackdrop({ bgFile = Theme.texture, edgeFile = Theme.texture, edgeSize = 1 })
    frame:SetBackdropColor(Theme.colors.backgroundSolid[1], Theme.colors.backgroundSolid[2], Theme.colors.backgroundSolid[3], 0.94)
    frame:SetBackdropBorderColor(Theme.colors.border[1], Theme.colors.border[2], Theme.colors.border[3], 0.95)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetScale(clampUIScale(tonumber(database.uiScale) or 1))

    local position = database.position
    frame:SetPoint(position.point, UIParent, position.relativePoint, position.x, position.y)

    frame.drag = CreateFrame("Button", nil, frame)
    frame.drag:SetPoint("TOPLEFT", 0, 0)
    frame.drag:SetPoint("TOPRIGHT", 0, 0)
    frame.drag:SetHeight(24)
    frame.drag:RegisterForDrag("LeftButton")
    frame.drag:EnableMouseWheel(true)
    frame.drag:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    frame.drag:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        local point, _, relativePoint, x, y = frame:GetPoint(1)
        database.position.point = point
        database.position.relativePoint = relativePoint
        database.position.x = x
        database.position.y = y
    end)
    frame.drag:SetScript("OnMouseWheel", function(_, delta)
        if not IsControlKeyDown() then return end
        self:SetUIScale((tonumber(database.uiScale) or 1) + (delta > 0 and 0.05 or -0.05))
    end)
    frame.drag:SetScript("OnEnter", function(button)
        GameTooltip:SetOwner(button, "ANCHOR_TOP")
        GameTooltip:SetText("Drag to move Raid Lead Assist", 0.82, 0.86, 0.82, 1)
        GameTooltip:AddLine(("Ctrl + mouse wheel to resize (%d%%)"):format(math.floor((database.uiScale or 1) * 100 + 0.5)), 0.55, 0.63, 0.58, true)
        GameTooltip:Show()
    end)
    frame.drag:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    frame.raidLabel = frame:CreateFontString(nil, "OVERLAY")
    frame.raidLabel:SetFont(Theme.font, 10, "OUTLINE")
    frame.raidLabel:SetPoint("TOPLEFT", Theme.padding, -9)
    frame.raidLabel:SetTextColor(Theme.colors.venom[1], Theme.colors.venom[2], Theme.colors.venom[3], 1)

    frame.settingsButton = CreateFrame("Button", nil, frame)
    frame.settingsButton:SetSize(62, 26)
    frame.settingsButton:SetPoint("TOPRIGHT", -Theme.padding, -1)
    frame.settingsButton:SetFrameLevel(frame.drag:GetFrameLevel() + 1)
    frame.settingsButton.text = frame.settingsButton:CreateFontString(nil, "OVERLAY")
    frame.settingsButton.text:SetFont(Theme.font, 9, "OUTLINE")
    frame.settingsButton.text:SetAllPoints()
    frame.settingsButton.text:SetText("SETTINGS")
    frame.settingsButton.text:SetTextColor(Theme.colors.muted[1], Theme.colors.muted[2], Theme.colors.muted[3], 1)
    frame.settingsButton:SetScript("OnEnter", function(button)
        if self.settingsEnabled then
            button.text:SetTextColor(Theme.colors.venom[1], Theme.colors.venom[2], Theme.colors.venom[3], 1)
        else
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.settingsDisabledReason or "Settings are currently unavailable.", 0.82, 0.86, 0.82, 1)
            GameTooltip:Show()
        end
    end)
    frame.settingsButton:SetScript("OnLeave", function(button)
        GameTooltip:Hide()
        if self.settingsEnabled then
            button.text:SetTextColor(Theme.colors.muted[1], Theme.colors.muted[2], Theme.colors.muted[3], 1)
        else
            button.text:SetTextColor(0.34, 0.40, 0.36, 1)
        end
    end)
    frame.settingsButton:SetScript("OnClick", function()
        if self.settingsEnabled and callbacks.onSettings then callbacks.onSettings() end
    end)

    self.dropdown = Dropdown:Create(frame)
    self.dropdown.frame:SetHeight(Theme.dropdownHeight)
    self.dropdown.frame:SetPoint("TOPLEFT", Theme.padding, -28)
    self.dropdown.frame:SetPoint("TOPRIGHT", -Theme.padding, -28)
    self.dropdown.menu:SetPoint("TOPLEFT", self.dropdown.frame, "BOTTOMLEFT", 0, -2)
    self.dropdown.menu:SetPoint("TOPRIGHT", self.dropdown.frame, "BOTTOMRIGHT", 0, -2)

    local tabWidth = (Theme.width - (Theme.padding * 2) - (Theme.difficultyTabGap * 2)) / 3
    local previousTab
    for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
        local info = Constants.DIFFICULTIES[difficultyKey]
        local tab = CreateFrame("Button", nil, frame, "BackdropTemplate")
        tab:SetSize(tabWidth, Theme.difficultyTabHeight)
        tab:SetBackdrop({ bgFile = Theme.texture, edgeFile = Theme.texture, edgeSize = 1 })
        if previousTab then
            tab:SetPoint("LEFT", previousTab, "RIGHT", Theme.difficultyTabGap, 0)
        else
            tab:SetPoint("TOPLEFT", self.dropdown.frame, "BOTTOMLEFT", 0, -7)
        end
        tab.text = tab:CreateFontString(nil, "OVERLAY")
        tab.text:SetFont(Theme.font, 10, "OUTLINE")
        tab.text:SetAllPoints()
        tab.text:SetText(info.label)
        tab:SetScript("OnClick", function()
            if not self.difficultyLocked and callbacks.onDifficultySelected then callbacks.onDifficultySelected(difficultyKey) end
        end)
        tab:SetScript("OnEnter", function(button)
            if self.difficultyLocked or difficultyKey == self.currentDifficultyKey then return end
            button:SetBackdropBorderColor(Theme.colors.venom[1], Theme.colors.venom[2], Theme.colors.venom[3], 1)
        end)
        tab:SetScript("OnLeave", function()
            self:RefreshDifficultyTabs()
        end)
        self.difficultyTabs[difficultyKey] = tab
        previousTab = tab
    end

    self.timeline = TimelineBar:Create(frame)
    self.timeline.frame:SetHeight(Theme.timelineHeight)
    self.timeline.frame:SetPoint("TOPLEFT", self.difficultyTabs.normal, "BOTTOMLEFT", 0, -8)
    self.timeline.frame:SetPoint("TOPRIGHT", self.difficultyTabs.mythic, "BOTTOMRIGHT", 0, -8)

    self.explanationTitle = createSectionTitle(frame, "Boss Plan")
    self.explanationTitle:SetPoint("TOPLEFT", self.timeline.frame, "BOTTOMLEFT", 0, -14)

    self.explanationButton = CallButton:Create(frame)
    self.explanationButton.frame:SetHeight(Theme.explanationButtonHeight)
    self.explanationButton.frame:SetPoint("TOPLEFT", self.explanationTitle, "BOTTOMLEFT", 0, -6)
    self.explanationButton.frame:SetPoint("RIGHT", self.dropdown.frame, "RIGHT", 0, 0)
    self.explanationButton.frame.name:SetText("SEND PRE-PULL PLAN")
    self.explanationButton.frame:SetScript("OnClick", function()
        if callbacks.onExplanation then callbacks.onExplanation() end
    end)

    self.callTitle = createSectionTitle(frame, "Combat Call Buttons")
    self.callTitle:SetPoint("TOPLEFT", self.explanationButton.frame, "BOTTOMLEFT", 0, -14)

    self.callScroll = CreateFrame("ScrollFrame", nil, frame)
    self.callScroll:SetPoint("TOPLEFT", self.callTitle, "BOTTOMLEFT", 0, -6)
    self.callScroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -Theme.padding, Theme.padding)
    self.callScroll:EnableMouseWheel(true)

    self.callContent = CreateFrame("Frame", nil, self.callScroll)
    self.callContent:SetWidth(Theme.width - (Theme.padding * 2))
    self.callContent:SetHeight(Theme.callButtonHeight)
    self.callScroll:SetScrollChild(self.callContent)
    self.callScroll:SetScript("OnMouseWheel", function(scrollFrame, delta)
        local range = scrollFrame:GetVerticalScrollRange() or 0
        local step = (Theme.callButtonHeight + Theme.gap) * 2
        local offset = scrollFrame:GetVerticalScroll() - (delta * step)
        scrollFrame:SetVerticalScroll(math.max(0, math.min(range, offset)))
    end)

    frame:SetScript("OnUpdate", function(_, elapsed)
        self.updateAccumulator = (self.updateAccumulator or 0) + elapsed
        if self.updateAccumulator >= 0.05 then
            self.updateAccumulator = 0
            if callbacks.onUpdate then callbacks.onUpdate() end
        end
    end)

    self.frame = frame
    self:RefreshDifficultyTabs()
    self:RefreshDropdown(database.selectedBossKey)
    self:SetEncounter(database.selectedBossKey)
end

function MainFrame:RefreshDropdown(selectedKey)
    local options = Registry:GetOrdered()
    self.dropdown:SetOptions(options, selectedKey, function(key)
        if self.callbacks.onBossSelected then self.callbacks.onBossSelected(key) end
    end)
end

function MainFrame:SetEncounter(encounterKey)
    local encounter = Registry:Get(encounterKey)
    local profile = Registry:GetProfile(encounterKey, self.currentDifficultyKey)
    if not encounter or not profile then return end

    self.currentEncounter = encounter
    self.dropdown:SetSelected(encounterKey, Registry:GetOrdered())
    self:EnsureCallButtons(#profile.calls)

    local difficultyInfo = Constants.DIFFICULTIES[self.currentDifficultyKey]
    self.explanationButton.frame.action:SetText("Send " .. difficultyInfo.name .. " plan as Raid Warning")

    for index = 1, #self.callButtons do
        local button = self.callButtons[index]
        local call = profile.calls[index]
        if call then
            button:SetCall(call, function(callKey)
                if self.callbacks.onCall then self.callbacks.onCall(callKey) end
            end, function(callKey)
                return Messages:GetCallWarning(encounterKey, self.currentDifficultyKey, callKey)
            end)
        else
            button.frame:Hide()
        end
    end

    self.callContent:SetHeight(math.max(Theme.callButtonHeight, calculateCallStackHeight(#profile.calls)))
    self.callScroll:SetVerticalScroll(0)
    self.frame:SetHeight(calculateVisibleHeight(#profile.calls))
end

function MainFrame:SetCallState(callKey, state)
    if not self.currentEncounter then return end
    local profile = Registry:GetProfile(self.currentEncounter.key, self.currentDifficultyKey)
    if not profile then return end

    for index = 1, #profile.calls do
        if profile.calls[index].key == callKey then
            self.callButtons[index]:SetState(state)
            return
        end
    end
end

function MainFrame:ResetCallStates()
    if not self.currentEncounter then return end
    local profile = Registry:GetProfile(self.currentEncounter.key, self.currentDifficultyKey)
    if not profile then return end
    for index = 1, #profile.calls do
        self.callButtons[index]:SetState(Constants.CallState.IDLE)
    end
end

function MainFrame:Show()
    self.frame:Show()
end

function MainFrame:Hide()
    if self.dropdown and self.dropdown.Close then self.dropdown:Close() end
    self.frame:Hide()
end

function MainFrame:IsShown()
    return self.frame:IsShown()
end

ns:RegisterModule("UI.MainFrame", MainFrame)
