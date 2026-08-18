local _, ns = ...

local Constants = ns:GetModule("Core.Constants")
local Theme = ns:GetModule("UI.Theme")
local CallButton = ns:GetModule("UI.CallButton")
local Messages = ns:GetModule("Services.MessageService")

local SentinelsPanel = {}
SentinelsPanel.__index = SentinelsPanel

local BREATH_NPC_ID = 258557
local BLOOD_NPC_ID = 258558
local BOSS_TOKENS = { "boss1", "boss2", "boss3", "boss4", "boss5" }

local function valueIsSecret(value)
    return type(issecretvalue) == "function" and issecretvalue(value) == true
end

local function valueIsAccessible(value)
    if valueIsSecret(value) then return false end
    if type(canaccessvalue) == "function" and not canaccessvalue(value) then return false end
    return value ~= nil
end

local function npcIDFromGUID(guid)
    if not valueIsAccessible(guid) or type(guid) ~= "string" then return nil end
    local unitType, npcID = guid:match("^([^-]+)%-[^-]+%-[^-]+%-[^-]+%-[^-]+%-([^-]+)%-")
    if unitType ~= "Creature" and unitType ~= "Vehicle" then return nil end
    return tonumber(npcID)
end

local function setBackdrop(frame, color)
    frame:SetBackdropColor(color[1], color[2], color[3], color[4] or 1)
    frame:SetBackdropBorderColor(Theme.colors.border[1], Theme.colors.border[2], Theme.colors.border[3], 1)
end

local function createTitle(parent, text, color)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont(Theme.font, 12, "OUTLINE")
    label:SetText(text)
    label:SetTextColor(color[1], color[2], color[3], 1)
    label:SetJustifyH("LEFT")
    return label
end

local function createHealthCard(parent, title, color)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetHeight(46)
    card:SetBackdrop({ bgFile = Theme.texture, edgeFile = Theme.texture, edgeSize = 1 })
    setBackdrop(card, Theme.colors.surface)

    card.title = createTitle(card, title, color)
    card.title:SetPoint("TOPLEFT", 8, -6)
    card.title:SetPoint("RIGHT", -8, 0)

    card.bar = CreateFrame("StatusBar", nil, card, "BackdropTemplate")
    card.bar:SetPoint("BOTTOMLEFT", 8, 7)
    card.bar:SetPoint("BOTTOMRIGHT", -8, 7)
    card.bar:SetHeight(12)
    card.bar:SetStatusBarTexture(Theme.texture)
    card.bar:SetStatusBarColor(color[1], color[2], color[3], 1)
    card.bar:SetMinMaxValues(0, 1)
    card.bar:SetValue(0)
    card.bar:SetBackdrop({ bgFile = Theme.texture, edgeFile = Theme.texture, edgeSize = 1 })
    card.bar:SetBackdropColor(0.02, 0.04, 0.03, 0.95)
    card.bar:SetBackdropBorderColor(Theme.colors.border[1], Theme.colors.border[2], Theme.colors.border[3], 1)

    card.status = card:CreateFontString(nil, "OVERLAY")
    card.status:SetFont(Theme.font, 8, "OUTLINE")
    card.status:SetPoint("BOTTOMRIGHT", -10, 8)
    card.status:SetTextColor(Theme.colors.text[1], Theme.colors.text[2], Theme.colors.text[3], 1)
    card.status:SetText("WAITING")

    return card
end

local function createColumn(parent, title, color)
    local column = CreateFrame("Frame", nil, parent)
    column.title = createTitle(column, title, color)
    column.title:SetPoint("TOPLEFT", 0, 0)
    column.title:SetPoint("RIGHT", 0, 0)
    return column
end

local function ensureButton(pool, index, parent)
    local button = pool[index]
    if not button then
        button = CallButton:Create(parent)
        pool[index] = button
    end
    button.frame:ClearAllPoints()
    button.frame:SetPoint("LEFT", parent, "LEFT", 0, 0)
    button.frame:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
    return button
end

local function hidePool(pool)
    for _, button in ipairs(pool) do button.frame:Hide() end
end

function SentinelsPanel:Create(parent, mainUI)
    local instance = setmetatable({}, SentinelsPanel)
    instance.mainUI = mainUI
    instance.frame = CreateFrame("Frame", nil, parent)
    instance.frame:Hide()
    instance.callButtonsByKey = {}
    instance.units = {}
    instance.healthAccumulator = 0
    instance.breathButtons = {}
    instance.bloodButtons = {}
    instance.sharedButtons = {}
    instance.balanceButtons = {}

    instance.breathColumn = createColumn(instance.frame, "BREATH SIDE", Theme.colors.venomBright)
    instance.bloodColumn = createColumn(instance.frame, "BLOOD SIDE", Theme.colors.error)

    local columnGap = Theme.gap
    instance.breathColumn:SetPoint("TOPLEFT", 0, 0)
    instance.breathColumn:SetPoint("TOPRIGHT", instance.frame, "TOP", -columnGap / 2, 0)
    instance.bloodColumn:SetPoint("TOPLEFT", instance.frame, "TOP", columnGap / 2, 0)
    instance.bloodColumn:SetPoint("TOPRIGHT", 0, 0)

    instance.breathHealth = createHealthCard(instance.breathColumn, "BREATH BOSS HP", Theme.colors.venomBright)
    instance.breathHealth:SetPoint("TOPLEFT", instance.breathColumn.title, "BOTTOMLEFT", 0, -5)
    instance.breathHealth:SetPoint("RIGHT", instance.breathColumn, "RIGHT", 0, 0)

    instance.bloodHealth = createHealthCard(instance.bloodColumn, "BLOOD BOSS HP", Theme.colors.error)
    instance.bloodHealth:SetPoint("TOPLEFT", instance.bloodColumn.title, "BOTTOMLEFT", 0, -5)
    instance.bloodHealth:SetPoint("RIGHT", instance.bloodColumn, "RIGHT", 0, 0)

    instance.sharedTitle = createTitle(instance.frame, "SHARED RAID CALLS", Theme.colors.text)
    instance.balanceTitle = createTitle(instance.frame, "MANUAL BALANCE CALLS", Theme.colors.text)

    return instance
end

function SentinelsPanel:BindButton(button, call, previous, healthCard)
    if previous then
        button.frame:SetPoint("TOP", previous.frame, "BOTTOM", 0, -Theme.gap)
    else
        button.frame:SetPoint("TOP", healthCard, "BOTTOM", 0, -Theme.gap)
    end
    button:SetCall(call, function(callKey)
        if self.mainUI.callbacks.onCall then self.mainUI.callbacks.onCall(callKey) end
    end, function(callKey)
        return Messages:GetCallWarning("sentinels", self.mainUI.currentDifficultyKey, callKey)
    end)
    self.callButtonsByKey[call.key] = button
    return button
end

function SentinelsPanel:Configure(profile)
    hidePool(self.breathButtons)
    hidePool(self.bloodButtons)
    hidePool(self.sharedButtons)
    hidePool(self.balanceButtons)
    self.callButtonsByKey = {}

    local breathCalls, bloodCalls, sharedCalls, balanceCalls = {}, {}, {}, {}
    for _, call in ipairs(profile.calls) do
        if call.uiGroup == "balance" then
            balanceCalls[#balanceCalls + 1] = call
        elseif call.uiGroup == "breath" then
            breathCalls[#breathCalls + 1] = call
        elseif call.uiGroup == "blood" then
            bloodCalls[#bloodCalls + 1] = call
        elseif call.uiGroup == "shared" then
            sharedCalls[#sharedCalls + 1] = call
        end
    end

    local breathPrevious
    for index, call in ipairs(breathCalls) do
        local button = ensureButton(self.breathButtons, index, self.breathColumn)
        breathPrevious = self:BindButton(button, call, breathPrevious, self.breathHealth)
    end

    local bloodPrevious
    for index, call in ipairs(bloodCalls) do
        local button = ensureButton(self.bloodButtons, index, self.bloodColumn)
        bloodPrevious = self:BindButton(button, call, bloodPrevious, self.bloodHealth)
    end

    local sideRows = math.max(#breathCalls, #bloodCalls)
    self.sharedTitle:ClearAllPoints()
    self.sharedTitle:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -(18 + 5 + 46 + Theme.gap + sideRows * Theme.callButtonHeight + math.max(0, sideRows - 1) * Theme.gap + 12))
    self.sharedTitle:SetPoint("RIGHT", self.frame, "RIGHT", 0, 0)

    local sharedPrevious
    for index, call in ipairs(sharedCalls) do
        local button = ensureButton(self.sharedButtons, index, self.frame)
        if sharedPrevious then
            button.frame:SetPoint("TOP", sharedPrevious.frame, "BOTTOM", 0, -Theme.gap)
        else
            button.frame:SetPoint("TOP", self.sharedTitle, "BOTTOM", 0, -5)
        end
        button:SetCall(call, function(callKey)
            if self.mainUI.callbacks.onCall then self.mainUI.callbacks.onCall(callKey) end
        end, function(callKey)
            return Messages:GetCallWarning("sentinels", self.mainUI.currentDifficultyKey, callKey)
        end)
        self.callButtonsByKey[call.key] = button
        sharedPrevious = button
    end

    self.balanceTitle:ClearAllPoints()
    if sharedPrevious then
        self.balanceTitle:SetPoint("TOPLEFT", sharedPrevious.frame, "BOTTOMLEFT", 0, -12)
    else
        self.balanceTitle:SetPoint("TOPLEFT", self.sharedTitle, "BOTTOMLEFT", 0, -5)
    end
    self.balanceTitle:SetPoint("RIGHT", self.frame, "RIGHT", 0, 0)

    local balancePrevious
    for index, call in ipairs(balanceCalls) do
        local button = ensureButton(self.balanceButtons, index, self.frame)
        if balancePrevious then
            button.frame:SetPoint("TOP", balancePrevious.frame, "BOTTOM", 0, -Theme.gap)
        else
            button.frame:SetPoint("TOP", self.balanceTitle, "BOTTOM", 0, -5)
        end
        button:SetCall(call, function(callKey)
            if self.mainUI.callbacks.onCall then self.mainUI.callbacks.onCall(callKey) end
        end, function(callKey)
            return Messages:GetCallWarning("sentinels", self.mainUI.currentDifficultyKey, callKey)
        end)
        self.callButtonsByKey[call.key] = button
        balancePrevious = button
    end

    local sharedHeight = #sharedCalls * Theme.callButtonHeight + math.max(0, #sharedCalls - 1) * Theme.gap
    local balanceHeight = #balanceCalls * Theme.callButtonHeight + math.max(0, #balanceCalls - 1) * Theme.gap
    self.height = 18 + 5 + 46 + Theme.gap + sideRows * Theme.callButtonHeight + math.max(0, sideRows - 1) * Theme.gap
        + 12 + 18 + 5 + sharedHeight + 12 + 18 + 5 + balanceHeight
    self.frame:SetHeight(self.height)
end

function SentinelsPanel:RefreshUnitMap()
    self.units.breath = nil
    self.units.blood = nil
    for _, token in ipairs(BOSS_TOKENS) do
        if UnitExists(token) then
            local npcID = npcIDFromGUID(UnitGUID(token))
            if npcID == BREATH_NPC_ID then self.units.breath = token end
            if npcID == BLOOD_NPC_ID then self.units.blood = token end
        end
    end
end

function SentinelsPanel:UpdateHealthCard(card, unit)
    if not unit or not UnitExists(unit) then
        card.bar:SetMinMaxValues(0, 1)
        card.bar:SetValue(0)
        card.status:SetText("WAITING")
        return
    end

    local health = UnitHealth(unit, true)
    local maximum = UnitHealthMax(unit)
    local secret = valueIsSecret(health) or valueIsSecret(maximum)

    if secret then
        card.bar:SetMinMaxValues(0, maximum)
        card.bar:SetValue(health, Enum.StatusBarInterpolation.ExponentialEaseOut)
        card.status:SetText("LIVE HP")
        return
    end

    if not valueIsAccessible(health) or not valueIsAccessible(maximum) or maximum <= 0 then
        card.bar:SetMinMaxValues(0, 1)
        card.bar:SetValue(0)
        card.status:SetText("UNAVAILABLE")
        return
    end

    card.bar:SetMinMaxValues(0, maximum)
    card.bar:SetValue(health, Enum.StatusBarInterpolation.ExponentialEaseOut)
    local percent = (health / maximum) * 100
    card.status:SetFormattedText("%.1f%%", percent)
end

function SentinelsPanel:UpdateHealth(elapsed)
    if not self.frame:IsShown() then return end
    self.healthAccumulator = self.healthAccumulator + elapsed
    if self.healthAccumulator < 0.10 then return end
    self.healthAccumulator = 0

    self:RefreshUnitMap()
    self:UpdateHealthCard(self.breathHealth, self.units.breath)
    self:UpdateHealthCard(self.bloodHealth, self.units.blood)
end

function SentinelsPanel:SetCallState(callKey, state)
    local button = self.callButtonsByKey[callKey]
    if not button then return false end
    button:SetState(state)
    return true
end

function SentinelsPanel:ResetCallStates()
    for _, button in pairs(self.callButtonsByKey) do
        button:SetState(Constants.CallState.IDLE, true)
    end
end

function SentinelsPanel:Show()
    self.frame:Show()
end

function SentinelsPanel:Hide()
    self.frame:Hide()
end

ns:RegisterModule("UI.SentinelsPanel", SentinelsPanel)
