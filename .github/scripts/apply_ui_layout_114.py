from pathlib import Path


def replace_once(text, old, new, label):
    if old not in text:
        raise SystemExit(f"Expected block not found: {label}")
    return text.replace(old, new, 1)


manager_path = Path("UI/BossMacroManager.lua")
manager = manager_path.read_text(encoding="utf-8")

manager = replace_once(
    manager,
    '''local function shortName(name)\n    name = tostring(name or "")\n    if #name <= 10 then return name end\n    return name:sub(1, 9) .. "…"\nend\n''',
    '''local function shortName(name)\n    name = tostring(name or "")\n    if #name <= 7 then return name end\n    return name:sub(1, 6) .. "…"\nend\n''',
    "compact macro names",
)

manager = replace_once(
    manager,
    '''local function removePortrait(frame)\n    if not frame then return end\n    if type(ButtonFrameTemplate_HidePortrait) == "function" then\n        pcall(ButtonFrameTemplate_HidePortrait, frame)\n    elseif type(PortraitFrameTemplate_HidePortrait) == "function" then\n        pcall(PortraitFrameTemplate_HidePortrait, frame)\n    end\n    hideRegion(frame.PortraitContainer)\n    hideRegion(frame.portrait)\n    hideRegion(frame.Portrait)\n    if frame.PortraitContainer and frame.PortraitContainer.portrait then\n        hideRegion(frame.PortraitContainer.portrait)\n    end\n    if frame.TitleText then\n        frame.TitleText:ClearAllPoints()\n        frame.TitleText:SetPoint("TOP", frame, "TOP", 0, -6)\n    end\nend\n''',
    '''local function removePortrait(frame)\n    if not frame then return end\n    if type(ButtonFrameTemplate_HidePortrait) == "function" then\n        pcall(ButtonFrameTemplate_HidePortrait, frame)\n    elseif type(PortraitFrameTemplate_HidePortrait) == "function" then\n        pcall(PortraitFrameTemplate_HidePortrait, frame)\n    end\n    hideRegion(frame.PortraitContainer)\n    hideRegion(frame.portrait)\n    hideRegion(frame.Portrait)\n    if frame.PortraitContainer then\n        hideRegion(frame.PortraitContainer.portrait)\n        hideRegion(frame.PortraitContainer.CircleMask)\n    end\n\n    -- Modern Blizzard ButtonFrameTemplate owns the title through TitleContainer.\n    -- Keep the template's TitleText anchors intact and move the container to the\n    -- same no-portrait margins Blizzard uses instead of pinning text to the frame.\n    if frame.TitleContainer then\n        frame.TitleContainer:ClearAllPoints()\n        frame.TitleContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 30, -1)\n        frame.TitleContainer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -1)\n    end\nend\n\nlocal function setFrameTitle(frame, text)\n    if not frame then return end\n    if type(frame.SetTitle) == "function" then\n        frame:SetTitle(text)\n    elseif frame.TitleText then\n        frame.TitleText:SetText(text)\n    end\nend\n''',
    "Blizzard title container handling",
)

manager = manager.replace('if frame.TitleText then frame.TitleText:SetText("Advanced Timer Matching") end', 'setFrameTitle(frame, "Advanced Timer Matching")')
manager = manager.replace('if frame.TitleText then frame.TitleText:SetText("Raid Leader Tactics") end', 'setFrameTitle(frame, "Boss Tactics")')
manager = manager.replace('if frame.TitleText then frame.TitleText:SetText("Raid Lead Assist — Boss Macros") end', 'setFrameTitle(frame, "Raid Lead Assist — Boss Macros")')

manager = replace_once(
    manager,
    '''    local context = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")\n    context:SetPoint("TOPLEFT", 18, -54)\n    context:SetPoint("TOPRIGHT", -18, -54)\n    context:SetJustifyH("LEFT")\n    frame.Context = context\n\n    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")\n    hint:SetPoint("TOPLEFT", context, "BOTTOMLEFT", 0, -6)\n    hint:SetPoint("TOPRIGHT", context, "BOTTOMRIGHT", 0, -6)\n    hint:SetJustifyH("LEFT")\n    hint:SetText("Use this for mechanics, assignments, interrupts, dispels, defensives, movement and raid-leader callouts.")\n\n    local background = CreateFrame("Frame", nil, frame, "TooltipBackdropTemplate")\n    background:SetPoint("TOPLEFT", 18, -100)\n    background:SetPoint("BOTTOMRIGHT", -18, 52)\n''',
    '''    local contentAnchor = frame.Inset or frame\n\n    local context = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")\n    context:SetPoint("TOPLEFT", contentAnchor, "TOPLEFT", 14, -12)\n    context:SetPoint("TOPRIGHT", contentAnchor, "TOPRIGHT", -14, -12)\n    context:SetJustifyH("LEFT")\n    frame.Context = context\n\n    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")\n    hint:SetPoint("TOPLEFT", context, "BOTTOMLEFT", 0, -5)\n    hint:SetPoint("TOPRIGHT", context, "BOTTOMRIGHT", 0, -5)\n    hint:SetJustifyH("LEFT")\n    hint:SetText("Use this for mechanics, assignments, interrupts, dispels, defensives, movement and raid-leader callouts.")\n\n    local background = CreateFrame("Frame", nil, frame, "TooltipBackdropTemplate")\n    background:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -8)\n    background:SetPoint("BOTTOMRIGHT", contentAnchor, "BOTTOMRIGHT", -14, 14)\n''',
    "tactics content inside inset",
)

manager = replace_once(
    manager,
    '''        button:SetSize(44, 44)\n        local col = (index - 1) % columns\n        local row = math.floor((index - 1) / columns)\n        button:SetPoint("TOPLEFT", 20 + (col * 62), -10 - (row * 50))\n''',
    '''        button:SetSize(40, 40)\n        local col = (index - 1) % columns\n        local row = math.floor((index - 1) / columns)\n        button:SetPoint("TOPLEFT", 18 + (col * 64), -8 - (row * 54))\n''',
    "macro grid spacing",
)
manager = manager.replace('selected:SetSize(56, 56)', 'selected:SetSize(50, 50)', 1)
manager = replace_once(
    manager,
    '''        local name = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")\n        name:SetPoint("BOTTOM", 0, 2)\n        name:SetWidth(58)\n        name:SetWordWrap(false)\n        name:SetJustifyH("CENTER")\n        button.Name = name\n''',
    '''        local name = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")\n        name:SetPoint("TOP", button, "BOTTOM", 0, -1)\n        name:SetWidth(54)\n        name:SetWordWrap(false)\n        name:SetJustifyH("CENTER")\n        button.Name = name\n''',
    "macro labels below icons",
)

manager = replace_once(
    manager,
    '''    local abilityLabel = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")\n    abilityLabel:SetPoint("TOPLEFT", 8, -74)\n    abilityLabel:SetText("Boss Ability:")\n\n    local abilityDropdown = CreateFrame("Frame", "RaidLeadAssistAbilityDropdown", editor, "UIDropDownMenuTemplate")\n    abilityDropdown:SetPoint("TOPLEFT", abilityLabel, "BOTTOMLEFT", -18, 6)\n    UIDropDownMenu_SetWidth(abilityDropdown, 210)\n    frame.AbilityDropdown = abilityDropdown\n\n    local advancedButton = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")\n    advancedButton:SetSize(92, 22)\n    advancedButton:SetPoint("TOPRIGHT", 0, -86)\n    advancedButton:SetText("Advanced")\n    advancedButton:SetScript("OnClick", function() self:OpenAdvanced() end)\n    frame.AdvancedButton = advancedButton\n\n    local dragButton = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")\n    dragButton:SetSize(118, 22)\n    dragButton:SetPoint("TOPRIGHT", 0, -114)\n    dragButton:SetText("To Action Bar")\n''',
    '''    local abilityRow = CreateFrame("Frame", nil, editor)\n    abilityRow:SetPoint("TOPLEFT", 0, -70)\n    abilityRow:SetPoint("TOPRIGHT", 0, -70)\n    abilityRow:SetHeight(32)\n\n    local abilityLabel = abilityRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")\n    abilityLabel:SetPoint("LEFT", abilityRow, "LEFT", 8, 0)\n    abilityLabel:SetWidth(74)\n    abilityLabel:SetJustifyH("LEFT")\n    abilityLabel:SetText("Boss Ability:")\n\n    local abilityDropdown = CreateFrame("Frame", "RaidLeadAssistAbilityDropdown", abilityRow, "UIDropDownMenuTemplate")\n    abilityDropdown:SetPoint("LEFT", abilityLabel, "RIGHT", -12, -1)\n    UIDropDownMenu_SetWidth(abilityDropdown, 178)\n    frame.AbilityDropdown = abilityDropdown\n\n    local advancedButton = CreateFrame("Button", nil, abilityRow, "UIPanelButtonTemplate")\n    advancedButton:SetSize(92, 22)\n    advancedButton:SetPoint("RIGHT", abilityRow, "RIGHT", 0, 0)\n    advancedButton:SetText("Advanced")\n    advancedButton:SetScript("OnClick", function() self:OpenAdvanced() end)\n    frame.AdvancedButton = advancedButton\n\n    local dragButton = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")\n    dragButton:SetSize(118, 22)\n    dragButton:SetPoint("TOP", advancedButton, "BOTTOM", 0, -6)\n    dragButton:SetText("To Action Bar")\n''',
    "boss ability row",
)

manager_path.write_text(manager, encoding="utf-8")

picker_path = Path("UI/IconPicker.lua")
picker = picker_path.read_text(encoding="utf-8")
picker = replace_once(
    picker,
    '''local function removePortrait(frame)\n    if not frame then return end\n    if type(ButtonFrameTemplate_HidePortrait) == "function" then\n        pcall(ButtonFrameTemplate_HidePortrait, frame)\n    elseif type(PortraitFrameTemplate_HidePortrait) == "function" then\n        pcall(PortraitFrameTemplate_HidePortrait, frame)\n    end\n    hideRegion(frame.PortraitContainer)\n    hideRegion(frame.portrait)\n    hideRegion(frame.Portrait)\n    if frame.PortraitContainer and frame.PortraitContainer.portrait then\n        hideRegion(frame.PortraitContainer.portrait)\n    end\n    if frame.TitleText then\n        frame.TitleText:SetText("Change Name/Icon")\n        frame.TitleText:ClearAllPoints()\n        frame.TitleText:SetPoint("TOP", frame, "TOP", 0, -6)\n    end\nend\n''',
    '''local function removePortrait(frame)\n    if not frame then return end\n    if type(ButtonFrameTemplate_HidePortrait) == "function" then\n        pcall(ButtonFrameTemplate_HidePortrait, frame)\n    elseif type(PortraitFrameTemplate_HidePortrait) == "function" then\n        pcall(PortraitFrameTemplate_HidePortrait, frame)\n    end\n    hideRegion(frame.PortraitContainer)\n    hideRegion(frame.portrait)\n    hideRegion(frame.Portrait)\n    if frame.PortraitContainer then\n        hideRegion(frame.PortraitContainer.portrait)\n        hideRegion(frame.PortraitContainer.CircleMask)\n    end\n    if frame.TitleContainer then\n        frame.TitleContainer:ClearAllPoints()\n        frame.TitleContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 30, -1)\n        frame.TitleContainer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -1)\n    end\n    if type(frame.SetTitle) == "function" then\n        frame:SetTitle("Change Name/Icon")\n    elseif frame.TitleText then\n        frame.TitleText:SetText("Change Name/Icon")\n    end\nend\n''',
    "icon picker title handling",
)
picker_path.write_text(picker, encoding="utf-8")

toc_path = Path("RaidLeadAssist.toc")
toc = toc_path.read_text(encoding="utf-8")
toc = replace_once(toc, "## Version: 1.1.3", "## Version: 1.1.4", "toc version")
toc_path.write_text(toc, encoding="utf-8")
