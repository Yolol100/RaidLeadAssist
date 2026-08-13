local _, ns = ...

local Constants = ns:GetModule("Core.Constants")
local Theme = ns:GetModule("UI.Theme")

local CallButton = {}
CallButton.__index = CallButton

local function setBackdropColor(frame, color)
    frame:SetBackdropColor(color[1], color[2], color[3], color[4] or 1)
end

function CallButton:Create(parent)
    local instance = setmetatable({}, CallButton)

    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetHeight(Theme.callButtonHeight)
    button:SetBackdrop({ bgFile = Theme.texture, edgeFile = Theme.texture, edgeSize = 1 })

    button.name = button:CreateFontString(nil, "OVERLAY")
    button.name:SetFont(Theme.font, 11, "OUTLINE")
    button.name:SetPoint("TOPLEFT", 11, -7)
    button.name:SetPoint("RIGHT", -84, 0)
    button.name:SetJustifyH("LEFT")

    button.action = button:CreateFontString(nil, "OVERLAY")
    button.action:SetFont(Theme.font, 9, "OUTLINE")
    button.action:SetPoint("BOTTOMLEFT", 11, 7)
    button.action:SetPoint("RIGHT", -11, 0)
    button.action:SetJustifyH("LEFT")

    button.state = button:CreateFontString(nil, "OVERLAY")
    button.state:SetFont(Theme.font, 9, "OUTLINE")
    button.state:SetPoint("TOPRIGHT", -10, -7)
    button.state:SetJustifyH("RIGHT")

    button:SetScript("OnEnter", function(frame)
        if instance.state == Constants.CallState.IDLE then
            local color = Theme.colors.venomBright
            frame:SetBackdropBorderColor(color[1], color[2], color[3], 1)
        end

        if instance.call then
            GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
            GameTooltip:SetText(instance.call.ability, 1, 1, 1)
            local warning = instance.warningResolver and instance.warningResolver(instance.call.key) or instance.call.warning
            GameTooltip:AddLine(warning or instance.call.warning, 0.75, 0.9, 0.45, true)
            GameTooltip:Show()
        end
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
        instance:SetState(instance.state, true)
    end)

    instance.frame = button
    instance.state = nil
    instance:SetState(Constants.CallState.IDLE, true)
    return instance
end

function CallButton:SetCall(call, onClick, warningResolver)
    self.call = call
    self.warningResolver = warningResolver
    self.frame.name:SetText(call.ability)
    self.frame.action:SetText(call.action)
    self.frame:SetScript("OnClick", function()
        if onClick then onClick(call.key) end
    end)
    self:SetState(Constants.CallState.IDLE, true)
    self.frame:Show()
end

function CallButton:SetState(state, force)
    if not force and self.state == state then return end

    self.state = state
    local frame = self.frame

    if state == Constants.CallState.PRESS then
        setBackdropColor(frame, Theme.colors.teal)
        frame:SetBackdropBorderColor(0.56, 0.94, 0.88, 1)
        frame.name:SetTextColor(0.03, 0.09, 0.07, 1)
        frame.action:SetTextColor(0.06, 0.22, 0.19, 1)
        frame.state:SetTextColor(0.04, 0.20, 0.17, 1)
        frame.state:SetText("PRESS NOW")
    elseif state == Constants.CallState.PREPARE then
        setBackdropColor(frame, Theme.colors.venomBright)
        frame:SetBackdropBorderColor(0.90, 1.00, 0.48, 1)
        frame.name:SetTextColor(0.05, 0.10, 0.03, 1)
        frame.action:SetTextColor(0.15, 0.23, 0.07, 1)
        frame.state:SetTextColor(0.14, 0.23, 0.06, 1)
        frame.state:SetText("PREPARE")
    elseif state == Constants.CallState.CALLED then
        setBackdropColor(frame, Theme.colors.called)
        frame:SetBackdropBorderColor(0.20, 0.28, 0.23, 1)
        frame.name:SetTextColor(0.58, 0.65, 0.60, 1)
        frame.action:SetTextColor(0.55, 0.62, 0.57, 1)
        frame.state:SetTextColor(0.70, 0.66, 0.88, 1)
        frame.state:SetText("CALLED")
    else
        setBackdropColor(frame, Theme.colors.venom)
        frame:SetBackdropBorderColor(0.78, 0.92, 0.28, 1)
        frame.name:SetTextColor(0.05, 0.10, 0.03, 1)
        frame.action:SetTextColor(0.16, 0.22, 0.08, 1)
        frame.state:SetText("")
    end
end

ns:RegisterModule("UI.CallButton", CallButton)
