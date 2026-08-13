local _, ns = ...

local Theme = ns:GetModule("UI.Theme")
local ActionButton = ns:GetModule("UI.ActionButton")

local SettingsField = {}
SettingsField.__index = SettingsField

local function setBorder(edit, color, alpha)
    edit:SetBackdropBorderColor(color[1], color[2], color[3], alpha or color[4] or 1)
end

function SettingsField:Create(parent, options)
    local instance = setmetatable({}, SettingsField)
    local multiline = options and options.multiline == true
    local helperText = options and options.helperText
    local labelSize = options and options.labelSize or 11
    local maxLetters = options and options.maxLetters or (multiline and 1700 or 200)
    local height = multiline and Theme.settings.explanationFieldHeight or Theme.settings.callFieldHeight

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(height)

    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont(Theme.font, labelSize, "OUTLINE")
    label:SetPoint("TOPLEFT", 0, 0)
    label:SetPoint("RIGHT", -72, 0)
    label:SetJustifyH("LEFT")
    label:SetTextColor(Theme.colors.text[1], Theme.colors.text[2], Theme.colors.text[3], 1)

    local reset = ActionButton:Create(frame, {
        text = "RESET",
        width = 58,
        height = 22,
        fontSize = 9,
        variant = "secondary",
    })
    reset:SetPoint("TOPRIGHT", 0, 3)

    local helper
    if helperText then
        helper = frame:CreateFontString(nil, "OVERLAY")
        helper:SetFont(Theme.font, 9, "OUTLINE")
        helper:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)
        helper:SetPoint("RIGHT", frame, "RIGHT", -2, 0)
        helper:SetJustifyH("LEFT")
        helper:SetText(helperText)
        helper:SetTextColor(Theme.colors.muted[1], Theme.colors.muted[2], Theme.colors.muted[3], 1)
    end

    local edit = CreateFrame("EditBox", nil, frame, "BackdropTemplate")
    if helper then
        edit:SetPoint("TOPLEFT", helper, "BOTTOMLEFT", 0, -7)
    else
        edit:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -6)
    end
    edit:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    edit:SetHeight(multiline and 82 or 32)
    edit:SetAutoFocus(false)
    edit:SetMultiLine(multiline)
    edit:SetMaxLetters(maxLetters)
    if multiline then edit:SetJustifyV("TOP") end
    edit:SetFont(Theme.font, 10, "")
    edit:SetTextColor(0.92, 0.95, 0.92, 1)
    edit:SetTextInsets(8, 8, 6, 6)
    edit:SetBackdrop({ bgFile = Theme.texture, edgeFile = Theme.texture, edgeSize = 1 })
    edit:SetBackdropColor(Theme.colors.background[1], Theme.colors.background[2], Theme.colors.background[3], 0.98)
    setBorder(edit, Theme.colors.borderStrong, 1)
    edit:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
    if not multiline then
        edit:SetScript("OnEnterPressed", function(box) box:ClearFocus() end)
    end

    instance.frame = frame
    instance.label = label
    instance.helper = helper
    instance.edit = edit
    instance.reset = reset
    instance.multiline = multiline
    instance.invalid = false
    instance.focused = false

    local function refreshBorder()
        if instance.invalid then
            setBorder(edit, Theme.colors.error, 1)
        elseif instance.focused then
            setBorder(edit, Theme.colors.venom, 1)
        else
            setBorder(edit, Theme.colors.borderStrong, 1)
        end
    end
    instance.refreshBorder = refreshBorder

    edit:SetScript("OnEditFocusGained", function()
        instance.focused = true
        refreshBorder()
    end)
    edit:SetScript("OnEditFocusLost", function()
        instance.focused = false
        refreshBorder()
    end)

    return instance
end

function SettingsField:SetLabel(text)
    self.label:SetText(text or "")
end

function SettingsField:SetText(text)
    self.edit:SetText(text or "")
    self:SetInvalid(false)
end

function SettingsField:GetText()
    return self.edit:GetText() or ""
end

function SettingsField:SetInvalid(invalid)
    self.invalid = invalid == true
    self.refreshBorder()
end

function SettingsField:Focus()
    self.edit:SetFocus()
end

function SettingsField:SetOnChanged(callback)
    self.edit:SetScript("OnTextChanged", function(_, userInput)
        if userInput then
            self:SetInvalid(false)
            if callback then callback(self) end
        end
    end)
end

function SettingsField:SetOnReset(callback)
    self.reset:SetScript("OnClick", function()
        if callback then callback() end
    end)
end

ns:RegisterModule("UI.SettingsField", SettingsField)
