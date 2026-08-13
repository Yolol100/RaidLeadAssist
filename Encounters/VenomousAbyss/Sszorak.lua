local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

Registry:Register({
    key = "sszorak",
    name = "Sszorak",
    encounterID = 3420,
    strategyStatus = "12.1 PTR source-reviewed 2026-08-13; live Heroic pending",
    explanation = {
        "VENOMOUS SURGE TARGETS: MOVE AWAY FROM THE RAID. YOU LEAVE CYSTS.",
        "CYSTS KNOCK THE RAID BUT GIVE A SHORT STICKY EFFECT AGAINST KNOCKBACK.",
        "RAGING CROSSWINDS: FOLLOW YOUR PERSONAL KNOCK DIRECTION.",
        "BEFORE MAELSTROM: POP A CYST SO THE RAID GETS THE STICKY EFFECT.",
        "MAELSTROM: STAY ON THE PLATFORM AND USE DPS CDS.",
        "APEX PREDATOR: TANK COMBO. MUTILATE NEEDS 5+ PLAYERS IN THE FRONTAL.",
    },
    calls = {
        {
            key = "venom",
            ability = "Venomous Surge",
            action = "Targets out > drop cysts away",
            warning = "VENOMOUS SURGE > TARGETS MOVE OUT > DROP CYSTS AWAY",
            voice = "Venom",
            spellIDs = { 1305959 },
        },
        {
            key = "maelstrom",
            ability = "Howling Maelstrom",
            action = "Pop cyst > stay on platform > DPS CDs",
            warning = "MAELSTROM > POP CYST > STAY ON PLATFORM > DPS CDS",
            voice = "Maelstrom",
            spellIDs = { 1285732 },
        },
        {
            key = "apex",
            ability = "Apex Predator",
            action = "Mutilate > assigned 5+ soak",
            warning = "APEX PREDATOR > MUTILATE > ASSIGNED 5+ SOAKERS IN",
            voice = "Soak",
            spellIDs = { 1277025 },
        },
    },
})
