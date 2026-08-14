local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function baseCalls(bloodAction, bloodWarning)
    return {
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
            action = "4-player groups > clear at exactly 4",
            warning = "STASIS > FIXED 4-PLAYER GROUPS > CLEAR TOXIN AT EXACTLY 4",
            voice = "Stasis",
            spellIDs = { 1284588 },
            prepareSeconds = 8,
            pressSeconds = 5,
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
            prepareSeconds = 6,
            pressSeconds = 3,
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
            action = bloodAction,
            warning = bloodWarning,
            voice = "Dispel",
            spellIDs = { 1284483 },
        },
    }
end

local livingVenom = {
    key = "living",
    ability = "Living Venom",
    action = "Clear return lane > dodge venom",
    warning = "LIVING VENOM > CLEAR RETURN LANE > DODGE RETURNING VENOM",
    voice = "Return lane",
    timing = false,
}

local normalCalls = baseCalls(
    "Dispel infected players",
    "BLIGHTED BLOOD > DISPEL INFECTED PLAYERS"
)
local heroicCalls = baseCalls(
    "Targets edge > dispel > drop pools",
    "BLIGHTED BLOOD > TARGETS EDGE > DISPEL > DROP POOLS THERE"
)
heroicCalls[#heroicCalls + 1] = livingVenom

local mythicCalls = baseCalls(
    "Targets edge > dispel > drop pools",
    "BLIGHTED BLOOD > TARGETS EDGE > DISPEL > DROP POOLS THERE"
)
mythicCalls[#mythicCalls + 1] = livingVenom
mythicCalls[#mythicCalls + 1] = {
    key = "protovenom",
    ability = "Shifting Protovenom",
    action = "Marked players pair > avoid clean players",
    warning = "PROTOVENOM > MARKED PLAYERS PAIR TOGETHER > AVOID CLEAN PLAYERS",
    voice = "Pair",
    spellIDs = { 1296878 },
    prepareSeconds = 7,
    pressSeconds = 4,
}

Registry:Register({
    key = "sentinels",
    name = "Entombed Sentinels",
    encounterID = 3445,
    strategyStatus = "12.1 difficulty plans source-reviewed 2026-08-14; live validation pending",
    profiles = {
        normal = {
            explanation = {
                "PLAN: TWO FIXED TEAMS. ANCHOR BOSSES 40+ YARDS APART TO AVOID CROSS-MARKS.",
                "KEEP BOTH BOSS HEALTH BARS EVEN BEFORE EACH STASIS.",
                "BREATH TEAM: KILL COAGULATION FAST; ASSIGNED PLAYERS STEP ON DROPLETS.",
                "BLOOD TEAM: MIASMA STACKS AT MARK; DISPEL BLIGHTED BLOOD WHEN SAFE.",
                "STASIS: FIXED 4-PLAYER GROUPS TOUCH UNTIL TOXIN IS EXACTLY 4.",
                "WHEN YOUR TOXIN CLEARS, STOP TOUCHING PEOPLE. THEN RE-SPLIT FAST.",
            },
            calls = normalCalls,
        },
        heroic = {
            explanation = {
                "PLAN: TWO FIXED TEAMS. ANCHOR BOSSES 40+ YARDS APART; KEEP HEALTH EVEN.",
                "BREATH TEAM: KILL COAGULATION; ASSIGNED PLAYERS STEP ON DROPLETS.",
                "LIVING VENOM: CLEAR ITS RETURN LANE AFTER 4 SEC; DODGE IT BACK TO BREATH.",
                "BLOOD TEAM: MIASMA AT MARK; BLOOD VENOM POOLS GO TO THE EDGE.",
                "BLIGHTED BLOOD: DISPEL WHEN SAFE AND KEEP THE DROP AWAY FROM THE RAID.",
                "STASIS: FIXED 4-PLAYER GROUPS. PAIR, JOIN PAIRS, CLEAR AT EXACTLY 4.",
                "AFTER STASIS: RE-SPLIT IMMEDIATELY AND RETURN TO YOUR ORIGINAL SIDE.",
            },
            calls = heroicCalls,
        },
        mythic = {
            explanation = {
                "PLAN: HEROIC SPLIT PLUS FIXED PROTOVENOM PAIRS.",
                "KEEP BOSSES 40+ YARDS APART AND HEALTH EVEN BEFORE EVERY STASIS.",
                "BREATH: KILL SLIME, STOMP DROPLETS, AND CLEAR LIVING VENOM RETURN LANES.",
                "BLOOD: MIASMA AT MARK; BLOOD VENOM POOLS GO TO THE EDGE.",
                "PROTOVENOM: MARKED PLAYERS PAIR TOGETHER; NEVER TOUCH CLEAN PLAYERS.",
                "STASIS: FIXED 4-PLAYER GROUPS PAIR, JOIN PAIRS, CLEAR AT EXACTLY 4.",
                "AFTER STASIS: RE-SPLIT FAST AND RETURN TO YOUR ORIGINAL SIDE.",
            },
            calls = mythicCalls,
        },
    },
})
