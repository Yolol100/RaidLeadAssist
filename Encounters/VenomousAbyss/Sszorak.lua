local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function baseCalls()
    return {
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
            action = "Poppers 1-2-3 trigger Cysts",
            warning = "Maelstrom: Poppers 1-2-3 trigger Cysts on each wind.",
            voice = "Maelstrom",
            spellIDs = { 1285732 },
            prepareSeconds = 8,
            pressSeconds = 5,
        },
        {
            key = "apex",
            ability = "Apex Predator",
            action = "Called team soak green frontal",
            warning = "Mutilate: called team soak green frontal.",
            voice = "Soak",
            spellIDs = { 1277025, 1285430 },
            prepareSeconds = 7,
            pressSeconds = 4,
        },
    }
end

Registry:Register({
    key = "sszorak",
    name = "Sszorak",
    encounterID = 3420,
    strategyStatus = "12.1 Journal + current Wowhead + DBM/BigWigs source-reviewed 2026-08-19; player briefing split from marker/poppers prep; live validation pending",
    profiles = {
        normal = {
            explanation = {
                "Venom debuff on you: run to your assigned outer marker.",
                "Let it expire there and leave the Cyst for later.",
                "Wind arrow on you: find the player with the opposite direction.",
                "Position so both knockbacks send you toward each other.",
                "Maelstrom starts: only assigned Cyst Poppers touch saved Cysts.",
                "Mutilate frontal: assigned soak team enters; everyone else stays out.",
                "When Sszorak digs in, use major damage cooldowns.",
            },
            calls = baseCalls(),
        },
        heroic = {
            explanation = {
                "Keep new poison pools at the arena edge.",
                "Use the other Mutilate soak team on every new cast.",
            },
            calls = baseCalls(),
        },
        mythic = {
            explanation = {
                "Serpent's Fury marks a player: 14+ players stack on them.",
                "After the charge, Virulence players spread from everyone.",
                "Drop Virulence residue away from the raid.",
            },
            calls = {
                baseCalls()[1], baseCalls()[2], baseCalls()[3], baseCalls()[4],
                {
                    key = "serpent",
                    ability = "Serpent's Fury",
                    action = "14+ stack on marked player",
                    warning = "Serpent's Fury: 14+ stack on marked player.",
                    voice = "Stack",
                    timing = false,
                    iconSpellID = 1305621,
                },
            },
        },
    },
})
