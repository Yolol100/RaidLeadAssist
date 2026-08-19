local _, ns = ...

local Theme = ns:GetModule("UI.Theme")
local SetupRegistry = ns:GetModule("Encounters.SetupRegistry")

local SetupCard = {}
SetupCard.__index = SetupCard

local function setBackdrop(frame, color)
    frame:SetBackdropColor(color[1], color[2], color[3], color[4] or 1)
end

local function iconTexture(icon)
    return ("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%d:14:14|t"):format(icon)
end

function SetupCard:Create(parent)
    local instance = setmetatable({}, SetupCard)

    local frame = CreateFrame("Button", nil, parent, "BackdropTemplate")
    frame:SetHeight(56)
    frame:SetBackdrop({ bgFile = Theme.texture, edgeFile = Theme.texture, edgeSize = 1 })
    setBackdrop(frame, Theme.colors.surface)
    frame:SetBackdropBorderColor(Theme.colors.borderStrong[1], Theme.colors.borderStrong[2], Theme.colors.borderStrong[3], 1)

    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFont(Theme.font, 10, "OUTLINE")
    frame.title:SetPoint("TOPLEFT", 10, -7)
    frame.title:SetText("PRE-PULL SETUP")
    frame.title:SetTextColor(Theme.colors.venom[1], Theme.colors.venom[2], Theme.colors.venom[3], 1)

    frame.state = frame:CreateFontString(nil, "OVERLAY")
    frame.state:SetFont(Theme.font, 9, "OUTLINE")
    frame.state:SetPoint("TOPRIGHT", -10, -7)
    frame.state:SetJustifyH("RIGHT")

    frame.summary = frame:CreateFontString(nil, "OVERLAY")
    frame.summary:SetFont(Theme.font, 9, "OUTLINE")
    frame.summary:SetPoint("BOTTOMLEFT", 10, 8)
    frame.summary:SetPoint("RIGHT", -10, 0)
    frame.summary:SetJustifyH("LEFT")
    frame.summary:SetTextColor(Theme.colors.text[1], Theme.colors.text[2], Theme.colors.text[3], 1)

    frame:SetScript("OnEnter", function()
        local layout = instance.layout
        if not layout then return end
        frame:SetBackdropBorderColor(Theme.colors.venom[1], Theme.colors.venom[2], Theme.colors.venom[3], 1)
        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
        GameTooltip:SetText("Pre-pull Setup", 1, 1, 1)
        GameTooltip:AddLine(layout.summary, 0.82, 0.86, 0.82, true)

        if #layout.markers > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Markers", 1, 1, 1)
            for index = 1, #layout.markers do
                local marker = layout.markers[index]
                local prefix = marker.kind == "world" and "World" or "Target"
                local markerName = SetupRegistry:GetMarkerName(marker.icon) or tostring(marker.icon)
                GameTooltip:AddLine(("%s %s %s — %s"):format(iconTexture(marker.icon), prefix, markerName, marker.label),
                    0.73, 0.91, 0.20, true)
                GameTooltip:AddLine(marker.purpose, 0.68, 0.74, 0.69, true)
            end
        end

        if #layout.checks > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Raid Leader Prep", 1, 1, 1)
            for index = 1, #layout.checks do
                GameTooltip:AddLine("• " .. layout.checks[index], 0.68, 0.74, 0.69, true)
            end
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(instance.ready and "Click to mark setup as CHECK again." or "Click READY when markers and raidleader prep are complete.",
            0.55, 0.63, 0.58, true)
        GameTooltip:Show()
    end)

    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
        frame:SetBackdropBorderColor(Theme.colors.borderStrong[1], Theme.colors.borderStrong[2], Theme.colors.borderStrong[3], 1)
    end)

    frame:SetScript("OnClick", function()
        if instance.onToggle then instance.onToggle() end
    end)

    instance.frame = frame
    return instance
end

function SetupCard:SetLayout(layout, ready, onToggle)
    self.layout = layout
    self.ready = ready == true
    self.onToggle = onToggle

    local world, target = 0, 0
    for index = 1, #layout.markers do
        if layout.markers[index].kind == "world" then world = world + 1 else target = target + 1 end
    end

    local parts = {}
    if world > 0 then parts[#parts + 1] = world .. " world marker" .. (world == 1 and "" or "s") end
    if target > 0 then parts[#parts + 1] = target .. " target marker" .. (target == 1 and "" or "s") end
    if #layout.checks > 0 then parts[#parts + 1] = #layout.checks .. " prep step" .. (#layout.checks == 1 and "" or "s") end

    self.frame.summary:SetText(table.concat(parts, " · ") .. " · hover for details")
    if self.ready then
        self.frame.state:SetText("READY")
        self.frame.state:SetTextColor(Theme.colors.success[1], Theme.colors.success[2], Theme.colors.success[3], 1)
        setBackdrop(self.frame, Theme.colors.called)
    else
        self.frame.state:SetText("CHECK")
        self.frame.state:SetTextColor(Theme.colors.error[1], Theme.colors.error[2], Theme.colors.error[3], 1)
        setBackdrop(self.frame, Theme.colors.surface)
    end
    self.frame:Show()
end

function SetupCard:Hide()
    self.layout = nil
    self.onToggle = nil
    self.frame:Hide()
end

ns:RegisterModule("UI.SetupCard", SetupCard)
