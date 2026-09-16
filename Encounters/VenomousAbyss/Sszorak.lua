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

Registry:Register({
    key = "sszorak",
    name = "Sszorak",
    encounterID = 3420,
    strategyStatus = "Heroic mechanics retained; Mythic raid-leader macro set intentionally reduced to one soak-order call (Raid -> Tank -> Tank) while the remaining mechanics stay in tactics; PASS-LIVE pending",
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
