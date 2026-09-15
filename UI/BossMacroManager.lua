local _, ns = ...

local BossMacros = ns:GetModule("Services.BossMacroService")
local IconPicker = ns:GetModule("UI.IconPicker")

local BossMacroManager = {
    frame = nil,
    database = nil,
    callbacks = nil,
    selectedBossId = nil,
    selectedMacroId = nil,
    macroButtons = {},
    macroOffset = 1,
    macroPageSize = 18,
    draft = nil,
    advancedShown = false,
}

local function trim(value)
    if type(value) ~= "string" then return "" end
    return value:match("^%s*(.-)%s*$") or ""
end

local function copyArray(source)
    local result = {}
    if type(source) ~= "table" then return result end
    for index = 1, #source do result[index] = source[index] end
    return result
end

local function shortName(name)
    name = tostring(name or "")
    if #name <= 8 then return name end
    return name:sub(1, 7) .. "…"
end

local function setupDialogs()
    if not StaticPopupDialogs["RLA_BOSS_NAME"] then
        StaticPopupDialogs["RLA_BOSS_NAME"] = {
            text = "%s",
            button1 = ACCEPT or "Accept",
            button2 = CANCEL or "Cancel",
            hasEditBox = true,
            maxLetters = 48,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
            OnShow = function(dialog, data)
                dialog.editBox:SetText((data and data.value) or "")
                dialog.editBox:HighlightText()
                dialog.editBox:SetFocus()
            end,
            OnAccept = function(dialog, data)
                if data and data.callback then data.callback(dialog.editBox:GetText() or "") end
            end,
            EditBoxOnEnterPressed = function(editBox)
                local parent = editBox:GetParent()
                local data = parent.data
                if data and data.callback then data.callback(editBox:GetText() or "") end
                parent:Hide()
            end,
        }
    end

    if not StaticPopupDialogs["RLA_CONFIRM_DELETE"] then
        StaticPopupDialogs["RLA_CONFIRM_DELETE"] = {
            text = "%s",
            button1 = DELETE or "Delete",
            button2 = CANCEL or "Cancel",
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            showAlert = true,
            preferredIndex = 3,
            OnAccept = function(_, data)
                if data and data.callback then data.callback() end
            end,
        }
    end
end

local function setPortrait(frame)
    if frame.PortraitContainer and frame.PortraitContainer.portrait then
        frame.PortraitContainer.portrait:SetTexture("Interface\\MacroFrame\\MacroFrame-Icon")
    end
end

local function addHorizontalBar(parent, y)
    local left = parent:CreateTexture(nil, "ARTWORK")
    left:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar")
    left:SetSize(256, 16)
    left:SetPoint("TOPLEFT", 2, y)
    left:SetTexCoord(0, 1, 0, 0.25)

    local right = parent:CreateTexture(nil, "ARTWORK")
    right:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar")
    right:SetSize(118, 16)
    right:SetPoint("LEFT", left, "RIGHT", 0, 0)
    right:SetTexCoord(0, 0.46, 0.25, 0.5)
end

function BossMacroManager:GetBoss()
    return self.selectedBossId and BossMacros:GetBoss(self.selectedBossId) or nil
end

function BossMacroManager:GetSelectedMacro()
    local macro = self.selectedMacroId and BossMacros:FindMacroById(self.selectedMacroId) or nil
    return macro
end

function BossMacroManager:RefreshBossDropdown()
    if not self.frame then return end
    local dropdown = self.frame.BossDropdown
    UIDropDownMenu_Initialize(dropdown, function(_, level)
        if level ~= 1 then return end
        for _, boss in ipairs(BossMacros:GetBossesOrdered()) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = boss.name
            info.checked = boss.id == self.selectedBossId
            info.func = function() self:SelectBoss(boss.id, true) end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    local boss = self:GetBoss()
    UIDropDownMenu_SetText(dropdown, boss and boss.name or "Select Boss")
end

function BossMacroManager:RefreshMacroGrid()
    local boss = self:GetBoss()
    local macros = boss and BossMacros:GetMacros(boss.id) or {}
    local maxOffset = math.max(1, #macros - self.macroPageSize + 1)
    self.macroOffset = math.max(1, math.min(self.macroOffset or 1, maxOffset))

    for index = 1, #self.macroButtons do
        local button = self.macroButtons[index]
        local macro = macros[self.macroOffset + index - 1]
        button.macroId = macro and macro.id or nil
        button:SetEnabled(macro ~= nil)
        button:SetAlpha(macro and 1 or 0.32)
        button.Icon:SetTexture(macro and BossMacros:GetIcon(macro) or nil)
        button.Name:SetText(macro and shortName(macro.name) or "")
        button.Selected:SetShown(macro ~= nil and tonumber(macro.id) == tonumber(self.selectedMacroId))
    end

    if self.frame and self.frame.GridStatus then
        if #macros == 0 then
            self.frame.GridStatus:SetText("No macros for this boss — press New to create one.")
        elseif #macros > self.macroPageSize then
            local last = math.min(#macros, self.macroOffset + self.macroPageSize - 1)
            self.frame.GridStatus:SetFormattedText("%d-%d / %d", self.macroOffset, last, #macros)
        else
            self.frame.GridStatus:SetText("")
        end
    end
end

function BossMacroManager:SetAbilityDraftFromMacro(sourceMacro)
    if not self.draft or not sourceMacro then return end
    self.draft.sourceCallKey = sourceMacro.sourceCallKey
    self.draft.spellIDs = copyArray(sourceMacro.spellIDs)
    self.draft.timerNames = copyArray(sourceMacro.timerNames)
    self.draft.timingEnabled = sourceMacro.timingEnabled == true
    self.draft.prepareSeconds = sourceMacro.prepareSeconds
    self.draft.pressSeconds = sourceMacro.pressSeconds
    self:RefreshAbilityDropdownText()
    if self.draft.iconMode == "ability" then
        self.frame.SelectedIcon:SetTexture(BossMacros:GetIcon(self.draft))
    end
    if self.advancedShown then self:RefreshAdvancedFields() end
end

function BossMacroManager:RefreshAbilityDropdownText()
    if not self.frame then return end
    local boss = self:GetBoss()
    local label = "Manual / unlinked"
    if boss and self.draft then
        for _, macro in ipairs(BossMacros:GetMacros(boss.id)) do
            if self.draft.sourceCallKey and macro.sourceCallKey == self.draft.sourceCallKey then
                label = macro.name
                break
            end
        end
    end
    UIDropDownMenu_SetText(self.frame.AbilityDropdown, label)
end

function BossMacroManager:RefreshAbilityDropdown()
    if not self.frame then return end
    local boss = self:GetBoss()
    local dropdown = self.frame.AbilityDropdown
    UIDropDownMenu_Initialize(dropdown, function(_, level)
        if level ~= 1 then return end

        local manual = UIDropDownMenu_CreateInfo()
        manual.text = "Manual / unlinked"
        manual.checked = self.draft and not self.draft.sourceCallKey
        manual.func = function()
            if not self.draft then return end
            self.draft.sourceCallKey = nil
            self.draft.spellIDs = {}
            self.draft.timerNames = {}
            self.draft.timingEnabled = false
            self:RefreshAbilityDropdownText()
            self:RefreshAdvancedFields()
        end
        UIDropDownMenu_AddButton(manual, level)

        if boss then
            local seen = {}
            for _, source in ipairs(BossMacros:GetMacros(boss.id)) do
                local key = source.sourceCallKey
                if key and not seen[key] then
                    seen[key] = true
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = source.name
                    info.icon = BossMacros:GetIcon(source)
                    info.checked = self.draft and self.draft.sourceCallKey == key
                    info.func = function() self:SetAbilityDraftFromMacro(source) end
                    UIDropDownMenu_AddButton(info, level)
                end
            end
        end
    end)
    self:RefreshAbilityDropdownText()
end

function BossMacroManager:RefreshAdvancedFields()
    if not self.frame then return end
    local draft = self.draft
    self.frame.AdvancedPanel:SetShown(self.advancedShown == true and draft ~= nil)
    if not draft or not self.advancedShown then return end
    self.frame.SpellIdEdit:SetText(draft.spellIDs and draft.spellIDs[1] and tostring(draft.spellIDs[1]) or "")
    self.frame.TimerNameEdit:SetText(draft.timerNames and draft.timerNames[1] or "")
    self.frame.TimingCheck:SetChecked(draft.timingEnabled == true)
end

function BossMacroManager:UpdateCharacterCount()
    if not self.frame then return end
    local body = self.frame.BodyEdit:GetText() or ""
    local extra = self.callbacks and self.callbacks.getManagedOverhead and self.callbacks.getManagedOverhead(self.selectedMacroId) or 0
    self.frame.CharCount:SetFormattedText("%d/255 Characters Used", math.min(999, #body + (tonumber(extra) or 0)))
end

function BossMacroManager:PopulateEditor(macro)
    self.draft = nil
    if not macro then
        self.frame.SelectedName:SetText("")
        self.frame.SelectedIcon:SetTexture(nil)
        self.frame.NameEdit:SetText("")
        self.frame.BodyEdit:SetText("")
        self.frame.Editor:SetAlpha(0.45)
        self.frame.SaveButton:Disable()
        self.frame.ChangeButton:Disable()
        self.frame.DeleteButton:Disable()
        self.frame.DragButton:Disable()
        self:RefreshAbilityDropdown()
        self:RefreshAdvancedFields()
        self:UpdateCharacterCount()
        return
    end

    self.draft = {
        name = macro.name,
        body = macro.body,
        sourceCallKey = macro.sourceCallKey,
        spellIDs = copyArray(macro.spellIDs),
        timerNames = copyArray(macro.timerNames),
        iconMode = macro.iconMode,
        customIcon = macro.customIcon,
        timingEnabled = macro.timingEnabled == true,
        prepareSeconds = macro.prepareSeconds,
        pressSeconds = macro.pressSeconds,
    }

    self.frame.Editor:SetAlpha(1)
    self.frame.SelectedName:SetText(macro.name or "")
    self.frame.SelectedIcon:SetTexture(BossMacros:GetIcon(macro))
    self.frame.NameEdit:SetText(macro.name or "")
    self.frame.BodyEdit:SetText(macro.body or "")
    self.frame.SaveButton:Enable()
    self.frame.ChangeButton:Enable()
    self.frame.DeleteButton:Enable()
    self.frame.DragButton:Enable()
    self:RefreshAbilityDropdown()
    self:RefreshAdvancedFields()
    self:UpdateCharacterCount()
end

function BossMacroManager:SelectMacro(macroId)
    self.selectedMacroId = macroId and tonumber(macroId) or nil
    local macro = self:GetSelectedMacro()
    if not macro then self.selectedMacroId = nil end
    self:RefreshMacroGrid()
    self:PopulateEditor(macro)
end

function BossMacroManager:SelectBoss(bossId, userInitiated)
    local boss = BossMacros:GetBoss(bossId)
    if not boss then return false end
    self.selectedBossId = boss.id
    self.database.selectedBossId = boss.id
    if boss.sourceEncounterKey then self.database.selectedBossKey = boss.sourceEncounterKey end
    self.macroOffset = 1
    local macros = BossMacros:GetMacros(boss.id)
    self.selectedMacroId = macros[1] and macros[1].id or nil
    self:RefreshBossDropdown()
    self:RefreshMacroGrid()
    self:PopulateEditor(self:GetSelectedMacro())
    if self.callbacks and self.callbacks.onBossSelected then self.callbacks.onBossSelected(boss, userInitiated == true) end
    return true
end

function BossMacroManager:SaveSelected()
    local macro = self:GetSelectedMacro()
    local boss = self:GetBoss()
    if not macro or not boss or not self.draft then return end

    self.draft.name = trim(self.frame.NameEdit:GetText())
    self.draft.body = self.frame.BodyEdit:GetText() or ""
    if self.advancedShown then
        local spellID = tonumber(self.frame.SpellIdEdit:GetText() or "")
        local timerName = trim(self.frame.TimerNameEdit:GetText())
        self.draft.spellIDs = spellID and { spellID } or {}
        self.draft.timerNames = timerName ~= "" and { timerName } or {}
        self.draft.timingEnabled = self.frame.TimingCheck:GetChecked() == true
    end

    local ok, result = BossMacros:UpdateMacro(boss.id, macro.id, self.draft)
    if not ok then
        ns:Print(result or "Could not save macro.")
        return
    end

    self.selectedMacroId = result.id
    self:RefreshMacroGrid()
    self:PopulateEditor(result)
    if self.callbacks and self.callbacks.onMacroSaved then self.callbacks.onMacroSaved(result, boss) end
end

function BossMacroManager:OpenIconPicker()
    local macro = self:GetSelectedMacro()
    if not macro or not self.draft then return end
    local currentIcon = self.draft.iconMode == "custom" and self.draft.customIcon or BossMacros:GetIcon(self.draft)
    IconPicker:Open(self.frame, self.frame.NameEdit:GetText(), currentIcon, function(name, icon)
        self.draft.name = trim(name)
        self.draft.iconMode = "custom"
        self.draft.customIcon = icon
        self.frame.NameEdit:SetText(self.draft.name)
        self.frame.SelectedName:SetText(self.draft.name)
        self.frame.SelectedIcon:SetTexture(icon)
    end)
end

function BossMacroManager:CreateNewMacro()
    local boss = self:GetBoss()
    if not boss then return end
    local macro, err = BossMacros:CreateMacro(boss.id)
    if not macro then ns:Print(err or "Could not create macro.") return end
    self.selectedMacroId = macro.id
    self:RefreshMacroGrid()
    self:PopulateEditor(macro)
    self.frame.NameEdit:SetFocus()
    self.frame.NameEdit:HighlightText()
end

function BossMacroManager:DeleteSelectedMacro()
    local macro = self:GetSelectedMacro()
    local boss = self:GetBoss()
    if not macro or not boss then return end
    StaticPopup_Show("RLA_CONFIRM_DELETE", ("Delete macro '%s'?"):format(macro.name or "Macro"), nil, {
        callback = function()
            local ok, removed = BossMacros:DeleteMacro(boss.id, macro.id)
            if not ok then return end
            if self.callbacks and self.callbacks.onMacroDeleted then self.callbacks.onMacroDeleted(removed, boss) end
            local macros = BossMacros:GetMacros(boss.id)
            self.selectedMacroId = macros[1] and macros[1].id or nil
            self.macroOffset = 1
            self:RefreshMacroGrid()
            self:PopulateEditor(self:GetSelectedMacro())
        end,
    })
end

function BossMacroManager:CreateBoss()
    StaticPopup_Show("RLA_BOSS_NAME", "New Boss Name", nil, {
        value = "",
        callback = function(name)
            local boss, err = BossMacros:CreateBoss(name)
            if not boss then ns:Print(err or "Could not create boss.") return end
            self:SelectBoss(boss.id, true)
        end,
    })
end

function BossMacroManager:RenameBoss()
    local boss = self:GetBoss()
    if not boss then return end
    StaticPopup_Show("RLA_BOSS_NAME", "Rename Boss", nil, {
        value = boss.name,
        callback = function(name)
            local ok, err = BossMacros:RenameBoss(boss.id, name)
            if not ok then ns:Print(err or "Could not rename boss.") return end
            self:RefreshBossDropdown()
        end,
    })
end

function BossMacroManager:DeleteBoss()
    local boss = self:GetBoss()
    if not boss then return end
    StaticPopup_Show("RLA_CONFIRM_DELETE", ("Delete boss '%s' and its macros?"):format(boss.name or "Boss"), nil, {
        callback = function()
            local macros = BossMacros:GetMacros(boss.id)
            if self.callbacks and self.callbacks.onBossDeleting then self.callbacks.onBossDeleting(boss, macros) end
            BossMacros:DeleteBoss(boss.id)
            local ordered = BossMacros:GetBossesOrdered()
            if ordered[1] then
                self:SelectBoss(ordered[1].id, true)
            else
                self.selectedBossId, self.selectedMacroId = nil, nil
                self:RefreshBossDropdown()
                self:RefreshMacroGrid()
                self:PopulateEditor(nil)
            end
        end,
    })
end

function BossMacroManager:Initialize(database, callbacks)
    if self.frame then return end
    setupDialogs()
    self.database = database
    self.callbacks = callbacks or {}

    local frame = CreateFrame("Frame", "RaidLeadAssistBossMacroFrame", UIParent, "ButtonFrameTemplate")
    frame:SetSize(388, 574)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    if frame.TitleText then frame.TitleText:SetText("Raid Lead Assist — Boss Macros") end
    setPortrait(frame)

    local bossLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bossLabel:SetPoint("TOPLEFT", 22, -57)
    bossLabel:SetText("Boss:")

    local bossDropdown = CreateFrame("Frame", "RaidLeadAssistBossDropdown", frame, "UIDropDownMenuTemplate")
    bossDropdown:SetPoint("TOPLEFT", 47, -45)
    UIDropDownMenu_SetWidth(bossDropdown, 176)
    frame.BossDropdown = bossDropdown

    local newBoss = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    newBoss:SetSize(46, 21)
    newBoss:SetPoint("LEFT", bossDropdown, "RIGHT", -5, 1)
    newBoss:SetText("New")
    newBoss:SetScript("OnClick", function() self:CreateBoss() end)

    local renameBoss = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    renameBoss:SetSize(55, 21)
    renameBoss:SetPoint("LEFT", newBoss, "RIGHT", 2, 0)
    renameBoss:SetText("Rename")
    renameBoss:SetScript("OnClick", function() self:RenameBoss() end)

    local deleteBoss = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    deleteBoss:SetSize(22, 21)
    deleteBoss:SetPoint("LEFT", renameBoss, "RIGHT", 2, 0)
    deleteBoss:SetText("-")
    deleteBoss:SetScript("OnClick", function() self:DeleteBoss() end)

    local grid = CreateFrame("Frame", nil, frame, "TooltipBackdropTemplate")
    grid:SetPoint("TOPLEFT", 14, -88)
    grid:SetSize(350, 155)
    grid:EnableMouseWheel(true)
    grid:SetScript("OnMouseWheel", function(_, delta)
        local macros = self:GetBoss() and BossMacros:GetMacros(self.selectedBossId) or {}
        local maxOffset = math.max(1, #macros - self.macroPageSize + 1)
        self.macroOffset = math.max(1, math.min(maxOffset, self.macroOffset - (delta * 6)))
        self:RefreshMacroGrid()
    end)

    local columns, rows = 6, 3
    self.macroPageSize = columns * rows
    for index = 1, self.macroPageSize do
        local button = CreateFrame("Button", nil, grid)
        button:SetSize(42, 42)
        local col = (index - 1) % columns
        local row = math.floor((index - 1) / columns)
        button:SetPoint("TOPLEFT", 14 + (col * 54), -8 - (row * 46))
        button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
        button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 3, -3)
        icon:SetPoint("BOTTOMRIGHT", -3, 3)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        button.Icon = icon

        local selected = button:CreateTexture(nil, "OVERLAY")
        selected:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        selected:SetBlendMode("ADD")
        selected:SetAllPoints()
        selected:Hide()
        button.Selected = selected

        local name = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")
        name:SetPoint("BOTTOM", 0, 2)
        name:SetWidth(44)
        button.Name = name

        button:SetScript("OnClick", function(btn)
            if btn.macroId then self:SelectMacro(btn.macroId) end
        end)
        self.macroButtons[index] = button
    end

    local gridStatus = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    gridStatus:SetPoint("TOP", grid, "BOTTOM", 0, -2)
    frame.GridStatus = gridStatus

    addHorizontalBar(frame, -250)

    local editor = CreateFrame("Frame", nil, frame)
    editor:SetPoint("TOPLEFT", 14, -264)
    editor:SetPoint("BOTTOMRIGHT", -14, 44)
    frame.Editor = editor

    local selectedSlot = editor:CreateTexture(nil, "ARTWORK")
    selectedSlot:SetTexture("Interface\\Buttons\\UI-EmptySlot")
    selectedSlot:SetSize(64, 64)
    selectedSlot:SetPoint("TOPLEFT", 0, 0)

    local selectedIcon = editor:CreateTexture(nil, "ARTWORK")
    selectedIcon:SetSize(38, 38)
    selectedIcon:SetPoint("CENTER", selectedSlot, "CENTER", 0, 0)
    selectedIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    frame.SelectedIcon = selectedIcon

    local selectedName = editor:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    selectedName:SetPoint("TOPLEFT", selectedSlot, "TOPRIGHT", -4, -9)
    selectedName:SetWidth(250)
    selectedName:SetJustifyH("LEFT")
    frame.SelectedName = selectedName

    local changeButton = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    changeButton:SetSize(170, 22)
    changeButton:SetPoint("TOPLEFT", selectedSlot, "TOPRIGHT", -4, -31)
    changeButton:SetText("Change Name/Icon")
    changeButton:SetScript("OnClick", function() self:OpenIconPicker() end)
    frame.ChangeButton = changeButton

    local nameEdit = CreateFrame("EditBox", nil, editor, "InputBoxTemplate")
    nameEdit:SetSize(105, 22)
    nameEdit:SetPoint("LEFT", changeButton, "RIGHT", 8, 0)
    nameEdit:SetMaxLetters(16)
    nameEdit:SetAutoFocus(false)
    nameEdit:SetScript("OnTextChanged", function(edit)
        if self.draft then
            self.draft.name = edit:GetText() or ""
            selectedName:SetText(self.draft.name)
        end
    end)
    frame.NameEdit = nameEdit

    local abilityLabel = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    abilityLabel:SetPoint("TOPLEFT", selectedSlot, "BOTTOMLEFT", 8, 0)
    abilityLabel:SetText("Boss Ability:")

    local abilityDropdown = CreateFrame("Frame", "RaidLeadAssistAbilityDropdown", editor, "UIDropDownMenuTemplate")
    abilityDropdown:SetPoint("TOPLEFT", abilityLabel, "BOTTOMLEFT", -18, 4)
    UIDropDownMenu_SetWidth(abilityDropdown, 235)
    frame.AbilityDropdown = abilityDropdown

    local advancedButton = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    advancedButton:SetSize(76, 20)
    advancedButton:SetPoint("LEFT", abilityDropdown, "RIGHT", -8, 1)
    advancedButton:SetText("Advanced")
    advancedButton:SetScript("OnClick", function()
        self.advancedShown = not self.advancedShown
        self:RefreshAdvancedFields()
    end)

    local commandsLabel = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    commandsLabel:SetPoint("TOPLEFT", 8, -111)
    commandsLabel:SetText("Enter Macro Commands:")

    local bodyBackground = CreateFrame("Frame", nil, editor, "TooltipBackdropTemplate")
    bodyBackground:SetPoint("TOPLEFT", 0, -128)
    bodyBackground:SetSize(350, 86)

    local bodyScroll = CreateFrame("ScrollFrame", nil, bodyBackground, "UIPanelScrollFrameTemplate")
    bodyScroll:SetPoint("TOPLEFT", 8, -6)
    bodyScroll:SetPoint("BOTTOMRIGHT", -25, 7)

    local bodyEdit = CreateFrame("EditBox", nil, bodyScroll)
    bodyEdit:SetMultiLine(true)
    bodyEdit:SetAutoFocus(false)
    bodyEdit:SetFontObject("GameFontHighlightSmall")
    bodyEdit:SetWidth(302)
    bodyEdit:SetMaxLetters(245)
    bodyEdit:SetScript("OnEscapePressed", bodyEdit.ClearFocus)
    bodyEdit:SetScript("OnTextChanged", function(edit)
        if self.draft then self.draft.body = edit:GetText() or "" end
        self:UpdateCharacterCount()
    end)
    bodyScroll:SetScrollChild(bodyEdit)
    frame.BodyEdit = bodyEdit

    local charCount = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    charCount:SetPoint("TOP", bodyBackground, "BOTTOM", 0, -2)
    frame.CharCount = charCount

    local advanced = CreateFrame("Frame", nil, editor, "TooltipBackdropTemplate")
    advanced:SetPoint("TOPLEFT", bodyBackground, "BOTTOMLEFT", 0, -20)
    advanced:SetSize(350, 57)
    advanced:Hide()
    frame.AdvancedPanel = advanced

    local spellLabel = advanced:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    spellLabel:SetPoint("TOPLEFT", 8, -8)
    spellLabel:SetText("Spell ID")
    local spellEdit = CreateFrame("EditBox", nil, advanced, "InputBoxTemplate")
    spellEdit:SetSize(72, 20)
    spellEdit:SetPoint("LEFT", spellLabel, "RIGHT", 7, 0)
    spellEdit:SetAutoFocus(false)
    frame.SpellIdEdit = spellEdit

    local timerLabel = advanced:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    timerLabel:SetPoint("LEFT", spellEdit, "RIGHT", 10, 0)
    timerLabel:SetText("Timer")
    local timerEdit = CreateFrame("EditBox", nil, advanced, "InputBoxTemplate")
    timerEdit:SetSize(100, 20)
    timerEdit:SetPoint("LEFT", timerLabel, "RIGHT", 6, 0)
    timerEdit:SetAutoFocus(false)
    frame.TimerNameEdit = timerEdit

    local timingCheck = CreateFrame("CheckButton", nil, advanced, "UICheckButtonTemplate")
    timingCheck:SetPoint("TOPLEFT", 6, -29)
    timingCheck.text:SetText("Automatic timing overlay")
    frame.TimingCheck = timingCheck

    local saveButton = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    saveButton:SetSize(80, 22)
    saveButton:SetPoint("BOTTOMRIGHT", 0, 38)
    saveButton:SetText(SAVE or "Save")
    saveButton:SetScript("OnClick", function() self:SaveSelected() end)
    frame.SaveButton = saveButton

    local cancelButton = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    cancelButton:SetSize(80, 22)
    cancelButton:SetPoint("TOP", saveButton, "BOTTOM", 0, -6)
    cancelButton:SetText(CANCEL or "Cancel")
    cancelButton:SetScript("OnClick", function() self:PopulateEditor(self:GetSelectedMacro()) end)

    local dragButton = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    dragButton:SetSize(140, 22)
    dragButton:SetPoint("RIGHT", saveButton, "LEFT", -6, 0)
    dragButton:SetText("Drag to Action Bar")
    dragButton:SetScript("OnClick", function()
        local macro = self:GetSelectedMacro()
        if macro and self.callbacks and self.callbacks.onPickupMacro then self.callbacks.onPickupMacro(macro, self:GetBoss()) end
    end)
    frame.DragButton = dragButton

    local newButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    newButton:SetSize(80, 22)
    newButton:SetPoint("BOTTOMRIGHT", -86, 7)
    newButton:SetText(NEW or "New")
    newButton:SetScript("OnClick", function() self:CreateNewMacro() end)

    local deleteButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    deleteButton:SetSize(80, 22)
    deleteButton:SetPoint("BOTTOMLEFT", 6, 7)
    deleteButton:SetText(DELETE or "Delete")
    deleteButton:SetScript("OnClick", function() self:DeleteSelectedMacro() end)
    frame.DeleteButton = deleteButton

    local exitButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    exitButton:SetSize(80, 22)
    exitButton:SetPoint("BOTTOMRIGHT", -5, 7)
    exitButton:SetText(EXIT or "Exit")
    exitButton:SetScript("OnClick", function() frame:Hide() end)

    self.frame = frame
    self:SelectBoss(database.selectedBossId or (BossMacros:GetBossesOrdered()[1] and BossMacros:GetBossesOrdered()[1].id), false)
end

function BossMacroManager:Show()
    if self.frame then
        self:RefreshBossDropdown()
        self:RefreshMacroGrid()
        self.frame:Show()
    end
end

function BossMacroManager:Hide()
    if self.frame then self.frame:Hide() end
end

function BossMacroManager:Toggle()
    if not self.frame then return end
    if self.frame:IsShown() then self:Hide() else self:Show() end
end

ns:RegisterModule("UI.BossMacroManager", BossMacroManager)
