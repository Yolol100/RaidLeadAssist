local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

Registry:Register({
    key = "ulatek",
    name = "Ula'tek",
    encounterID = 3492,
    strategyStatus = "12.1 source-reviewed; not public PTR-tested; automatic timing intentionally disabled",
    explanation = {
        "CAUSTIC WAVES: DODGE. NEVER LET A WAVE TOUCH AN EGG.",
        "SPECTRAL COILS: ASSIGNED GROUP SOAKS THE IMPACT.",
        "HEROIC: ROTATE COILS SOAKERS. LAST SOAKERS CANNOT HELP WITH THE NEXT ONE.",
        "CALL OF THE SERPENT: DODGE THE FALLING ADDS, THEN KILL THEM.",
        "RAGE: DODGE FALLING DEBRIS.",
        "RAGE EXPOSES THE HEART. USE DPS CDS AND BURN IT.",
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
            action = "Assigned soak group in > rotate next",
            warning = "SPECTRAL COILS > ASSIGNED SOAK GROUP IN > ROTATE NEXT",
            voice = "Coils",
            timing = false,
            iconSpellID = 1300530,
        },
        {
            key = "serpents",
            ability = "Call of the Serpent",
            action = "Dodge impacts > kill adds",
            warning = "CALL OF SERPENT > DODGE IMPACTS > KILL ADDS",
            voice = "Adds",
            timing = false,
            iconSpellID = 1300751,
        },
        {
            key = "heart",
            ability = "Rage of the Shackled",
            action = "Dodge debris > burn heart",
            warning = "RAGE > DODGE DEBRIS > BURN EXPOSED HEART",
            voice = "Heart",
            timing = false,
            iconSpellID = 1286860,
        },
    },
})
