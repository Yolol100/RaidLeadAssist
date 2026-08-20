local _, ns = ...

local Theme = ns:GetModule("UI.Theme")
local ActionButton = ns:GetModule("UI.ActionButton")
local MainUI = ns:GetModule("UI.MainFrame")
local SettingsUI = ns:GetModule("UI.SettingsFrame")
local AssignmentUI = ns:GetModule("UI.AssignmentFrame")

local ProductivityPanel = {
    callbacks = {},
    attached = false,
    readinessButton = nil,
    timingButton = nil,
    timingPanel = nil,
    presetButton = nil,
    personalButton = nil,
    presetPanel = nil,
}

local function setBackdrop(frame, color)
    frame:SetBackdropColor(color[1], color[2], color[3], color[4] or 1)
end

local function createEditBox(parent, width)
    local edit = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    edit:SetSize(width, 30)
    edit:SetAutoFocus(false)
    edit:SetMaxLetters(32)
    edit:SetFont(Theme.font, 10, "")
    edit:SetTextColor(Theme.colors.text[1], Theme.colors.text[2], Theme.colors.text[3], 1)
    edit:SetTextInsets(8, 8, 4, 4)
    edit:SetBackdrop({ bgFile = Theme.texture, edgeFile = Theme.texture, edgeSize = 1 })
    setBackdrop(edit, Theme.colors.background)
    edit:SetBackdropBorderColor(Theme.colors.borderStrong[1], Theme.colors.borderStrong[2], Theme.colors.borderStrong[3], 1)
    edit:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
    edit:SetScript("OnEnterPressed", function(box) box:ClearFocus() end)
    return edit
end

local function setInputInvalid(edit, invalid)
    if invalid then
        edit:SetBackdropBorderColor(Theme.colors.error[1], Theme.colors.error[2], Theme.colors.error[3], 1)
    else
        edit:SetBackdropBorderColor(Theme.colors.borderStrong[1], Theme.colors.borderStrong[2], Theme.colors.borderStrong[3], 1)
    end
end

local function createPopover(parent, width, height)
    local panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    panel:SetSize(width, height)
    panel:SetFrameLevel(parent:GetFrameLevel() + 30)
    panel:SetClampedToScreen(true)
    panel:SetBackdrop({ bgFile = Theme.texture, edgeFile = Theme.texture, edgeSize = 1 })
    setBackdrop(panel, Theme.colors.backgroundSolid)
    panel:SetBackdropBorderColor(Theme.colors.borderStrong[1], Theme.colors.borderStrong[2], Theme.colors.borderStrong[3], 1)
    panel:Hide()
    return panel
end

local function setStatusColor(status, ok)
    local color = ok and Theme.colors.success or Theme.colors.error
    status:SetTextColor(color[1], color[2], color[3], 1)
end

function ProductivityPanel:SetCallbacks(callbacks)
    self.callbacks = callbacks or {}
end

function ProductivityPanel:SetReadinessState(state)
    if not self.readinessButton then return end
    state = type(state) == "table" and state or { ready = false, label = "CHECK", states = { "CHECK" } }
    self.readinessButton:SetActionText(state.label or (state.ready and "READY" or "CHECK"))
    self.readinessButton:SetActionVariant(state.ready and "primary" or "secondary")
    self.readinessButton.readinessState = state
end

function ProductivityPanel:AttachReadiness()
    if self.readinessButton or not MainUI.frame or not MainUI.frame.settingsButton then return end
    local button = ActionButton:Create(MainUI.frame, {
        text = "CHECK",
        width = 60,
        height = 24,
        fontSize = 9,
        variant = "secondary",
    })
    button:SetPoint("RIGHT", MainUI.frame.settingsButton, "LEFT", -4, 0)
    if MainUI.frame.drag then button:SetFrameLevel(MainUI.frame.drag:GetFrameLevel() + 1) end
    button:SetScript("OnClick", function()
        if self.callbacks.onReadiness then self.callbacks.onReadiness() end
    end)
    button:HookScript("OnEnter", function(control)
        local state = control.readinessState or { ready = false, states = { "CHECK" } }
        GameTooltip:SetOwner(control, "ANCHOR_TOP")
        GameTooltip:SetText(state.ready and "Raid plan readiness: READY" or "Raid plan readiness: CHECK", 0.82, 0.86, 0.82, 1)
        GameTooltip:AddLine(table.concat(state.states or {}, " | "), 0.60, 0.72, 0.64, true)
        GameTooltip:AddLine("Click for the full doctor report.", 0.55, 0.63, 0.58, true)
        GameTooltip:Show()
    end)
    button:HookScript("OnLeave", function() GameTooltip:Hide() end)
    self.readinessButton = button
end

function ProductivityPanel:RefreshTiming()
    if not self.timingButton then return end
    local prepare, press = 5, 3
    if self.callbacks.getTimingLead then
        local valuePrepare, valuePress = self.callbacks.getTimingLead()
        if type(valuePrepare) == "number" then prepare = valuePrepare end
        if type(valuePress) == "number" then press = valuePress end
    end
    self.timingButton:SetActionText(("LEADS %g/%g"):format(prepare, press))
    if self.timingPrepare then self.timingPrepare:SetText(tostring(prepare)) end
    if self.timingPress then self.timingPress:SetText(tostring(press)) end
end

function ProductivityPanel:AttachTiming()
    if self.timingButton or not SettingsUI.frame or not SettingsUI.timingButton then return end

    local button = ActionButton:Create(SettingsUI.frame, {
        text = "LEADS 5/3",
        width = 88,
        height = 22,
        fontSize = 9,
        variant = "secondary",
    })
    button:SetPoint("RIGHT", SettingsUI.timingButton, "LEFT", -6, 0)
    button:HookScript("OnEnter", function(control)
        GameTooltip:SetOwner(control, "ANCHOR_TOP")
        GameTooltip:SetText("Default timing lead windows", 0.82, 0.86, 0.82, 1)
        GameTooltip:AddLine("PREPARE / PRESS defaults for timed calls. Encounter-specific call windows remain authoritative.", 0.55, 0.63, 0.58, true)
        GameTooltip:Show()
    end)
    button:HookScript("OnLeave", function() GameTooltip:Hide() end)

    local panel = createPopover(SettingsUI.frame, 340, 178)
    panel:SetPoint("TOPRIGHT", button, "BOTTOMRIGHT", 0, -6)

    local title = panel:CreateFontString(nil, "OVERLAY")
    title:SetFont(Theme.font, 13, "OUTLINE")
    title:SetPoint("TOPLEFT", 14, -13)
    title:SetText("Default Lead Windows")
    title:SetTextColor(1, 1, 1, 1)

    local helper = panel:CreateFontString(nil, "OVERLAY")
    helper:SetFont(Theme.font, 8, "OUTLINE")
    helper:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    helper:SetPoint("RIGHT", -14, 0)
    helper:SetJustifyH("LEFT")
    helper:SetText("Used only when a call has no encounter-specific lead window. PREPARE must be greater than PRESS.")
    helper:SetTextColor(Theme.colors.muted[1], Theme.colors.muted[2], Theme.colors.muted[3], 1)

    local prepareLabel = panel:CreateFontString(nil, "OVERLAY")
    prepareLabel:SetFont(Theme.font, 9, "OUTLINE")
    prepareLabel:SetPoint("TOPLEFT", 14, -70)
    prepareLabel:SetText("PREPARE seconds")
    prepareLabel:SetTextColor(Theme.colors.text[1], Theme.colors.text[2], Theme.colors.text[3], 1)

    local pressLabel = panel:CreateFontString(nil, "OVERLAY")
    pressLabel:SetFont(Theme.font, 9, "OUTLINE")
    pressLabel:SetPoint("TOPLEFT", 174, -70)
    pressLabel:SetText("PRESS seconds")
    pressLabel:SetTextColor(Theme.colors.text[1], Theme.colors.text[2], Theme.colors.text[3], 1)

    local prepare = createEditBox(panel, 146)
    prepare:SetPoint("TOPLEFT", 14, -86)
    local press = createEditBox(panel, 146)
    press:SetPoint("TOPLEFT", 174, -86)

    local status = panel:CreateFontString(nil, "OVERLAY")
    status:SetFont(Theme.font, 8, "OUTLINE")
    status:SetPoint("BOTTOMLEFT", 14, 16)
    status:SetPoint("RIGHT", -210, 0)
    status:SetJustifyH("LEFT")
    status:SetTextColor(Theme.colors.muted[1], Theme.colors.muted[2], Theme.colors.muted[3], 1)

    local close = ActionButton:Create(panel, { text = "CLOSE", width = 62, height = 24, fontSize = 8, variant = "secondary" })
    close:SetPoint("BOTTOMRIGHT", -14, 12)
    close:SetScript("OnClick", function() panel:Hide() end)

    local reset = ActionButton:Create(panel, { text = "RESET", width = 62, height = 24, fontSize = 8, variant = "secondary" })
    reset:SetPoint("RIGHT", close, "LEFT", -6, 0)
    reset:SetScript("OnClick", function()
        local ok, message = false, "Timing defaults are unavailable."
        if self.callbacks.resetTimingLead then ok, message = self.callbacks.resetTimingLead() end
        if ok then
            setInputInvalid(prepare, false)
            setInputInvalid(press, false)
            self:RefreshTiming()
            status:SetText(message or "Reset to defaults.")
            setStatusColor(status, true)
            if SettingsUI.SetStatus then SettingsUI:SetStatus(message or "Default lead windows reset.", "success") end
        else
            status:SetText(message or "Timing defaults are unavailable.")
            setStatusColor(status, false)
        end
    end)

    local save = ActionButton:Create(panel, { text = "SAVE", width = 62, height = 24, fontSize = 8, variant = "primary" })
    save:SetPoint("RIGHT", reset, "LEFT", -6, 0)
    save:SetScript("OnClick", function()
        local ok, message = false, "Timing defaults are unavailable."
        if self.callbacks.saveTimingLead then ok, message = self.callbacks.saveTimingLead(prepare:GetText(), press:GetText()) end
        setInputInvalid(prepare, not ok)
        setInputInvalid(press, not ok)
        if ok then
            self:RefreshTiming()
            status:SetText(message or "Saved.")
            setStatusColor(status, true)
            if SettingsUI.SetStatus then SettingsUI:SetStatus(message or "Default lead windows saved.", "success") end
        else
            status:SetText(message or "Check PREPARE and PRESS values.")
            setStatusColor(status, false)
        end
    end)

    button:SetScript("OnClick", function()
        if panel:IsShown() then
            panel:Hide()
        else
            self:RefreshTiming()
            status:SetText("")
            setInputInvalid(prepare, false)
            setInputInvalid(press, false)
            panel:Show()
            panel:Raise()
        end
    end)

    SettingsUI.frame:HookScript("OnHide", function() panel:Hide() end)
    self.timingButton = button
    self.timingPanel = panel
    self.timingPrepare = prepare
    self.timingPress = press
    self.timingStatus = status
    self:RefreshTiming()
end

function ProductivityPanel:RefreshPresetPanel()
    if not self.presetPanel or not AssignmentUI.currentBossKey then return end
    local names = {}
    if self.callbacks.listPresets then
        names = self.callbacks.listPresets(AssignmentUI.currentBossKey, AssignmentUI.currentDifficultyKey) or {}
    end
    if self.presetList then
        self.presetList:SetText(#names > 0 and ("Saved: " .. table.concat(names, ", ")) or "Saved: none for this boss/difficulty")
    end
end

function ProductivityPanel:AttachPresets()
    if self.presetButton or not AssignmentUI.frame then return end

    local presetButton = ActionButton:Create(AssignmentUI.frame, {
        text = "PRESETS",
        width = 76,
        height = 24,
        fontSize = 8,
        variant = "secondary",
    })
    presetButton:SetPoint("TOPRIGHT", -48, -43)

    local personalButton = ActionButton:Create(AssignmentUI.frame, {
        text = "MY TASKS",
        width = 78,
        height = 24,
        fontSize = 8,
        variant = "secondary",
    })
    personalButton:SetPoint("RIGHT", presetButton, "LEFT", -6, 0)
    personalButton:SetScript("OnClick", function()
        if self.callbacks.showPersonalAssignments then
            self.callbacks.showPersonalAssignments(AssignmentUI.currentBossKey, AssignmentUI.currentDifficultyKey)
        end
        if AssignmentUI.SetStatus then AssignmentUI:SetStatus("Personal assignments printed to chat.", "success") end
    end)
    personalButton:HookScript("OnEnter", function(control)
        GameTooltip:SetOwner(control, "ANCHOR_TOP")
        GameTooltip:SetText("My Tasks", 0.82, 0.86, 0.82, 1)
        GameTooltip:AddLine("Local read-only view of direct, rotation and raid-group duties for the assignment plan currently open here.", 0.55, 0.63, 0.58, true)
        GameTooltip:Show()
    end)
    personalButton:HookScript("OnLeave", function() GameTooltip:Hide() end)

    local panel = createPopover(AssignmentUI.frame, 470, 188)
    panel:SetPoint("TOPRIGHT", presetButton, "BOTTOMRIGHT", 0, -6)

    local title = panel:CreateFontString(nil, "OVERLAY")
    title:SetFont(Theme.font, 13, "OUTLINE")
    title:SetPoint("TOPLEFT", 14, -13)
    title:SetText("Assignment Presets")
    title:SetTextColor(1, 1, 1, 1)

    local helper = panel:CreateFontString(nil, "OVERLAY")
    helper:SetFont(Theme.font, 8, "OUTLINE")
    helper:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    helper:SetPoint("RIGHT", -14, 0)
    helper:SetJustifyH("LEFT")
    helper:SetText("Local pre-pull presets are scoped to the boss and difficulty currently open in this assignment window.")
    helper:SetTextColor(Theme.colors.muted[1], Theme.colors.muted[2], Theme.colors.muted[3], 1)

    local list = panel:CreateFontString(nil, "OVERLAY")
    list:SetFont(Theme.font, 8, "OUTLINE")
    list:SetPoint("TOPLEFT", 14, -63)
    list:SetPoint("RIGHT", -14, 0)
    list:SetJustifyH("LEFT")
    list:SetTextColor(Theme.colors.muted[1], Theme.colors.muted[2], Theme.colors.muted[3], 1)

    local name = createEditBox(panel, 210)
    name:SetPoint("TOPLEFT", 14, -88)

    local status = panel:CreateFontString(nil, "OVERLAY")
    status:SetFont(Theme.font, 8, "OUTLINE")
    status:SetPoint("BOTTOMLEFT", 14, 16)
    status:SetPoint("RIGHT", -305, 0)
    status:SetJustifyH("LEFT")
    status:SetTextColor(Theme.colors.muted[1], Theme.colors.muted[2], Theme.colors.muted[3], 1)

    local close = ActionButton:Create(panel, { text = "CLOSE", width = 58, height = 24, fontSize = 8, variant = "secondary" })
    close:SetPoint("BOTTOMRIGHT", -14, 12)
    close:SetScript("OnClick", function() panel:Hide() end)

    local delete = ActionButton:Create(panel, { text = "DELETE", width = 64, height = 24, fontSize = 8, variant = "destructive" })
    delete:SetPoint("RIGHT", close, "LEFT", -6, 0)
    delete:SetScript("OnClick", function()
        local ok, message = false, "Preset delete is unavailable."
        if self.callbacks.deletePreset then
            ok, message = self.callbacks.deletePreset(name:GetText(), AssignmentUI.currentBossKey, AssignmentUI.currentDifficultyKey)
        end
        status:SetText(message or (ok and "Preset deleted." or "Preset not deleted."))
        setStatusColor(status, ok)
        if ok then self:RefreshPresetPanel() end
    end)

    local load = ActionButton:Create(panel, { text = "LOAD", width = 58, height = 24, fontSize = 8, variant = "secondary" })
    load:SetPoint("RIGHT", delete, "LEFT", -6, 0)
    local function loadSelectedPreset()
        local bossKey = AssignmentUI.currentBossKey
        local difficultyKey = AssignmentUI.currentDifficultyKey
        local ok, message = false, "Preset load is unavailable."
        if self.callbacks.loadPreset then
            ok, message = self.callbacks.loadPreset(name:GetText(), bossKey, difficultyKey)
        end
        status:SetText(message or (ok and "Preset loaded." or "Preset not loaded."))
        setStatusColor(status, ok)
        if ok then
            AssignmentUI:Load(bossKey, difficultyKey)
            self:RefreshPresetPanel()
        end
    end
    load:SetScript("OnClick", function()
        if AssignmentUI.dirty then
            AssignmentUI:ConfirmTransition(
                "Save this assignment draft before loading the selected preset?",
                loadSelectedPreset,
                function() end
            )
        else
            loadSelectedPreset()
        end
    end)

    local save = ActionButton:Create(panel, { text = "SAVE", width = 58, height = 24, fontSize = 8, variant = "primary" })
    save:SetPoint("RIGHT", load, "LEFT", -6, 0)
    save:SetScript("OnClick", function()
        if AssignmentUI.dirty and not AssignmentUI:SaveCurrent(true) then
            status:SetText("Fix the assignment draft before saving a preset.")
            setStatusColor(status, false)
            return
        end
        local ok, message = false, "Preset save is unavailable."
        if self.callbacks.savePreset then
            ok, message = self.callbacks.savePreset(name:GetText(), AssignmentUI.currentBossKey, AssignmentUI.currentDifficultyKey)
        end
        status:SetText(message or (ok and "Preset saved." or "Preset not saved."))
        setStatusColor(status, ok)
        if ok then self:RefreshPresetPanel() end
    end)

    presetButton:SetScript("OnClick", function()
        if panel:IsShown() then
            panel:Hide()
        else
            status:SetText("")
            self:RefreshPresetPanel()
            panel:Show()
            panel:Raise()
        end
    end)
    presetButton:HookScript("OnEnter", function(control)
        GameTooltip:SetOwner(control, "ANCHOR_TOP")
        GameTooltip:SetText("Assignment Presets", 0.82, 0.86, 0.82, 1)
        GameTooltip:AddLine("Save, load or delete validated local pre-pull plans for this boss and difficulty.", 0.55, 0.63, 0.58, true)
        GameTooltip:Show()
    end)
    presetButton:HookScript("OnLeave", function() GameTooltip:Hide() end)

    AssignmentUI.frame:HookScript("OnHide", function() panel:Hide() end)
    self.presetButton = presetButton
    self.personalButton = personalButton
    self.presetPanel = panel
    self.presetName = name
    self.presetList = list
    self.presetStatus = status
end

function ProductivityPanel:Attach(callbacks)
    if self.attached then return end
    self:SetCallbacks(callbacks)
    self:AttachReadiness()
    self:AttachTiming()
    self:AttachPresets()
    self.attached = true
end

ns:RegisterModule("UI.ProductivityPanel", ProductivityPanel)
