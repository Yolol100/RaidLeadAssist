local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

Registry:Register({
    key = "twinfangs",
    name = "The Twin Fangs",
    encounterID = 3421,
    strategyStatus = "12.1 PTR source-reviewed 2026-08-13; live Heroic pending",
    explanation = {
        "HEROIC: ETERNAL VENOM KILLS YOU AT 8 STACKS.",
        "RAVENOUS FEAST HITS 3 TIMES. EACH HIT NEEDS 3+ PLAYERS.",
        "EACH FEAST HIT REMOVES 1 VENOM STACK FROM PLAYERS HIT.",
        "HEROIC: USE A DIFFERENT SOAK GROUP FOR EACH FEAST HIT.",
        "VENOMOUS EMERGENCE: KILL THE SPAWNS FAST.",
        "AT 100 ENERGY: DODGE VILE FLOOD AND SANGUINE STORM.",
    },
    calls = {
        {
            key = "feast",
            ability = "Ravenous Feast",
            action = "3 hits > rotate 3+ player soak groups",
            warning = "RAVENOUS FEAST > 3 HITS > ROTATE 3+ PLAYER SOAK GROUPS",
            voice = "Feast",
            spellIDs = { 1290516 },
        },
        {
            key = "adds",
            ability = "Venomous Emergence",
            action = "Kill spawns now",
            warning = "VENOMOUS EMERGENCE > KILL SPAWNS NOW",
            voice = "Adds",
            spellIDs = { 1291404 },
        },
    },
})
