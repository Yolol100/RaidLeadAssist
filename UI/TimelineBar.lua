local _, ns = ...

local Constants = ns:GetModule("Core.Constants")
local Theme = ns:GetModule("UI.Theme")
local Util = ns:GetModule("Core.Util")

local TimelineBar = {}
TimelineBar.__index = TimelineBar

local function sourceLabel(timer)
    if not timer then return nil end
    if timer.bridge == "Blizzard" then return "Blizzard/BW" end
    if timer.providerName == "BigWigs" then return "BigWigs" end
    if timer.providerName == "DBM" then return "DBM" end
    if timer.providerName == "Blizzard" then return "Blizzard" end
    return timer.providerName
end

function TimelineBar:Create(parent)
    local instance = setmetatable({}, TimelineBar)

    local frame = CreateFrame("StatusBar", nil, parent, "BackdropTemplate")
    frame:SetHeight(Theme.timelineHeight)
    frame:SetStatusBarTexture(Theme.texture)
    frame:SetMinMaxValues(0, 1)
    frame:SetValue(0)
    frame:SetStatusBarColor(
        Theme.colors.venomDark[1], Theme.colors.venomDark[2], Theme.colors.venomDark[3], 0.82
    )
    frame:SetBackdrop({ bgFile = Theme.texture, edgeFile = Theme.texture, edgeSize = 1 })
    frame:SetBackdropColor(0.03, 0.07, 0.05, 1)
    frame:SetBackdropBorderColor(0.22, 0.36, 0.27, 1)

    frame.iconFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.iconFrame:SetSize(32, 32)
    frame.iconFrame:SetPoint("LEFT", 1, 0)
    frame.iconFrame:SetFrameLevel(frame:GetFrameLevel() + 3)
    frame.iconFrame:SetBackdrop({ bgFile = Theme.texture, edgeFile = Theme.texture, edgeSize = 1 })
    frame.iconFrame:SetBackdropColor(0.08, 0.14, 0.10, 1)
    frame.iconFrame:SetBackdropBorderColor(0.16, 0.25, 0.19, 1)

    frame.icon = frame.iconFrame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetPoint("TOPLEFT", 2, -2)
    frame.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    frame.icon:SetTexture(134400)

    frame.label = frame:CreateFontString(nil, "OVERLAY")
    frame.label:SetFont(Theme.font, 11, "OUTLINE")
    frame.label:SetPoint("LEFT", frame.iconFrame, "RIGHT", 8, 0)
    frame.label:SetPoint("RIGHT", -132, 0)
    frame.label:SetJustifyH("LEFT")
    frame.label:SetTextColor(1, 1, 1, 1)
    frame.label:SetText("NO LINKED TIMER")

    frame.state = frame:CreateFontString(nil, "OVERLAY")
    frame.state:SetFont(Theme.font, 9, "OUTLINE")
    frame.state:SetPoint("RIGHT", -52, 0)
    frame.state:SetWidth(72)
    frame.state:SetJustifyH("RIGHT")
    frame.state:SetText("")

    frame.time = frame:CreateFontString(nil, "OVERLAY")
    frame.time:SetFont(Theme.font, 14, "OUTLINE")
    frame.time:SetPoint("RIGHT", -8, 0)
    frame.time:SetWidth(38)
    frame.time:SetJustifyH("RIGHT")
    frame.time:SetText("--")

    instance.frame = frame
    instance.state = nil
    instance:SetState(Constants.CallState.IDLE)
    return instance
end

function TimelineBar:SetIdle(label)
    self.frame:SetMinMaxValues(0, 1)
    self.frame:SetValue(0)
    self.frame.label:SetText(label or "NO LINKED TIMER")
    self.frame.time:SetText("--")
    self.frame.icon:SetTexture(134400)
    self:SetState(Constants.CallState.IDLE)
end

function TimelineBar:SetTimer(timer, remaining)
    local duration = math.max(timer.duration or 0.1, 0.1)
    self.frame:SetMinMaxValues(0, duration)
    self.frame:SetValue(Util.Clamp(remaining or 0, 0, duration))

    local label = timer.call and timer.call.ability or timer.name or "Boss timer"
    local source = sourceLabel(timer)
    if source then label = label .. " · " .. source end
    local approximate = timer.precision == Constants.TimerPrecision.APPROXIMATE
    if approximate then label = label .. " (approx)" end
    if timer.faded == true then label = label .. " (faded)" end
    self.frame.label:SetText(label)

    if remaining then
        local seconds = tostring(math.max(0, math.ceil(remaining)))
        self.frame.time:SetText(approximate and ("~" .. seconds) or seconds)
    else
        self.frame.time:SetText("--")
    end

    local icon = Util.NormalizeTexture(timer.icon)
    if not icon and timer.call then
        icon = Util.GetSpellIcon(timer.call.iconSpellID)
        if not icon and timer.call.spellIDs then
            icon = Util.GetSpellIcon(timer.call.spellIDs[1])
        end
    end
    self.frame.icon:SetTexture(icon or 134400)
end

function TimelineBar:SetState(state)
    if self.state == state then return end
    self.state = state

    if state == Constants.CallState.PRESS then
        self.frame:SetStatusBarColor(Theme.colors.success[1], Theme.colors.success[2], Theme.colors.success[3], 0.92)
        self.frame:SetBackdropBorderColor(Theme.colors.success[1], Theme.colors.success[2], Theme.colors.success[3], 1)
        self.frame.state:SetTextColor(Theme.colors.success[1], Theme.colors.success[2], Theme.colors.success[3], 1)
        self.frame.state:SetText("PRESS NOW")
    elseif state == Constants.CallState.PREPARE then
        self.frame:SetStatusBarColor(Theme.colors.warning[1], Theme.colors.warning[2], Theme.colors.warning[3], 0.78)
        self.frame:SetBackdropBorderColor(Theme.colors.warning[1], Theme.colors.warning[2], Theme.colors.warning[3], 1)
        self.frame.state:SetTextColor(Theme.colors.warning[1], Theme.colors.warning[2], Theme.colors.warning[3], 1)
        self.frame.state:SetText("SOON")
    elseif state == Constants.CallState.LATE then
        self.frame:SetStatusBarColor(Theme.colors.error[1], Theme.colors.error[2], Theme.colors.error[3], 0.72)
        self.frame:SetBackdropBorderColor(Theme.colors.error[1], Theme.colors.error[2], Theme.colors.error[3], 1)
        self.frame.state:SetTextColor(Theme.colors.error[1], Theme.colors.error[2], Theme.colors.error[3], 1)
        self.frame.state:SetText("LATE")
    elseif state == Constants.CallState.WAIT then
        self.frame:SetStatusBarColor(Theme.colors.surfaceRaised[1], Theme.colors.surfaceRaised[2], Theme.colors.surfaceRaised[3], 0.90)
        self.frame:SetBackdropBorderColor(Theme.colors.muted[1], Theme.colors.muted[2], Theme.colors.muted[3], 0.85)
        self.frame.state:SetTextColor(Theme.colors.muted[1], Theme.colors.muted[2], Theme.colors.muted[3], 1)
        self.frame.state:SetText("WAIT")
    elseif state == Constants.CallState.CALLED then
        self.frame:SetStatusBarColor(Theme.colors.called[1], Theme.colors.called[2], Theme.colors.called[3], 0.90)
        self.frame:SetBackdropBorderColor(Theme.colors.borderStrong[1], Theme.colors.borderStrong[2], Theme.colors.borderStrong[3], 1)
        self.frame.state:SetTextColor(Theme.colors.muted[1], Theme.colors.muted[2], Theme.colors.muted[3], 1)
        self.frame.state:SetText("CALLED")
    else
        self.frame:SetStatusBarColor(
            Theme.colors.venomDark[1], Theme.colors.venomDark[2], Theme.colors.venomDark[3], 0.82
        )
        self.frame:SetBackdropBorderColor(0.22, 0.36, 0.27, 1)
        self.frame.state:SetText("")
    end
end

ns:RegisterModule("UI.TimelineBar", TimelineBar)
