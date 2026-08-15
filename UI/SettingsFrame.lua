local _, ns = ...

local Registry = ns:GetModule("Encounters.Registry")
local Messages = ns:GetModule("Services.MessageService")
local Theme = ns:GetModule("UI.Theme")
local Dropdown = ns:GetModule("UI.Dropdown")
local SettingsField = ns:GetModule("UI.SettingsField")
local ActionButton = ns:GetModule("UI.ActionButton")
local ConfirmDialog = ns:GetModule("UI.ConfirmDialog")

local SettingsFrame = {
    selectedBossKey = nil,
    callFields = {},
    dirty = false,
    allowHide = false,
}

local function setBackdropColor(frame, color)
    frame:SetBackdropColor(color[1], color[2], color[3], color[4] or 1)
end

function SettingsFrame:SetStatus(message, kind)
    if not self.status then return end
    self.status:SetText(message or "")
    local color = Theme.colors.muted
    if kind == "error" then color = Theme.colors.error end
    if kind == "success" then color = Theme.colors.success end
    self.status:SetTextColor(color[1], color[2], color[3], 1)
end

function SettingsFrame:Initialize(database, callbacks)
    self.database = database
    self.callbacks = callbacks or {}

    local frame = CreateFrame("Frame", "RaidLeadAssistSettingsFrame", UIParent, "BackdropTemplate")
    frame:SetSize(Theme.settings.width, Theme.settings.height)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetBackdrop({ bgFile = Theme.texture, edgeFile = Theme.texture, edgeSize = 1 })
    setBackdropColor(frame, Theme.colors.backgroundSolid)
    frame:SetBackdropBorderColor(Theme.colors.border[1], Theme.colors.border[2], Theme.colors.border[3], 1)
    frame:Hide()

    local eyebrow = frame:CreateFontString(nil, "OVERLAY")
    eyebrow:SetFont(Theme.font, 10, "OUTLINE")
    eyebrow:SetPoint("TOPLEFT", Theme.settings.padding, -14)
    eyebrow:SetText("RAID LEAD ASSIST \194\183 SETTINGS")
    eyebrow:SetTextColor(Theme.colors.venom[1], Theme.colors.venom[2], Theme.colors.venom[3], 1)

    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(Theme.font, 16, "OUTLINE")
    title:SetPoint("TOPLEFT", eyebrow, "BOTTOMLEFT", 0, -7)
    title:SetText("Raid Warning Text")
    title:SetTextColor(1, 1, 1, 1)

    local subtitle = frame:CreateFontString(nil, "OVERLAY")
    subtitle:SetFont(Theme.font, 9, "OUTLINE")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    subtitle:SetText("Customize what each button sends to /rw. Timer matching never changes here.")
    subtitle:SetTextColor(Theme.colors.muted[1], Theme.colors.muted[2], Theme.colors.muted[3], 1)

    local close = CreateFrame("Button", nil, frame)
    close:SetSize(28, 28)
    close:SetPoint("TOPRIGHT", -10, -10)
    close.text = close:CreateFontString(nil, "OVERLAY")
    close.text:SetFont(Theme.font, 14, "OUTLINE")
    close.text:SetAllPoints()
    close.text:SetText("X")
    close.text:SetTextColor(0.65, 0.72, 0.68, 1)
    close:SetScript("OnEnter", function() close.text:SetTextColor(1, 1, 1, 1) end)
    close:SetScript("OnLeave", function() close.text:SetTextColor(0.65, 0.72, 0.68, 1) end)
    close:SetScript("OnClick", function() self:Close() end)

    local audioButton = ActionButton:Create(frame, {
        text = "VOICE  ON",
        width = 76,
        height = 22,
        fontSize = 9,
        variant = "primary",
    })
    audioButton:SetPoint("TOPRIGHT", -48, -46)
    audioButton:SetScript("OnClick", function()
        database.audioEnabled = not database.audioEnabled
        self:RefreshAudioButton()
    end)
    self.audioButton = audioButton

    local timingButton = ActionButton:Create(frame, {
        text = "AUTO  ON",
        width = 76,
        height = 22,
        fontSize = 9,
        variant = "primary",
    })
    timingButton:SetPoint("RIGHT", audioButton, "LEFT", -6, 0)
    timingButton:SetScript("OnClick", function()
        database.automaticTimingEnabled = not database.automaticTimingEnabled
        self:RefreshTimingButton()
    end)
    self.timingButton = timingButton

    self.bossDropdown = Dropdown:Create(frame)
    self.bossDropdown.frame:SetPoint("TOPLEFT", Theme.settings.padding, -82)
    self.bossDropdown.frame:SetPoint("TOPRIGHT", -Theme.settings.padding, -82)
    self.bossDropdown.menu:SetPoint("TOPLEFT", self.bossDropdown.frame, "BOTTOMLEFT", 0, -2)
    self.bossDropdown.menu:SetPoint("TOPRIGHT", self.bossDropdown.frame, "BOTTOMRIGHT", 0, -2)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", Theme.settings.padding, -128)
    scroll:SetPoint("BOTTOMRIGHT", -36, Theme.settings.footerHeight)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(Theme.settings.width - 64)
    content:SetHeight(1)
    scroll:SetScrollChild(content)
    self.content = content

    self.explanationField = SettingsField:Create(content, {
        multiline = true,
        labelSize = 14,
        maxLetters = Messages.MAX_EXPLANATION_LINES * (Messages.MAX_WARNING_LENGTH + 1),
        helperText = "One non-empty line equals one pre-pull Raid Warning.",
    })
    self.explanationField.frame:SetPoint("TOPLEFT", 0, 0)
    self.explanationField.frame:SetPoint("RIGHT", content, "RIGHT", 0, 0)
    self.explanationField:SetLabel("Boss Explanation")
    self.explanationField:SetOnChanged(function()
        self:SetDirty(true)
        self:SetStatus("Unsaved changes.", "muted")
    end)
    self.explanationField:SetOnReset(function()
        local encounter = Registry:Get(self.selectedBossKey)
        if encounter then self.explanationField:SetText(table.concat(encounter.explanation, "\n")) end
        self:SetDirty(true)
        self:SetStatus("Boss Explanation reset to its default draft. Save to apply.", "muted")
    end)

    self.callsTitle = content:CreateFontString(nil, "OVERLAY")
    self.callsTitle:SetFont(Theme.font, 14, "OUTLINE")
    self.callsTitle:SetPoint("TOPLEFT", self.explanationField.frame, "BOTTOMLEFT", 0, -14)
    self.callsTitle:SetText("Combat Call Buttons")
    self.callsTitle:SetTextColor(1, 1, 1, 1)

    self.saveButton = ActionButton:Create(frame, { text = "SAVE CHANGES", width = 124, variant = "primary" })
    self.saveButton:SetPoint("BOTTOMRIGHT", -Theme.settings.padding, 16)
    self.saveButton:SetScript("OnClick", function() self:SaveCurrentBoss(false) end)

    self.resetBossButton = ActionButton:Create(frame, { text = "RESET TO DEFAULTS", width = 132, variant = "secondary" })
    self.resetBossButton:SetPoint("RIGHT", self.saveButton, "LEFT", -8, 0)
    self.resetBossButton:SetScript("OnClick", function()
        local encounter = Registry:Get(self.selectedBossKey)
        if not encounter then return end
        self.explanationField:SetText(table.concat(encounter.explanation, "\n"))
        for index = 1, #encounter.calls do
            self.callFields[index]:SetText(encounter.calls[index].warning)
        end
        self:SetDirty(true)
        self:SetStatus("Defaults loaded as a draft. Click SAVE CHANGES to apply them.", "muted")
    end)

    self.status = frame:CreateFontString(nil, "OVERLAY")
    self.status:SetFont(Theme.font, 9, "OUTLINE")
    self.status:SetPoint("BOTTOMLEFT", Theme.settings.padding, 34)
    self.status:SetPoint("RIGHT", self.resetBossButton, "LEFT", -10, 0)
    self.status:SetJustifyH("LEFT")

    self.providerText = frame:CreateFontString(nil, "OVERLAY")
    self.providerText:SetFont(Theme.font, 8, "OUTLINE")
    self.providerText:SetPoint("BOTTOMLEFT", Theme.settings.padding, 17)
    self.providerText:SetPoint("RIGHT", self.resetBossButton, "LEFT", -10, 0)
    self.providerText:SetJustifyH("LEFT")
    self.providerText:SetTextColor(0.43, 0.50, 0.46, 1)

    self.frame = frame
    self.confirmDialog = ConfirmDialog:Create(frame)

    frame:SetScript("OnHide", function()
        if self.allowHide then return end
        if self.confirmDialog and self.confirmDialog:IsShown() then
            frame:Show()
            self.confirmDialog:Hide()
            return
        end
        if not self.dirty then return end
        frame:Show()
        self:RequestClose()
    end)

    table.insert(UISpecialFrames, "RaidLeadAssistSettingsFrame")
    self:RefreshAudioButton()
    self:RefreshTimingButton()
    self:ConfigureBossDropdown(database.selectedBossKey)
    self:SetDirty(false)
end

function SettingsFrame:RefreshAudioButton()
    if not self.audioButton then return end
    if self.database.audioEnabled then
        self.audioButton:SetActionText("VOICE  ON")
        self.audioButton:SetActionVariant("primary")
    else
        self.audioButton:SetActionText("VOICE  OFF")
        self.audioButton:SetActionVariant("secondary")
    end
end

function SettingsFrame:RefreshTimingButton()
    if not self.timingButton then return end
    if self.database.automaticTimingEnabled ~= false then
        self.timingButton:SetActionText("AUTO  ON")
        self.timingButton:SetActionVariant("primary")
    else
        self.timingButton:SetActionText("AUTO  OFF")
        self.timingButton:SetActionVariant("secondary")
    end
end

function SettingsFrame:SetDirty(dirty)
    self.dirty = dirty == true
    if self.saveButton then self.saveButton:SetActionEnabled(self.dirty) end
end

function SettingsFrame:ConfigureBossDropdown(selectedKey)
    local options = Registry:GetOrdered()
    self.bossDropdown:SetOptions(options, selectedKey, function(key)
        self:RequestBossChange(key)
    end)
end

function SettingsFrame:EnsureCallFields(count)
    while #self.callFields < count do
        local index = #self.callFields + 1
        local field = SettingsField:Create(self.content, { multiline = false })
        field.frame:SetPoint("LEFT", self.content, "LEFT", 0, 0)
        field.frame:SetPoint("RIGHT", self.content, "RIGHT", 0, 0)
        if index == 1 then
            field.frame:SetPoint("TOP", self.callsTitle, "BOTTOM", 0, -9)
        else
            field.frame:SetPoint("TOP", self.callFields[index - 1].frame, "BOTTOM", 0, -Theme.settings.fieldGap)
        end
        field:SetOnChanged(function()
            self:SetDirty(true)
            self:SetStatus("Unsaved changes.", "muted")
        end)
        self.callFields[index] = field
    end
end

function SettingsFrame:LoadBoss(bossKey)
    local encounter = Registry:Get(bossKey)
    if not encounter then return end

    self.selectedBossKey = bossKey
    self.bossDropdown:SetSelected(bossKey, Registry:GetOrdered())
    self.explanationField:SetText(Messages:GetExplanationText(bossKey))
    self:EnsureCallFields(#encounter.calls)

    for index = 1, #self.callFields do
        local field = self.callFields[index]
        local call = encounter.calls[index]
        if call then
            field.callKey = call.key
            field:SetLabel(call.ability)
            field:SetText(Messages:GetCallWarning(bossKey, call.key))
            local defaultWarning = call.warning
            field:SetOnReset(function()
                field:SetText(defaultWarning)
                self:SetDirty(true)
                self:SetStatus(call.ability .. " reset to its default draft. Save to apply.", "muted")
            end)
            field.frame:Show()
        else
            field.callKey = nil
            field.frame:Hide()
        end
    end

    local callHeight = #encounter.calls * Theme.settings.callFieldHeight
    local gaps = math.max(0, #encounter.calls - 1) * Theme.settings.fieldGap
    local contentHeight = Theme.settings.explanationFieldHeight + 14 + 18 + 9 + callHeight + gaps + 16
    self.content:SetHeight(math.max(430, contentHeight))
    self:SetDirty(false)
    self:SetStatus("Edit Raid Warning text, then save.", "muted")
end

function SettingsFrame:ClearValidation()
    self.explanationField:SetInvalid(false)
    for index = 1, #self.callFields do
        self.callFields[index]:SetInvalid(false)
    end
end

function SettingsFrame:GetDraftCallWarnings(encounter)
    local values = {}
    for index = 1, #encounter.calls do
        local call = encounter.calls[index]
        values[call.key] = self.callFields[index]:GetText()
    end
    return values
end

function SettingsFrame:ShowDraftError(errorInfo)
    self:ClearValidation()
    local message = errorInfo and errorInfo.message or "Unable to save settings."

    if errorInfo and errorInfo.scope == "explanation" then
        self.explanationField:SetInvalid(true)
        self.explanationField:Focus()
    elseif errorInfo and errorInfo.scope == "call" then
        for index = 1, #self.callFields do
            local field = self.callFields[index]
            if field.callKey == errorInfo.callKey then
                field:SetInvalid(true)
                field:Focus()
                break
            end
        end
    end

    self:SetStatus(message, "error")
end

function SettingsFrame:SaveCurrentBoss(silent)
    local encounter = Registry:Get(self.selectedBossKey)
    if not encounter then return false end

    self:ClearValidation()
    local callWarnings = self:GetDraftCallWarnings(encounter)
    local ok, result = Messages:ApplyBossDraft(
        self.selectedBossKey,
        self.explanationField:GetText(),
        callWarnings
    )

    if not ok then
        self:ShowDraftError(result)
        return false
    end

    self.explanationField:SetText(table.concat(result.explanation, "\n"))
    for index = 1, #encounter.calls do
        local call = encounter.calls[index]
        self.callFields[index]:SetText(result.calls[call.key])
    end

    self:SetDirty(false)
    self:SetStatus("Saved. Combat buttons use these Raid Warning messages immediately.", "success")
    if not silent then ns:Print("Raid Warning text saved for " .. encounter.name .. ".") end
    return true
end

function SettingsFrame:RequestBossChange(key)
    if key == self.selectedBossKey then return end
    if not Registry:Get(key) then return end

    if not self.dirty then
        self:LoadBoss(key)
        return
    end

    self.confirmDialog:Show(
        "Unsaved changes",
        "Save your Raid Warning text before switching bosses?",
        function()
            if self:SaveCurrentBoss(true) then self:LoadBoss(key) end
        end,
        function()
            self:LoadBoss(key)
        end,
        function()
            self.bossDropdown:SetSelected(self.selectedBossKey, Registry:GetOrdered())
        end
    )
end

function SettingsFrame:RefreshProviderSummary(summary)
    if not self.providerText then return end
    if summary == nil and self.callbacks.getProviderSummary then
        summary = self.callbacks.getProviderSummary()
    end
    self.providerText:SetText("Timer sources: " .. ((summary and summary ~= "") and summary or "Manual only"))
end

function SettingsFrame:Open(bossKey)
    if self.callbacks.canOpen then
        local allowed, reason = self.callbacks.canOpen()
        if not allowed then
            ns:Print(reason or "Settings are currently unavailable.")
            return false
        end
    end

    local key = bossKey or self.database.selectedBossKey
    if self.frame:IsShown() and self.dirty and key ~= self.selectedBossKey then
        self:RequestBossChange(key)
        return true
    end

    if not self.frame:IsShown() or not self.dirty then self:LoadBoss(key) end
    self:RefreshProviderSummary()
    self.frame:Show()
    self.frame:Raise()
    return true
end

function SettingsFrame:HideNow()
    if self.bossDropdown and self.bossDropdown.Close then self.bossDropdown:Close() end
    self.allowHide = true
    self.frame:Hide()
    self.allowHide = false
end

function SettingsFrame:RequestClose()
    if self.confirmDialog:IsShown() then return end

    if not self.dirty then
        self:HideNow()
        return
    end

    self.confirmDialog:Show(
        "Unsaved changes",
        "Save your Raid Warning text before closing Settings?",
        function()
            if self:SaveCurrentBoss(true) then self:HideNow() end
        end,
        function()
            self:SetDirty(false)
            self:HideNow()
        end,
        nil
    )
end

function SettingsFrame:Close()
    self:RequestClose()
end

function SettingsFrame:CloseForEncounter()
    local discarded = self.dirty
    if self.confirmDialog then self.confirmDialog:Hide() end
    self:SetDirty(false)
    if self.frame and self.frame:IsShown() then self:HideNow() end
    if discarded then ns:Print("Unsaved Settings draft discarded when the encounter started.") end
end

ns:RegisterModule("UI.SettingsFrame", SettingsFrame)
