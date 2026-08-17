local _, ns = ...

local Theme = ns:GetModule("UI.Theme")

local ActionButton = {}
ActionButton.__index = ActionButton

local function setBackdropColor(frame, color)
    frame:SetBackdropColor(color[1], color[2], color[3], color[4] or 1)
end

local function applyStyle(button, hover)
    local variant = button.variant or "secondary"
    local enabled = button.enabledState ~= false

    if not enabled then
        setBackdropColor(button, Theme.colors.called)
        button:SetBackdropBorderColor(Theme.colors.border[1], Theme.colors.border[2], Theme.colors.border[3], 0.75)
        button.text:SetTextColor(Theme.colors.muted[1], Theme.colors.muted[2], Theme.colors.muted[3], 0.68)
        return
    end

    if variant == "primary" then
        local background = hover and Theme.colors.venom or Theme.colors.venomDark
        setBackdropColor(button, background)
        button:SetBackdropBorderColor(Theme.colors.venomBright[1], Theme.colors.venomBright[2], Theme.colors.venomBright[3], 1)
        button.text:SetTextColor(0.05, 0.10, 0.03, 1)
    elseif variant == "destructive" then
        setBackdropColor(button, Theme.colors.surface)
        button:SetBackdropBorderColor(Theme.colors.error[1], Theme.colors.error[2], Theme.colors.error[3], hover and 1 or 0.75)
        if hover then
            button.text:SetTextColor(1.00, 0.80, 0.76, 1)
        else
            button.text:SetTextColor(0.94, 0.74, 0.70, 1)
        end
    else
        setBackdropColor(button, Theme.colors.surface)
        local border = hover and Theme.colors.venom or Theme.colors.border
        button:SetBackdropBorderColor(border[1], border[2], border[3], hover and 0.90 or 1)
        if hover then
            button.text:SetTextColor(Theme.colors.venom[1], Theme.colors.venom[2], Theme.colors.venom[3], 1)
        else
            button.text:SetTextColor(0.82, 0.86, 0.82, 1)
        end
    end
end

function ActionButton.Create(_, parent, options)
    options = options or {}
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(options.width or 100, options.height or 30)
    button:SetBackdrop({ bgFile = Theme.texture, edgeFile = Theme.texture, edgeSize = 1 })
    button.variant = options.variant or "secondary"
    button.enabledState = options.enabled ~= false

    button.text = button:CreateFontString(nil, "OVERLAY")
    button.text:SetFont(Theme.font, options.fontSize or 10, "OUTLINE")
    button.text:SetAllPoints()
    button.text:SetText(options.text or "")

    function button:SetActionEnabled(enabled)
        self.enabledState = enabled == true
        if self.enabledState then self:Enable() else self:Disable() end
        applyStyle(self, false)
    end

    function button:SetActionVariant(variant)
        self.variant = variant or "secondary"
        applyStyle(self, false)
    end

    function button:SetActionText(text)
        self.text:SetText(text or "")
    end

    button:SetScript("OnEnter", function(self)
        if self.enabledState then applyStyle(self, true) end
    end)
    button:SetScript("OnLeave", function(self)
        applyStyle(self, false)
    end)

    button:SetActionEnabled(button.enabledState)
    return button
end

ns:RegisterModule("UI.ActionButton", ActionButton)
