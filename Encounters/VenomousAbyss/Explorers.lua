local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

Registry:Register({
    key = "explorers",
    name = "The Lost Explorers",
    encounterID = 3497,
    strategyStatus = "12.1 source-reviewed; live Heroic pending",
    explanation = {
        "STOP FINAL ASCENSION: FEED THE ASSIGNED TORTOLLAN A FISH.",
        "EACH TORTOLLAN CAN ONLY BE FED ONCE. KILL THEM BEFORE FISH RUN OUT.",
        "MIGHTY THUD > SOAK TOGETHER.",
        "ICEBOUND FLAMES > INTERRUPT. HANDLE FIRE/FROST PATCHES CLEANLY.",
    },
    calls = {
        {
            key = "fish",
            ability = "Final Ascension",
            action = "Assigned Fish now",
            warning = "FINAL ASCENSION > ASSIGNED FISH NOW",
            voice = "Fish",
            timing = false,
            iconSpellID = 1292779,
        },
        {
            key = "thud",
            ability = "Mighty Thud",
            action = "Stack for the hit",
            warning = "MIGHTY THUD > STACK IN",
            voice = "Soak",
            spellIDs = { 1296092 },
        },
        {
            key = "icebound",
            ability = "Icebound Flames",
            action = "Interrupt the cast",
            warning = "ICEBOUND FLAMES > INTERRUPT",
            voice = "Interrupt",
            spellIDs = { 1286921 },
        },
    },
})
