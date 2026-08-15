local _, ns = ...

local Theme = ns:GetModule("UI.Theme")
local ActionButton = ns:GetModule("UI.ActionButton")

local AssignmentLaunchers = {}

function AssignmentLaunchers:Attach(mainUI, settingsUI, onOpen)
    if mainUI and mainUI.frame and not mainUI.frame.assignmentButton then
        local button = CreateFrame("Button", nil, mainUI.frame)
        button:SetSize(68, 24)
        button:SetPoint("TOPRIGHT", -82, -1)
        button:SetFrameLevel(mainUI.frame:GetFrameLevel() + 2)
        button.text = button:CreateFontString(nil, "OVERLAY")
        button.text:SetFont(Theme.font, 9, "OUTLINE")
        button.text:SetAllPoints()
        button.text:SetText("ASSIGN")
        button.text:SetTextColor(Theme.colors.muted[1], Theme.colors.muted[2], Theme.colors.muted[3], 1)
        button:SetScript("OnEnter", function(self)
            self.text:SetTextColor(Theme.colors.venom[1], Theme.colors.venom[2], Theme.colors.venom[3], 1)
        end)
        button:SetScript("OnLeave", function(self)
            self.text:SetTextColor(Theme.colors.muted[1], Theme.colors.muted[2], Theme.colors.muted[3], 1)
        end)
        button:SetScript("OnClick", function() if onOpen then onOpen() end end)
        mainUI.frame.assignmentButton = button
    end

    if settingsUI and settingsUI.frame and settingsUI.audioButton and not settingsUI.frame.assignmentButton then
        local button = ActionButton:Create(settingsUI.frame, {
            text = "ASSIGNMENTS",
            width = 104,
            height = 24,
            fontSize = 9,
            variant = "secondary",
        })
        button:SetPoint("RIGHT", settingsUI.audioButton, "LEFT", -8, 0)
        button:SetScript("OnClick", function() if onOpen then onOpen() end end)
        settingsUI.frame.assignmentButton = button
    end
end

ns:RegisterModule("UI.AssignmentLaunchers", AssignmentLaunchers)
