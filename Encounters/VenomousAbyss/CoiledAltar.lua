local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

Registry:Register({
    key = "altar",
    name = "The Coiled Altar",
    encounterID = 3429,
    strategyStatus = "12.1 PTR source-reviewed 2026-08-13; live Heroic pending",
    explanation = {
        "GUILLOTINE: 5+ PLAYERS SOAK. USE THE ASSIGNED GROUP.",
        "ON HEROIC: ROTATE GUILLOTINE GROUPS. DO NOT SOAK TWICE IN A ROW.",
        "TANK: AIM SEVER THROUGH VENOM TO CLEAR SPACE.",
        "DREADMARCH: BREAK THE PLAYER SHIELDS BEFORE THEY WALK OFF.",
        "MANIFESTATIONS: FIXATED PLAYERS FACE THEM. TANK HITS THEM WITH SOUL SEVER.",
        "ETERNAL NIGHTFALL: BREAK THE SHIELD, THEN INTERRUPT.",
        "SPIRITCACKLE: KILL SOULCOILERS AND INTERRUPT WAIL.",
        "FINAL: REPEAT OLD MECHANICS AND KILL BOTH BOSSES TOGETHER.",
    },
    calls = {
        {
            key = "guillotine",
            ability = "Guillotine",
            action = "Assigned 5+ player soak",
            warning = "GUILLOTINE > ASSIGNED 5+ PLAYER SOAK IN",
            voice = "Guillotine",
            spellIDs = { 1283489, 1283485, 1299266 },
            timerNames = { "Guillotine", "Grim Guillotine" },
        },
        {
            key = "dreadmarch",
            ability = "Dreadmarch",
            action = "Break player shields now",
            warning = "DREADMARCH > BREAK PLAYER SHIELDS NOW",
            voice = "Dreadmarch",
            spellIDs = { 1289900 },
        },
        {
            key = "nightfall",
            ability = "Eternal Nightfall",
            action = "Break shield > interrupt",
            warning = "ETERNAL NIGHTFALL > BREAK SHIELD > INTERRUPT",
            voice = "Nightfall",
            spellIDs = { 1286918 },
        },
        {
            key = "spiritcackle",
            ability = "Spiritcackle",
            action = "Kill Soulcoilers > interrupt Wail",
            warning = "SPIRITCACKLE > KILL SOULCOILERS > INTERRUPT WAIL",
            voice = "Add",
            spellIDs = { 1286441 },
        },
        {
            key = "final",
            ability = "Final Phase",
            action = "Repeat mechanics > kill both together",
            warning = "FINAL PHASE > REPEAT MECHANICS > KILL BOTH TOGETHER",
            voice = "Final phase",
            timing = false,
            iconSpellID = 1298381,
        },
    },
})
