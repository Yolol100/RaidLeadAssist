local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local heroicCalls = {
    {
        key = "venom",
        ability = "Venomous Surge",
        action = "CYSTS — PLACE AT CORRECT WIND MARK",
        warning = "CYSTS — PLACE AT CORRECT WIND MARK",
        voice = "Place cysts",
        spellIDs = { 1305959 },
        prepareSeconds = 6,
        pressSeconds = 3,
    },
    {
        key = "crosswinds",
        ability = "Raging Crosswinds",
        action = "WHITE CIRCLES — STACK MID, PAIR OPPOSITE",
        warning = "WHITE CIRCLES — STACK MID, PAIR OPPOSITE",
        voice = "Pair opposite",
        spellIDs = { 1285425 },
        prepareSeconds = 7,
        pressSeconds = 4,
    },
    {
        key = "maelstrom",
        ability = "Howling Maelstrom",
        action = "WIND — POP ONE CYST",
        warning = "WIND — POP ONE CYST",
        voice = "Pop one cyst",
        spellIDs = { 1285732 },
        prepareSeconds = 8,
        pressSeconds = 5,
    },
}

local mythicCalls = {
    {
        key = "venom",
        ability = "Venomous Surge",
        action = "Take debuffs to outer markers",
        warning = "Venom: take debuffs to outer markers.",
        voice = "Venom",
        spellIDs = { 1305959 },
        prepareSeconds = 6,
        pressSeconds = 3,
    },
    {
        key = "crosswinds",
        ability = "Raging Crosswinds",
        action = "Pair opposite arrows",
        warning = "Crosswinds: pair opposite arrows.",
        voice = "Crosswinds",
        spellIDs = { 1285425 },
        prepareSeconds = 7,
        pressSeconds = 4,
    },
    {
        key = "maelstrom",
        ability = "Howling Maelstrom",
        action = "Assigned Poppers trigger Cysts",
        warning = "Maelstrom: assigned Poppers trigger Cysts.",
        actionTemplate = "{{cyst_popper_1}}/{{cyst_popper_2}}/{{cyst_popper_3}} pop Cysts",
        warningTemplate = "Maelstrom: {{cyst_popper_1}}, {{cyst_popper_2}}, {{cyst_popper_3}} pop Cysts 1-2-3.",
        voice = "Maelstrom",
        spellIDs = { 1285732 },
        prepareSeconds = 8,
        pressSeconds = 5,
    },
    {
        key = "apex",
        ability = "Apex Predator",
        action = "Assigned group soaks Mutilate",
        warning = "Mutilate: assigned group soak frontal.",
        actionTemplate = "{{rotation:mutilate_teams}} soak Mutilate",
        warningTemplate = "Mutilate: {{rotation:mutilate_teams}} soak frontal.",
        voice = "Soak",
        spellIDs = { 1277025, 1285430 },
        prepareSeconds = 7,
        pressSeconds = 4,
    },
    {
        key = "dig_in",
        ability = "Dig In",
        action = "Use damage cooldowns",
        warning = "Dig In: use damage cooldowns.",
        voice = "Burn",
        timing = false,
    },
    {
        key = "serpent",
        ability = "Serpent's Fury",
        action = "14+ stack on marked player",
        warning = "Serpent's Fury: 14+ stack on marked player.",
        voice = "Stack",
        timing = false,
        iconSpellID = 1305621,
    },
}

Registry:Register({
    key = "sszorak",
    name = "Sszorak",
    encounterID = 3420,
    strategyStatus = "Heroic reduced to cyst placement, verified Raging Crosswinds opposite-pair positioning and one-cyst Maelstrom execution; current Sep 2026 Crosswinds hotfix accounted for; Mythic remains separate; PASS-LIVE pending",
    profiles = {
        heroic = {
            explanation = { "{{GROUP_SPLIT:BLUE:X}}" },
            calls = heroicCalls,
        },
        mythic = {
            explanation = {
                "Keep Mythic Mutilate and Cyst assignments separate from the simplified Heroic call set.",
                "Serpent's Fury marks a player: 14+ players stack on them.",
                "After the charge, Virulence players spread and drop residue away from the raid.",
            },
            calls = mythicCalls,
        },
    },
})
