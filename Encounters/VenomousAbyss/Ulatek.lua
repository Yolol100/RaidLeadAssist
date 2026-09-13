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
    "Use safe gap; keep waves off eggs",
    "Waves: use safe gap; keep waves off eggs.",
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
    "Kill priority serpent adds; stop casts",
    "Serpent adds: kill priority adds and stop dangerous casts.",
    "Adds",
    { 1300751 },
    6,
    3
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

local function bite(mythic)
    if mythic then
        return timedCall(
            "bite",
            "Serpent's Bite",
            "Meet helpers; Purge out; dodge waves",
            "Bite: leech; Purge 7+ yards out; dodge waves.",
            "Bite",
            { 1295905 },
            8,
            5
        )
    end

    return timedCall(
        "bite",
        "Serpent's Bite",
        "Meet helpers; Purge helpers move out",
        "Bite: leech within 15s; Purge move 7+ yards out.",
        "Bite",
        { 1295905 },
        8,
        5
    )
end

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
            "Break one tether; wait for Blight Vein",
            "Fangs: break one tether; wait for Blight Vein.",
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
        "Bloodlust; execute final burn plan",
        "Phase 3: Bloodlust; execute the final burn plan.",
        "Bloodlust"
    )
    result[#result + 1] = bite(includeMythic)
    result[#result + 1] = circling
    return result
end

Registry:Register({
    key = "ulatek",
    name = "Ula'tek",
    encounterID = 3492,
    strategyStatus = "12.1 live Blizzard hotfixes through 2026-09-10 + current Wowhead/Icy Veins/Method/RWF + DBM 12.1.9/BigWigs v424.8 source-reviewed 2026-09-13; selected exact-ID timing enabled; PASS-LIVE pending",
    profiles = {
        normal = {
            explanation = {
                "Caustic Waves: use a safe gap and never let a wave touch an egg; swimming underneath no longer works.",
                "Spectral Coils: stack at least 40% of the raid in the active soak to minimize raid damage.",
                "Rage of the Shackled exposes the Heart: swap immediately and use the planned damage/healing window.",
                "Phase 2: split to both side platforms; kill the Warden before using the planned Doomscale egg.",
                "Protect and move eggs safely, kill priority serpent adds and interrupt dangerous add casts.",
                "Phase 3: Bloodlust; Serpent's Bite targets meet nearby helpers before 15s, then Purge helpers move 7+ yards out.",
                "Caustic Waves return with gaps: cross through the safe lane and keep remaining eggs protected.",
                "Circling Prey destroys the current platform: leave it before the platform breaks.",
            },
            calls = calls(
                coils("Stack 40%+ raid in the active Coil", "Coils: stack 40%+ raid in the active soak."),
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
                "Caustic Waves: use a safe gap and keep every wave away from eggs; swimming underneath no longer works.",
                "Spectral Coils: stack at least 40% of the raid in the active soak; current live timing is more consistent after hotfixes.",
                "Rage of the Shackled exposes the Heart: swap immediately and use the planned damage/healing window.",
                "Phase 2: split to opposite side platforms; kill the Warden, then use the planned egg.",
                "Grasping Fangs targets three players per side: break tethers sequentially and let Blight Vein clear between breaks.",
                "Protect and move eggs safely, kill priority serpent adds and interrupt dangerous add casts.",
                "Phase 3: Bloodlust; Serpent's Bite targets meet helpers before 15s, then Purge helpers move 7+ yards out.",
                "Circling Prey destroys the current platform: leave it before the platform breaks.",
            },
            calls = calls(
                coils("Stack 40%+ raid in the active Coil", "Coils: stack 40%+ raid in the active soak."),
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
                "Spectral Coils: soak only with the assigned team; Soul Constrictor prevents that team from mitigating the next Coil.",
                "Toxic Incubation: assigned interceptors take one hit each; Toxic Burn players do not intercept another hit.",
                "Hardened eggs must have their shield broken before the assigned carrier moves them.",
                "Egg carriers stay 3+ yards apart and use only the called side.",
                "Grasping Fangs breaks hit the raid: break tethers sequentially and never chain multiple breaks together.",
                "Phase 3: Bloodlust; Serpent's Bite helpers leech before 15s, move 7+ yards out and handle the Purge waves.",
                "Caustic Waves must be crossed through safe gaps; swimming underneath is not a valid route.",
                "Circling Prey destroys the current platform: leave it before the platform breaks.",
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
