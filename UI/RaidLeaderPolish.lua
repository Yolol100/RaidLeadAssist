local _, ns = ...

local UI = ns:GetModule("UI.BossMacroManager")
local IconPicker = ns:GetModule("UI.IconPicker")

local function inCombat()
    return type(InCombatLockdown) == "function" and InCombatLockdown() == true
end

local function hideButtonBar(frame)
    if frame and type(ButtonFrameTemplate_HideButtonBar) == "function" then
        pcall(ButtonFrameTemplate_HideButtonBar, frame)
    end
end

local function findButton(frame, text)
    if not frame or type(frame.GetChildren) ~= "function" then return nil end
    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        if type(child.GetText) == "function" and child:GetText() == text then return child end
    end
end

local function findTextRegion(frame, text)
    if not frame or type(frame.GetRegions) ~= "function" then return nil end
    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
        if type(region.GetText) == "function" and region:GetText() == text then return region end
    end
end

local function hideLegacySeparator(frame)
    if not frame or type(frame.GetRegions) ~= "function" then return end
    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
        if type(region.GetObjectType) == "function" and region:GetObjectType() == "Texture"
            and type(region.GetWidth) == "function" and type(region.GetHeight) == "function" then
            local width, height = region:GetWidth(), region:GetHeight()
            local point, _, _, _, y = region:GetPoint(1)
            if width and width > 500 and height and height <= 18 and point == "TOP"
                and type(y) == "number" and math.abs(y + 126) <= 3 then
                region:Hide()
            end
        end
    end
end

function UI:RefreshTestButton()
    if not self.frame or not self.frame.TestButton then return end
    local macro = self:GetSelectedMacro()
    local active = macro and self.callbacks and self.callbacks.isTestActive and self.callbacks.isTestActive(macro)
    self.frame.TestButton:SetText(active and "Stop Test" or "Test")
    self.frame.TestButton:SetEnabled(macro ~= nil)
end

local originalPopulateEditor = UI.PopulateEditor
function UI:PopulateEditor(...)
    local result = originalPopulateEditor(self, ...)
    self:RefreshTestButton()
    return result
end

local originalInitialize = UI.Initialize
function UI:Initialize(database, callbacks)
    originalInitialize(self, database, callbacks)
    local frame = self.frame
    if not frame then return end
    frame:SetScale(tonumber(database and database.uiScale) or 1)
    hideButtonBar(frame)

    if frame.AbilityDropdown then UIDropDownMenu_SetWidth(frame.AbilityDropdown, 184) end
    local advanced = frame.AdvancedButton
    local drag = frame.DragButton
    if advanced and drag then
        local abilityRow = advanced:GetParent()
        if abilityRow then abilityRow:SetHeight(86) end
        advanced:ClearAllPoints()
        advanced:SetSize(92, 22)
        advanced:SetPoint("TOPLEFT", abilityRow, "TOPLEFT", 88, -52)
        drag:ClearAllPoints()
        drag:SetSize(112, 22)
        drag:SetPoint("LEFT", advanced, "RIGHT", 6, 0)

        local test = CreateFrame("Button", nil, abilityRow, "UIPanelButtonTemplate")
        test:SetSize(72, 22)
        test:SetPoint("LEFT", drag, "RIGHT", 6, 0)
        test:SetText("Test")
        test:SetScript("OnClick", function()
            local macro = self:GetSelectedMacro()
            if not macro or not self.callbacks then return end
            if self.callbacks.isTestActive and self.callbacks.isTestActive(macro) then
                if self.callbacks.onStopTest then self.callbacks.onStopTest(macro) end
            elseif self.callbacks.onTestMacro then
                self.callbacks.onTestMacro(macro, self:GetBoss())
            end
            self:RefreshTestButton()
        end)
        frame.TestButton = test
    end

    local commandsLabel = frame.Editor and findTextRegion(frame.Editor, "Enter Macro Commands:") or nil
    if commandsLabel then
        commandsLabel:ClearAllPoints()
        commandsLabel:SetPoint("TOPLEFT", frame.Editor, "TOPLEFT", 8, -158)
    end
    if frame.BodyEdit then
        local scroll = frame.BodyEdit:GetParent()
        local bodyBackground = scroll and scroll:GetParent()
        if bodyBackground then
            bodyBackground:ClearAllPoints()
            bodyBackground:SetPoint("TOPLEFT", frame.Editor, "TOPLEFT", 0, -176)
            bodyBackground:SetPoint("BOTTOMRIGHT", frame.Editor, "BOTTOMRIGHT", 0, 30)
        end
    end

    local deleteButton = frame.DeleteButton
    local newButton = findButton(frame, NEW or "New")
    local exitButton = findButton(frame, EXIT or "Exit")
    if deleteButton then
        deleteButton:ClearAllPoints()
        deleteButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 16)
    end
    if newButton then
        newButton:ClearAllPoints()
        newButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -106, 16)
    end
    if exitButton then
        exitButton:ClearAllPoints()
        exitButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 16)
    end
    self:RefreshTestButton()
end

local originalShow = UI.Show
function UI:Show(...)
    local result = originalShow(self, ...)
    self:RefreshTestButton()
    return result
end

local originalInitializeTacticsFrame = UI.InitializeTacticsFrame
function UI:InitializeTacticsFrame()
    originalInitializeTacticsFrame(self)
    local frame = self.tacticsFrame
    if not frame or frame.RLAPolished then return end
    frame.RLAPolished = true
    frame:SetSize(530, 390)
    frame:SetScale(tonumber(self.database and self.database.uiScale) or 1)
    hideButtonBar(frame)
    if frame.Inset then
        frame.Inset:ClearAllPoints()
        frame.Inset:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -31)
        frame.Inset:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 5)
    end
    if frame.Context then
        frame.Context:ClearAllPoints()
        frame.Context:SetPoint("TOPLEFT", frame.Inset or frame, "TOPLEFT", 10, -8)
        frame.Context:SetPoint("TOPRIGHT", frame.Inset or frame, "TOPRIGHT", -10, -8)
    end

    if frame.BodyEdit then
        frame.BodyEdit:SetHeight(224)
        local scroll = frame.BodyEdit:GetParent()
        local background = scroll and scroll:GetParent()
        if background then
            local point, relativeTo, relativePoint, x, y = background:GetPoint(1)
            background:ClearAllPoints()
            if point then background:SetPoint(point, relativeTo, relativePoint, x, y) end
            background:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 52)
        end
    end

    local reset = findButton(frame, "Reset Default")
    local save = findButton(frame, SAVE or "Save")
    local cancel = findButton(frame, CANCEL or "Cancel")
    if reset then
        reset:ClearAllPoints()
        reset:SetSize(108, 24)
        reset:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, 14)
    end
    if save then
        save:ClearAllPoints()
        save:SetSize(90, 24)
        save:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -114, 14)
    end
    if cancel and save then
        cancel:ClearAllPoints()
        cancel:SetSize(90, 24)
        cancel:SetPoint("LEFT", save, "RIGHT", 6, 0)
    end
    if reset then
        local preview = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        preview:SetSize(90, 24)
        preview:SetPoint("LEFT", reset, "RIGHT", 6, 0)
        preview:SetText("Preview")
        preview:SetScript("OnClick", function()
            local text = frame.BodyEdit and frame.BodyEdit:GetText() or ""
            text = tostring(text):match("^%s*(.-)%s*$") or ""
            ns:Print("[RLA Preview] " .. (text ~= "" and text:gsub("\n+", " | ") or "No tactics text."))
        end)
        frame.PreviewButton = preview
    end
end

local originalCreateBoss = UI.CreateBoss
function UI:CreateBoss(...)
    if inCombat() then ns:Print("Boss editing is unavailable during combat.") return end
    return originalCreateBoss(self, ...)
end

local originalRenameBoss = UI.RenameBoss
function UI:RenameBoss(...)
    if inCombat() then ns:Print("Boss editing is unavailable during combat.") return end
    return originalRenameBoss(self, ...)
end

local originalPickerOpen = IconPicker.Open
function IconPicker:Open(anchorFrame, name, icon, callback, cancelCallback)
    if inCombat() then ns:Print("Icon editing is unavailable during combat.") return end
    if tonumber(icon) == 134400 then icon = "Interface\\Icons\\INV_Misc_Note_01" end
    local result = originalPickerOpen(self, anchorFrame, name, icon, callback, cancelCallback)
    if self.frame then
        hideButtonBar(self.frame)
        hideLegacySeparator(self.frame)
        self.frame:SetScale(anchorFrame and type(anchorFrame.GetScale) == "function" and (anchorFrame:GetScale() or 1) or 1)

        -- IconPicker.lua owns all picker geometry. This wrapper only applies
        -- non-positional polish so reopening the picker cannot override anchors.
        for _, button in ipairs(self.buttons or {}) do
            if button.Selected then
                button.Selected:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
                button.Selected:ClearAllPoints()
                button.Selected:SetPoint("CENTER", 0, 0)
                button.Selected:SetSize(56, 56)
            end
        end
        local regions = { self.frame:GetRegions() }
        for _, region in ipairs(regions) do
            if type(region.GetTexture) == "function" then
                local texture = region:GetTexture()
                if type(texture) == "string" and texture:find("UI%-ClassTrainer%-HorizontalBar") then region:Hide() end
            end
        end
    end
    return result
end

ns:RegisterModule("UI.RaidLeaderPolish", UI)
