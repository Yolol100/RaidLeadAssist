local _, ns = ...

local UI = ns:GetModule("UI.BossMacroManager")

local TACTICS_ROLE = "tactics-prepull"

local function findTextRegion(frame, text)
    if not frame or type(frame.GetRegions) ~= "function" then return nil end
    for _, region in ipairs({ frame:GetRegions() }) do
        if type(region.GetText) == "function" and region:GetText() == text then return region end
    end
end

local function findButton(frame, text)
    if not frame or type(frame.GetChildren) ~= "function" then return nil end
    for _, child in ipairs({ frame:GetChildren() }) do
        if type(child.GetText) == "function" and child:GetText() == text then return child end
    end
end

local function hideButtonBar(frame)
    if frame and type(ButtonFrameTemplate_HideButtonBar) == "function" then
        pcall(ButtonFrameTemplate_HideButtonBar, frame)
    end
end

local function setShown(region, shown)
    if not region then return end
    if shown then
        if type(region.Show) == "function" then region:Show() end
    else
        if type(region.Hide) == "function" then region:Hide() end
    end
end

local function refreshAbilitySelectorVisibility(self, macro)
    local frame = self.frame
    if not frame then return end
    local abilityRow = frame.AdvancedButton and frame.AdvancedButton:GetParent() or nil
    local label = frame.AbilityLabel or findTextRegion(abilityRow, "Boss Ability:")
    if label and not frame.AbilityLabel then frame.AbilityLabel = label end

    local showSelector = not (type(macro) == "table" and macro.systemRole == TACTICS_ROLE)
    setShown(label, showSelector)
    setShown(frame.AbilityDropdown, showSelector)
end

local function refreshMacroSlotChrome(self)
    for _, button in ipairs(self.macroButtons or {}) do
        local normal = type(button.GetNormalTexture) == "function" and button:GetNormalTexture() or nil
        if normal and type(normal.SetAlpha) == "function" then
            normal:SetAlpha(button.macroId and 0 or 1)
        end
    end

    local frame = self.frame
    local selectedButton = frame and frame.SelectedIcon and frame.SelectedIcon:GetParent() or nil
    local selectedNormal = selectedButton and type(selectedButton.GetNormalTexture) == "function" and selectedButton:GetNormalTexture() or nil
    if selectedNormal and type(selectedNormal.SetAlpha) == "function" then
        selectedNormal:SetAlpha(frame.SelectedIcon:GetTexture() and 0 or 1)
    end
end

local function pickupSelectedMacro(self)
    local macro = self:GetSelectedMacro()
    if macro and self.callbacks and self.callbacks.onPickupMacro then
        self.callbacks.onPickupMacro(macro, self:GetBoss())
    end
end

local function cursorContainsMacro()
    if type(GetCursorInfo) ~= "function" then return false end
    local ok, kind = pcall(GetCursorInfo)
    return ok and kind == "macro"
end

local function installActionBarDrag(self)
    for _, button in ipairs(self.macroButtons or {}) do
        if not button.RLAActionBarDrag then
            button.RLAActionBarDrag = true
            button:SetScript("OnDragStart", function(btn)
                if not btn.macroId then return end
                self:SelectMacro(btn.macroId)
                self.draggingMacroId = nil
                btn:UnlockHighlight()
                pickupSelectedMacro(self)
            end)
            button:SetScript("OnDragStop", function(btn)
                self.draggingMacroId = nil
                btn:UnlockHighlight()
            end)
        end
    end

    -- The large selected-macro icon below the grid is a separate Button. Treat it
    -- like Blizzard's selected macro pickup control: pressing the icon picks up the
    -- managed General Macro immediately, while OnDragStart remains as a fallback.
    -- This makes Pull Tactics and every other selected macro draggable from the
    -- exact preview icon shown in the editor, not only from the grid tiles.
    local frame = self.frame
    local selectedButton = frame and frame.SelectedIcon and frame.SelectedIcon:GetParent() or nil
    if selectedButton and not selectedButton.RLASelectedActionBarDrag then
        selectedButton.RLASelectedActionBarDrag = true
        selectedButton:EnableMouse(true)
        selectedButton:RegisterForDrag("LeftButton")
        selectedButton:SetScript("OnMouseDown", function(_, mouseButton)
            if mouseButton == "LeftButton" then
                pickupSelectedMacro(self)
            end
        end)
        selectedButton:SetScript("OnDragStart", function()
            if not cursorContainsMacro() then
                pickupSelectedMacro(self)
            end
        end)
    end
end

local originalRefreshMacroGrid = UI.RefreshMacroGrid
function UI:RefreshMacroGrid(...)
    local result = originalRefreshMacroGrid(self, ...)
    refreshMacroSlotChrome(self)
    return result
end

local originalRefreshDifficultyButtons = UI.RefreshDifficultyButtons
function UI:RefreshDifficultyButtons(...)
    local result = originalRefreshDifficultyButtons(self, ...)
    for key, button in pairs(self.frame and self.frame.DifficultyButtons or {}) do
        button:SetButtonState("NORMAL", false)
        if key == self.selectedDifficultyKey then
            button:LockHighlight()
        else
            button:UnlockHighlight()
        end
    end
    return result
end

local originalPopulateEditor = UI.PopulateEditor
function UI:PopulateEditor(macro, ...)
    local result = originalPopulateEditor(self, macro, ...)
    refreshAbilitySelectorVisibility(self, macro)
    refreshMacroSlotChrome(self)
    return result
end

local originalInitialize = UI.Initialize
function UI:Initialize(database, callbacks)
    originalInitialize(self, database, callbacks)
    local frame = self.frame
    if not frame or not frame.AbilityDropdown or not frame.AdvancedButton then return end

    -- Every macro tile and the large selected-macro preview can place the managed
    -- General Macro on the cursor for dropping onto an action bar. Grid ordering
    -- remains available through the dedicated < / > buttons.
    installActionBarDrag(self)

    local bossRow = frame.BossDropdown and frame.BossDropdown:GetParent() or nil
    if bossRow then
        bossRow:ClearAllPoints()
        bossRow:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -41)
        bossRow:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -15, -41)

        -- Keep the dropdown fixed and lift only Boss:, New, Rename and X so the
        -- four controls visually share the dropdown's horizontal center line.
        frame.BossDropdown:ClearAllPoints()
        frame.BossDropdown:SetPoint("LEFT", bossRow, "LEFT", 36, 1)

        local bossLabel = findTextRegion(bossRow, "Boss:")
        if bossLabel then
            bossLabel:ClearAllPoints()
            bossLabel:SetPoint("LEFT", bossRow, "LEFT", 0, 4)
        end

        local deleteBoss = findButton(bossRow, "X")
        local renameBoss = findButton(bossRow, "Rename")
        local newBoss = findButton(bossRow, "New")
        if deleteBoss then
            deleteBoss:ClearAllPoints()
            deleteBoss:SetPoint("RIGHT", bossRow, "RIGHT", 0, 4)
        end
        if renameBoss and deleteBoss then
            renameBoss:ClearAllPoints()
            renameBoss:SetPoint("RIGHT", deleteBoss, "LEFT", -4, 0)
        end
        if newBoss and renameBoss then
            newBoss:ClearAllPoints()
            newBoss:SetPoint("RIGHT", renameBoss, "LEFT", -4, 0)
        end
    end

    local heroic = frame.DifficultyButtons and frame.DifficultyButtons.heroic or nil
    local difficultyRow = heroic and heroic:GetParent() or nil
    if difficultyRow then
        difficultyRow:ClearAllPoints()
        difficultyRow:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -76)
        difficultyRow:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -15, -76)

        local difficultyLabel = findTextRegion(difficultyRow, "Difficulty:")
        if difficultyLabel then
            difficultyLabel:ClearAllPoints()
            difficultyLabel:SetPoint("LEFT", difficultyRow, "LEFT", 0, -2)
        end
    end

    if frame.Editor then
        frame.Editor:ClearAllPoints()
        frame.Editor:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -310)
        frame.Editor:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, 42)
        if frame.SaveButton then
            frame.SaveButton:ClearAllPoints()
            frame.SaveButton:SetPoint("TOPRIGHT", frame.Editor, "TOPRIGHT", -2, -1)
        end
    end

    -- Final screenshot-verified bottom-row alignment. Keep these controls scoped
    -- to the main window so tactics/advanced dialogs are unaffected.
    local mainNew = findButton(frame, NEW or "New")
    local mainExit = findButton(frame, EXIT or "Exit")
    if mainNew then
        mainNew:ClearAllPoints()
        mainNew:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -113, 16)
    end
    if mainExit then
        mainExit:ClearAllPoints()
        mainExit:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, 16)
    end

    local abilityRow = frame.AdvancedButton:GetParent()
    if not abilityRow then return end
    abilityRow:SetHeight(108)
    frame.AbilityLabel = frame.AbilityLabel or findTextRegion(abilityRow, "Boss Ability:")

    -- Keep the label, dropdown and button row as independent anchors. This avoids
    -- moving one control when fine-tuning another.
    if frame.AbilityLabel then
        frame.AbilityLabel:ClearAllPoints()
        frame.AbilityLabel:SetPoint("RIGHT", frame.AdvancedButton, "LEFT", -10, 0)
        frame.AbilityLabel:SetJustifyH("RIGHT")
    end

    frame.AbilityDropdown:ClearAllPoints()
    frame.AbilityDropdown:SetPoint("TOPLEFT", abilityRow, "TOPLEFT", 72, 10)
    UIDropDownMenu_SetWidth(frame.AbilityDropdown, 184)

    frame.AdvancedButton:ClearAllPoints()
    frame.AdvancedButton:SetPoint("TOPLEFT", abilityRow, "TOPLEFT", 88, -28)
    if frame.DragButton then
        frame.DragButton:ClearAllPoints()
        frame.DragButton:SetPoint("LEFT", frame.AdvancedButton, "RIGHT", 6, 0)
    end
    if frame.TestButton and frame.DragButton then
        frame.TestButton:ClearAllPoints()
        frame.TestButton:SetPoint("LEFT", frame.DragButton, "RIGHT", 6, 0)
    end

    local commandsLabel = frame.Editor and findTextRegion(frame.Editor, "Enter Macro Commands:") or nil
    if commandsLabel then
        commandsLabel:ClearAllPoints()
        commandsLabel:SetPoint("TOPLEFT", frame.Editor, "TOPLEFT", 8, -166)
    end
    if frame.BodyEdit then
        local scroll = frame.BodyEdit:GetParent()
        local background = scroll and scroll:GetParent()
        if background then
            background:ClearAllPoints()
            background:SetPoint("TOPLEFT", frame.Editor, "TOPLEFT", 0, -184)
            background:SetPoint("BOTTOMRIGHT", frame.Editor, "BOTTOMRIGHT", 0, 30)
        end
    end

    self:RefreshDifficultyButtons()
    refreshMacroSlotChrome(self)
    refreshAbilitySelectorVisibility(self, self:GetSelectedMacro())
end

local originalInitializeAdvancedFrame = UI.InitializeAdvancedFrame
function UI:InitializeAdvancedFrame()
    originalInitializeAdvancedFrame(self)
    local frame = self.advancedFrame
    if not frame or frame.RLAAdvancedBackgroundFixed then return end
    frame.RLAAdvancedBackgroundFixed = true

    -- Match the dark content/background treatment used by the main and tactics
    -- windows instead of leaving ButtonFrameTemplate's grey button-bar area visible.
    hideButtonBar(frame)
    if frame.Inset then
        frame.Inset:ClearAllPoints()
        frame.Inset:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -31)
        frame.Inset:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 5)
    end

    local apply = findButton(frame, APPLY or "Apply")
    local cancel = findButton(frame, CANCEL or "Cancel")
    if apply then
        apply:ClearAllPoints()
        apply:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -119, 14)
    end
    if cancel and apply then
        cancel:ClearAllPoints()
        cancel:SetPoint("LEFT", apply, "RIGHT", 10, 0)
    end
end

local originalInitializeTacticsFrame = UI.InitializeTacticsFrame
function UI:InitializeTacticsFrame()
    originalInitializeTacticsFrame(self)
    local frame = self.tacticsFrame
    if not frame or frame.RLAHintRemoved then return end
    frame.RLAHintRemoved = true

    local hint = findTextRegion(frame, "Use this for mechanics, assignments, interrupts, dispels, defensives, movement and raid-leader callouts.")
    if hint then hint:Hide() end

    if frame.BodyEdit and frame.Context then
        local scroll = frame.BodyEdit:GetParent()
        local background = scroll and scroll:GetParent()
        if background then
            background:ClearAllPoints()
            background:SetPoint("TOPLEFT", frame.Context, "BOTTOMLEFT", 0, -10)
            background:SetPoint("BOTTOMRIGHT", frame.Inset or frame, "BOTTOMRIGHT", -14, 46)
        end
    end

    -- Saving or resetting tactics can create/update the Pull Tactics macro.
    -- Refresh only the macro grid/editor afterwards; no other layout is touched.
    local save = findButton(frame, SAVE or "Save")
    local reset = findButton(frame, "Reset Default")
    if save then
        save:HookScript("OnClick", function()
            self:RefreshMacroGrid()
            self:PopulateEditor(self:GetSelectedMacro())
        end)
    end
    if reset then
        reset:HookScript("OnClick", function()
            self:RefreshMacroGrid()
            self:PopulateEditor(self:GetSelectedMacro())
        end)
    end
end

ns:RegisterModule("UI.LayoutHotfix", UI)
