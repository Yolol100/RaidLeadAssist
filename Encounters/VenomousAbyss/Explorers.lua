local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

Registry:Register({
    key = "explorers",
    name = "The Lost Explorers",
    encounterID = 3497,
    strategyStatus = "12.1 PTR source-reviewed 2026-08-13; live Heroic pending",
    explanation = {
        "KEEP NAMA, IKU, AND GEBBO MORE THAN 30 YARDS APART.",
        "FINAL ASCENSION: THROW THE ASSIGNED FISH AT A POSSESSED TORTOLLAN.",
        "EACH TORTOLLAN CAN EAT ONLY ONE FISH. KILL THEM BEFORE FISH RUN OUT.",
        "MIGHTY THUD: 3 PLAYERS ARE MARKED. SOAK EACH JUMP WITH A GROUP.",
        "ICEBOUND FLAMES: INTERRUPT IT.",
        "FIRE CLEARS FROST. FROST CLEARS FIRE.",
        "FROSTFIRE IMPACTS: KEEP THEM OFF PLAYERS WHO ALREADY HAVE FIRE OR FROST.",
    },
    calls = {
        {
            key = "fish",
            ability = "Final Ascension",
            action = "Throw assigned fish now",
            warning = "FINAL ASCENSION > THROW ASSIGNED FISH NOW",
            voice = "Fish",
            timing = false,
            iconSpellID = 1292779,
        },
        {
            key = "thud",
            ability = "Mighty Thud",
            action = "3 targets > group soak each jump",
            warning = "MIGHTY THUD > 3 TARGETS > GROUP SOAK EACH JUMP",
            voice = "Soak",
            spellIDs = { 1296092 },
        },
        {
            key = "icebound",
            ability = "Icebound Flames",
            action = "Interrupt now",
            warning = "ICEBOUND FLAMES > INTERRUPT NOW",
            voice = "Interrupt",
            spellIDs = { 1286921 },
        },
    },
})
