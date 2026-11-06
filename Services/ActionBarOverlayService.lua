local _, ns = ...

local Constants = ns:GetModule("Core.Constants")
local Util = ns:GetModule("Core.Util")
local BossMacros = ns:GetModule("Services.BossMacroService")
local ManagedMacros = ns:GetModule("Services.ManagedMacroService")
local Timeline = ns:GetModule("Services.TimelineService")

local OverlayService = {
    database = nil,
    overlays = {},
    frame = nil,
    accumulator = 0,
}

local BUTTON_PREFIXES = {
    "ActionButton",
    "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton",
    "MultiBarRightButton",
    "MultiBarLeftButton",
    "MultiBar5Button",
    "MultiBar6Button",
    "MultiBar7Button",
}

local function inCombat()
    return type(InCombatLockdown) == "function" and InCombatLockdown() == true
end

local function finite(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function setTextureColor(texture, r, g, b, a)
    if texture then texture:SetColorTexture(r, g, b, a or 1) end
end

local function setBorderColor(overlay, r, g, b, a)
    a = a or 1
    setTextureColor(overlay.BorderTop, r, g, b, a)
    setTextureColor(overlay.BorderBottom, r, g, b, a)
    setTextureColor(overlay.BorderLeft, r, g, b, a)
    setTextureColor(overlay.BorderRight, r, g, b, a)
end

local function createBorder(owner)
    local top = owner:CreateTexture(nil, "OVERLAY", nil, 7)
    top:SetPoint("TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", 0, 0)
    top:SetHeight(2)

    local bottom = owner:CreateTexture(nil, "OVERLAY", nil, 7)
    bottom:SetPoint("BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(2)

    local left = owner:CreateTexture(nil, "OVERLAY", nil, 7)
    left:SetPoint("TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", 0, 0)
    left:SetWidth(2)

    local right = owner:CreateTexture(nil, "OVERLAY", nil, 7)
    right:SetPoint("TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", 0, 0)
    right:SetWidth(2)

    owner.BorderTop = top
    owner.BorderBottom = bottom
    owner.BorderLeft = left
    owner.BorderRight = right
end

function OverlayService:AttachButton(button)
    if not button or self.overlays[button] then return self.overlays[button] end
    if inCombat() or type(button.GetFrameLevel) ~= "function" then return nil end

    local overlay = CreateFrame("Frame", nil, button)
    overlay:SetAllPoints(button)
    overlay:SetFrameLevel((button:GetFrameLevel() or 0) + 8)
    overlay:EnableMouse(false)
    overlay:Hide()

    local progress = CreateFrame("StatusBar", nil, overlay)
    progress:SetAllPoints(overlay)
    progress:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    progress:SetMinMaxValues(0, 1)
    progress:SetValue(0)
    progress:SetStatusBarColor(1, 1, 1, 0.20)
    progress:EnableMouse(false)
    overlay.Progress = progress

    local veil = overlay:CreateTexture(nil, "OVERLAY", nil, 4)
    veil:SetAllPoints(overlay)
    veil:SetColorTexture(0.85, 0.04, 0.02, 0.0)
    overlay.Veil = veil

    local edge = overlay:CreateTexture(nil, "OVERLAY", nil, 6)
    edge:SetWidth(2)
    edge:SetColorTexture(1, 1, 1, 0.82)
    edge:Hide()
    overlay.Edge = edge

    local countdown = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalLargeOutline")
    countdown:SetPoint("CENTER", 0, 0)
    countdown:SetTextColor(1, 1, 1, 1)
    countdown:SetText("")
    overlay.Countdown = countdown

    createBorder(overlay)
    setBorderColor(overlay, 1, 1, 1, 0)

    overlay.button = button
    overlay.macroId = nil
    overlay.lastState = nil
    self.overlays[button] = overlay
    return overlay
end

function OverlayService:CollectButtons(allowCreate)
    local seen = {}

    local function collect(button)
        if not button or type(button.GetObjectType) ~= "function" or seen[button] then return end
        seen[button] = true
        if allowCreate then self:AttachButton(button) end
    end

    if ActionBarButtonEventsFrame and type(ActionBarButtonEventsFrame.ForEachFrame) == "function" then
        pcall(ActionBarButtonEventsFrame.ForEachFrame, ActionBarButtonEventsFrame, collect)
    end

    for _, prefix in ipairs(BUTTON_PREFIXES) do
        for index = 1, 12 do
            local button = _G[prefix .. index]
            if button then collect(button) end
        end
    end

    return seen
end

function OverlayService:ResolveButtonMacroId(button)
    if not button then return nil end
    local action = button.action
    if Util.IsSecret(action) or type(action) ~= "number" then return nil end
    if type(GetActionInfo) ~= "function" then return nil end

    local ok, actionType, actionId = pcall(GetActionInfo, action)
    if not ok or Util.IsSecret(actionType) or Util.IsSecret(actionId) then return nil end
    if actionType ~= "macro" or type(actionId) ~= "number" then return nil end
    return ManagedMacros:GetManagedIdByMacroIndex(actionId)
end

function OverlayService:RefreshBindings()
    local allowCreate = not inCombat()
    local seen = self:CollectButtons(allowCreate)

    for button, overlay in pairs(self.overlays) do
        local visible = type(button.IsVisible) == "function" and button:IsVisible()
        if seen[button] or visible then
            overlay.macroId = self:ResolveButtonMacroId(button)
        else
            overlay.macroId = nil
        end
        if not overlay.macroId then overlay:Hide() end
    end
end

function OverlayService:HideAll()
    for _, overlay in pairs(self.overlays) do overlay:Hide() end
end

function OverlayService:ApplyProgress(overlay, timing)
    local duration = tonumber(timing.duration)
    local remaining = tonumber(timing.remaining)
    if not finite(duration) or duration <= 0 or not finite(remaining) then
        overlay.Progress:SetMinMaxValues(0, 1)
        overlay.Progress:SetValue(0)
        overlay.Edge:Hide()
        return 0
    end

    local clamped = math.max(0, math.min(duration, remaining))
    overlay.Progress:SetMinMaxValues(0, duration)
    overlay.Progress:SetValue(clamped)

    local ratio = clamped / duration
    local width = overlay.button and overlay.button:GetWidth() or overlay:GetWidth()
    local height = overlay.button and overlay.button:GetHeight() or overlay:GetHeight()
    if finite(width) and width > 0 and finite(height) and height > 0 then
        overlay.Edge:ClearAllPoints()
        overlay.Edge:SetPoint("CENTER", overlay, "LEFT", math.max(1, width * ratio), 0)
        overlay.Edge:SetHeight(math.max(1, height - 2))
        overlay.Edge:Show()
    else
        overlay.Edge:Hide()
    end
    return ratio
end

function OverlayService:ApplyState(overlay, timing)
    local state = timing.state
    local remaining = tonumber(timing.remaining) or 0
    local ratio = self:ApplyProgress(overlay, timing)
    overlay.lastState = state

    overlay.Countdown:SetText(remaining < 0 and "NOW" or (remaining < 10 and string.format("%.1f", remaining) or tostring(math.ceil(remaining))))
    overlay.Countdown:SetTextColor(1, 1, 1, 1)
    overlay.Veil:SetColorTexture(0.85, 0.04, 0.02, 0)

    if state == Constants.CallState.PRESS then
        overlay.Progress:SetStatusBarColor(0.95, 0.12, 0.08, 0.50)
        local pulse = 0.30 + (0.12 * (0.5 + (0.5 * math.sin(GetTime() * 8))))
        overlay.Veil:SetColorTexture(0.95, 0.04, 0.02, pulse)
        overlay.Edge:SetColorTexture(1, 0.78, 0.72, 0.95)
        setBorderColor(overlay, 1, 0.08, 0.04, 1)
        overlay.Countdown:SetTextColor(1, 0.92, 0.88, 1)
    elseif state == Constants.CallState.LATE then
        overlay.Progress:SetStatusBarColor(0.92, 0.04, 0.03, 0.58)
        overlay.Veil:SetColorTexture(0.95, 0.02, 0.01, 0.48)
        overlay.Edge:Hide()
        setBorderColor(overlay, 1, 0.02, 0.01, 1)
        overlay.Countdown:SetText("NOW")
        overlay.Countdown:SetTextColor(1, 0.88, 0.84, 1)
    elseif state == Constants.CallState.PREPARE then
        overlay.Progress:SetStatusBarColor(1, 1, 1, 0.28)
        overlay.Edge:SetColorTexture(1, 0.92, 0.58, 0.95)
        setBorderColor(overlay, 1, 0.72, 0.10, 1)
        overlay.Countdown:SetTextColor(1, 0.92, 0.52, 1)
    else
        overlay.Progress:SetStatusBarColor(1, 1, 1, 0.18)
        overlay.Edge:SetColorTexture(1, 1, 1, 0.78)
        setBorderColor(overlay, 1, 1, 1, 0.18)
        if ratio > 0.85 and remaining > 30 then
            overlay.Countdown:SetTextColor(1, 1, 1, 0.82)
        end
    end

    overlay:Show()
end

function OverlayService:UpdateOverlay(overlay)
    if not overlay.macroId or not self.database then overlay:Hide() return end
    local macro, boss, difficultyKey = BossMacros:FindMacroById(overlay.macroId)
    if not macro or not boss
        or boss.id ~= self.database.selectedBossId
        or difficultyKey ~= self.database.selectedDifficultyKey then
        overlay:Hide()
        return
    end

    local timing = BossMacros:GetTimingState(boss, macro, Timeline)
    if not timing then
        overlay:Hide()
        return
    end

    self:ApplyState(overlay, timing)
end

function OverlayService:UpdateAll(elapsed)
    self.accumulator = self.accumulator + (elapsed or 0)
    if self.accumulator < 0.05 then return end
    self.accumulator = 0
    for _, overlay in pairs(self.overlays) do self:UpdateOverlay(overlay) end
end

function OverlayService:NotifyMacroAcknowledged()
    for _, overlay in pairs(self.overlays) do
        if overlay.macroId then self:UpdateOverlay(overlay) end
    end
end

function OverlayService:Initialize(database)
    self.database = database

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    frame:RegisterEvent("UPDATE_MACROS")
    frame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    frame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
    frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    frame:SetScript("OnEvent", function(_, eventName)
        if eventName == "PLAYER_REGEN_ENABLED" or not inCombat() then
            C_Timer.After(0, function() self:RefreshBindings() end)
        else
            self:RefreshBindings()
        end
    end)
    frame:SetScript("OnUpdate", function(_, elapsed) self:UpdateAll(elapsed) end)
    self.frame = frame

    if not inCombat() then C_Timer.After(0, function() self:RefreshBindings() end) end
end

ns:RegisterModule("Services.ActionBarOverlayService", OverlayService)
