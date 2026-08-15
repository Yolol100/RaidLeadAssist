local _, ns = ...

local Theme = ns:GetModule("UI.Theme")
local ActionButton = ns:GetModule("UI.ActionButton")

local AssignmentSlot = {}
AssignmentSlot.__index = AssignmentSlot

local KIND_LABELS = {
    assignee = "PLAYER/GROUP",
    rotation = "ROTATION",
    rule = "RULE",
    sequence = "SEQUENCE",
}

local function setEditBorder(instance)
    local color = Theme.colors.borderStrong
    if instance.invalid then
        color = Theme.colors.error
    elseif instance.focused then
        color = Theme.colors.venom
    end
    instance.edit:SetBackdropBorderColor(color[1], color[2], color[3], 1)
end

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
    label:SetPoint("RIGHT", -86, 0)
    label:SetJustifyH("LEFT")
    label:SetTextColor(Theme.colors.text[1], Theme.colors.text[2], Theme.colors.text[3], 1)

    local kind = frame:CreateFontString(nil, "OVERLAY")
    kind:SetFont(Theme.font, 7, "OUTLINE")
    kind:SetPoint("TOPRIGHT", -9, -10)
    kind:SetJustifyH("RIGHT")
    kind:SetTextColor(Theme.colors.muted[1], Theme.colors.muted[2], Theme.colors.muted[3], 1)

    local edit = CreateFrame("EditBox", nil, frame, "BackdropTemplate")
    edit:SetPoint("BOTTOMLEFT", 8, 8)
    edit:SetPoint("BOTTOMRIGHT", -72, 8)
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

    local roster = ActionButton:Create(frame, { text = "ROSTER", width = 58, height = 30, fontSize = 8, variant = "secondary" })
    roster:SetPoint("BOTTOMRIGHT", -8, 8)

    instance.frame = frame
    instance.label = label
    instance.kind = kind
    instance.edit = edit
    instance.roster = roster
    instance.assignmentKey = nil
    instance.onChanged = nil
    instance.onRoster = nil
    instance.onTab = nil
    instance.invalid = false
    instance.focused = false

    edit:SetScript("OnTextChanged", function(_, userInput)
        if userInput and instance.onChanged then instance.onChanged(instance) end
    end)
    edit:SetScript("OnEditFocusGained", function()
        instance.focused = true
        setEditBorder(instance)
    end)
    edit:SetScript("OnEditFocusLost", function()
        instance.focused = false
        setEditBorder(instance)
    end)
    edit:SetScript("OnTabPressed", function()
        if instance.onTab then instance.onTab(instance, IsShiftKeyDown and IsShiftKeyDown() == true) end
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
    local fieldKind = definition and definition.kind or "assignee"
    local usesRoster = fieldKind == "assignee" or fieldKind == "rotation"

    self.label:SetText((definition and definition.label or "Assignment") .. suffix)
    self.kind:SetText(KIND_LABELS[fieldKind] or "ASSIGNMENT")

    self.edit:ClearAllPoints()
    self.edit:SetPoint("BOTTOMLEFT", 8, 8)
    if usesRoster then
        self.edit:SetPoint("BOTTOMRIGHT", -72, 8)
        self.roster:Show()
    else
        self.edit:SetPoint("BOTTOMRIGHT", -8, 8)
        self.roster:Hide()
    end
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

function AssignmentSlot:SetOnTab(callback)
    self.onTab = callback
end

function AssignmentSlot:SetInvalid(invalid)
    self.invalid = invalid == true
    setEditBorder(self)
end

function AssignmentSlot:Focus()
    self.edit:SetFocus()
end

ns:RegisterModule("UI.AssignmentSlot", AssignmentSlot)
