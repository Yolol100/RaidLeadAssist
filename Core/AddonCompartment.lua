local _, ns = ...

local App = ns:GetModule("Core.App")
local MainFrame = ns:GetModule("UI.MainFrame")
local SettingsFrame = ns:GetModule("UI.SettingsFrame")

function RaidLeadAssist_Open(_, buttonName)
    if buttonName == "RightButton" then
        SettingsFrame:Open(App.activeBossKey)
        return
    end

    if MainFrame:IsShown() then
        MainFrame:Hide()
    else
        MainFrame:Show()
    end
end

function RaidLeadAssist_CompartmentEnter(button)
    if not button or not GameTooltip then return end
    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip:SetText("Raid Lead Assist", 0.36, 0.90, 0.58, 1)
    GameTooltip:AddLine("Left-click: show/hide raid controls", 1, 1, 1)
    GameTooltip:AddLine("Right-click: open settings", 0.72, 0.76, 0.72)
    GameTooltip:Show()
end

function RaidLeadAssist_CompartmentLeave()
    if GameTooltip then GameTooltip:Hide() end
end
