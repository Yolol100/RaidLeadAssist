local _, ns = ...

local Theme = ns:GetModule("UI.Theme")

local Dropdown = {}
Dropdown.__index = Dropdown

function Dropdown:Create(parent)
    local instance = setmetatable({}, Dropdown)

    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetHeight(34)
    button:SetBackdrop({ bgFile = Theme.texture, edgeFile = Theme.texture, edgeSize = 1 })
    button:SetBackdropColor(0.10, 0.19, 0.13, 1)
    button:SetBackdropBorderColor(0.22, 0.36, 0.27, 1)

    button.text = button:CreateFontString(nil, "OVERLAY")
    button.text:SetFont(Theme.font, 13, "OUTLINE")
    button.text:SetPoint("LEFT", 12, 0)
    button.text:SetPoint("RIGHT", -34, 0)
    button.text:SetJustifyH("LEFT")
    button.text:SetTextColor(Theme.colors.text[1], Theme.colors.text[2], Theme.colors.text[3])

    button.chevron = button:CreateFontString(nil, "OVERLAY")
    button.chevron:SetFont(Theme.font, 10, "OUTLINE")
    button.chevron:SetPoint("RIGHT", -12, 0)
    button.chevron:SetText("v")
    button.chevron:SetTextColor(Theme.colors.venom[1], Theme.colors.venom[2], Theme.colors.venom[3])

    local menu = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    menu:SetFrameStrata("DIALOG")
    menu:SetClampedToScreen(true)
    menu:SetBackdrop({ bgFile = Theme.texture, edgeFile = Theme.texture, edgeSize = 1 })
    menu:SetBackdropColor(0.04, 0.08, 0.06, 0.98)
    menu:SetBackdropBorderColor(0.22, 0.36, 0.27, 1)
    menu:Hide()

    button:SetScript("OnClick", function()
        if menu:IsShown() then menu:Hide() else menu:Show() end
    end)

    instance.frame = button
    instance.menu = menu
    instance.options = {}
    return instance
end

function Dropdown:SetOptions(options, selectedKey, onSelect)
    for _, optionButton in ipairs(self.options) do optionButton:Hide() end
    table.wipe(self.options)

    local height = 6
    for index = 1, #options do
        local option = options[index]
        local button = CreateFrame("Button", nil, self.menu)
        button:SetHeight(28)
        button:SetPoint("TOPLEFT", 4, -4 - (index - 1) * 28)
        button:SetPoint("TOPRIGHT", -4, -4 - (index - 1) * 28)

        button.text = button:CreateFontString(nil, "OVERLAY")
        button.text:SetFont(Theme.font, 11, "OUTLINE")
        button.text:SetPoint("LEFT", 8, 0)
        button.text:SetText(option.name)
        button.text:SetTextColor(0.91, 0.94, 0.91, 1)

        button.highlight = button:CreateTexture(nil, "BACKGROUND")
        button.highlight:SetAllPoints()
        button.highlight:SetColorTexture(0.33, 0.45, 0.17, 0.20)
        button.highlight:Hide()

        button:SetScript("OnEnter", function() button.highlight:Show() end)
        button:SetScript("OnLeave", function() button.highlight:Hide() end)
        button:SetScript("OnClick", function()
            self.menu:Hide()
            if onSelect then onSelect(option.key) end
        end)

        self.options[#self.options + 1] = button
        height = height + 28
    end

    self.menu:SetHeight(height + 4)
    self:SetSelected(selectedKey, options)
end

function Dropdown:Close()
    if self.menu then self.menu:Hide() end
end

function Dropdown:SetSelected(selectedKey, options)
    for index = 1, #options do
        if options[index].key == selectedKey then
            self.frame.text:SetText(options[index].name)
            return
        end
    end
end

ns:RegisterModule("UI.Dropdown", Dropdown)
