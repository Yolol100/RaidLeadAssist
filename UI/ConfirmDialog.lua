local _, ns = ...

local Theme = ns:GetModule("UI.Theme")
local ActionButton = ns:GetModule("UI.ActionButton")

local ConfirmDialog = {}
ConfirmDialog.__index = ConfirmDialog

local function setBackdropColor(frame, color)
    frame:SetBackdropColor(color[1], color[2], color[3], color[4] or 1)
end

function ConfirmDialog:Create(parent)
    local instance = setmetatable({}, ConfirmDialog)

    local overlay = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    overlay:SetAllPoints(parent)
    overlay:SetFrameLevel(parent:GetFrameLevel() + 50)
    overlay:EnableMouse(true)
    overlay:SetBackdrop({ bgFile = Theme.texture })
    overlay:SetBackdropColor(0, 0, 0, 0.58)
    overlay:Hide()

    local panel = CreateFrame("Frame", nil, overlay, "BackdropTemplate")
    panel:SetSize(380, 154)
    panel:SetPoint("CENTER")
    panel:SetBackdrop({ bgFile = Theme.texture, edgeFile = Theme.texture, edgeSize = 1 })
    setBackdropColor(panel, Theme.colors.backgroundSolid)
    panel:SetBackdropBorderColor(Theme.colors.borderStrong[1], Theme.colors.borderStrong[2], Theme.colors.borderStrong[3], 1)

    panel.title = panel:CreateFontString(nil, "OVERLAY")
    panel.title:SetFont(Theme.font, 15, "OUTLINE")
    panel.title:SetPoint("TOPLEFT", 16, -16)
    panel.title:SetPoint("RIGHT", -16, 0)
    panel.title:SetJustifyH("LEFT")
    panel.title:SetTextColor(1, 1, 1, 1)

    panel.message = panel:CreateFontString(nil, "OVERLAY")
    panel.message:SetFont(Theme.font, 10, "OUTLINE")
    panel.message:SetPoint("TOPLEFT", panel.title, "BOTTOMLEFT", 0, -8)
    panel.message:SetPoint("RIGHT", -16, 0)
    panel.message:SetJustifyH("LEFT")
    panel.message:SetJustifyV("TOP")
    panel.message:SetTextColor(Theme.colors.muted[1], Theme.colors.muted[2], Theme.colors.muted[3], 1)

    local save = ActionButton:Create(panel, { text = "SAVE", width = 92, height = 28, variant = "primary" })
    save:SetPoint("BOTTOMRIGHT", -16, 14)

    local discard = ActionButton:Create(panel, { text = "DISCARD", width = 92, height = 28, variant = "destructive" })
    discard:SetPoint("RIGHT", save, "LEFT", -8, 0)

    local cancel = ActionButton:Create(panel, { text = "CANCEL", width = 82, height = 28, variant = "secondary" })
    cancel:SetPoint("RIGHT", discard, "LEFT", -8, 0)

    instance.overlay = overlay
    instance.panel = panel
    instance.save = save
    instance.discard = discard
    instance.cancel = cancel

    save:SetScript("OnClick", function()
        overlay:Hide()
        local callback = instance.onSave
        instance:ClearCallbacks()
        if callback then callback() end
    end)

    discard:SetScript("OnClick", function()
        overlay:Hide()
        local callback = instance.onDiscard
        instance:ClearCallbacks()
        if callback then callback() end
    end)

    cancel:SetScript("OnClick", function()
        overlay:Hide()
        local callback = instance.onCancel
        instance:ClearCallbacks()
        if callback then callback() end
    end)

    return instance
end

function ConfirmDialog:ClearCallbacks()
    self.onSave = nil
    self.onDiscard = nil
    self.onCancel = nil
end

function ConfirmDialog:Show(title, message, onSave, onDiscard, onCancel)
    self.panel.title:SetText(title or "Unsaved changes")
    self.panel.message:SetText(message or "Save your changes before continuing?")
    self.onSave = onSave
    self.onDiscard = onDiscard
    self.onCancel = onCancel
    self.overlay:Show()
    self.overlay:Raise()
end

function ConfirmDialog:Hide()
    self.overlay:Hide()
    self:ClearCallbacks()
end

function ConfirmDialog:IsShown()
    return self.overlay:IsShown()
end

ns:RegisterModule("UI.ConfirmDialog", ConfirmDialog)
