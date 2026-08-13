local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

Registry:Register({
    key = "vashnik",
    name = "Vashnik the Malignant",
    encounterID = 3455,
    strategyStatus = "12.1 PTR source-reviewed 2026-08-13; live Heroic pending",
    explanation = {
        "IMBIBE USES THE 2 NEAREST FOUNTAINS. MOVE THE BOSS TO THE PLANNED PAIR.",
        "KILL EVERY LIVING VENOM BEFORE IT REACHES THE CENTER.",
        "DO NOT OVERSTACK ONE FOUNTAIN. REPEATED INFUSIONS MAKE ITS MECHANICS STRONGER.",
        "CATALYST: EVERY BILE CIRCLE NEEDS AT LEAST 1 PLAYER.",
        "FROTH TARGETS: MOVE AWAY FROM OTHER PLAYERS.",
        "WHEN FROTH ENDS, DODGE THE 4 WAVES FROM EACH TARGET.",
    },
    calls = {
        {
            key = "imbibe",
            ability = "Imbibe",
            action = "Boss to planned fountains > kill Venoms",
            warning = "IMBIBE > BOSS TO PLANNED FOUNTAINS > KILL VENOMS BEFORE CENTER",
            voice = "Imbibe",
            spellIDs = { 1283164 },
        },
        {
            key = "catalyst",
            ability = "Malignant Catalyst",
            action = "1 player in every Bile circle",
            warning = "CATALYST > 1 PLAYER IN EVERY BILE CIRCLE",
            voice = "Catalyst",
            spellIDs = { 1282525, 1282509 },
        },
        {
            key = "froth",
            ability = "Plague Froth",
            action = "Targets out > dodge 4 waves",
            warning = "PLAGUE FROTH > TARGETS MOVE OUT > DODGE 4 WAVES",
            voice = "Froth",
            spellIDs = { 1281907 },
        },
    },
})
