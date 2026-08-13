local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

Registry:Register({
    key = "sentinels",
    name = "Entombed Sentinels",
    encounterID = 3445,
    strategyStatus = "12.1 PTR source-reviewed 2026-08-13; live Heroic pending",
    explanation = {
        "SPLIT INTO 2 GROUPS. KEEP THE BOSSES 40+ YARDS APART.",
        "COAGULATION: KILL THE SLIME FAST.",
        "TOXIC DROPLETS: STEP ON THEM BEFORE THEY EXPLODE.",
        "MIASMA TARGET: STACK WITH YOUR GROUP TO SPLIT THE HIT.",
        "STASIS: TOUCH PLAYERS UNTIL YOUR TOXIN HAS EXACTLY 4 STACKS.",
        "WHEN YOUR TOXIN REACHES 4, STOP TOUCHING PLAYERS.",
        "AFTER STASIS: SPLIT AGAIN AND SEPARATE THE BOSSES.",
    },
    calls = {
        {
            key = "stasis",
            ability = "Vitriolic Stasis",
            action = "Get exactly 4 toxin stacks > re-split",
            warning = "STASIS > GET EXACTLY 4 TOXIN STACKS > THEN RE-SPLIT",
            voice = "Stasis",
            spellIDs = { 1284588 },
        },
        {
            key = "coagulation",
            ability = "Venom Coagulation",
            action = "Kill slime now",
            warning = "COAGULATION > KILL SLIME NOW",
            voice = "Add",
            spellIDs = { 1284251 },
        },
        {
            key = "droplets",
            ability = "Toxic Droplets",
            action = "Step on droplets now",
            warning = "TOXIC DROPLETS > STEP ON THEM NOW",
            voice = "Droplets",
            spellIDs = { 1284434 },
        },
        {
            key = "miasma",
            ability = "Unstable Miasma",
            action = "Target stacks with group",
            warning = "MIASMA TARGET > STACK WITH GROUP",
            voice = "Miasma",
            spellIDs = { 1288232 },
        },
    },
})
