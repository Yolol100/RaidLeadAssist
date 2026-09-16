local _, ns = ...

local IconPicker = {
    frame = nil,
    provider = nil,
    selectedIcon = 134400,
    offset = 1,
    pageSize = 70,
    buttons = {},
    callback = nil,
    cancelCallback = nil,
    accepted = false,
}

local FILTERS = {
    { key = "all", label = "All Icons" },
    { key = "spell", label = "Spell Icons" },
    { key = "item", label = "Item Icons" },
}

local function trim(value)
    if type(value) ~= "string" then return "" end
    return value:match("^%s*(.-)%s*$") or ""
end

local function ensureMacroUI()
    if C_AddOns and type(C_AddOns.LoadAddOn) == "function" then
        pcall(C_AddOns.LoadAddOn, "Blizzard_MacroUI")
    elseif type(LoadAddOn) == "function" then
        pcall(LoadAddOn, "Blizzard_MacroUI")
    end
end

local function createProvider(filterKey)
    ensureMacroUI()
    if not IconDataProviderMixin or not IconDataProviderExtraType then return nil end
    local provider = CreateAndInitFromMixin(IconDataProviderMixin, IconDataProviderExtraType.Spellbook)
    if filterKey == "spell" and IconDataProviderIconType then
        provider:SetIconTypes({ IconDataProviderIconType.Spell })
    elseif filterKey == "item" and IconDataProviderIconType then
        provider:SetIconTypes({ IconDataProviderIconType.Item })
    end
    return provider
end

local function releaseProvider(owner)
    if owner.provider and type(owner.provider.Release) == "function" then owner.provider:Release() end
    owner.provider = nil
end

local function hideRegion(region)
    if not region then return end
    if type(region.SetTexture) == "function" then pcall(region.SetTexture, region, nil) end
    if type(region.Hide) == "function" then region:Hide() end
end

local function removePortrait(frame)
    if not frame then return end
    if type(ButtonFrameTemplate_HidePortrait) == "function" then
        pcall(ButtonFrameTemplate_HidePortrait, frame)
    elseif type(PortraitFrameTemplate_HidePortrait) == "function" then
        pcall(PortraitFrameTemplate_HidePortrait, frame)
    end
    hideRegion(frame.PortraitContainer)
    hideRegion(frame.portrait)
    hideRegion(frame.Portrait)
    if frame.PortraitContainer then
        hideRegion(frame.PortraitContainer.portrait)
        hideRegion(frame.PortraitContainer.CircleMask)
    end
    if frame.TitleContainer then
        frame.TitleContainer:ClearAllPoints()
        frame.TitleContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 30, -1)
        frame.TitleContainer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -1)
    end
    if type(frame.SetTitle) == "function" then
        frame:SetTitle("Change Name/Icon")
    elseif frame.TitleText then
        frame.TitleText:SetText("Change Name/Icon")
    end
end

function IconPicker:RefreshGrid()
    local provider = self.provider
    local count = provider and provider:GetNumIcons() or 0
    local maxOffset = math.max(1, count - self.pageSize + 1)
    self.offset = math.max(1, math.min(self.offset or 1, maxOffset))

    for index = 1, #self.buttons do
        local button = self.buttons[index]
        local iconIndex = self.offset + index - 1
        local icon = provider and provider:GetIconByIndex(iconIndex) or nil
        button.iconIndex = icon and iconIndex or nil
        button.iconValue = icon
        button.Icon:SetTexture(icon or nil)
        button:SetShown(icon ~= nil)
        button.Selected:SetShown(icon ~= nil and tostring(icon) == tostring(self.selectedIcon))
    end

    if self.frame and self.frame.ScrollText then
        if count <= self.pageSize then
            self.frame.ScrollText:SetText("")
        else
            local last = math.min(count, self.offset + self.pageSize - 1)
            self.frame.ScrollText:SetFormattedText("%d-%d / %d", self.offset, last, count)
        end
    end
end

function IconPicker:SetFilter(filterKey)
    releaseProvider(self)
    self.filterKey = filterKey or "all"
    self.provider = createProvider(self.filterKey)
    self.offset = 1
    if self.frame and self.frame.FilterDropdown then
        local label = "All Icons"
        for _, item in ipairs(FILTERS) do if item.key == self.filterKey then label = item.label break end end
        UIDropDownMenu_SetText(self.frame.FilterDropdown, label)
    end
    self:RefreshGrid()
end

function IconPicker:Scroll(delta)
    if not self.provider then return end
    local count = self.provider:GetNumIcons()
    local maxOffset = math.max(1, count - self.pageSize + 1)
    local stride = 10
    self.offset = math.max(1, math.min(maxOffset, (self.offset or 1) - (delta * stride)))
    self:RefreshGrid()
end

function IconPicker:Open(anchorFrame, name, icon, callback, cancelCallback)
    self:Initialize()
    self.callback = callback
    self.cancelCallback = cancelCallback
    self.accepted = false
    self.selectedIcon = icon or 134400
    self.frame.NameEdit:SetText(name or "")
    self.frame.NameEdit:HighlightText()
    self.frame.SelectedIcon:SetTexture(self.selectedIcon)
    self:SetFilter("all")

    self.frame:ClearAllPoints()
    if anchorFrame then
        self.frame:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", 6, -36)
    else
        self.frame:SetPoint("CENTER")
    end
    self.frame:Show()
    self.frame.NameEdit:SetFocus()
end

function IconPicker:Close()
    if self.frame then self.frame:Hide() end
end

function IconPicker:Initialize()
    if self.frame then return end
    ensureMacroUI()

    local frame = CreateFrame("Frame", "RaidLeadAssistIconPicker", UIParent, "ButtonFrameTemplate")
    frame:SetSize(642, 590)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:Hide()
    removePortrait(frame)

    local nameLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameLabel:SetPoint("TOPLEFT", 24, -62)
    nameLabel:SetText("Enter Macro Name (Max 16 Characters):")

    local nameEdit = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    nameEdit:SetSize(250, 28)
    nameEdit:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 4, -5)
    nameEdit:SetAutoFocus(false)
    nameEdit:SetMaxLetters(16)
    frame.NameEdit = nameEdit

    local selectedLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    selectedLabel:SetPoint("TOPRIGHT", -70, -63)
    selectedLabel:SetText("Currently Selected")

    local selectedSub = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    selectedSub:SetPoint("TOP", selectedLabel, "BOTTOM", 0, -2)
    selectedSub:SetText("Click to view in the list")

    local selectedButton = CreateFrame("Button", nil, frame)
    selectedButton:SetSize(50, 50)
    selectedButton:SetPoint("LEFT", selectedLabel, "RIGHT", 10, -8)
    selectedButton:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
    local selectedIcon = selectedButton:CreateTexture(nil, "ARTWORK")
    selectedIcon:SetPoint("TOPLEFT", 3, -3)
    selectedIcon:SetPoint("BOTTOMRIGHT", -3, 3)
    selectedIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    frame.SelectedIcon = selectedIcon
    selectedButton:SetScript("OnClick", function()
        if not self.provider then return end
        local index = self.provider:GetIndexOfIcon(self.selectedIcon)
        if index then
            self.offset = math.max(1, index - math.floor(self.pageSize / 2))
            self:RefreshGrid()
        end
    end)

    local separator = frame:CreateTexture(nil, "ARTWORK")
    separator:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar")
    separator:SetSize(590, 16)
    separator:SetPoint("TOP", 0, -126)
    separator:SetTexCoord(0, 1, 0, 0.25)

    local chooseLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    chooseLabel:SetPoint("TOPLEFT", 24, -146)
    chooseLabel:SetText("Choose an Icon:")

    local filterDropdown = CreateFrame("Frame", "RaidLeadAssistIconFilterDropdown", frame, "UIDropDownMenuTemplate")
    filterDropdown:SetPoint("TOPRIGHT", -26, -137)
    UIDropDownMenu_SetWidth(filterDropdown, 150)
    UIDropDownMenu_Initialize(filterDropdown, function(_, level)
        if level ~= 1 then return end
        for _, filter in ipairs(FILTERS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = filter.label
            info.checked = self.filterKey == filter.key
            info.func = function() self:SetFilter(filter.key) end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    frame.FilterDropdown = filterDropdown

    local gridBackground = CreateFrame("Frame", nil, frame, "TooltipBackdropTemplate")
    gridBackground:SetPoint("TOPLEFT", 20, -178)
    gridBackground:SetPoint("BOTTOMRIGHT", -20, 54)
    gridBackground:EnableMouseWheel(true)
    gridBackground:SetScript("OnMouseWheel", function(_, delta) self:Scroll(delta) end)

    local columns, rows = 10, 7
    self.pageSize = columns * rows
    for index = 1, self.pageSize do
        local button = CreateFrame("Button", nil, gridBackground)
        button:SetSize(45, 45)
        local col = (index - 1) % columns
        local row = math.floor((index - 1) / columns)
        button:SetPoint("TOPLEFT", 24 + (col * 55), -14 - (row * 49))
        button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
        button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

        local iconTexture = button:CreateTexture(nil, "ARTWORK")
        iconTexture:SetPoint("TOPLEFT", 3, -3)
        iconTexture:SetPoint("BOTTOMRIGHT", -3, 3)
        iconTexture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        button.Icon = iconTexture

        local selected = button:CreateTexture(nil, "OVERLAY")
        selected:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        selected:SetBlendMode("ADD")
        selected:SetAllPoints()
        selected:Hide()
        button.Selected = selected

        button:SetScript("OnClick", function(btn)
            if not btn.iconValue then return end
            self.selectedIcon = btn.iconValue
            frame.SelectedIcon:SetTexture(self.selectedIcon)
            self:RefreshGrid()
        end)
        self.buttons[index] = button
    end

    local scrollText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    scrollText:SetPoint("BOTTOM", 0, 37)
    frame.ScrollText = scrollText

    local okay = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    okay:SetSize(90, 24)
    okay:SetPoint("BOTTOMRIGHT", -108, 12)
    okay:SetText(OKAY or "Okay")
    okay:SetScript("OnClick", function()
        local callback = self.callback
        local pickedName = trim(frame.NameEdit:GetText())
        if pickedName == "" then
            ns:Print("Macro name cannot be empty.")
            frame.NameEdit:SetFocus()
            return
        end
        local pickedIcon = self.selectedIcon
        self.accepted = true
        self:Close()
        if callback then callback(pickedName, pickedIcon) end
    end)

    local cancel = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    cancel:SetSize(90, 24)
    cancel:SetPoint("LEFT", okay, "RIGHT", 8, 0)
    cancel:SetText(CANCEL or "Cancel")
    cancel:SetScript("OnClick", function() self:Close() end)

    frame:SetScript("OnHide", function()
        local cancelCallback = not self.accepted and self.cancelCallback or nil
        releaseProvider(self)
        self.callback = nil
        self.cancelCallback = nil
        self.accepted = false
        if cancelCallback then cancelCallback() end
    end)

    self.frame = frame
end

ns:RegisterModule("UI.IconPicker", IconPicker)