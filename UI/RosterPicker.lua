local _, ns = ...

local Theme = ns:GetModule("UI.Theme")
local ActionButton = ns:GetModule("UI.ActionButton")
local Roster = ns:GetModule("Services.RosterService")

local RosterPicker = { rows = {}, selected = {}, extras = {}, compactGroups = false }

local function trim(value)
    return type(value) == "string" and (value:match("^%s*(.-)%s*$") or "") or ""
end

local function parseGroupNumbers(value)
    local lower = trim(value):lower()
    local body = lower:match("^group%s+(%d+)$") or lower:match("^groups%s+([%d+]+)$")
    if not body then return nil end
    local result = {}
    local seen = {}
    for token in body:gmatch("%d+") do
        local group = tonumber(token)
        if not group or group < 1 or group > 8 or seen[group] then return nil end
        seen[group] = true
        result[#result + 1] = group
    end
    table.sort(result)
    return #result > 0 and result or nil
end

local function splitTokens(value)
    local result = {}
    if type(value) ~= "string" then return result end
    for part in value:gmatch("[^,]+") do
        local token = trim(part)
        if token ~= "" then result[#result + 1] = token end
    end
    return result
end

local function groupMap(roster)
    local result = {}
    for index = 1, #roster do
        local entry = roster[index]
        local group = tonumber(entry.subgroup) or 1
        result[group] = result[group] or {}
        result[group][#result[group] + 1] = entry.name
    end
    return result
end

local function orderedSelection(roster, selected, extras, compactGroups)
    local values = {}
    local seen = {}
    local consumed = {}

    if compactGroups then
        local groups = groupMap(roster)
        local completeGroups = {}
        for group = 1, 8 do
            local members = groups[group]
            if members and #members > 0 then
                local complete = true
                for index = 1, #members do
                    if not selected[members[index]] then complete = false break end
                end
                if complete then
                    completeGroups[#completeGroups + 1] = group
                    for index = 1, #members do consumed[members[index]] = true end
                end
            end
        end
        if #completeGroups == 1 then
            values[#values + 1] = "Group " .. completeGroups[1]
        elseif #completeGroups > 1 then
            local labels = {}
            for index = 1, #completeGroups do labels[index] = tostring(completeGroups[index]) end
            values[#values + 1] = "Groups " .. table.concat(labels, "+")
        end
    end

    for index = 1, #roster do
        local name = roster[index].name
        if selected[name] and not consumed[name] then
            values[#values + 1] = name
            seen[name] = true
        elseif consumed[name] then
            seen[name] = true
        end
    end
    for index = 1, #extras do
        local name = extras[index]
        if not seen[name] then values[#values + 1] = name end
    end
    return table.concat(values, ", ")
end

local function classColor(entry)
    local colors = _G.RAID_CLASS_COLORS
    local color = colors and entry.classFileName and colors[entry.classFileName]
    if color then return color.r or 1, color.g or 1, color.b or 1 end
    return Theme.colors.text[1], Theme.colors.text[2], Theme.colors.text[3]
end

function RosterPicker:Initialize(parent)
    if self.frame then return end

    local frame = CreateFrame("Frame", "RaidLeadAssistRosterPicker", parent or UIParent, "BackdropTemplate")
    frame:SetSize(420, 520)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetBackdrop({ bgFile = Theme.texture, edgeFile = Theme.texture, edgeSize = 1 })
    frame:SetBackdropColor(Theme.colors.backgroundSolid[1], Theme.colors.backgroundSolid[2], Theme.colors.backgroundSolid[3], 1)
    frame:SetBackdropBorderColor(Theme.colors.borderStrong[1], Theme.colors.borderStrong[2], Theme.colors.borderStrong[3], 1)
    frame:Hide()

    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(Theme.font, 14, "OUTLINE")
    title:SetPoint("TOPLEFT", 16, -14)
    title:SetText("Choose players")
    title:SetTextColor(1, 1, 1, 1)
    self.title = title

    local helper = frame:CreateFontString(nil, "OVERLAY")
    helper:SetFont(Theme.font, 9, "OUTLINE")
    helper:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    helper:SetText("Choose current players. Available G1-G8 buttons select complete raid groups.")
    helper:SetTextColor(Theme.colors.muted[1], Theme.colors.muted[2], Theme.colors.muted[3], 1)
    self.helper = helper

    local close = CreateFrame("Button", nil, frame)
    close:SetSize(28, 28)
    close:SetPoint("TOPRIGHT", -8, -8)
    close.text = close:CreateFontString(nil, "OVERLAY")
    close.text:SetAllPoints()
    close.text:SetFont(Theme.font, 13, "OUTLINE")
    close.text:SetText("X")
    close:SetScript("OnClick", function() self:Hide() end)

    self.groupButtons = {}
    local previous
    for group = 1, 8 do
        local button = ActionButton:Create(frame, { text = "G" .. group, width = 42, height = 24, fontSize = 8, variant = "secondary" })
        if previous then button:SetPoint("LEFT", previous, "RIGHT", 5, 0) else button:SetPoint("TOPLEFT", 16, -62) end
        button:SetScript("OnClick", function() self:ToggleGroup(group) end)
        self.groupButtons[group] = button
        previous = button
    end

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -98)
    scroll:SetPoint("BOTTOMRIGHT", -34, 58)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(360)
    content:SetHeight(1)
    scroll:SetScrollChild(content)
    self.content = content

    local clear = ActionButton:Create(frame, { text = "CLEAR", width = 78, height = 28, fontSize = 9, variant = "secondary" })
    clear:SetPoint("BOTTOMLEFT", 16, 16)
    clear:SetScript("OnClick", function()
        self.selected = {}
        self.extras = {}
        self:RefreshRows()
    end)

    local apply = ActionButton:Create(frame, { text = "APPLY", width = 96, height = 28, fontSize = 9, variant = "primary" })
    apply:SetPoint("BOTTOMRIGHT", -16, 16)
    apply:SetScript("OnClick", function()
        local value = orderedSelection(self.roster or {}, self.selected, self.extras, self.compactGroups)
        local callback = self.onApply
        self:Hide()
        if callback then callback(value) end
    end)

    self.frame = frame
end

function RosterPicker:EnsureRows(count)
    while #self.rows < count do
        local index = #self.rows + 1
        local row = CreateFrame("Button", nil, self.content, "BackdropTemplate")
        row:SetHeight(30)
        row:SetBackdrop({ bgFile = Theme.texture, edgeFile = Theme.texture, edgeSize = 1 })
        row:SetBackdropColor(Theme.colors.surface[1], Theme.colors.surface[2], Theme.colors.surface[3], 0.92)
        row:SetBackdropBorderColor(Theme.colors.border[1], Theme.colors.border[2], Theme.colors.border[3], 1)
        row:SetPoint("LEFT", 0, 0)
        row:SetPoint("RIGHT", 0, 0)
        if index == 1 then row:SetPoint("TOP", 0, 0) else row:SetPoint("TOP", self.rows[index - 1], "BOTTOM", 0, -4) end

        row.check = row:CreateFontString(nil, "OVERLAY")
        row.check:SetFont(Theme.font, 10, "OUTLINE")
        row.check:SetPoint("LEFT", 8, 0)

        row.group = row:CreateFontString(nil, "OVERLAY")
        row.group:SetFont(Theme.font, 8, "OUTLINE")
        row.group:SetPoint("LEFT", 30, 0)
        row.group:SetWidth(28)
        row.group:SetJustifyH("LEFT")
        row.group:SetTextColor(Theme.colors.muted[1], Theme.colors.muted[2], Theme.colors.muted[3], 1)

        row.name = row:CreateFontString(nil, "OVERLAY")
        row.name:SetFont(Theme.font, 10, "OUTLINE")
        row.name:SetPoint("LEFT", 62, 0)
        row.name:SetPoint("RIGHT", -70, 0)
        row.name:SetJustifyH("LEFT")

        row.role = row:CreateFontString(nil, "OVERLAY")
        row.role:SetFont(Theme.font, 8, "OUTLINE")
        row.role:SetPoint("RIGHT", -8, 0)
        row.role:SetTextColor(Theme.colors.muted[1], Theme.colors.muted[2], Theme.colors.muted[3], 1)

        row:SetScript("OnClick", function(button)
            if not button.playerName then return end
            self.selected[button.playerName] = not self.selected[button.playerName]
            self:RefreshRows()
        end)
        self.rows[index] = row
    end
end

function RosterPicker:RefreshRows()
    local roster = self.roster or {}
    self:EnsureRows(#roster)
    for index = 1, #self.rows do
        local row = self.rows[index]
        local entry = roster[index]
        if entry then
            row.playerName = entry.name
            row.check:SetText(self.selected[entry.name] and "[x]" or "[ ]")
            row.check:SetTextColor(Theme.colors.venom[1], Theme.colors.venom[2], Theme.colors.venom[3], 1)
            row.group:SetText("G" .. tostring(entry.subgroup or 1))
            row.name:SetText(entry.name)
            row.name:SetTextColor(classColor(entry))
            row.role:SetText(entry.role == "DAMAGER" and "DPS" or (entry.role or ""))
            row:Show()
        else
            row.playerName = nil
            row:Hide()
        end
    end

    local groups = groupMap(roster)
    for group = 1, 8 do
        local button = self.groupButtons[group]
        local members = groups[group] or {}
        local exists = #members > 0
        local complete = exists
        for index = 1, #members do
            if not self.selected[members[index]] then complete = false break end
        end
        button:SetActionEnabled(exists)
        button:SetActionVariant(complete and "primary" or "secondary")
    end

    self.content:SetHeight(math.max(1, (#roster * 34) - 4))
end

function RosterPicker:ToggleGroup(group)
    local roster = self.roster or {}
    local anyMember = false
    local anyUnselected = false
    for index = 1, #roster do
        if roster[index].subgroup == group then
            anyMember = true
            if not self.selected[roster[index].name] then anyUnselected = true end
        end
    end
    if not anyMember then return end
    for index = 1, #roster do
        if roster[index].subgroup == group then self.selected[roster[index].name] = anyUnselected or nil end
    end
    self:RefreshRows()
end

function RosterPicker:Open(label, currentValue, onApply, compactGroups)
    self:Initialize(UIParent)
    self.roster = Roster:GetRoster()
    self.selected = {}
    self.extras = {}
    self.onApply = onApply
    self.compactGroups = compactGroups == true
    self.title:SetText("Choose players · " .. (label or "Assignment"))
    self.helper:SetText(self.compactGroups
        and "Select players or complete current raid groups; full groups are saved compactly."
        or "Select current players; unavailable raid groups cannot be selected.")

    local rosterNames = {}
    local groups = groupMap(self.roster)
    for index = 1, #self.roster do rosterNames[self.roster[index].name] = true end

    local tokens = splitTokens(currentValue)
    for index = 1, #tokens do
        local token = tokens[index]
        local groupNumbers = self.compactGroups and parseGroupNumbers(token) or nil
        if groupNumbers then
            for groupIndex = 1, #groupNumbers do
                local members = groups[groupNumbers[groupIndex]] or {}
                for memberIndex = 1, #members do self.selected[members[memberIndex]] = true end
            end
        elseif rosterNames[token] then
            self.selected[token] = true
        else
            self.extras[#self.extras + 1] = token
        end
    end

    self:RefreshRows()
    self.frame:Show()
    self.frame:Raise()
end

function RosterPicker:Hide()
    if self.frame then self.frame:Hide() end
end

ns:RegisterModule("UI.RosterPicker", RosterPicker)
