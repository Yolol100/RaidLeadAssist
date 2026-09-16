local _, ns = ...

local UI = ns:GetModule("UI.BossMacroManager")

local function findTextRegion(frame, text)
    if not frame or type(frame.GetRegions) ~= "function" then return nil end
    for _, region in ipairs({ frame:GetRegions() }) do
        if type(region.GetText) == "function" and region:GetText() == text then return region end
    end
end

local function setAbilityControlsVisible(frame, macro)
    if not frame then return end
    local abilityRow = frame.AdvancedButton and frame.AdvancedButton:GetParent() or nil
    local abilityLabel = abilityRow and findTextRegion(abilityRow, "Boss Ability:") or nil
    local isPullTactics = type(macro) == "table" and macro.systemRole == "tactics-prepull"
    local showAbility = not isPullTactics

    if abilityLabel then abilityLabel:SetShown(showAbility) end
    if frame.AbilityDropdown then frame.AbilityDropdown:SetShown(showAbility) end
    if frame.AdvancedButton then frame.AdvancedButton:SetEnabled(macro ~= nil and showAbility) end
end

local originalInitialize = UI.Initialize
local originalPopulateEditor = UI.PopulateEditor

function UI:Initialize(database, callbacks)
    originalInitialize(self, database, callbacks)
    local frame = self.frame
    if not frame or not frame.AbilityDropdown or not frame.AdvancedButton then return end

    local bossRow = frame.BossDropdown and frame.BossDropdown:GetParent() or nil
    if bossRow then
        bossRow:ClearAllPoints()
        bossRow:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -41)
        bossRow:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -15, -41)
    end

    local heroic = frame.DifficultyButtons and frame.DifficultyButtons.heroic or nil
    local difficultyRow = heroic and heroic:GetParent() or nil
    if difficultyRow then
        difficultyRow:ClearAllPoints()
        difficultyRow:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -76)
        difficultyRow:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -15, -76)
    end

    if frame.Editor then
        frame.Editor:ClearAllPoints()
        frame.Editor:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -310)
        frame.Editor:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, 42)
    end

    local abilityRow = frame.AdvancedButton:GetParent()
    if not abilityRow then return end
    abilityRow:SetHeight(108)

    local abilityLabel = findTextRegion(abilityRow, "Boss Ability:")
    if abilityLabel then
        abilityLabel:ClearAllPoints()
        abilityLabel:SetPoint("LEFT", abilityRow, "LEFT", 8, -5)
    end

    frame.AbilityDropdown:ClearAllPoints()
    frame.AbilityDropdown:SetPoint("TOPLEFT", abilityRow, "TOPLEFT", 72, 10)
    UIDropDownMenu_SetWidth(frame.AbilityDropdown, 184)

    frame.AdvancedButton:ClearAllPoints()
    frame.AdvancedButton:SetPoint("TOPLEFT", abilityRow, "TOPLEFT", 88, -48)
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

    setAbilityControlsVisible(frame, self:GetSelectedMacro())
end

function UI:PopulateEditor(macro)
    local result = originalPopulateEditor(self, macro)
    setAbilityControlsVisible(self.frame, macro)
    return result
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
end

ns:RegisterModule("UI.LayoutHotfix", UI)
