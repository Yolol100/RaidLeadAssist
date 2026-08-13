local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

Registry:Register({
    key = "twinfangs",
    name = "The Twin Fangs",
    encounterID = 3421,
    strategyStatus = "12.1 source-reviewed; live Heroic pending",
    explanation = {
        "WATCH ETERNAL VENOM STACKS. HIGH STACKS ARE LETHAL.",
        "RAVENOUS FEAST > SOAK TO REMOVE VENOM STACKS.",
        "VENOMOUS EMERGENCE > KILL ADDS QUICKLY.",
        "AT 100 ENERGY: DODGE VILE FLOOD AND SANGUINE STORM; BOSS WARNINGS HANDLE THEM.",
    },
    calls = {
        {
            key = "feast",
            ability = "Ravenous Feast",
            action = "Soak rotation > clear stacks",
            warning = "RAVENOUS FEAST > SOAK ROTATION > CLEAR STACKS",
            voice = "Feast",
            spellIDs = { 1290516 },
        },
        {
            key = "adds",
            ability = "Venomous Emergence",
            action = "Kill adds immediately",
            warning = "VENOMOUS EMERGENCE > KILL ADDS NOW",
            voice = "Adds",
            spellIDs = { 1291404 },
        },
    },
})
