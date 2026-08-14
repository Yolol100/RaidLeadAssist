local _, ns = ...

local Theme = ns:GetModule("UI.Theme")
local ActionButton = ns:GetModule("UI.ActionButton")

local AssignmentSlot = {}
AssignmentSlot.__index = AssignmentSlot

function AssignmentSlot:Create(parent)
    local instance = setmetatable({}, AssignmentSlot)

    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetHeight(68)
    frame:SetBackdrop({ bgFile = Theme.texture, edgeFile = Theme.texture, edgeSize = 1 })
    frame:SetBackdropColor(Theme.colors.surface[1], Theme.colors.surface[2], Theme.colors.surface[3], 0.92)
    frame:SetBackdropBorderColor(Theme.colors.border[1], Theme.colors.border[2], Theme.colors.border[3], 1)

    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont(Theme.font, 10, "OUTLINE")
    label:SetPoint("TOPLEFT", 9, -8)
    label:SetPoint("RIGHT", -70, 0)
    label:SetJustifyH("LEFT")
    label:SetTextColor(Theme.colors.text[1], Theme.colors.text[2], Theme.colors.text[3], 1)

    local edit = CreateFrame("EditBox", nil, frame, "BackdropTemplate")
    edit:SetPoint("BOTTOMLEFT", 8, 8)
    edit:SetPoint("BOTTOMRIGHT", -68, 8)
    edit:SetHeight(30)
    edit:SetAutoFocus(false)
    edit:SetMaxLetters(96)
    edit:SetFont(Theme.font, 9, "")
    edit:SetTextInsets(7, 7, 4, 4)
    edit:SetTextColor(Theme.colors.text[1], Theme.colors.text[2], Theme.colors.text[3], 1)
    edit:SetBackdrop({ bgFile = Theme.texture, edgeFile = Theme.texture, edgeSize = 1 })
    edit:SetBackdropColor(Theme.colors.background[1], Theme.colors.background[2], Theme.colors.background[3], 1)
    edit:SetBackdropBorderColor(Theme.colors.borderStrong[1], Theme.colors.borderStrong[2], Theme.colors.borderStrong[3], 1)
    edit:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
    edit:SetScript("OnEnterPressed", function(box) box:ClearFocus() end)

    local roster = ActionButton:Create(frame, { text = "ROSTER", width = 54, height = 30, fontSize = 8, variant = "secondary" })
    roster:SetPoint("BOTTOMRIGHT", -8, 8)

    instance.frame = frame
    instance.label = label
    instance.edit = edit
    instance.roster = roster
    instance.assignmentKey = nil
    instance.onChanged = nil
    instance.onRoster = nil

    edit:SetScript("OnTextChanged", function(_, userInput)
        if userInput and instance.onChanged then instance.onChanged(instance) end
    end)
    roster:SetScript("OnClick", function()
        if instance.onRoster then instance.onRoster(instance) end
    end)

    return instance
end

function AssignmentSlot:SetDefinition(definition)
    self.definition = definition
    self.assignmentKey = definition and definition.key or nil
    local suffix = definition and definition.required and "  *" or ""
    self.label:SetText((definition and definition.label or "Assignment") .. suffix)
end

function AssignmentSlot:SetText(value)
    self.edit:SetText(value or "")
end

function AssignmentSlot:GetText()
    return self.edit:GetText() or ""
end

function AssignmentSlot:SetOnChanged(callback)
    self.onChanged = callback
end

function AssignmentSlot:SetOnRoster(callback)
    self.onRoster = callback
end

function AssignmentSlot:SetInvalid(invalid)
    local color = invalid and Theme.colors.error or Theme.colors.borderStrong
    self.edit:SetBackdropBorderColor(color[1], color[2], color[3], 1)
end

function AssignmentSlot:Focus()
    self.edit:SetFocus()
end

ns:RegisterModule("UI.AssignmentSlot", AssignmentSlot)
