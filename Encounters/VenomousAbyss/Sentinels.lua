local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

Registry:Register({
    key = "sentinels",
    name = "Entombed Sentinels",
    encounterID = 3445,
    strategyStatus = "12.1 source-reviewed; live Heroic pending",
    explanation = {
        "SPLIT THE RAID. KEEP THE SENTINELS SEPARATED; DO NOT LET DOMINANCE ACTIVATE.",
        "COAGULATION ADD > KILL IT. TOXIC DROPLETS > SOAK THEM.",
        "MIASMA > STACK TO SPLIT THE HIT.",
        "STASIS: HELICAL TOXINS MUST REACH EXACTLY 4 STACKS.",
    },
    calls = {
        {
            key = "stasis",
            ability = "Vitriolic Stasis",
            action = "Toxins = exactly 4 > re-split",
            warning = "STASIS > TOXINS = EXACTLY 4 > RE-SPLIT",
            voice = "Stasis",
            spellIDs = { 1284588 },
        },
        {
            key = "coagulation",
            ability = "Venom Coagulation",
            action = "Kill the slime immediately",
            warning = "COAGULATION ADD > KILL NOW",
            voice = "Add",
            spellIDs = { 1284251 },
        },
        {
            key = "droplets",
            ability = "Toxic Droplets",
            action = "Soak the droplets",
            warning = "TOXIC DROPLETS > SOAK",
            voice = "Droplets",
            spellIDs = { 1284434 },
        },
        {
            key = "miasma",
            ability = "Unstable Miasma",
            action = "Stack to split the impact",
            warning = "MIASMA > STACK TO SPLIT",
            voice = "Miasma",
            spellIDs = { 1288232 },
        },
    },
})
