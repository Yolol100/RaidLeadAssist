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
    button.name:SetPoint("TOPLEFT", 11, -6)
    button.name:SetPoint("RIGHT", -84, 0)
    button.name:SetJustifyH("LEFT")

    button.action = button:CreateFontString(nil, "OVERLAY")
    button.action:SetFont(Theme.font, 9, "OUTLINE")
    button.action:SetPoint("BOTTOMLEFT", 11, 6)
    button.action:SetPoint("RIGHT", -11, 0)
    button.action:SetJustifyH("LEFT")

    button.state = button:CreateFontString(nil, "OVERLAY")
    button.state:SetFont(Theme.font, 9, "OUTLINE")
    button.state:SetPoint("TOPRIGHT", -10, -6)
    button.state:SetJustifyH("RIGHT")

    button:SetScript("OnEnter", function(frame)
        if instance.state == Constants.CallState.IDLE then
            local color = Theme.colors.venom
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

function CallButton:SetActionText(text)
    self.frame.action:SetText(text or (self.call and self.call.action) or "")
end

function CallButton:SetState(state, force)
    if not force and self.state == state then return end

    self.state = state
    local frame = self.frame

    if state == Constants.CallState.PRESS then
        setBackdropColor(frame, Theme.colors.success)
        frame:SetBackdropBorderColor(0.88, 1.00, 0.55, 1)
        frame.name:SetTextColor(0.04, 0.10, 0.03, 1)
        frame.action:SetTextColor(0.08, 0.18, 0.05, 1)
        frame.state:SetTextColor(0.04, 0.14, 0.03, 1)
        frame.state:SetText("PRESS NOW")
    elseif state == Constants.CallState.PREPARE then
        setBackdropColor(frame, Theme.colors.surfaceRaised)
        frame:SetBackdropBorderColor(Theme.colors.warning[1], Theme.colors.warning[2], Theme.colors.warning[3], 1)
        frame.name:SetTextColor(1, 1, 1, 1)
        frame.action:SetTextColor(0.90, 0.88, 0.72, 1)
        frame.state:SetTextColor(Theme.colors.warning[1], Theme.colors.warning[2], Theme.colors.warning[3], 1)
        frame.state:SetText("SOON")
    elseif state == Constants.CallState.LATE then
        setBackdropColor(frame, Theme.colors.surfaceRaised)
        frame:SetBackdropBorderColor(Theme.colors.error[1], Theme.colors.error[2], Theme.colors.error[3], 1)
        frame.name:SetTextColor(1, 0.88, 0.84, 1)
        frame.action:SetTextColor(0.90, 0.72, 0.68, 1)
        frame.state:SetTextColor(Theme.colors.error[1], Theme.colors.error[2], Theme.colors.error[3], 1)
        frame.state:SetText("LATE")
    elseif state == Constants.CallState.WAIT then
        setBackdropColor(frame, Theme.colors.surface)
        frame:SetBackdropBorderColor(Theme.colors.muted[1], Theme.colors.muted[2], Theme.colors.muted[3], 0.85)
        frame.name:SetTextColor(Theme.colors.text[1], Theme.colors.text[2], Theme.colors.text[3], 1)
        frame.action:SetTextColor(0.72, 0.78, 0.73, 1)
        frame.state:SetTextColor(Theme.colors.muted[1], Theme.colors.muted[2], Theme.colors.muted[3], 1)
        frame.state:SetText("WAIT")
    elseif state == Constants.CallState.CALLED then
        setBackdropColor(frame, Theme.colors.called)
        frame:SetBackdropBorderColor(0.20, 0.28, 0.23, 1)
        frame.name:SetTextColor(0.58, 0.65, 0.60, 1)
        frame.action:SetTextColor(0.55, 0.62, 0.57, 1)
        frame.state:SetTextColor(0.70, 0.66, 0.88, 1)
        frame.state:SetText("CALLED")
    else
        setBackdropColor(frame, Theme.colors.surfaceRaised)
        frame:SetBackdropBorderColor(Theme.colors.borderStrong[1], Theme.colors.borderStrong[2], Theme.colors.borderStrong[3], 1)
        frame.name:SetTextColor(Theme.colors.text[1], Theme.colors.text[2], Theme.colors.text[3], 1)
        frame.action:SetTextColor(0.72, 0.78, 0.73, 1)
        frame.state:SetText("")
    end
end

ns:RegisterModule("UI.CallButton", CallButton)
