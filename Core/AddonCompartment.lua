local _, ns = ...

local UI = ns:GetModule("UI.BossMacroManager")

function RaidLeadAssist_Open()
    UI:Toggle()
end

function RaidLeadAssist_CompartmentEnter(_, menuButtonFrame)
    if not menuButtonFrame or not GameTooltip then return end
    GameTooltip:SetOwner(menuButtonFrame, "ANCHOR_LEFT")
    GameTooltip:SetText("Raid Lead Assist", 0.95, 0.82, 0.25, 1)
    GameTooltip:AddLine("Open the Blizzard-style Boss Macro Manager", 1, 1, 1)
    GameTooltip:AddLine("Create or edit boss macros, then place them on your action bar.", 0.78, 0.78, 0.78, true)
    GameTooltip:Show()
end

function RaidLeadAssist_CompartmentLeave()
    if GameTooltip then GameTooltip:Hide() end
end
