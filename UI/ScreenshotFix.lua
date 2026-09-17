local _, ns = ...

local UI = ns:GetModule("UI.BossMacroManager")
local IconPicker = ns:GetModule("UI.IconPicker")

local function findButton(frame, text)
    if not frame or type(frame.GetChildren) ~= "function" then return nil end
    for _, child in ipairs({ frame:GetChildren() }) do
        if type(child.GetText) == "function" and child:GetText() == text then return child end
    end
end

local function findTextRegion(frame, text)
    if not frame or type(frame.GetRegions) ~= "function" then return nil end
    for _, region in ipairs({ frame:GetRegions() }) do
        if type(region.GetText) == "function" and region:GetText() == text then return region end
    end
end

-- Screenshot-only alignment pass. Keep every adjustment scoped to the exact
-- control shown in the screenshots so unrelated UI geometry stays untouched.
local originalInitialize = UI.Initialize
function UI:Initialize(database, callbacks)
    local result = originalInitialize(self, database, callbacks)
    local frame = self.frame
    if not frame then return result end

    -- Boss Ability: align the text exactly to the vertical center of Advanced.
    if frame.AdvancedButton then
        local abilityRow = frame.AdvancedButton:GetParent()
        local label = frame.AbilityLabel or findTextRegion(abilityRow, "Boss Ability:")
        if label then
            frame.AbilityLabel = label
            label:ClearAllPoints()
            label:SetPoint("RIGHT", frame.AdvancedButton, "LEFT", -10, 0)
            label:SetJustifyH("RIGHT")
        end
    end

    -- Main editor only: moving Save also moves Cancel because Cancel is anchored
    -- directly to Save. No tactics-window buttons are touched here.
    if frame.Editor and frame.SaveButton then
        frame.SaveButton:ClearAllPoints()
        frame.SaveButton:SetPoint("TOPRIGHT", frame.Editor, "TOPRIGHT", -2, -1)
    end

    -- Main-window New / Exit only. Their original right offsets are -106 / -8;
    -- use -111 / -13 to move both exactly 5 px left without moving their parent.
    local newButton = findButton(frame, NEW or "New")
    if newButton then
        newButton:ClearAllPoints()
        newButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -111, 16)
    end

    local exitButton = findButton(frame, EXIT or "Exit")
    if exitButton then
        exitButton:ClearAllPoints()
        exitButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -13, 16)
    end

    return result
end

-- Advanced Timer Matching dialog only. Re-anchor the Apply / Cancel pair after
-- the base frame is created. Cancel remains attached to Apply, so moving Apply
-- 5 px left moves the pair together and does not affect fields or labels above.
local originalInitializeAdvancedFrame = UI.InitializeAdvancedFrame
function UI:InitializeAdvancedFrame()
    local result = originalInitializeAdvancedFrame(self)
    local frame = self.advancedFrame
    if not frame then return result end

    local apply = findButton(frame, APPLY or "Apply")
    local cancel = findButton(frame, CANCEL or "Cancel")
    if apply then
        apply:ClearAllPoints()
        apply:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -117, 14)
    end
    if cancel and apply then
        cancel:ClearAllPoints()
        cancel:SetPoint("LEFT", apply, "RIGHT", 10, 0)
    end

    return result
end

local originalPickerOpen = IconPicker.Open
function IconPicker:Open(...)
    local result = originalPickerOpen(self, ...)
    local frame = self.frame
    local closeButton = frame and frame.CloseButton or nil
    if closeButton then
        -- Only the icon-picker X: make the entire visible button smaller and move
        -- it two pixels farther right than the previous screenshot position.
        closeButton:ClearAllPoints()
        closeButton:SetSize(18, 18)
        closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 6, 0)

        local function polish(texture, xOffset, yOffset)
            if not texture then return end
            texture:ClearAllPoints()
            texture:SetPoint("CENTER", closeButton, "CENTER", xOffset or 0, yOffset or 0)
            texture:SetSize(14, 14)
        end

        polish(closeButton:GetNormalTexture(), 1, 0)
        polish(closeButton:GetPushedTexture(), 2, -1)
        polish(closeButton:GetHighlightTexture(), 1, 0)
        if type(closeButton.GetDisabledTexture) == "function" then
            polish(closeButton:GetDisabledTexture(), 1, 0)
        end
    end
    return result
end

ns:RegisterModule("UI.ScreenshotFix", UI)
