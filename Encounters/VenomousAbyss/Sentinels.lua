local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function baseCalls(bloodAction, bloodWarning)
    return {
        {
            key = "balance",
            ability = "Boss Health",
            action = "Keep health even",
            warning = "BOSS HEALTH > KEEP EVEN",
            voice = "Balance",
            timing = false,
        },
        {
            key = "tankswap",
            ability = "Tank Swap",
            action = "Tanks swap",
            warning = "TANKS > SWAP",
            voice = "Tank swap",
            timing = false,
        },
        {
            key = "stasis",
            ability = "Vitriolic Stasis",
            action = "Groups of 4 > clear at 4",
            warning = "STASIS > GROUPS OF 4 > CLEAR AT 4",
            voice = "Stasis",
            spellIDs = { 1284588 },
            prepareSeconds = 8,
            pressSeconds = 5,
        },
        {
            key = "coagulation",
            ability = "Venom Coagulation",
            action = "Kill slime",
            warning = "COAGULATION > KILL SLIME",
            voice = "Add",
            spellIDs = { 1284251 },
        },
        {
            key = "droplets",
            ability = "Toxic Droplets",
            action = "Assigned players soak droplets",
            warning = "DROPLETS > ASSIGNED PLAYERS SOAK",
            voice = "Droplets",
            spellIDs = { 1284434 },
            prepareSeconds = 6,
            pressSeconds = 3,
        },
        {
            key = "miasma",
            ability = "Unstable Miasma",
            action = "Target to Blood mark > raid soak",
            warning = "MIASMA > TARGET TO BLOOD MARK > RAID SOAK",
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
    action = "Clear return lane > dodge",
    warning = "LIVING VENOM > CLEAR LANE > DODGE",
    voice = "Return lane",
    timing = false,
}

local normalCalls = baseCalls(
    "Dispel infected players",
    "BLIGHTED BLOOD > DISPEL"
)
local heroicCalls = baseCalls(
    "Targets edge > dispel",
    "BLIGHTED BLOOD > TARGETS EDGE > DISPEL"
)
heroicCalls[#heroicCalls + 1] = livingVenom

local mythicCalls = baseCalls(
    "Targets edge > dispel",
    "BLIGHTED BLOOD > TARGETS EDGE > DISPEL"
)
mythicCalls[#mythicCalls + 1] = livingVenom
mythicCalls[#mythicCalls + 1] = {
    key = "protovenom",
    ability = "Shifting Protovenom",
    action = "Marked players pair",
    warning = "PROTOVENOM > MARKED PLAYERS PAIR",
    voice = "Pair",
    spellIDs = { 1296878 },
    prepareSeconds = 7,
    pressSeconds = 4,
}

Registry:Register({
    key = "sentinels",
    name = "Entombed Sentinels",
    encounterID = 3445,
    strategyStatus = "12.1 Journal + current community strategy source-reviewed 2026-08-17; live validation pending",
    profiles = {
        normal = {
            explanation = {
                "PLAN: SPLIT INTO BREATH AND BLOOD SIDES. KEEP BOSSES 40+ YARDS APART AND KEEP THEIR HEALTH EVEN BEFORE STASIS.",
                "BREATH SIDE KILLS COAGULATION AND ASSIGNED PLAYERS SOAK DROPLETS. BLOOD SIDE STACKS MIASMA AT ITS MARK AND DISPELS BLOOD SAFELY.",
                "STASIS: FIXED GROUPS REACH EXACTLY 4 TOXIN APPLICATIONS, THEN STOP TOUCHING. TANKS SWAP BEFORE REPEATED TANK HITS BECOME DANGEROUS.",
            },
            calls = normalCalls,
        },
        heroic = {
            explanation = {
                "PLAN: NORMAL SPLIT; BOSSES 40+ YARDS APART AND HEALTH EVEN. LIVING VENOM RETURNS TO BREATH AFTER 4 SEC, SO CLEAR ITS LANE.",
                "BLOOD TARGETS MOVE EDGE BEFORE DISPEL SO POOLS STAY OUT. MIASMA TARGET GOES TO BLOOD MARK FOR THE RAID SOAK.",
                "STASIS USES FIXED GROUPS OF 4. RE-SPLIT IMMEDIATELY AFTER CLEARING. TANKS SWAP BEFORE STACKING TANK DAMAGE GETS DANGEROUS.",
            },
            calls = heroicCalls,
        },
        mythic = {
            explanation = {
                "PLAN: HEROIC SPLIT PLUS FIXED PROTOVENOM PAIRS. KEEP BOSSES 40+ YARDS APART AND HEALTH EVEN.",
                "PROTOVENOM PLAYERS TOUCH THEIR ASSIGNED MARKED PARTNER ONLY; NEVER COLLIDE WITH CLEAN PLAYERS.",
                "STASIS GROUPS CLEAR AT EXACTLY 4, THEN RE-SPLIT FAST. KEEP LIVING VENOM LANES CLEAR AND BLOOD POOLS AT THE EDGE.",
                "TANKS SWAP BEFORE REPEATED TANK HITS BECOME DANGEROUS.",
            },
            calls = mythicCalls,
        },
    },
})
