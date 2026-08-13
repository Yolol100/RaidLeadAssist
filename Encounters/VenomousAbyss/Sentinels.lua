local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function baseCalls()
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
    }
end

local normalCalls = baseCalls()
local heroicCalls = baseCalls()
local mythicCalls = baseCalls()
mythicCalls[#mythicCalls + 1] = {
    key = "protovenom",
    ability = "Shifting Protovenom",
    action = "Marked players pair > avoid clean players",
    warning = "PROTOVENOM > MARKED PLAYERS PAIR TOGETHER > AVOID CLEAN PLAYERS",
    voice = "Pair",
    spellIDs = { 1296878 },
}

Registry:Register({
    key = "sentinels",
    name = "Entombed Sentinels",
    encounterID = 3445,
    strategyStatus = "12.1 difficulty plans source-reviewed 2026-08-13; live validation pending",
    profiles = {
        normal = {
            explanation = {
                "PLAN: SPLIT INTO 2 FIXED TEAMS AND KEEP THE BOSSES 30+ YARDS APART.",
                "KEEP BOTH BOSS HEALTH BARS EVEN BEFORE EACH STASIS.",
                "BREATH TEAM: KILL COAGULATION FAST; ASSIGNED PLAYERS STEP ON DROPLETS.",
                "BLOOD TEAM: MIASMA STACKS AT THE MARK; BLOOD TARGETS GO EDGE FOR DISPEL.",
                "STASIS: FIXED 4-PLAYER GROUPS TOUCH UNTIL TOXIN IS EXACTLY 4.",
                "WHEN YOUR TOXIN CLEARS, STOP TOUCHING PEOPLE. THEN RE-SPLIT FAST.",
            },
            calls = normalCalls,
        },
        heroic = {
            explanation = {
                "PLAN: TWO FIXED TEAMS, BOSSES 30+ YARDS APART, HEALTH KEPT EVEN.",
                "BREATH TEAM: KILL COAGULATION; ASSIGNED PLAYERS STEP ON DROPLETS.",
                "LIVING VENOM RETURNS: CONTROL IT AND DO NOT LET IT REACH THE BOSS.",
                "BLOOD TEAM: MIASMA AT MARK; BLOOD TARGETS DROP THEIR POOLS AT THE EDGE.",
                "STASIS: FIXED 4-PLAYER GROUPS. MAKE PAIRS, JOIN PAIRS, CLEAR AT EXACTLY 4.",
                "AFTER STASIS: RE-SPLIT IMMEDIATELY AND SEPARATE THE BOSSES AGAIN.",
            },
            calls = heroicCalls,
        },
        mythic = {
            explanation = {
                "PLAN: HEROIC SPLIT PLUS FIXED PROTOVENOM PAIRS.",
                "KEEP BOSSES 30+ APART AND HEALTH EVEN BEFORE EVERY STASIS.",
                "BREATH: KILL SLIME, STOMP DROPLETS. BLOOD: MIASMA MARK, POOLS AT EDGE.",
                "PROTOVENOM: MARKED PLAYERS PAIR TOGETHER; NEVER TOUCH CLEAN PLAYERS.",
                "STASIS: FIXED 4-PLAYER GROUPS PAIR, JOIN PAIRS, CLEAR AT EXACTLY 4.",
                "AFTER STASIS: RE-SPLIT FAST AND RETURN TO YOUR ORIGINAL SIDE.",
            },
            calls = mythicCalls,
        },
    },
})
