local _, ns = ...

local BossMacros = ns:GetModule("Services.BossMacroService")
local IconPicker = ns:GetModule("UI.IconPicker")

local BossMacroManager = {
    frame = nil,
    advancedFrame = nil,
    database = nil,
    callbacks = nil,
    selectedBossId = nil,
    selectedMacroId = nil,
    macroButtons = {},
    macroOffset = 1,
    macroPageSize = 18,
    draft = nil,
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
    right:SetSize(128, 16)
    right:SetPoint("LEFT", left, "RIGHT", 0, 0)
    right:SetTexCoord(0, 0.5, 0.25, 0.5)
end

function BossMacroManager:GetBoss()
    return self.selectedBossId and BossMacros:GetBoss(self.selectedBossId) or nil
end

function BossMacroManager:GetSelectedMacro()
    local macro = self.selectedMacroId and BossMacros:FindMacroById(self.selectedMacroId) or nil
    return macro
end

function BossMacroManager:GetMacroLimit()
    local value = self.callbacks and self.callbacks.getMacroMaxLength and self.callbacks.getMacroMaxLength() or nil
    return tonumber(value) or 255
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
        button:SetAlpha(macro and 1 or 0.28)
        button.Icon:SetTexture(macro and BossMacros:GetIcon(macro) or nil)
        button.Name:SetText(macro and shortName(macro.name) or "")
        button.Selected:SetShown(macro ~= nil and tonumber(macro.id) == tonumber(self.selectedMacroId))
    end

    if #macros == 0 then
        self.frame.GridStatus:SetText("No macros for this boss — press New to create one.")
    elseif #macros > self.macroPageSize then
        local last = math.min(#macros, self.macroOffset + self.macroPageSize - 1)
        self.frame.GridStatus:SetFormattedText("%d-%d / %d", self.macroOffset, last, #macros)
    else
        self.frame.GridStatus:SetText("")
    end
end

function BossMacroManager:RefreshAbilityDropdownText()
    if not self.frame then return end
    local boss = self:GetBoss()
    local label = "Manual / unlinked"
    if boss and self.draft and self.draft.sourceCallKey then
        for _, macro in ipairs(BossMacros:GetMacros(boss.id)) do
            if macro.sourceCallKey == self.draft.sourceCallKey then
                label = macro.name
                break
            end
        end
    end
    UIDropDownMenu_SetText(self.frame.AbilityDropdown, label)
end

function BossMacroManager:SetAbilityDraftFromMacro(sourceMacro)
    if not self.draft or not sourceMacro then return end
    self.draft.sourceCallKey = sourceMacro.sourceCallKey
    self.draft.spellIDs = copyArray(sourceMacro.spellIDs)
    self.draft.timerNames = copyArray(sourceMacro.timerNames)
    self.draft.iconSpellID = sourceMacro.iconSpellID
    self.draft.timingEnabled = sourceMacro.timingEnabled == true
    self.draft.prepareSeconds = sourceMacro.prepareSeconds
    self.draft.pressSeconds = sourceMacro.pressSeconds
    self.draft.iconMode = "ability"
    self:RefreshAbilityDropdownText()
    self.frame.SelectedIcon:SetTexture(BossMacros:GetIcon(self.draft))
end

function BossMacroManager:RefreshAbilityDropdown()
    if not self.frame then return end
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
            self.draft.iconSpellID = nil
            self.draft.timingEnabled = false
            self:RefreshAbilityDropdownText()
        end
        UIDropDownMenu_AddButton(manual, level)

        local boss = self:GetBoss()
        local seen = {}
        for _, source in ipairs(boss and BossMacros:GetMacros(boss.id) or {}) do
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
    end)
    self:RefreshAbilityDropdownText()
end

function BossMacroManager:UpdateCharacterCount()
    if not self.frame then return end
    local body = self.frame.BodyEdit:GetText() or ""
    local overhead = self.callbacks and self.callbacks.getManagedOverhead and self.callbacks.getManagedOverhead(self.selectedMacroId) or 0
    local total = #body + (tonumber(overhead) or 0)
    local maxLength = self:GetMacroLimit()
    self.frame.CharCount:SetFormattedText("%d/%d Characters Used", total, maxLength)
    if total > maxLength then
        self.frame.CharCount:SetTextColor(1, 0.15, 0.10, 1)
    else
        self.frame.CharCount:SetTextColor(1, 1, 1, 1)
    end
end

function BossMacroManager:PopulateEditor(macro)
    self.draft = nil
    if not macro then
        self.frame.SelectedName:SetText("")
        self.frame.SelectedIcon:SetTexture(nil)
        self.frame.BodyEdit:SetText("")
        self.frame.Editor:SetAlpha(0.45)
        self.frame.SaveButton:Disable()
        self.frame.ChangeButton:Disable()
        self.frame.DeleteButton:Disable()
        self.frame.DragButton:Disable()
        self:RefreshAbilityDropdown()
        self:UpdateCharacterCount()
        return
    end

    self.draft = {
        name = macro.name,
        body = macro.body,
        sourceCallKey = macro.sourceCallKey,
        spellIDs = copyArray(macro.spellIDs),
        timerNames = copyArray(macro.timerNames),
        iconSpellID = macro.iconSpellID,
        iconMode = macro.iconMode,
        customIcon = macro.customIcon,
        timingEnabled = macro.timingEnabled == true,
        prepareSeconds = macro.prepareSeconds,
        pressSeconds = macro.pressSeconds,
    }

    self.frame.Editor:SetAlpha(1)
    self.frame.SelectedName:SetText(macro.name or "")
    self.frame.SelectedIcon:SetTexture(BossMacros:GetIcon(macro))
    self.frame.BodyEdit:SetText(macro.body or "")
    self.frame.SaveButton:Enable()
    self.frame.ChangeButton:Enable()
    self.frame.DeleteButton:Enable()
    self.frame.DragButton:Enable()
    self:RefreshAbilityDropdown()
    self:UpdateCharacterCount()
end

function BossMacroManager:SelectMacro(macroId)
    self.selectedMacroId = macroId and tonumber(macroId) or nil
    if not self:GetSelectedMacro() then self.selectedMacroId = nil end
    self:RefreshMacroGrid()
    self:PopulateEditor(self:GetSelectedMacro())
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

    self.draft.body = self.frame.BodyEdit:GetText() or ""
    local overhead = self.callbacks and self.callbacks.getManagedOverhead and self.callbacks.getManagedOverhead(macro.id) or 0
    local total = #self.draft.body + (tonumber(overhead) or 0)
    local maxLength = self:GetMacroLimit()
    if total > maxLength then
        ns:Print(("Macro is %d characters including the Raid Lead Assist timer marker; maximum is %d."):format(total, maxLength))
        self:UpdateCharacterCount()
        return
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
    if not self.draft then return end
    local currentIcon = self.draft.iconMode == "custom" and self.draft.customIcon or BossMacros:GetIcon(self.draft)
    IconPicker:Open(self.frame, self.draft.name, currentIcon, function(name, icon)
        self.draft.name = trim(name):sub(1, 16)
        self.draft.iconMode = "custom"
        self.draft.customIcon = icon
        self.frame.SelectedName:SetText(self.draft.name)
        self.frame.SelectedIcon:SetTexture(icon)
    end)
end

function BossMacroManager:OpenAdvanced()
    if not self.draft then return end
    self:InitializeAdvancedFrame()
    local frame = self.advancedFrame
    frame.SpellIdEdit:SetText(self.draft.spellIDs and self.draft.spellIDs[1] and tostring(self.draft.spellIDs[1]) or "")
    frame.TimerNameEdit:SetText(self.draft.timerNames and self.draft.timerNames[1] or "")
    frame.PrepareEdit:SetText(tostring(self.draft.prepareSeconds or 5))
    frame.PressEdit:SetText(tostring(self.draft.pressSeconds or 3))
    frame.TimingCheck:SetChecked(self.draft.timingEnabled == true)
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", self.frame, "TOPRIGHT", 5, -75)
    frame:Show()
end

function BossMacroManager:InitializeAdvancedFrame()
    if self.advancedFrame then return end
    local frame = CreateFrame("Frame", "RaidLeadAssistAdvancedFrame", UIParent, "ButtonFrameTemplate")
    frame:SetSize(340, 220)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:Hide()
    if frame.TitleText then frame.TitleText:SetText("Advanced Timer Matching") end
    setPortrait(frame)

    local spellLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    spellLabel:SetPoint("TOPLEFT", 28, -64)
    spellLabel:SetText("Spell ID")
    local spellEdit = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    spellEdit:SetSize(100, 24)
    spellEdit:SetPoint("LEFT", spellLabel, "RIGHT", 12, 0)
    spellEdit:SetAutoFocus(false)
    frame.SpellIdEdit = spellEdit

    local timerLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timerLabel:SetPoint("TOPLEFT", spellLabel, "BOTTOMLEFT", 0, -24)
    timerLabel:SetText("Timer alias")
    local timerEdit = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    timerEdit:SetSize(150, 24)
    timerEdit:SetPoint("LEFT", timerLabel, "RIGHT", 12, 0)
    timerEdit:SetAutoFocus(false)
    frame.TimerNameEdit = timerEdit

    local prepareLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    prepareLabel:SetPoint("TOPLEFT", timerLabel, "BOTTOMLEFT", 0, -24)
    prepareLabel:SetText("Prepare / Press")
    local prepareEdit = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    prepareEdit:SetSize(44, 24)
    prepareEdit:SetPoint("LEFT", prepareLabel, "RIGHT", 12, 0)
    prepareEdit:SetAutoFocus(false)
    frame.PrepareEdit = prepareEdit
    local pressEdit = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    pressEdit:SetSize(44, 24)
    pressEdit:SetPoint("LEFT", prepareEdit, "RIGHT", 8, 0)
    pressEdit:SetAutoFocus(false)
    frame.PressEdit = pressEdit

    local timingCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    timingCheck:SetPoint("TOPLEFT", prepareLabel, "BOTTOMLEFT", -6, -12)
    timingCheck.text:SetText("Automatic timing overlay")
    frame.TimingCheck = timingCheck

    local apply = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    apply:SetSize(90, 22)
    apply:SetPoint("BOTTOMRIGHT", -102, 12)
    apply:SetText(APPLY or "Apply")
    apply:SetScript("OnClick", function()
        if not self.draft then frame:Hide() return end
        local spellID = tonumber(frame.SpellIdEdit:GetText() or "")
        local timerName = trim(frame.TimerNameEdit:GetText())
        self.draft.spellIDs = spellID and { spellID } or {}
        self.draft.iconSpellID = spellID or self.draft.iconSpellID
        self.draft.timerNames = timerName ~= "" and { timerName } or {}
        self.draft.prepareSeconds = tonumber(frame.PrepareEdit:GetText()) or self.draft.prepareSeconds
        self.draft.pressSeconds = tonumber(frame.PressEdit:GetText()) or self.draft.pressSeconds
        self.draft.timingEnabled = frame.TimingCheck:GetChecked() == true
        if self.draft.iconMode == "ability" then self.frame.SelectedIcon:SetTexture(BossMacros:GetIcon(self.draft)) end
        frame:Hide()
    end)

    local cancel = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    cancel:SetSize(90, 22)
    cancel:SetPoint("LEFT", apply, "RIGHT", 8, 0)
    cancel:SetText(CANCEL or "Cancel")
    cancel:SetScript("OnClick", function() frame:Hide() end)

    self.advancedFrame = frame
end

function BossMacroManager:CreateNewMacro()
    local boss = self:GetBoss()
    if not boss then return end
    local previousMacroId = self.selectedMacroId
    local macro, err = BossMacros:CreateMacro(boss.id)
    if not macro then ns:Print(err or "Could not create macro.") return end

    self.selectedMacroId = macro.id
    self:RefreshMacroGrid()
    self:PopulateEditor(macro)

    IconPicker:Open(self.frame, macro.name, BossMacros:GetIcon(macro), function(name, icon)
        if not self.draft or self.selectedMacroId ~= macro.id then return end
        self.draft.name = trim(name):sub(1, 16)
        self.draft.iconMode = "custom"
        self.draft.customIcon = icon
        local ok, updated = BossMacros:UpdateMacro(boss.id, macro.id, self.draft)
        if not ok then
            ns:Print(updated or "Could not create macro.")
            return
        end
        self:RefreshMacroGrid()
        self:PopulateEditor(updated)
    end, function()
        BossMacros:DeleteMacro(boss.id, macro.id)
        self.selectedMacroId = previousMacroId
        if not self:GetSelectedMacro() then
            local macros = BossMacros:GetMacros(boss.id)
            self.selectedMacroId = macros[1] and macros[1].id or nil
        end
        self:RefreshMacroGrid()
        self:PopulateEditor(self:GetSelectedMacro())
    end)
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

function BossMacroManager:PickupSelected()
    local macro = self:GetSelectedMacro()
    if macro and self.callbacks and self.callbacks.onPickupMacro then
        self.callbacks.onPickupMacro(macro, self:GetBoss())
    end
end

function BossMacroManager:Initialize(database, callbacks)
    if self.frame then return end
    setupDialogs()
    self.database = database
    self.callbacks = callbacks or {}

    local frame = CreateFrame("Frame", "RaidLeadAssistBossMacroFrame", UIParent, "ButtonFrameTemplate")
    frame:SetSize(402, 604)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    local position = database.position or {}
    frame:SetPoint(position.point or "CENTER", UIParent, position.relativePoint or "CENTER", tonumber(position.x) or 0, tonumber(position.y) or 40)
    frame:SetScript("OnDragStart", function(owner) owner:StartMoving() end)
    frame:SetScript("OnDragStop", function(owner)
        owner:StopMovingOrSizing()
        local point, _, relativePoint, x, y = owner:GetPoint(1)
        database.position = { point = point, relativePoint = relativePoint, x = x, y = y }
    end)
    frame:Hide()
    if frame.TitleText then frame.TitleText:SetText("Raid Lead Assist — Boss Macros") end
    setPortrait(frame)

    local bossLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bossLabel:SetPoint("TOPLEFT", 22, -57)
    bossLabel:SetText("Boss:")

    local bossDropdown = CreateFrame("Frame", "RaidLeadAssistBossDropdown", frame, "UIDropDownMenuTemplate")
    bossDropdown:SetPoint("TOPLEFT", 47, -45)
    UIDropDownMenu_SetWidth(bossDropdown, 182)
    frame.BossDropdown = bossDropdown

    local newBoss = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    newBoss:SetSize(44, 21)
    newBoss:SetPoint("LEFT", bossDropdown, "RIGHT", -4, 1)
    newBoss:SetText("New")
    newBoss:SetScript("OnClick", function() self:CreateBoss() end)

    local renameBoss = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    renameBoss:SetSize(55, 21)
    renameBoss:SetPoint("LEFT", newBoss, "RIGHT", 2, 0)
    renameBoss:SetText("Rename")
    renameBoss:SetScript("OnClick", function() self:RenameBoss() end)

    local deleteBoss = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    deleteBoss:SetSize(24, 21)
    deleteBoss:SetPoint("LEFT", renameBoss, "RIGHT", 2, 0)
    deleteBoss:SetText("-")
    deleteBoss:SetScript("OnClick", function() self:DeleteBoss() end)

    local grid = CreateFrame("Frame", nil, frame, "TooltipBackdropTemplate")
    grid:SetPoint("TOPLEFT", 14, -88)
    grid:SetSize(364, 164)
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
        button:SetSize(44, 44)
        local col = (index - 1) % columns
        local row = math.floor((index - 1) / columns)
        button:SetPoint("TOPLEFT", 13 + (col * 57), -9 - (row * 49))
        button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
        button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        button:RegisterForDrag("LeftButton")

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
        name:SetWidth(48)
        button.Name = name

        button:SetScript("OnClick", function(btn) if btn.macroId then self:SelectMacro(btn.macroId) end end)
        button:SetScript("OnDragStart", function(btn)
            if not btn.macroId then return end
            self:SelectMacro(btn.macroId)
            self:PickupSelected()
        end)
        self.macroButtons[index] = button
    end

    local gridStatus = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    gridStatus:SetPoint("TOP", grid, "BOTTOM", 0, -1)
    frame.GridStatus = gridStatus

    addHorizontalBar(frame, -260)

    local editor = CreateFrame("Frame", nil, frame)
    editor:SetPoint("TOPLEFT", 14, -274)
    editor:SetPoint("BOTTOMRIGHT", -14, 42)
    frame.Editor = editor

    local selectedButton = CreateFrame("Button", nil, editor)
    selectedButton:SetSize(64, 64)
    selectedButton:SetPoint("TOPLEFT", 0, 0)
    selectedButton:SetNormalTexture("Interface\\Buttons\\UI-EmptySlot")
    selectedButton:RegisterForDrag("LeftButton")
    selectedButton:SetScript("OnDragStart", function() self:PickupSelected() end)

    local selectedIcon = selectedButton:CreateTexture(nil, "ARTWORK")
    selectedIcon:SetSize(38, 38)
    selectedIcon:SetPoint("CENTER", 0, 0)
    selectedIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    frame.SelectedIcon = selectedIcon

    local selectedName = editor:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    selectedName:SetPoint("TOPLEFT", selectedButton, "TOPRIGHT", -2, -8)
    selectedName:SetWidth(205)
    selectedName:SetJustifyH("LEFT")
    frame.SelectedName = selectedName

    local changeButton = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    changeButton:SetSize(174, 22)
    changeButton:SetPoint("TOPLEFT", selectedButton, "TOPRIGHT", -2, -31)
    changeButton:SetText("Change Name/Icon")
    changeButton:SetScript("OnClick", function() self:OpenIconPicker() end)
    frame.ChangeButton = changeButton

    local saveButton = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    saveButton:SetSize(82, 22)
    saveButton:SetPoint("TOPRIGHT", 0, -3)
    saveButton:SetText(SAVE or "Save")
    saveButton:SetScript("OnClick", function() self:SaveSelected() end)
    frame.SaveButton = saveButton

    local cancelButton = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    cancelButton:SetSize(82, 22)
    cancelButton:SetPoint("TOP", saveButton, "BOTTOM", 0, -5)
    cancelButton:SetText(CANCEL or "Cancel")
    cancelButton:SetScript("OnClick", function() self:PopulateEditor(self:GetSelectedMacro()) end)

    local abilityLabel = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    abilityLabel:SetPoint("TOPLEFT", 8, -74)
    abilityLabel:SetText("Boss Ability:")

    local abilityDropdown = CreateFrame("Frame", "RaidLeadAssistAbilityDropdown", editor, "UIDropDownMenuTemplate")
    abilityDropdown:SetPoint("TOPLEFT", abilityLabel, "BOTTOMLEFT", -18, 6)
    UIDropDownMenu_SetWidth(abilityDropdown, 202)
    frame.AbilityDropdown = abilityDropdown

    local advancedButton = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    advancedButton:SetSize(73, 20)
    advancedButton:SetPoint("LEFT", abilityDropdown, "RIGHT", -5, 1)
    advancedButton:SetText("Advanced")
    advancedButton:SetScript("OnClick", function() self:OpenAdvanced() end)

    local dragButton = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    dragButton:SetSize(116, 22)
    dragButton:SetPoint("TOPRIGHT", 0, -82)
    dragButton:SetText("To Action Bar")
    dragButton:SetScript("OnClick", function() self:PickupSelected() end)
    frame.DragButton = dragButton

    local commandsLabel = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    commandsLabel:SetPoint("TOPLEFT", 8, -124)
    commandsLabel:SetText("Enter Macro Commands:")

    local bodyBackground = CreateFrame("Frame", nil, editor, "TooltipBackdropTemplate")
    bodyBackground:SetPoint("TOPLEFT", 0, -141)
    bodyBackground:SetSize(364, 111)

    local bodyScroll = CreateFrame("ScrollFrame", nil, bodyBackground, "UIPanelScrollFrameTemplate")
    bodyScroll:SetPoint("TOPLEFT", 8, -6)
    bodyScroll:SetPoint("BOTTOMRIGHT", -25, 7)

    local bodyEdit = CreateFrame("EditBox", nil, bodyScroll)
    bodyEdit:SetMultiLine(true)
    bodyEdit:SetAutoFocus(false)
    bodyEdit:SetFontObject(GameFontHighlightSmall or ChatFontNormal)
    bodyEdit:SetWidth(315)
    bodyEdit:SetHeight(95)
    bodyEdit:SetMaxLetters(255)
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

    local deleteButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    deleteButton:SetSize(86, 22)
    deleteButton:SetPoint("BOTTOMLEFT", 7, 7)
    deleteButton:SetText(DELETE or "Delete")
    deleteButton:SetScript("OnClick", function() self:DeleteSelectedMacro() end)
    frame.DeleteButton = deleteButton

    local newButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    newButton:SetSize(86, 22)
    newButton:SetPoint("BOTTOMRIGHT", -94, 7)
    newButton:SetText(NEW or "New")
    newButton:SetScript("OnClick", function() self:CreateNewMacro() end)

    local exitButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    exitButton:SetSize(86, 22)
    exitButton:SetPoint("BOTTOMRIGHT", -7, 7)
    exitButton:SetText(EXIT or "Exit")
    exitButton:SetScript("OnClick", function() frame:Hide() end)

    self.frame = frame
    frame:HookScript("OnHide", function()
        if self.advancedFrame then self.advancedFrame:Hide() end
        IconPicker:Close()
    end)

    local initial = database.selectedBossId or (BossMacros:GetBossesOrdered()[1] and BossMacros:GetBossesOrdered()[1].id)
    if initial then self:SelectBoss(initial, false) else self:PopulateEditor(nil) end
end

function BossMacroManager:Show()
    if self.frame then
        self:RefreshBossDropdown()
        self:RefreshMacroGrid()
        self:PopulateEditor(self:GetSelectedMacro())
        self.frame:Show()
    end
end

function BossMacroManager:Hide()
    if self.frame then self.frame:Hide() end
    if self.advancedFrame then self.advancedFrame:Hide() end
    IconPicker:Close()
end

function BossMacroManager:Toggle()
    if not self.frame then return end
    if self.frame:IsShown() then self:Hide() else self:Show() end
end

ns:RegisterModule("UI.BossMacroManager", BossMacroManager)
