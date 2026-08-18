local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function manualCall(key, ability, action, warning, voice, iconSpellID)
    return {
        key = key,
        ability = ability,
        action = action,
        warning = warning,
        voice = voice,
        timing = false,
        iconSpellID = iconSpellID,
    }
end

local function calls(coilAction, coilWarning, eggAction, eggWarning, includeFangs, includeMythic)
    local result = {
        manualCall("coils", "Spectral Coils", coilAction, coilWarning, "Coils", 1300530),
        manualCall(
            "warden",
            "Doomscale Warden",
            "Kill Warden first; eggs after it dies",
            "Warden first: kill it; eggs only after it dies.",
            "Warden",
            1298559
        ),
        manualCall("eggs", "Doomscale Eggs", eggAction, eggWarning, "Eggs", 1299650),
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
            "Switch and burn the exposed Heart",
            "Heart exposed: switch and burn it.",
            "Heart",
            1286860
        ),
    }

    if includeFangs then
        result[#result + 1] = manualCall(
            "fangs",
            "Grasping Fangs",
            "Break one player free at a time",
            "Fangs: break one player free at a time.",
            "Fangs",
            1311611
        )
    end

    if includeMythic then
        result[#result + 1] = manualCall(
            "incubation",
            "Toxic Incubation",
            "Each interceptor takes one hit",
            "Toxic Incubation: each interceptor takes one hit.",
            "Intercept",
            1299759
        )
    end

    result[#result + 1] = manualCall(
        "phase3",
        "Ula'tek's Ascension",
        "Bloodlust; move together",
        "Phase 3: Bloodlust and move together.",
        "Bloodlust",
        1286905
    )
    result[#result + 1] = manualCall(
        "demolish",
        "Demolish",
        "Move together to the next safe area",
        "Demolish: move together to the next safe area.",
        "Move",
        1301510
    )
    return result
end

Registry:Register({
    key = "ulatek",
    name = "Ula'tek",
    encounterID = 3492,
    strategyStatus = "12.1 Journal + current Wowhead/Warcraft Wiki + DBM/BigWigs source-reviewed 2026-08-19; final boss was not publicly PTR-tested; live validation required; timing remains manual",
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
                "Spectral Coils: stack at Square.",
                "Handler uses the planned egg after Warden",
                "Warden dead: handler use the planned egg.",
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
                "Spectral Coils: stack at Square.",
                "Handler uses the planned egg after Warden",
                "Warden dead: handler use the planned egg.",
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
                "Egg carriers stay 3+ yards apart and use only the planned side.",
                "Fang breaks now hit the whole raid: never break multiple together.",
            },
            calls = calls(
                "Called group stacks at Square",
                "Spectral Coils: called group stack at Square.",
                "Use planned side; carriers stay 3+ yards apart",
                "Eggs: use the planned side; carriers stay 3+ yards apart.",
                true,
                true
            ),
        },
    },
})
