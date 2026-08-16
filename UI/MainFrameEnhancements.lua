local _, ns = ...

local MainFrame = ns:GetModule("UI.MainFrame")
local Theme = ns:GetModule("UI.Theme")

local originalInitialize = MainFrame.Initialize

function MainFrame:Initialize(database, callbacks)
    originalInitialize(self, database, callbacks)

    local settingsButton = self.frame and self.frame.settingsButton
    if settingsButton then
        settingsButton:SetSize(62, 26)
        settingsButton:ClearAllPoints()
        settingsButton:SetPoint("TOPRIGHT", -Theme.padding, -1)
    end

    if self.explanationButton and self.explanationButton.frame then
        self.explanationButton.frame.name:SetText("SEND PRE-PULL PLAN")
    end

    if self.frame and self.frame.drag then
        self.frame.drag:SetScript("OnEnter", function(button)
            GameTooltip:SetOwner(button, "ANCHOR_TOP")
            GameTooltip:SetText("Shift-drag to move Raid Lead Assist", 0.82, 0.86, 0.82, 1)
            GameTooltip:Show()
        end)
        self.frame.drag:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
end

ns:RegisterModule("UI.MainFrameEnhancements", {})
