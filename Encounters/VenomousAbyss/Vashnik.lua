local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

Registry:Register({
    key = "vashnik",
    name = "Vashnik the Malignant",
    encounterID = 3455,
    strategyStatus = "12.1 source-reviewed; live Heroic pending",
    explanation = {
        "IMBIBE USES THE TWO NEAREST FOUNTAINS. POSITION THE BOSS DELIBERATELY.",
        "IMBIBE SPAWNS LIVING VENOMS > KILL THEM BEFORE THE MALIGNANT CAVITY.",
        "CATALYST > EVERY BILE IMPACT NEEDS A SOAKER.",
        "FROTH TARGETS OUT. ADAPTIVE INFECTION CHANGES WITH ACTIVE INFUSIONS.",
    },
    calls = {
        {
            key = "imbibe",
            ability = "Imbibe",
            action = "Check position > kill Living Venoms",
            warning = "IMBIBE > CHECK POSITION > KILL LIVING VENOMS",
            voice = "Imbibe",
            spellIDs = { 1283164 },
        },
        {
            key = "catalyst",
            ability = "Malignant Catalyst",
            action = "Soak every Catalytic Bile impact",
            warning = "CATALYST > SOAK EVERY BILE IMPACT",
            voice = "Catalyst",
            spellIDs = { 1282525, 1282509 },
        },
    },
})
