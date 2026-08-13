local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

Registry:Register({
    key = "sszorak",
    name = "Sszorak",
    encounterID = 3420,
    strategyStatus = "12.1 source-reviewed; live Heroic pending",
    explanation = {
        "VENOMOUS SURGE > TARGETS OUT AND PLACE CYSTS CLEANLY.",
        "RAGING CROSSWINDS > FOLLOW YOUR PERSONAL KNOCK DIRECTION.",
        "HOWLING MAELSTROM > USE YOUR ADHESION AND STAY ON THE PLATFORM.",
        "APEX PREDATOR IS A TANK COMBO; LET BOSS WARNINGS HANDLE IT.",
    },
    calls = {
        {
            key = "venom",
            ability = "Venomous Surge",
            action = "Targets out > place cysts cleanly",
            warning = "VENOMOUS SURGE > TARGETS OUT > PLACE CYSTS CLEANLY",
            voice = "Venom",
            spellIDs = { 1305959 },
        },
        {
            key = "maelstrom",
            ability = "Howling Maelstrom",
            action = "Use adhesion > DPS CDs > stay on platform",
            warning = "MAELSTROM > USE ADHESION > DPS CDS > STAY ON PLATFORM",
            voice = "Maelstrom",
            spellIDs = { 1285732 },
        },
    },
})
