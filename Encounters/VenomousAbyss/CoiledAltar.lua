local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

Registry:Register({
    key = "altar",
    name = "The Coiled Altar",
    encounterID = 3429,
    strategyStatus = "12.1 source-reviewed; live Heroic pending",
    explanation = {
        "P1: GUILLOTINE SOAK. TANK FRONTALS CLEAR THE REQUIRED SPACE.",
        "P2: DREADMARCH > BREAK SHIELDS AND FACE THE MANIFESTATIONS.",
        "ETERNAL NIGHTFALL > BREAK THE SHIELD IMMEDIATELY.",
        "FINAL: HANDLE OVERLAPS AND KILL BOTH BOSSES TOGETHER.",
    },
    calls = {
        {
            key = "guillotine",
            ability = "Guillotine",
            action = "Assigned group soak",
            warning = "GUILLOTINE > ASSIGNED GROUP SOAK",
            voice = "Guillotine",
            spellIDs = { 1283489, 1283485, 1299266 },
            timerNames = { "Guillotine", "Grim Guillotine" },
        },
        {
            key = "dreadmarch",
            ability = "Dreadmarch",
            action = "Break shields > face Manifestations",
            warning = "DREADMARCH > BREAK SHIELDS > FACE MANIFESTATIONS",
            voice = "Dreadmarch",
            spellIDs = { 1289900 },
        },
        {
            key = "nightfall",
            ability = "Eternal Nightfall",
            action = "Break the shield immediately",
            warning = "ETERNAL NIGHTFALL > BREAK SHIELD NOW",
            voice = "Nightfall",
            spellIDs = { 1286918 },
        },
        {
            key = "spiritcackle",
            ability = "Spiritcackle",
            action = "Swap and kill the add",
            warning = "SPIRITCACKLE > SWAP > KILL ADD",
            voice = "Add",
            spellIDs = { 1286441 },
        },
        {
            key = "final",
            ability = "Final Phase",
            action = "Mechanics first > kill together",
            warning = "FINAL PHASE > MECHANICS FIRST > KILL TOGETHER",
            voice = "Final phase",
            timing = false,
            iconSpellID = 1298381,
        },
    },
})
