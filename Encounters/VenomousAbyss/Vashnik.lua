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

local function manualCall(key, ability, action, warning, voice)
    return { key=key, ability=ability, action=action, warning=warning, voice=voice, timing=false }
end

local killAdds = timedCall(
    "imbibe", "Imbibe",
    "Kill fountain adds before center",
    "Fountain adds: kill them before center.",
    "Kill adds", { 1283164 }, 8, 5
)
local fireStagger = manualCall(
    "fire_stagger", "Burning Venoms",
    "Skull, wait, then Cross",
    "Fire adds: Skull, wait, then Cross.",
    "Stagger fire adds"
)
local siphon = manualCall(
    "siphon", "Siphoning Infection",
    "Stack on Siphon target",
    "Siphon: stack on the target.",
    "Stack for siphon"
)
local catalyst = timedCall(
    "catalyst", "Malignant Catalyst",
    "Soak every green circle",
    "Green circles: soak every one.",
    "Soak every circle", { 1282525, 1282509 }, 7, 4
)
local frothMythic = timedCall(
    "froth", "Plague Froth",
    "Aim wave through Tumor",
    "Froth: aim one wave through a Tumor.",
    "Aim at tumors", { 1281907 }, 6, 3
)
local killTumors = manualCall(
    "tumors", "Malignant Tumors",
    "Kill exposed Tumor",
    "Tumor exposed: switch and kill.",
    "Kill tumors"
)

local function normalCalls() return { killAdds, siphon } end
local function heroicCalls() return { killAdds, fireStagger, siphon, catalyst } end
local function mythicCalls() return { killAdds, fireStagger, siphon, catalyst, frothMythic, killTumors } end

Registry:Register({
    key = "vashnik",
    name = "Vashnik the Malignant",
    encounterID = 3455,
    strategyStatus = "12.1 Journal + current Wowhead + DBM/BigWigs source-reviewed 2026-08-19; player briefing split from raidleader fountain/target prep; live validation pending",
    profiles = {
        normal = {
            explanation = {
                "Fountain adds spawn: kill them before they reach the center.",
                "Fire debuff on you: run far away before it explodes.",
                "Blood debuff on you: stay near teammates while healers recover you.",
                "Shadow debuff on you: spread and keep moving from eruptions.",
                "Froth circle on you: spread and aim all waves into clear space.",
            },
            calls = normalCalls(),
        },
        heroic = {
            explanation = {
                "Fire adds are Skull then Cross: kill Skull, wait, then kill Cross.",
                "Green circles appear: at least one player soaks each circle.",
            },
            calls = heroicCalls(),
        },
        mythic = {
            explanation = {
                "Froth near a Tumor: aim one wave through the Tumor.",
                "Tumor loses its shield: switch and kill it immediately.",
            },
            calls = mythicCalls(),
        },
    },
})
