local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function manualCall(key, ability, action, warning, voice, iconSpellID, actionTemplate, warningTemplate)
    return {
        key = key,
        ability = ability,
        action = action,
        warning = warning,
        voice = voice,
        timing = false,
        iconSpellID = iconSpellID,
        actionTemplate = actionTemplate,
        warningTemplate = warningTemplate,
    }
end

local function calls(coilAction, coilWarning, coilActionTemplate, coilWarningTemplate, eggAction, eggWarning, eggActionTemplate, eggWarningTemplate, includeFangs, includeMythic)
    local result = {
        manualCall("coils", "Spectral Coils", coilAction, coilWarning, "Coils", 1300530, coilActionTemplate, coilWarningTemplate),
        manualCall(
            "warden",
            "Doomscale Warden",
            "Kill Warden before eggs",
            "Warden: kill first; eggs after it dies.",
            "Warden",
            1298559
        ),
        manualCall("eggs", "Doomscale Eggs", eggAction, eggWarning, "Eggs", 1299650, eggActionTemplate, eggWarningTemplate),
        manualCall(
            "serpents",
            "Call of the Serpent",
            "Kill serpent adds fast",
            "Serpent adds: kill them fast.",
            "Adds",
            1300751
        ),
        manualCall(
            "heart",
            "Rage of the Shackled",
            "Burn exposed Heart",
            "Heart exposed: burn it.",
            "Heart",
            1286860
        ),
    }

    if includeFangs then
        result[#result + 1] = manualCall(
            "fangs",
            "Grasping Fangs",
            "Break one player at a time",
            "Fangs: break one player at a time.",
            "Fangs",
            1311611
        )
    end

    if includeMythic then
        result[#result + 1] = manualCall(
            "incubation",
            "Toxic Incubation",
            "Assigned group intercepts once each",
            "Incubation: assigned group take one hit each.",
            "Intercept",
            1299759,
            "{{incubation_team}} intercept once each",
            "Incubation: {{incubation_team}} take one hit each."
        )
    end

    result[#result + 1] = manualCall(
        "phase3",
        "Ula'tek's Ascension",
        "Bloodlust; move together",
        "Phase 3: Bloodlust; move together.",
        "Bloodlust",
        1286905
    )
    result[#result + 1] = manualCall(
        "demolish",
        "Demolish",
        "Move together to safe area",
        "Demolish: move together to safe area.",
        "Move",
        1301510
    )
    return result
end

Registry:Register({
    key = "ulatek",
    name = "Ula'tek",
    encounterID = 3492,
    strategyStatus = "12.1 Journal + current Wowhead/Warcraft Wiki + DBM/BigWigs source-reviewed 2026-08-28; current bossmod routing is still evolving; live validation required; timing remains manual",
    profiles = {
        normal = {
            explanation = {
                "Green venom waves: dodge them and never let them touch eggs.",
                "Spectral Coils: everyone stacks tightly at the Square soak marker.",
                "Heart becomes exposed: switch immediately and burn it.",
                "Phase 2: kill the Warden before anyone touches an egg.",
                "Warden dies: only the assigned handler uses the planned egg.",
                "Serpent adds spawn: kill them quickly.",
                "Phase 3: Bloodlust and move together as Demolish removes safe space.",
            },
            calls = calls(
                "Stack at Square",
                "Coils: stack at Square.",
                nil,
                nil,
                "Assigned handler uses egg",
                "Eggs: assigned handler use planned egg.",
                "{{egg_handler}} uses planned egg",
                "Eggs: {{egg_handler}} use planned egg.",
                false,
                false
            ),
        },
        heroic = {
            explanation = {
                "Grasping Fangs trap players: break them free one at a time.",
                "Petrifying Sting targets a player: everyone else clears 10+ yards.",
                "Birthlings stack Poisonous Bite: kill them quickly before stacks build.",
            },
            calls = calls(
                "Stack at Square",
                "Coils: stack at Square.",
                nil,
                nil,
                "Assigned handler uses egg",
                "Eggs: assigned handler use planned egg.",
                "{{egg_handler}} uses planned egg",
                "Eggs: {{egg_handler}} use planned egg.",
                true,
                false
            ),
        },
        mythic = {
            explanation = {
                "Spectral Coils: soak only when your Coil group is called.",
                "Toxic Incubation: assigned interceptors take one hit each.",
                "Toxic Burn on you: do not intercept another Incubation hit.",
                "Hardened egg: break its shield before the carrier moves it.",
                "Egg carriers stay 3+ yards apart and use only the called side.",
                "Fang breaks now hit the whole raid: never break multiple together.",
            },
            calls = calls(
                "Assigned group stacks at Square",
                "Coils: assigned group stack at Square.",
                "{{rotation:coils}} stack at Square",
                "Coils: {{rotation:coils}} stack at Square.",
                "Use called egg side",
                "Eggs: use called side; carriers stay apart.",
                "Triangle {{egg_left}}; Cross {{egg_right}}",
                "Eggs: Triangle {{egg_left}}; Cross {{egg_right}}; use called side.",
                true,
                true
            ),
        },
    },
})
