local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function timedCall(key, ability, action, warning, voice, spellIDs, prepareSeconds, pressSeconds)
    return {
        key = key,
        ability = ability,
        action = action,
        warning = warning,
        voice = voice,
        spellIDs = spellIDs,
        prepareSeconds = prepareSeconds,
        pressSeconds = pressSeconds,
    }
end

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

local killAddsHeroic = timedCall(
    "imbibe", "Imbibe",
    "KILL ADDS",
    "KILL ADDS",
    "Kill adds", { 1283164 }, 8, 5
)
local staggerDispelsHeroic = manualCall(
    "stagger_dispels", "Exploding Infection",
    "STAGGER DISPELS",
    "STAGGER DISPELS",
    "Stagger dispels", 1295166
)
local dodgeCrossHeroic = timedCall(
    "froth", "Plague Froth",
    "DODGE CROSS",
    "DODGE CROSS",
    "Dodge cross", { 1281907 }, 6, 3
)
local soakBileHeroic = timedCall(
    "catalyst", "Malignant Catalyst",
    "SOAK BILE",
    "SOAK BILE",
    "Soak bile", { 1282525, 1282509 }, 7, 4
)

local killAddsMythic = timedCall(
    "imbibe", "Imbibe",
    "Kill fountain adds before center",
    "Fountain adds: kill them before center.",
    "Kill adds", { 1283164 }, 8, 5
)
local fireStaggerMythic = manualCall(
    "fire_stagger", "Burning Venoms",
    "Skull, wait, then Cross",
    "Fire adds: Skull, wait, then Cross.",
    "Stagger fire adds", 1305902
)
local siphonMythic = manualCall(
    "siphon", "Siphoning Infection",
    "Stack several in Blood circle",
    "Blood circle: several teammates stack for healing.",
    "Stack blood circle", 1299941
)
local catalystMythic = timedCall(
    "catalyst", "Malignant Catalyst",
    "Soak every Catalyst circle",
    "Catalyst: soak every circle.",
    "Soak every circle", { 1282525, 1282509 }, 7, 4
)
local frothMythic = timedCall(
    "froth", "Plague Froth",
    "Aim wave through Tumor",
    "Froth: aim one wave through Tumor.",
    "Aim at tumors", { 1281907 }, 6, 3
)
local killTumorsMythic = manualCall(
    "tumors", "Malignant Tumors",
    "Kill exposed Tumor",
    "Tumor exposed: switch and kill.",
    "Kill tumors", 1304437
)

Registry:Register({
    key = "vashnik",
    name = "Vashnik the Malignant",
    encounterID = 3455,
    strategyStatus = "Heroic uses the current 2026-09 permanent Shadow/Purple + Fire/Orange simple strategy; old Blood/Red Heroic route removed; Mythic mechanics remain separate; PASS-LIVE pending",
    profiles = {
        heroic = {
            legacyExplanation = { "PURPLE + ORANGE ONLY — BL ON PULL" },
            explanation = { "Use Purple and Orange assignments only; Bloodlust on pull." },
            calls = { killAddsHeroic, staggerDispelsHeroic, dodgeCrossHeroic, soakBileHeroic },
        },
        mythic = {
            explanation = {
                "Use the current Mythic fountain plan; do not inherit the Heroic Purple/Orange simplification automatically.",
                "Froth near a Tumor: aim one wave through the Tumor.",
                "Tumor loses its shield: switch and kill it immediately.",
            },
            calls = {
                killAddsMythic,
                fireStaggerMythic,
                siphonMythic,
                catalystMythic,
                frothMythic,
                killTumorsMythic,
            },
        },
    },
})
