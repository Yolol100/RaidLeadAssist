local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

Registry:Register({
    key = "ulatek",
    name = "Ula'tek",
    encounterID = 3492,
    strategyStatus = "Pre-live final boss; automatic call timing intentionally disabled",
    explanation = {
        "CAUSTIC WAVES > DODGE AND KEEP VENOM OFF THE EGGS.",
        "SPECTRAL COILS > ASSIGNED SOAKERS IN.",
        "RAGE OF THE SHACKLED > VENOMOUS HEART EXPOSED > BURN THE HEART.",
    },
    calls = {
        {
            key = "waves",
            ability = "Caustic Waves",
            action = "Dodge > keep waves off eggs",
            warning = "CAUSTIC WAVES > DODGE > KEEP WAVES OFF EGGS",
            voice = "Waves",
            timing = false,
            iconSpellID = 1292188,
        },
        {
            key = "coils",
            ability = "Spectral Coils",
            action = "Assigned soakers in",
            warning = "SPECTRAL COILS > ASSIGNED SOAKERS IN",
            voice = "Coils",
            timing = false,
            iconSpellID = 1300530,
        },
        {
            key = "serpents",
            ability = "Call of the Serpent",
            action = "Control and kill priority adds",
            warning = "CALL OF THE SERPENT > CONTROL > KILL PRIORITY ADDS",
            voice = "Adds",
            timing = false,
            iconSpellID = 1300751,
        },
        {
            key = "heart",
            ability = "Rage of the Shackled",
            action = "Heart exposed > DPS CDs",
            warning = "HEART EXPOSED > DPS CDS > BURN HEART",
            voice = "Heart",
            timing = false,
            iconSpellID = 1286860,
        },
    },
})
