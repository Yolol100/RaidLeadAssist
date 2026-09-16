local _, ns = ...

local BossMacros = ns:GetModule("Services.BossMacroService")
local IconPicker = ns:GetModule("UI.IconPicker")

local BossMacroManager = {
    frame = nil,
    advancedFrame = nil,
    tacticsFrame = nil,
    database = nil,
    callbacks = nil,
    selectedBossId = nil,
    selectedDifficultyKey = "heroic",
    selectedMacroId = nil,
    macroButtons = {},
    macroOffset = 1,
    macroPageSize = 18,
    draft = nil,
    draggingMacroId = nil,
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
    if #name <= 7 then return name end
    return name:sub(1, 6) .. "…"
end

local function validDifficulty(key)
    return key == "heroic" or key == "mythic"
end

local function difficultyLabel(key)
    return key == "mythic" and "Mythic" or "Heroic"
end

local function getDialogEditBox(dialog)
    if not dialog then return nil end

    local editBox = dialog.EditBox or dialog.editBox
    if not editBox and type(dialog.GetEditBox) == "function" then
        editBox = dialog:GetEditBox()
    end
    if not editBox and type(dialog.GetName) == "function" then
        local name = dialog:GetName()
        if name and _G then editBox = _G[name .. "EditBox"] end
    end
    return editBox
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
                local editBox = getDialogEditBox(dialog)
                if not editBox then return end
                editBox:SetText((data and data.value) or "")
                editBox:HighlightText()
                editBox:SetFocus()
            end,
            OnAccept = function(dialog, data)
                local editBox = getDialogEditBox(dialog)
                if data and data.callback and editBox then data.callback(editBox:GetText() or "") end
            end,
            EditBoxOnEnterPressed = function(editBox)
                local parent = editBox and editBox:GetParent() or nil
                local data = parent and parent.data or nil
                if data and data.callback and editBox then data.callback(editBox:GetText() or "") end
                if parent then parent:Hide() end
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

    -- Modern Blizzard ButtonFrameTemplate owns the title through TitleContainer.
    -- Keep the template's TitleText anchors intact and move the container to the
    -- same no-portrait margins Blizzard uses instead of pinning text to the frame.
    if frame.TitleContainer then
        frame.TitleContainer:ClearAllPoints()
        frame.TitleContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 30, -1)
        frame.TitleContainer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -1)
    end
end

local function setFrameTitle(frame, text)
    if not frame then return end
    local titleText = frame.TitleContainer and frame.TitleContainer.TitleText or frame.TitleText
    if titleText then
        titleText:SetText(text or "")
    elseif type(frame.SetTitle) == "function" then
        frame:SetTitle(text or "")
    end
end

local function addHorizontalBar(parent, y, width)
    width = tonumber(width) or 400
    local left = parent:CreateTexture(nil, "ARTWORK")
    left:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar")
    left:SetSize(math.min(256, width), 16)
    left:SetPoint("TOPLEFT", 2, y)
    left:SetTexCoord(0, 1, 0, 0.25)

    local remaining = math.max(0, width - math.min(256, width))
    if remaining > 0 then
        local right = parent:CreateTexture(nil, "ARTWORK")
        right:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar")
        right:SetSize(remaining, 16)
        right:SetPoint("LEFT", left, "RIGHT", 0, 0)
        right:SetTexCoord(0, math.min(1, remaining / 256), 0.25, 0.5)
    end
end

local function getMouseFocusSafe()
    if type(GetMouseFoci) == "function" then
        local foci = GetMouseFoci()
        if type(foci) == "table" then
            for _, focus in ipairs(foci) do
                if focus and focus.rlaMacroButton then return focus end
            end
            return foci[1]
        end
    end
    if type(GetMouseFocus) == "function" then
        return GetMouseFocus()
    end
end

function BossMacroManager:GetBoss()
    return self.selectedBossId and BossMacros:GetBoss(self.selectedBossId) or nil
end

function BossMacroManager:GetSelectedMacro()
    if not self.selectedMacroId then return nil end
    local macro, boss, difficultyKey = BossMacros:FindMacroById(self.selectedMacroId)
    if not macro or not boss or boss.id ~= self.selectedBossId or difficultyKey ~= self.selectedDifficultyKey then
        return nil
    end
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

function BossMacroManager:RefreshDifficultyButtons()
    if not self.frame then return end
    for key, button in pairs(self.frame.DifficultyButtons or {}) do
        if key == self.selectedDifficultyKey then
            button:LockHighlight()
            button:SetButtonState("PUSHED", true)
        else
            button:UnlockHighlight()
            button:SetButtonState("NORMAL", false)
        end
    end
end

function BossMacroManager:RefreshMacroGrid()
    if not self.frame then return end
    local boss = self:GetBoss()
    local macros = boss and BossMacros:GetMacros(boss.id, self.selectedDifficultyKey) or {}
    local maxOffset = math.max(1, #macros - self.macroPageSize + 1)
    self.macroOffset = math.max(1, math.min(self.macroOffset or 1, maxOffset))

    for index = 1, #self.macroButtons do
        local button = self.macroButtons[index]
        local macro = macros[self.macroOffset + index - 1]
        button.macroId = macro and macro.id or nil
        button:SetEnabled(macro ~= nil)
        button:SetAlpha(macro and 1 or 0.25)
        button.Icon:SetTexture(macro and BossMacros:GetIcon(macro) or nil)
        button.Name:SetText(macro and tostring(macro.name or "") or "")
        button.Selected:SetShown(macro ~= nil and tonumber(macro.id) == tonumber(self.selectedMacroId))
    end

    local prefix = "Drag icons to reorder"
    if #macros == 0 then
        self.frame.GridStatus:SetText(("No %s macros — press New to create one."):format(difficultyLabel(self.selectedDifficultyKey)))
    elseif #macros > self.macroPageSize then
        local last = math.min(#macros, self.macroOffset + self.macroPageSize - 1)
        self.frame.GridStatus:SetFormattedText("%s   %d-%d / %d", prefix, self.macroOffset, last, #macros)
    else
        self.frame.GridStatus:SetText(prefix)
    end

    if self.frame.MoveLeftButton and self.frame.MoveRightButton then
        local hasSelection = self:GetSelectedMacro() ~= nil
        self.frame.MoveLeftButton:SetEnabled(hasSelection)
        self.frame.MoveRightButton:SetEnabled(hasSelection)
    end
end

function BossMacroManager:RefreshAbilityDropdownText()
    if not self.frame then return end
    local boss = self:GetBoss()
    local label = "Manual / unlinked"
    if boss and self.draft and self.draft.sourceCallKey then
        for _, ability in ipairs(BossMacros:GetAbilityOptions(boss.id, self.selectedDifficultyKey)) do
            if ability.sourceCallKey == self.draft.sourceCallKey then
                label = ability.name
                break
            end
        end
    end
    UIDropDownMenu_SetText(self.frame.AbilityDropdown, label)
end

function BossMacroManager:SetAbilityDraftFromAbility(ability)
    if not self.draft or not ability then return end
    self.draft.sourceCallKey = ability.sourceCallKey
    self.draft.spellIDs = copyArray(ability.spellIDs)
    self.draft.timerNames = copyArray(ability.timerNames)
    self.draft.iconSpellID = ability.iconSpellID
    self.draft.timingEnabled = ability.timingEnabled == true
    self.draft.prepareSeconds = ability.prepareSeconds
    self.draft.pressSeconds = ability.pressSeconds
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
            local currentIcon = BossMacros:GetIcon(self.draft)
            self.draft.sourceCallKey = nil
            self.draft.spellIDs = {}
            self.draft.timerNames = {}
            self.draft.iconSpellID = nil
            self.draft.timingEnabled = false
            if self.draft.iconMode == "ability" then
                self.draft.iconMode = "custom"
                self.draft.customIcon = currentIcon
            end
            self:RefreshAbilityDropdownText()
            self.frame.SelectedIcon:SetTexture(BossMacros:GetIcon(self.draft))
        end
        UIDropDownMenu_AddButton(manual, level)

        local boss = self:GetBoss()
        for _, ability in ipairs(boss and BossMacros:GetAbilityOptions(boss.id, self.selectedDifficultyKey) or {}) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = ability.name
            info.icon = BossMacros:GetIcon(ability)
            info.checked = self.draft and self.draft.sourceCallKey == ability.sourceCallKey
            info.func = function() self:SetAbilityDraftFromAbility(ability) end
            UIDropDownMenu_AddButton(info, level)
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
    if not self.frame then return end
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
        self.frame.AdvancedButton:Disable()
        self:RefreshAbilityDropdown()
        self:UpdateCharacterCount()
        return
    end

    self.draft = {
        difficultyKey = self.selectedDifficultyKey,
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
    self.frame.AdvancedButton:Enable()
    self:RefreshAbilityDropdown()
    self:UpdateCharacterCount()
end

function BossMacroManager:SelectMacro(macroId)
    self.selectedMacroId = macroId and tonumber(macroId) or nil
    if not self:GetSelectedMacro() then self.selectedMacroId = nil end
    self:RefreshMacroGrid()
    self:PopulateEditor(self:GetSelectedMacro())
end

function BossMacroManager:SelectDifficulty(difficultyKey, userInitiated, suppressCallback)
    if not validDifficulty(difficultyKey) then return false end
    self.selectedDifficultyKey = difficultyKey
    if self.database then self.database.selectedDifficultyKey = difficultyKey end
    self.macroOffset = 1

    local boss = self:GetBoss()
    local macros = boss and BossMacros:GetMacros(boss.id, difficultyKey) or {}
    self.selectedMacroId = macros[1] and macros[1].id or nil

    self:RefreshDifficultyButtons()
    self:RefreshMacroGrid()
    self:PopulateEditor(self:GetSelectedMacro())

    if self.tacticsFrame and self.tacticsFrame:IsShown() then self:PopulateTacticsFrame() end
    if not suppressCallback and self.callbacks and self.callbacks.onDifficultySelected then
        self.callbacks.onDifficultySelected(difficultyKey, userInitiated == true)
    end
    return true
end

function BossMacroManager:SelectBoss(bossId, userInitiated)
    local boss = BossMacros:GetBoss(bossId)
    if not boss then return false end
    self.selectedBossId = boss.id
    self.database.selectedBossId = boss.id
    if boss.sourceEncounterKey then self.database.selectedBossKey = boss.sourceEncounterKey end
    self.macroOffset = 1
    local macros = BossMacros:GetMacros(boss.id, self.selectedDifficultyKey)
    self.selectedMacroId = macros[1] and macros[1].id or nil
    self:RefreshBossDropdown()
    self:RefreshDifficultyButtons()
    self:RefreshMacroGrid()
    self:PopulateEditor(self:GetSelectedMacro())
    if self.tacticsFrame and self.tacticsFrame:IsShown() then self:PopulateTacticsFrame() end
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
    frame:SetPoint("TOPLEFT", self.frame, "TOPRIGHT", 6, -92)
    frame:Show()
end

function BossMacroManager:InitializeAdvancedFrame()
    if self.advancedFrame then return end
    local frame = CreateFrame("Frame", "RaidLeadAssistAdvancedFrame", UIParent, "ButtonFrameTemplate")
    frame:SetSize(360, 236)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:Hide()
    removePortrait(frame)
    setFrameTitle(frame, "Advanced Timer Matching")

    local spellLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    spellLabel:SetPoint("TOPLEFT", 28, -58)
    spellLabel:SetWidth(96)
    spellLabel:SetJustifyH("LEFT")
    spellLabel:SetText("Spell ID")
    local spellEdit = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    spellEdit:SetSize(150, 24)
    spellEdit:SetPoint("LEFT", spellLabel, "RIGHT", 12, 0)
    spellEdit:SetAutoFocus(false)
    frame.SpellIdEdit = spellEdit

    local timerLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timerLabel:SetPoint("TOPLEFT", spellLabel, "BOTTOMLEFT", 0, -25)
    timerLabel:SetWidth(96)
    timerLabel:SetJustifyH("LEFT")
    timerLabel:SetText("Timer alias")
    local timerEdit = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    timerEdit:SetSize(150, 24)
    timerEdit:SetPoint("LEFT", timerLabel, "RIGHT", 12, 0)
    timerEdit:SetAutoFocus(false)
    frame.TimerNameEdit = timerEdit

    local prepareLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    prepareLabel:SetPoint("TOPLEFT", timerLabel, "BOTTOMLEFT", 0, -25)
    prepareLabel:SetWidth(96)
    prepareLabel:SetJustifyH("LEFT")
    prepareLabel:SetText("Prepare / Press")
    local prepareEdit = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    prepareEdit:SetSize(52, 24)
    prepareEdit:SetPoint("LEFT", prepareLabel, "RIGHT", 12, 0)
    prepareEdit:SetAutoFocus(false)
    frame.PrepareEdit = prepareEdit
    local pressEdit = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    pressEdit:SetSize(52, 24)
    pressEdit:SetPoint("LEFT", prepareEdit, "RIGHT", 10, 0)
    pressEdit:SetAutoFocus(false)
    frame.PressEdit = pressEdit

    local timingCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    timingCheck:SetPoint("TOPLEFT", prepareLabel, "BOTTOMLEFT", -5, -13)
    timingCheck.text:SetText("Automatic timing overlay")
    frame.TimingCheck = timingCheck

    local apply = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    apply:SetSize(96, 24)
    apply:SetPoint("BOTTOMRIGHT", -112, 14)
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
    cancel:SetSize(96, 24)
    cancel:SetPoint("LEFT", apply, "RIGHT", 10, 0)
    cancel:SetText(CANCEL or "Cancel")
    cancel:SetScript("OnClick", function() frame:Hide() end)

    self.advancedFrame = frame
end

function BossMacroManager:PopulateTacticsFrame()
    local frame = self.tacticsFrame
    local boss = self:GetBoss()
    if not frame or not boss then return end
    frame.Context:SetText(("%s  —  %s"):format(boss.name or "Boss", difficultyLabel(self.selectedDifficultyKey)))
    frame.BodyEdit:SetText(BossMacros:GetTactics(boss.id, self.selectedDifficultyKey) or "")
    frame.BodyEdit:SetCursorPosition(0)
end

function BossMacroManager:InitializeTacticsFrame()
    if self.tacticsFrame then return end
    local frame = CreateFrame("Frame", "RaidLeadAssistTacticsFrame", UIParent, "ButtonFrameTemplate")
    frame:SetSize(530, 438)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:Hide()
    removePortrait(frame)
    setFrameTitle(frame, "Boss Tactics")

    local contentAnchor = frame.Inset or frame

    local context = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    context:SetPoint("TOPLEFT", contentAnchor, "TOPLEFT", 14, -12)
    context:SetPoint("TOPRIGHT", contentAnchor, "TOPRIGHT", -14, -12)
    context:SetJustifyH("LEFT")
    frame.Context = context

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", context, "BOTTOMLEFT", 0, -5)
    hint:SetPoint("TOPRIGHT", context, "BOTTOMRIGHT", 0, -5)
    hint:SetJustifyH("LEFT")
    hint:SetText("Use this for mechanics, assignments, interrupts, dispels, defensives, movement and raid-leader callouts.")

    local background = CreateFrame("Frame", nil, frame, "TooltipBackdropTemplate")
    background:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -8)
    background:SetPoint("BOTTOMRIGHT", contentAnchor, "BOTTOMRIGHT", -14, 14)

    local scroll = CreateFrame("ScrollFrame", nil, background, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -8)
    scroll:SetPoint("BOTTOMRIGHT", -26, 8)

    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject(GameFontHighlight or ChatFontNormal)
    edit:SetWidth(450)
    edit:SetHeight(288)
    edit:SetMaxLetters(6000)
    edit:SetScript("OnEscapePressed", edit.ClearFocus)
    scroll:SetScrollChild(edit)
    frame.BodyEdit = edit

    local reset = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    reset:SetSize(120, 24)
    reset:SetPoint("BOTTOMLEFT", 18, 12)
    reset:SetText("Reset Default")
    reset:SetScript("OnClick", function()
        local boss = self:GetBoss()
        if not boss then return end
        local ok, text = BossMacros:ResetTactics(boss.id, self.selectedDifficultyKey)
        if ok then frame.BodyEdit:SetText(text or "") end
    end)

    local save = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    save:SetSize(96, 24)
    save:SetPoint("BOTTOMRIGHT", -114, 12)
    save:SetText(SAVE or "Save")
    save:SetScript("OnClick", function()
        local boss = self:GetBoss()
        if not boss then frame:Hide() return end
        local ok, err = BossMacros:SetTactics(boss.id, self.selectedDifficultyKey, frame.BodyEdit:GetText() or "")
        if not ok then ns:Print(err or "Could not save tactics.") return end
        frame:Hide()
    end)

    local cancel = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    cancel:SetSize(96, 24)
    cancel:SetPoint("LEFT", save, "RIGHT", 10, 0)
    cancel:SetText(CANCEL or "Cancel")
    cancel:SetScript("OnClick", function() frame:Hide() end)

    self.tacticsFrame = frame
end

function BossMacroManager:OpenTactics()
    local boss = self:GetBoss()
    if not boss then return end
    self:InitializeTacticsFrame()
    local frame = self.tacticsFrame
    self:PopulateTacticsFrame()
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
    frame:Show()
end

function BossMacroManager:CreateNewMacro()
    local boss = self:GetBoss()
    if not boss then return end
    local previousMacroId = self.selectedMacroId
    local macro, err = BossMacros:CreateMacro(boss.id, self.selectedDifficultyKey)
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
        BossMacros:DeleteMacro(boss.id, macro.id, self.selectedDifficultyKey)
        self.selectedMacroId = previousMacroId
        if not self:GetSelectedMacro() then
            local macros = BossMacros:GetMacros(boss.id, self.selectedDifficultyKey)
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
            local ok, removed = BossMacros:DeleteMacro(boss.id, macro.id, self.selectedDifficultyKey)
            if not ok then return end
            if self.callbacks and self.callbacks.onMacroDeleted then self.callbacks.onMacroDeleted(removed, boss) end
            local macros = BossMacros:GetMacros(boss.id, self.selectedDifficultyKey)
            self.selectedMacroId = macros[1] and macros[1].id or nil
            self.macroOffset = 1
            self:RefreshMacroGrid()
            self:PopulateEditor(self:GetSelectedMacro())
        end,
    })
end

function BossMacroManager:MoveSelected(delta)
    local macro = self:GetSelectedMacro()
    local boss = self:GetBoss()
    if not macro or not boss then return end
    if BossMacros:MoveMacroByOffset(boss.id, macro.id, delta, self.selectedDifficultyKey) then
        self:RefreshMacroGrid()
    end
end

function BossMacroManager:FinishMacroDrag(sourceButton)
    local sourceId = self.draggingMacroId
    self.draggingMacroId = nil
    for _, button in ipairs(self.macroButtons) do button:UnlockHighlight() end
    if sourceButton then sourceButton:UnlockHighlight() end
    if not sourceId then return end

    local focus = getMouseFocusSafe()
    local targetId = focus and focus.rlaMacroButton and focus.macroId or nil
    if not targetId or tonumber(targetId) == tonumber(sourceId) then return end
    local boss = self:GetBoss()
    if boss and BossMacros:MoveMacro(boss.id, sourceId, targetId, self.selectedDifficultyKey) then
        self.selectedMacroId = tonumber(sourceId)
        self:RefreshMacroGrid()
        self:PopulateEditor(self:GetSelectedMacro())
    end
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
    StaticPopup_Show("RLA_CONFIRM_DELETE", ("Delete boss '%s' and all Heroic/Mythic macros?"):format(boss.name or "Boss"), nil, {
        callback = function()
            local macros = BossMacros:GetAllMacros(boss.id)
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
    self.selectedDifficultyKey = validDifficulty(database.selectedDifficultyKey) and database.selectedDifficultyKey or "heroic"

    local frame = CreateFrame("Frame", "RaidLeadAssistBossMacroFrame", UIParent, "ButtonFrameTemplate")
    frame:SetSize(432, 668)
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
    removePortrait(frame)
    setFrameTitle(frame, "Raid Lead Assist — Boss Macros")

    local bossLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bossLabel:SetPoint("TOPLEFT", 12, -57)
    bossLabel:SetText("Boss:")

    local bossDropdown = CreateFrame("Frame", "RaidLeadAssistBossDropdown", frame, "UIDropDownMenuTemplate")
    bossDropdown:SetPoint("TOPLEFT", 38, -46)
    UIDropDownMenu_SetWidth(bossDropdown, 185)
    frame.BossDropdown = bossDropdown

    local newBoss = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    newBoss:SetSize(50, 22)
    newBoss:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -106, -51)
    newBoss:SetText("New")
    newBoss:SetScript("OnClick", function() self:CreateBoss() end)

    local renameBoss = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    renameBoss:SetSize(62, 22)
    renameBoss:SetPoint("LEFT", newBoss, "RIGHT", 4, 0)
    renameBoss:SetText("Rename")
    renameBoss:SetScript("OnClick", function() self:RenameBoss() end)

    local deleteBoss = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    deleteBoss:SetSize(22, 22)
    deleteBoss:SetPoint("LEFT", renameBoss, "RIGHT", 4, 0)
    deleteBoss:SetText("X")
    deleteBoss:SetScript("OnClick", function() self:DeleteBoss() end)
    deleteBoss:SetScript("OnEnter", function(owner)
        if not GameTooltip then return end
        GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
        GameTooltip:SetText("Delete Boss", 1, 0.82, 0)
        GameTooltip:AddLine("Removes the boss and all Heroic/Mythic macros.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    deleteBoss:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

    local difficultyLabelText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    difficultyLabelText:SetPoint("TOPLEFT", 12, -89)
    difficultyLabelText:SetText("Difficulty:")

    frame.DifficultyButtons = {}
    local heroicButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    heroicButton:SetSize(80, 22)
    heroicButton:SetPoint("TOPLEFT", 82, -83)
    heroicButton:SetText("Heroic")
    heroicButton:SetScript("OnClick", function() self:SelectDifficulty("heroic", true) end)
    frame.DifficultyButtons.heroic = heroicButton

    local mythicButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    mythicButton:SetSize(80, 22)
    mythicButton:SetPoint("LEFT", heroicButton, "RIGHT", 6, 0)
    mythicButton:SetText("Mythic")
    mythicButton:SetScript("OnClick", function() self:SelectDifficulty("mythic", true) end)
    frame.DifficultyButtons.mythic = mythicButton

    local tacticsButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    tacticsButton:SetSize(116, 22)
    tacticsButton:SetPoint("TOPRIGHT", -14, -83)
    tacticsButton:SetText("Boss Tactics")
    tacticsButton:SetScript("OnClick", function() self:OpenTactics() end)
    frame.TacticsButton = tacticsButton

    local grid = CreateFrame("Frame", nil, frame, "TooltipBackdropTemplate")
    grid:SetPoint("TOPLEFT", 14, -116)
    grid:SetSize(404, 170)
    grid:EnableMouseWheel(true)
    grid:SetScript("OnMouseWheel", function(_, delta)
        local macros = self:GetBoss() and BossMacros:GetMacros(self.selectedBossId, self.selectedDifficultyKey) or {}
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
        button:SetPoint("TOPLEFT", 20 + (col * 62), -10 - (row * 50))
        button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
        button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        button:RegisterForDrag("LeftButton")
        button.rlaMacroButton = true

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 3, -3)
        icon:SetPoint("BOTTOMRIGHT", -3, 3)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        button.Icon = icon

        local selected = button:CreateTexture(nil, "OVERLAY")
        selected:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        selected:SetBlendMode("ADD")
        selected:SetVertexColor(1, 0.78, 0.08, 1)
        selected:SetPoint("CENTER", 0, 0)
        selected:SetSize(56, 56)
        selected:Hide()
        button.Selected = selected

        -- Match Blizzard's MacroButtonTemplate: the macro name is a small
        -- single-line overlay inside the icon instead of a separate label below it.
        local name = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")
        name:SetSize(36, 10)
        name:SetPoint("BOTTOM", button, "BOTTOM", 0, 2)
        name:SetWordWrap(false)
        name:SetJustifyH("CENTER")
        button.Name = name

        button:SetScript("OnEnter", function(btn)
            if not btn.macroId or not GameTooltip then return end
            local macro = BossMacros:FindMacroById(btn.macroId)
            if not macro then return end
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText(macro.name or "Macro", 1, 0.82, 0)
            if type(macro.body) == "string" and macro.body ~= "" then
                GameTooltip:AddLine(macro.body, 1, 1, 1, true)
            end
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        button:SetScript("OnClick", function(btn) if btn.macroId then self:SelectMacro(btn.macroId) end end)
        button:SetScript("OnDragStart", function(btn)
            if not btn.macroId then return end
            self:SelectMacro(btn.macroId)
            self.draggingMacroId = btn.macroId
            btn:LockHighlight()
        end)
        button:SetScript("OnDragStop", function(btn) self:FinishMacroDrag(btn) end)
        self.macroButtons[index] = button
    end

    local gridStatus = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    gridStatus:SetPoint("TOPLEFT", grid, "BOTTOMLEFT", 8, -2)
    gridStatus:SetWidth(300)
    gridStatus:SetJustifyH("LEFT")
    frame.GridStatus = gridStatus

    local moveRight = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    moveRight:SetSize(26, 19)
    moveRight:SetPoint("TOPRIGHT", grid, "BOTTOMRIGHT", -4, 1)
    moveRight:SetText(">")
    moveRight:SetScript("OnClick", function() self:MoveSelected(1) end)
    frame.MoveRightButton = moveRight

    local moveLeft = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    moveLeft:SetSize(26, 19)
    moveLeft:SetPoint("RIGHT", moveRight, "LEFT", -3, 0)
    moveLeft:SetText("<")
    moveLeft:SetScript("OnClick", function() self:MoveSelected(-1) end)
    frame.MoveLeftButton = moveLeft

    addHorizontalBar(frame, -307, 414)

    local editor = CreateFrame("Frame", nil, frame)
    editor:SetPoint("TOPLEFT", 14, -318)
    editor:SetPoint("BOTTOMRIGHT", -14, 42)
    frame.Editor = editor

    local selectedButton = CreateFrame("Button", nil, editor)
    selectedButton:SetSize(54, 54)
    selectedButton:SetPoint("TOPLEFT", 0, 0)
    selectedButton:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
    selectedButton:RegisterForDrag("LeftButton")
    selectedButton:SetScript("OnDragStart", function() self:PickupSelected() end)

    local selectedIcon = selectedButton:CreateTexture(nil, "ARTWORK")
    selectedIcon:SetSize(42, 42)
    selectedIcon:SetPoint("CENTER", 0, 0)
    selectedIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    frame.SelectedIcon = selectedIcon

    local selectedName = editor:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    selectedName:SetPoint("TOPLEFT", selectedButton, "TOPRIGHT", 6, -4)
    selectedName:SetWidth(220)
    selectedName:SetJustifyH("LEFT")
    frame.SelectedName = selectedName

    local changeButton = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    changeButton:SetSize(174, 22)
    changeButton:SetPoint("TOPLEFT", selectedButton, "TOPRIGHT", 6, -30)
    changeButton:SetText("Change Name/Icon")
    changeButton:SetScript("OnClick", function() self:OpenIconPicker() end)
    frame.ChangeButton = changeButton

    local saveButton = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    saveButton:SetSize(92, 22)
    saveButton:SetPoint("TOPRIGHT", 0, -1)
    saveButton:SetText(SAVE or "Save")
    saveButton:SetScript("OnClick", function() self:SaveSelected() end)
    frame.SaveButton = saveButton

    local cancelButton = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    cancelButton:SetSize(92, 22)
    cancelButton:SetPoint("TOP", saveButton, "BOTTOM", 0, -5)
    cancelButton:SetText(CANCEL or "Cancel")
    cancelButton:SetScript("OnClick", function() self:PopulateEditor(self:GetSelectedMacro()) end)

    local abilityRow = CreateFrame("Frame", nil, editor)
    abilityRow:SetPoint("TOPLEFT", 0, -70)
    abilityRow:SetPoint("TOPRIGHT", 0, -70)
    abilityRow:SetHeight(32)

    local abilityLabel = abilityRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    abilityLabel:SetPoint("LEFT", abilityRow, "LEFT", 8, 0)
    abilityLabel:SetWidth(74)
    abilityLabel:SetJustifyH("LEFT")
    abilityLabel:SetText("Boss Ability:")

    local abilityDropdown = CreateFrame("Frame", "RaidLeadAssistAbilityDropdown", abilityRow, "UIDropDownMenuTemplate")
    abilityDropdown:SetPoint("LEFT", abilityLabel, "RIGHT", -12, -1)
    UIDropDownMenu_SetWidth(abilityDropdown, 178)
    frame.AbilityDropdown = abilityDropdown

    local advancedButton = CreateFrame("Button", nil, abilityRow, "UIPanelButtonTemplate")
    advancedButton:SetSize(92, 22)
    advancedButton:SetPoint("RIGHT", abilityRow, "RIGHT", 0, 0)
    advancedButton:SetText("Advanced")
    advancedButton:SetScript("OnClick", function() self:OpenAdvanced() end)
    frame.AdvancedButton = advancedButton

    local dragButton = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    dragButton:SetSize(118, 22)
    dragButton:SetPoint("TOP", advancedButton, "BOTTOM", 0, -6)
    dragButton:SetText("To Action Bar")
    dragButton:SetScript("OnClick", function() self:PickupSelected() end)
    frame.DragButton = dragButton

    local commandsLabel = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    commandsLabel:SetPoint("TOPLEFT", 8, -136)
    commandsLabel:SetText("Enter Macro Commands:")

    local bodyBackground = CreateFrame("Frame", nil, editor, "TooltipBackdropTemplate")
    bodyBackground:SetPoint("TOPLEFT", 0, -154)
    bodyBackground:SetPoint("BOTTOMRIGHT", 0, 30)

    local bodyScroll = CreateFrame("ScrollFrame", nil, bodyBackground, "UIPanelScrollFrameTemplate")
    bodyScroll:SetPoint("TOPLEFT", 8, -7)
    bodyScroll:SetPoint("BOTTOMRIGHT", -26, 8)

    local bodyEdit = CreateFrame("EditBox", nil, bodyScroll)
    bodyEdit:SetMultiLine(true)
    bodyEdit:SetAutoFocus(false)
    bodyEdit:SetFontObject(GameFontHighlightSmall or ChatFontNormal)
    bodyEdit:SetWidth(342)
    bodyEdit:SetHeight(112)
    bodyEdit:SetMaxLetters(255)
    bodyEdit:SetScript("OnEscapePressed", bodyEdit.ClearFocus)
    bodyEdit:SetScript("OnTextChanged", function(edit)
        if self.draft then self.draft.body = edit:GetText() or "" end
        self:UpdateCharacterCount()
    end)
    bodyScroll:SetScrollChild(bodyEdit)
    frame.BodyEdit = bodyEdit

    local charCount = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    charCount:SetPoint("TOP", bodyBackground, "BOTTOM", 0, -3)
    frame.CharCount = charCount

    local deleteButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    deleteButton:SetSize(92, 22)
    deleteButton:SetPoint("BOTTOMLEFT", 8, 8)
    deleteButton:SetText(DELETE or "Delete")
    deleteButton:SetScript("OnClick", function() self:DeleteSelectedMacro() end)
    frame.DeleteButton = deleteButton

    local newButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    newButton:SetSize(92, 22)
    newButton:SetPoint("BOTTOMRIGHT", -106, 8)
    newButton:SetText(NEW or "New")
    newButton:SetScript("OnClick", function() self:CreateNewMacro() end)

    local exitButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    exitButton:SetSize(92, 22)
    exitButton:SetPoint("BOTTOMRIGHT", -8, 8)
    exitButton:SetText(EXIT or "Exit")
    exitButton:SetScript("OnClick", function() frame:Hide() end)

    self.frame = frame
    frame:HookScript("OnHide", function()
        if self.advancedFrame then self.advancedFrame:Hide() end
        if self.tacticsFrame then self.tacticsFrame:Hide() end
        IconPicker:Close()
    end)

    local initial = database.selectedBossId or (BossMacros:GetBossesOrdered()[1] and BossMacros:GetBossesOrdered()[1].id)
    if initial then self:SelectBoss(initial, false) else self:PopulateEditor(nil) end
    self:RefreshDifficultyButtons()
end

function BossMacroManager:Show()
    if self.frame then
        local selected = validDifficulty(self.database and self.database.selectedDifficultyKey) and self.database.selectedDifficultyKey or self.selectedDifficultyKey
        if selected ~= self.selectedDifficultyKey then
            self:SelectDifficulty(selected, false, true)
        else
            self:RefreshDifficultyButtons()
            self:RefreshBossDropdown()
            self:RefreshMacroGrid()
            self:PopulateEditor(self:GetSelectedMacro())
        end
        self.frame:Show()
    end
end

function BossMacroManager:Hide()
    if self.frame then self.frame:Hide() end
    if self.advancedFrame then self.advancedFrame:Hide() end
    if self.tacticsFrame then self.tacticsFrame:Hide() end
    IconPicker:Close()
end

function BossMacroManager:Toggle()
    if not self.frame then return end
    if self.frame:IsShown() then self:Hide() else self:Show() end
end

ns:RegisterModule("UI.BossMacroManager", BossMacroManager)
