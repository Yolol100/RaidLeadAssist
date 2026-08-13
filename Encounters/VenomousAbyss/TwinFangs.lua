local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

Registry:Register({
    key = "twinfangs",
    name = "The Twin Fangs",
    encounterID = 3421,
    strategyStatus = "12.1 PTR source-reviewed 2026-08-13; live Heroic pending",
    explanation = {
        "ETERNAL VENOM: 9 STACKS = DEATH.",
        "RAVENOUS FEAST HITS 3 TIMES. EACH HIT REMOVES 1 VENOM STACK.",
        "HEROIC: ROTATE SOAK GROUPS. DO NOT SOAK TWO FEAST HITS IN A ROW.",
        "VENOMOUS EMERGENCE: KILL THE SPAWNS FAST.",
        "AT 100 ENERGY: DODGE VILE FLOOD AND SANGUINE STORM.",
    },
    calls = {
        {
            key = "feast",
            ability = "Ravenous Feast",
            action = "Rotate soak groups > clear stacks",
            warning = "RAVENOUS FEAST > ROTATE SOAK GROUPS > CLEAR VENOM STACKS",
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
