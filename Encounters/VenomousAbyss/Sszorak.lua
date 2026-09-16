local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local heroicCalls = {
    {
        key = "venom",
        ability = "Venomous Surge",
        action = "Cysts: place them at the correct wind mark.",
        warning = "Cysts: place them at the correct wind mark.",
        voice = "Place cysts",
        spellIDs = { 1305959 },
        prepareSeconds = 6,
        pressSeconds = 3,
    },
    {
        key = "crosswinds",
        ability = "Raging Crosswinds",
        action = "White circles: stack middle and pair opposite.",
        warning = "White circles: stack middle and pair opposite.",
        voice = "Pair opposite",
        spellIDs = { 1285425 },
        prepareSeconds = 7,
        pressSeconds = 4,
    },
    {
        key = "maelstrom",
        ability = "Howling Maelstrom",
        action = "Wind: pop one cyst.",
        warning = "Wind: pop one cyst.",
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
            explanation = {
                "Pre-pull: assign wind marks and cyst placements before the pull.",
                "Cysts: place them at the correct wind mark and keep the center clear.",
                "Raging Crosswinds: stack middle, pair opposite, then move cleanly.",
                "Howling Maelstrom: pop one planned cyst for the wind mechanic.",
            },
            calls = heroicCalls,
        },
        mythic = {
            explanation = {
                "Pre-pull: assign the Mythic soak order as Raid -> Tank -> Tank and keep cyst assignments separate.",
                "Serpent's Fury marks a player: 14+ players stack on them.",
                "After the charge, Virulence players spread and drop residue away from the raid.",
            },
            calls = mythicCalls,
        },
    },
})
