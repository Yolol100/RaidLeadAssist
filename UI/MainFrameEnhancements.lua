local _, ns = ...

local MainFrame = ns:GetModule("UI.MainFrame")
local Theme = ns:GetModule("UI.Theme")

local originalInitialize = MainFrame.Initialize

function MainFrame:Initialize(database, callbacks)
    originalInitialize(self, database, callbacks)

    self.settingsButton:SetSize(62, 26)
    self.settingsButton:ClearAllPoints()
    self.settingsButton:SetPoint("TOPRIGHT", -Theme.padding, -1)

    self.explanationButton.frame.name:SetText("SEND PRE-PULL PLAN")

    self.frame.drag:SetScript("OnEnter", function(button)
        GameTooltip:SetOwner(button, "ANCHOR_TOP")
        GameTooltip:SetText("Shift-drag to move Raid Lead Assist", 0.82, 0.86, 0.82, 1)
        GameTooltip:Show()
    end)
    self.frame.drag:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

ns:RegisterModule("UI.MainFrameEnhancements", {})
