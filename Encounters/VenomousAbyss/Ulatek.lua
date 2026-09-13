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

local function timedCall(key, ability, action, warning, voice, spellIDs, prepareSeconds, pressSeconds, actionTemplate, warningTemplate, iconSpellID)
    return {
        key = key,
        ability = ability,
        action = action,
        warning = warning,
        voice = voice,
        spellIDs = spellIDs,
        prepareSeconds = prepareSeconds,
        pressSeconds = pressSeconds,
        actionTemplate = actionTemplate,
        warningTemplate = warningTemplate,
        iconSpellID = iconSpellID,
    }
end

local waves = timedCall(
    "waves",
    "Caustic Waves",
    "Find safe gap; keep waves off eggs",
    "Caustic Waves: find the safe gap; keep waves off eggs.",
    "Waves",
    { 1292188 },
    7,
    4
)

local heart = timedCall(
    "heart",
    "Rage of the Shackled",
    "Burn exposed Heart; use planned cooldowns",
    "Heart exposed: burn it; use planned cooldowns.",
    "Heart",
    { 1286860 },
    7,
    4
)

local serpents = timedCall(
    "serpents",
    "Call of the Serpent",
    "Kill serpent adds fast",
    "Serpent adds: kill them fast.",
    "Adds",
    { 1300751 },
    6,
    3
)

local bite = timedCall(
    "bite",
    "Serpent's Bite",
    "Three assigned groups fully soak",
    "Serpent's Bite: fully soak all three targets, then spread.",
    "Soak",
    { 1295905 },
    8,
    5,
    "Melee {{bite_melee}}; Ranged {{bite_ranged}}; Healer {{bite_healer}}",
    "Serpent's Bite: Melee {{bite_melee}}; Ranged {{bite_ranged}}; Healer {{bite_healer}}. Fully soak, then spread."
)

local circling = timedCall(
    "circling",
    "Circling Prey",
    "Leave the breaking platform",
    "Circling Prey: leave the breaking platform.",
    "Move",
    { 1301510 },
    8,
    5
)

local function coils(action, warning, actionTemplate, warningTemplate)
    return timedCall(
        "coils",
        "Spectral Coils",
        action,
        warning,
        "Coils",
        { 1300530 },
        8,
        5,
        actionTemplate,
        warningTemplate
    )
end

local function incubation()
    return timedCall(
        "incubation",
        "Toxic Incubation",
        "Assigned group intercepts once each",
        "Incubation: assigned group take one hit each.",
        "Intercept",
        { 1299757 },
        7,
        4,
        "{{incubation_team}} intercept once each",
        "Incubation: {{incubation_team}} take one hit each.",
        1299759
    )
end

local function calls(coilCall, eggAction, eggWarning, eggActionTemplate, eggWarningTemplate, includeFangs, includeMythic)
    local result = {
        waves,
        coilCall,
        heart,
        manualCall(
            "warden",
            "Doomscale Warden",
            "Kill Warden before eggs",
            "Warden: kill first; eggs after protection is gone.",
            "Warden"
        ),
        manualCall("eggs", "Doomscale Eggs", eggAction, eggWarning, "Eggs", 1299650, eggActionTemplate, eggWarningTemplate),
        serpents,
    }

    if includeFangs then
        result[#result + 1] = manualCall(
            "fangs",
            "Grasping Fangs",
            "Break controlled pairs; wait for Blight Vein",
            "Fangs: break controlled pairs; wait for Blight Vein to clear.",
            "Fangs",
            1311611
        )
    end

    if includeMythic then
        result[#result + 1] = incubation()
    end

    result[#result + 1] = manualCall(
        "phase3",
        "Phase 3",
        "Execute final burn plan; move together",
        "Phase 3: execute the burn plan; move together.",
        "Final phase"
    )
    result[#result + 1] = bite
    result[#result + 1] = circling
    return result
end

Registry:Register({
    key = "ulatek",
    name = "Ula'tek",
    encounterID = 3492,
    strategyStatus = "12.1 live Blizzard hotfixes through 2026-09-10 + current Icy Veins/Ready Check Pull + DBM 12.1.9/BigWigs v424.8 source-reviewed 2026-09-13; selected exact-ID timing enabled; PASS-LIVE pending",
    profiles = {
        normal = {
            explanation = {
                "Caustic Waves: use the safe gap and never let a wave touch an egg.",
                "Spectral Coils: stack enough players in the active soak; full-raid soaking is safe on Normal.",
                "Rage of the Shackled exposes the Heart: swap immediately and burn the damage window.",
                "Phase 2: split to both side platforms; kill the Warden before using the planned Doomscale egg.",
                "Collect eggs safely, kill spawned serpents quickly and interrupt dangerous add casts.",
                "Phase 3: use three Serpent's Bite soak groups; stay in each circle until the soak completes, then spread.",
                "Caustic Waves return with gaps: move through a safe lane instead of trying to pass underneath.",
                "Circling Prey destroys the current platform: rotate off it before it breaks.",
            },
            calls = calls(
                coils("Stack in the active Coil", "Coils: stack in the active soak."),
                "Assigned handler uses planned egg",
                "Eggs: assigned handler use planned egg.",
                "{{egg_handler}} uses planned egg",
                "Eggs: {{egg_handler}} use planned egg.",
                false,
                false
            ),
        },
        heroic = {
            explanation = {
                "Caustic Waves: use the safe gap and keep every wave away from eggs.",
                "Spectral Coils: alternate the two assigned teams; at least 40% of the raid is needed for minimum damage.",
                "Rage of the Shackled exposes the Heart: swap immediately and burn the damage window.",
                "Phase 2: split to opposite side platforms; kill the Warden, then use the planned egg.",
                "Grasping Fangs targets three players per side: break controlled pairs and let Blight Vein clear between breaks.",
                "Intermission: continue the alternating Coil teams while collecting eggs and preparing for the platform split.",
                "Phase 3: fully soak all three Serpent's Bite targets with assigned groups, then spread for Volatile Purge.",
                "Circling Prey destroys the current platform: rotate off it before it breaks.",
            },
            calls = calls(
                coils(
                    "Assigned team soaks the active Coil",
                    "Coils: assigned team soak the active Coil.",
                    "{{rotation:coils}} soak the active Coil",
                    "Coils: {{rotation:coils}} soak the active Coil."
                ),
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
                "Spectral Coils: soak only with the assigned team; Soul Constrictor blocks immediate repeat soaking.",
                "Toxic Incubation: assigned interceptors take one hit each; Toxic Burn players do not take another hit.",
                "Hardened eggs must have their shield broken before the assigned carrier moves them.",
                "Egg carriers stay 3+ yards apart and use only the called side.",
                "Grasping Fangs breaks hit the raid: break controlled pairs and never chain multiple breaks together.",
                "Phase 3: fully soak all three Serpent's Bite targets, then spread for Volatile Purge.",
                "Caustic Waves must be crossed through safe gaps; swimming underneath is not a valid route.",
                "Circling Prey destroys the current platform: rotate off it before it breaks.",
            },
            calls = calls(
                coils(
                    "Assigned team soaks the active Coil",
                    "Coils: assigned team soak the active Coil.",
                    "{{rotation:coils}} soak the active Coil",
                    "Coils: {{rotation:coils}} soak the active Coil."
                ),
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
