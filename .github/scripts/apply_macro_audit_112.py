from pathlib import Path
import re


def read(path):
    return Path(path).read_text(encoding="utf-8")


def write(path, text):
    Path(path).write_text(text, encoding="utf-8")


def replace_once(text, old, new, label):
    if old not in text:
        raise SystemExit(f"Could not find expected block: {label}")
    return text.replace(old, new, 1)


# Sszorak: the requested Mythic raid-leader plan is one single soak-order macro.
p = "Encounters/VenomousAbyss/Sszorak.lua"
text = read(p)
replacement = '''local mythicCalls = {
    {
        key = "soak_order",
        ability = "Soak Order",
        action = "Soak Raid -> Tank -> Tank",
        warning = "Soak Raid -> Tank -> Tank",
        voice = "Soak order",
        spellIDs = { 1277025, 1285430 },
        iconSpellID = 1277025,
        prepareSeconds = 7,
        pressSeconds = 4,
    },
}

Registry:Register({'''
text, count = re.subn(r"local mythicCalls = \{.*?\n\}\n\nRegistry:Register\(\{", replacement, text, count=1, flags=re.S)
if count != 1:
    raise SystemExit("Could not replace Sszorak Mythic call set")
text = re.sub(
    r'    strategyStatus = ".*?",\n    profiles = \{',
    '    strategyStatus = "Heroic mechanics retained; Mythic raid-leader macro set intentionally reduced to one soak-order call (Raid -> Tank -> Tank) while the remaining mechanics stay in tactics; PASS-LIVE pending",\n    profiles = {',
    text,
    count=1,
)
write(p, text)

# Entombed Sentinels: current live spell icons for manual mechanics.
p = "Encounters/VenomousAbyss/Sentinels.lua"
text = read(p)
text = replace_once(text,
    '        voice = "Soak droplets",\n        timing = false,\n',
    '        voice = "Soak droplets",\n        timing = false,\n        iconSpellID = 1284434,\n',
    "Sentinels Toxic Droplets icon")
text = replace_once(text,
    '        key = "return_lines",\n        ability = "Returning Venom",',
    '        key = "living_venom",\n        ability = "Living Venom",',
    "Sentinels Living Venom canonical call")
text = replace_once(text,
    '        voice = "Dodge return lines",\n        timing = false,\n',
    '        voice = "Dodge return lines",\n        timing = false,\n        iconSpellID = 1284207,\n',
    "Sentinels Living Venom icon")
text = replace_once(text,
    '        voice = "Tanks swap bosses",\n        timing = false,\n        uiGroup = "shared",\n',
    '        voice = "Tanks swap bosses",\n        timing = false,\n        iconSpellID = 1284588,\n        uiGroup = "shared",\n',
    "Sentinels post-Stasis icon")
write(p, text)

# Lost Explorers: canonical live mechanic names/icons for the manual Heroic calls.
p = "Encounters/VenomousAbyss/Explorers.lua"
text = read(p)
text = replace_once(text,
    '        key = "mushroom",\n        ability = "Gebbo Wave",\n        action = "USE MUSHROOM FOR WAVE",\n        warning = "USE MUSHROOM FOR WAVE",\n        voice = "Use mushroom",\n        timing = false,\n',
    '        key = "explosive_surprise",\n        ability = "Explosive Surprise",\n        action = "USE MUSHROOM FOR WAVE",\n        warning = "USE MUSHROOM FOR WAVE",\n        voice = "Use mushroom",\n        timing = false,\n        iconSpellID = 1297625,\n',
    "Explorers Explosive Surprise")
text = replace_once(text,
    '        key = "elements",\n        ability = "Frostfire",\n        action = "SPREAD FIRE/FROST — CLEAR WITH OPPOSITE",\n        warning = "SPREAD FIRE/FROST — CLEAR WITH OPPOSITE",\n        voice = "Spread and clear opposite",\n        timing = false,\n',
    '        key = "frostfire_volley",\n        ability = "Frostfire Volley",\n        action = "SPREAD FIRE/FROST — CLEAR WITH OPPOSITE",\n        warning = "SPREAD FIRE/FROST — CLEAR WITH OPPOSITE",\n        voice = "Spread and clear opposite",\n        timing = false,\n        iconSpellID = 1295886,\n',
    "Explorers Frostfire Volley")
write(p, text)

# Vashnik: remove generic question-mark icons from Mythic manual mechanics.
p = "Encounters/VenomousAbyss/Vashnik.lua"
text = read(p)
text = replace_once(text,
    '    "Fire adds: Skull, wait, then Cross.",\n    "Stagger fire adds"\n)',
    '    "Fire adds: Skull, wait, then Cross.",\n    "Stagger fire adds", 1305902\n)',
    "Vashnik Burning Venom icon")
text = replace_once(text,
    '    "Blood circle: several teammates stack for healing.",\n    "Stack blood circle"\n)',
    '    "Blood circle: several teammates stack for healing.",\n    "Stack blood circle", 1299941\n)',
    "Vashnik Siphoning Infection icon")
text = replace_once(text,
    '    "Tumor exposed: switch and kill.",\n    "Kill tumors"\n)',
    '    "Tumor exposed: switch and kill.",\n    "Kill tumors", 1304437\n)',
    "Vashnik Malignant Tumor icon")
write(p, text)

# Twin Fangs: Tainted Blood live mechanic icon.
p = "Encounters/VenomousAbyss/TwinFangs.lua"
text = read(p)
text = replace_once(text,
    '        warning = "Blood founts: heal every one to full.", voice = "Heal founts", timing = false,\n',
    '        warning = "Blood founts: heal every one to full.", voice = "Heal founts", timing = false, iconSpellID = 1310099,\n',
    "Twin Fangs Tainted Blood icon")
write(p, text)

# Coiled Altar: manual intermission gets a real Soulbinding icon.
p = "Encounters/VenomousAbyss/CoiledAltar.lua"
text = read(p)
text = replace_once(text,
    '    warning = "Intermission: Bloodlust, burn Zul\'jan; stagger fragment stops.", voice = "Bloodlust", timing = false,\n',
    '    warning = "Intermission: Bloodlust, burn Zul\'jan; stagger fragment stops.", voice = "Bloodlust", timing = false,\n    iconSpellID = 1304032,\n',
    "Coiled Altar Soulbinding icon")
write(p, text)

# Ula'tek: manual Warden/final-phase entries should not show a question mark.
p = "Encounters/VenomousAbyss/Ulatek.lua"
text = read(p)
text = replace_once(text,
    '        manualCall("warden", "Doomscale Warden", "Kill Warden before eggs",\n            "Warden: kill first; eggs after protection is gone.", "Warden"),',
    '        manualCall("warden", "Doomscale Warden", "Kill Warden before eggs",\n            "Warden: kill first; eggs after protection is gone.", "Warden", 1302950),',
    "Ulatek Warden icon")
text = replace_once(text,
    '    result[#result + 1] = manualCall("phase3", "Phase 3", "Execute final burn plan",\n        "Phase 3: execute the final burn plan.", "Final phase")',
    '    result[#result + 1] = manualCall("phase3", "Phase 3", "Execute final burn plan",\n        "Phase 3: execute the final burn plan.", "Final phase", 1301510)',
    "Ulatek Phase 3 icon")
write(p, text)

# Reconcile registry-backed defaults while preserving truly manual/user-created macros.
p = "Services/BossMacroService.lua"
text = read(p)
marker = '''local function addCallsFromProfile(service, boss, encounter, difficultyKey)
    local target = ensureDifficultyProfile(boss, difficultyKey)
    local profile = Registry:GetProfile(encounter.key, difficultyKey)
    if not profile or type(profile.calls) ~= "table" then return end

    local seen = {}
    for _, macro in ipairs(target.macros) do
        if type(macro) == "table" and type(macro.sourceCallKey) == "string" then
            seen[macro.sourceCallKey] = true
        end
    end

    for index = 1, #profile.calls do
        local call = profile.calls[index]
        if call and type(call.key) == "string" and not seen[call.key] then
            seen[call.key] = true
            target.macros[#target.macros + 1] = macroFromCall(service, encounter, difficultyKey, call)
        end
    end
end
'''
if marker not in text:
    raise SystemExit("Could not find addCallsFromProfile block")
sync_block = marker + '''
local function reconcileCallsFromProfile(service, boss, encounter, difficultyKey)
    local target = ensureDifficultyProfile(boss, difficultyKey)
    local profile = Registry:GetProfile(encounter.key, difficultyKey)
    if not profile or type(profile.calls) ~= "table" then return end

    local callsByKey = type(profile.callsByKey) == "table" and profile.callsByKey or {}
    local reconciled = {}
    for _, macro in ipairs(target.macros) do
        if type(macro) == "table" then
            local sourceKey = type(macro.sourceCallKey) == "string" and macro.sourceCallKey or nil
            if not sourceKey then
                reconciled[#reconciled + 1] = macro
            else
                local call = callsByKey[sourceKey]
                if call then
                    macro.spellIDs = copyArray(call.spellIDs)
                    macro.timerNames = copyArray(call.timerNames)
                    local iconSpellID = Util.ToNumericID(call.iconSpellID) or Util.ToNumericID(macro.spellIDs[1])
                    if macro.iconMode ~= "custom" then
                        macro.iconSpellID = iconSpellID
                        macro.iconMode = "ability"
                        macro.customIcon = nil
                    end
                    macro.timingEnabled = call.timing ~= false
                    local prepare, press = Constants.GetCallTiming(call, service.database.timingLead)
                    macro.prepareSeconds = prepare
                    macro.pressSeconds = press
                    reconciled[#reconciled + 1] = macro
                elseif tonumber(macro.id) then
                    service.database.pendingMacroSync[tostring(macro.id)] = "delete"
                end
            end
        end
    end
    target.macros = reconciled
    addCallsFromProfile(service, boss, encounter, difficultyKey)
end
'''
text = text.replace(marker, sync_block, 1)
text = replace_once(text,
    '''                    for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
                        addCallsFromProfile(self, boss, encounter, difficultyKey)
                    end
''',
    '''                    for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
                        reconcileCallsFromProfile(self, boss, encounter, difficultyKey)
                    end
''',
    "default macro reconciliation call")
write(p, text)

# UI: improve label readability, tooltips and stable right-side action anchoring.
p = "UI/BossMacroManager.lua"
text = read(p)
text = replace_once(text,
    'local function shortName(name)\n    name = tostring(name or "")\n    if #name <= 8 then return name end\n    return name:sub(1, 7) .. "…"\nend\n',
    'local function shortName(name)\n    name = tostring(name or "")\n    if #name <= 10 then return name end\n    return name:sub(1, 9) .. "…"\nend\n',
    "macro short labels")
text = replace_once(text,
    '    newBoss:SetPoint("TOPLEFT", 280, -51)\n',
    '    newBoss:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -106, -51)\n',
    "New boss relative anchor")
text = replace_once(text,
    '        selected:SetSize(62, 62)\n',
    '        selected:SetSize(56, 56)\n',
    "macro selection border")
text = replace_once(text,
    '        name:SetWidth(50)\n        name:SetJustifyH("CENTER")\n        button.Name = name\n\n        button:SetScript("OnClick", function(btn) if btn.macroId then self:SelectMacro(btn.macroId) end end)\n',
    '''        name:SetWidth(58)
        name:SetWordWrap(false)
        name:SetJustifyH("CENTER")
        button.Name = name

        button:SetScript("OnEnter", function(btn)
            if not btn.macroId or not GameTooltip then return end
            local macro = BossMacros:FindMacroById(btn.macroId)
            if not macro then return end
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText(macro.name or "Macro", 1, 0.82, 0)
            if type(macro.body) == "string" and macro.body ~= "" then
                GameTooltip:AddLine(macro.body, 1, 1, 1, true)
            end
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        button:SetScript("OnClick", function(btn) if btn.macroId then self:SelectMacro(btn.macroId) end end)
''',
    "macro tooltip and width")
write(p, text)

# Version and validation guardrails.
p = "RaidLeadAssist.toc"
text = read(p).replace("## Version: 1.1.1", "## Version: 1.1.2", 1)
write(p, text)

p = ".github/workflows/validation.yml"
text = read(p)
text = text.replace("grep -q '^## Version: 1.1.1$' RaidLeadAssist.toc", "grep -q '^## Version: 1.1.2$' RaidLeadAssist.toc", 1)
text = text.replace(
    "          test ! -e .github/workflows/apply-ui-polish-1.1.1.yml\n",
    "          test ! -e .github/workflows/apply-ui-polish-1.1.1.yml\n          test ! -e .github/workflows/apply-macro-audit-1.1.2.yml\n          test ! -e .github/scripts/apply_macro_audit_112.py\n",
    1,
)
text = text.replace(
    "          grep -q 'ButtonFrameTemplate_HidePortrait' UI/IconPicker.lua\n",
    "          grep -q 'ButtonFrameTemplate_HidePortrait' UI/IconPicker.lua\n          grep -q 'reconcileCallsFromProfile' Services/BossMacroService.lua\n          grep -q 'Soak Raid -> Tank -> Tank' Encounters/VenomousAbyss/Sszorak.lua\n",
    1,
)
write(p, text)
