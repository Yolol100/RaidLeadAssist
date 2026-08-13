local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

Registry:Register({
    key = "sentinels",
    name = "Entombed Sentinels",
    encounterID = 3445,
    strategyStatus = "12.1 Heroic plan: YouTube-guide + Journal reviewed 2026-08-13; live pending",
    explanation = {
        "SPLIT INTO 2 FIXED TEAMS. KEEP THE BOSSES 30+ YARDS APART.",
        "KEEP BOTH BOSS HEALTH BARS EVEN BEFORE EVERY STASIS.",
        "BREATH TEAM: KILL COAGULATION FAST AND ASSIGNED PLAYERS STEP ON DROPLETS.",
        "BLOOD TEAM: MIASMA TARGET STACKS AT THE BLOOD MARK.",
        "BLIGHTED BLOOD TARGETS MOVE TO THE EDGE, THEN HEALERS DISPEL THEM THERE.",
        "STASIS: USE FIXED 4-PLAYER TOXIN GROUPS. MAKE TWO PAIRS, THEN JOIN THE PAIRS.",
        "TOXIN MUST REACH EXACTLY 4. WHEN CLEARED, STOP TOUCHING PLAYERS.",
        "AFTER STASIS: RE-SPLIT IMMEDIATELY AND SEPARATE THE BOSSES AGAIN.",
    },
    calls = {
        {
            key = "balance",
            ability = "Boss Health",
            action = "Keep both even before Stasis",
            warning = "BOSS HEALTH > KEEP BOTH EVEN BEFORE STASIS",
            voice = "Balance",
            timing = false,
        },
        {
            key = "stasis",
            ability = "Vitriolic Stasis",
            action = "4-player groups > pair > join pairs > clear at 4",
            warning = "STASIS > 4-PLAYER GROUPS > PAIR > JOIN PAIRS > CLEAR AT EXACTLY 4",
            voice = "Stasis",
            spellIDs = { 1284588 },
        },
        {
            key = "coagulation",
            ability = "Venom Coagulation",
            action = "Breath team > kill slime now",
            warning = "COAGULATION > BREATH TEAM KILL SLIME NOW",
            voice = "Add",
            spellIDs = { 1284251 },
        },
        {
            key = "droplets",
            ability = "Toxic Droplets",
            action = "Assigned players step on droplets",
            warning = "TOXIC DROPLETS > ASSIGNED PLAYERS STEP ON THEM NOW",
            voice = "Droplets",
            spellIDs = { 1284434 },
        },
        {
            key = "miasma",
            ability = "Unstable Miasma",
            action = "Target stacks at Blood mark",
            warning = "MIASMA TARGET > STACK AT BLOOD MARK",
            voice = "Miasma",
            spellIDs = { 1288232 },
        },
        {
            key = "blood",
            ability = "Blighted Blood",
            action = "Targets edge > dispel there",
            warning = "BLIGHTED BLOOD > TARGETS EDGE > DISPEL THERE",
            voice = "Dispel",
            spellIDs = { 1284483 },
        },
    },
})
