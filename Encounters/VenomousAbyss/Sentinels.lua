local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local BOSSMOD_RULE = "CALL PRIORITY: FOLLOW DBM OR BIGWIGS FOR YOUR PERSONAL DEBUFFS, DODGES, ROLE WARNINGS AND TIMERS. FOLLOW RLA/RAID-LEADER CALLS FOR GROUPS, MARKERS, SOAKS, TARGET PRIORITY AND SHARED RAID MOVEMENT."

local function sharedCalls()
    return {
        {
            key = "stasis",
            ability = "Vitriolic Stasis",
            action = "Match to exactly 4",
            warning = "MATCH TO 4 > 1+3 OR 2+2",
            voice = "Match to four",
            spellIDs = { 1284588 },
            prepareSeconds = 6,
            pressSeconds = 2,
            uiGroup = "shared",
        },
        {
            key = "side_swap",
            ability = "Post-Stasis Side Reset",
            action = "Groups hold sides > bosses swap",
            warning = "GROUPS HOLD SIDES > BOSSES SWAP",
            voice = "Hold sides",
            timing = false,
            uiGroup = "shared",
        },
        {
            key = "balance",
            ability = "Boss Health Balance",
            action = "Check bars > stop lower HP boss",
            warning = "KEEP HP EVEN > STOP LOWER HP BOSS",
            voice = "Balance",
            timing = false,
            uiGroup = "balance",
        },
        {
            key = "balance_stop_breath",
            ability = "Boss Health Balance",
            action = "Stop DPS on Breath",
            warning = "STOP DPS > BREATH OF ULA'TEK",
            voice = "Stop Breath",
            timing = false,
            uiGroup = "balance",
        },
        {
            key = "balance_stop_blood",
            ability = "Boss Health Balance",
            action = "Stop DPS on Blood",
            warning = "STOP DPS > BLOOD OF ULA'TEK",
            voice = "Stop Blood",
            timing = false,
            uiGroup = "balance",
        },
        {
            key = "balance_resume",
            ability = "Boss Health Balance",
            action = "Resume DPS > keep even",
            warning = "RESUME DPS > KEEP BOTH EVEN",
            voice = "Resume DPS",
            timing = false,
            uiGroup = "balance",
        },
    }
end

local function breathCalls()
    return {
        {
            key = "coagulation",
            ability = "Venom Coagulation",
            action = "Breath side > kill add",
            warning = "BREATH SIDE > KILL ADD",
            voice = "Kill add",
            timing = false,
            iconSpellID = 1284251,
            uiGroup = "breath",
        },
    }
end

local function bloodCalls()
    return {
        {
            key = "miasma",
            ability = "Unstable Miasma",
            action = "Blood side soaks target",
            warning = "BLOOD SIDE > SOAK TARGET",
            voice = "Blood side soak",
            spellIDs = { 1288232 },
            prepareSeconds = 5,
            pressSeconds = 1,
            uiGroup = "blood",
        },
    }
end

local function combine(...)
    local result = {}
    for index = 1, select("#", ...) do
        local list = select(index, ...)
        for itemIndex = 1, #list do result[#result + 1] = list[itemIndex] end
    end
    return result
end

local normalCalls = combine(breathCalls(), bloodCalls(), sharedCalls())
local heroicCalls = combine(breathCalls(), bloodCalls(), sharedCalls())
local mythicCalls = combine(breathCalls(), bloodCalls(), sharedCalls())
mythicCalls[#mythicCalls + 1] = {
    key = "protovenom",
    ability = "Shifting Protovenom",
    action = "Match marked with marked",
    warning = "PROTOVENOM > MARKED + MARKED",
    voice = "Match marked",
    spellIDs = { 1296878, 1296880, 1296882 },
    prepareSeconds = 7,
    pressSeconds = 4,
    uiGroup = "shared",
}

Registry:Register({
    key = "sentinels",
    name = "Entombed Sentinels",
    encounterID = 3445,
    strategyStatus = "12.1 Journal + current Wowhead + DBM/BigWigs source-reviewed 2026-08-18; flex-safe fixed-side raid split with post-Stasis boss swap; raidlead-only call scope; live validation pending",
    profiles = {
        normal = {
            explanation = {
                "PLAN: BLOODLUST ON PULL. TEAM A HOLDS GREEN SIDE; TEAM B HOLDS RED SIDE. A STARTS WITH BREATH, B WITH BLOOD. KEEP BOSSES 40+ YARDS APART AND HP EVEN.",
                "CURRENT BREATH SIDE: KILL COAGULATION ADD AND RUN OVER GREEN DROPLETS. CURRENT BLOOD SIDE: SOAK MIASMA; HEALERS DISPEL BLIGHTED BLOOD.",
                "AT STASIS: MATCH EXACTLY 4 TOXIN STACKS (1+3 OR 2+2). AFTERWARD GROUPS HOLD THEIR PHYSICAL SIDES; TANKS TAUNT-SWAP THE BOSSES ACROSS THEM.",
                BOSSMOD_RULE,
            },
            calls = normalCalls,
        },
        heroic = {
            explanation = {
                "PLAN: BLOODLUST ON PULL. TEAM A HOLDS GREEN SIDE; TEAM B HOLDS RED SIDE. A STARTS WITH BREATH, B WITH BLOOD. KEEP BOSSES 40+ YARDS APART AND HP EVEN.",
                "BREATH SIDE: KILL ADD, RUN OVER GREEN DROPLETS, DODGE RETURNING VENOM. BLOOD SIDE: SOAK MIASMA; POOL TARGETS MOVE OUT BEFORE EXPIRY.",
                "DISPEL BLIGHTED BLOOD SAFELY. AT STASIS MATCH EXACTLY 4 (1+3 OR 2+2); GROUPS HOLD SIDES WHILE TANKS TAUNT-SWAP THE BOSSES.",
                BOSSMOD_RULE,
            },
            calls = heroicCalls,
        },
        mythic = {
            explanation = {
                "PLAN: BLOODLUST ON PULL. TEAM A HOLDS GREEN SIDE; TEAM B HOLDS RED SIDE. A STARTS WITH BREATH, B WITH BLOOD. KEEP BOSSES 40+ YARDS APART AND HP EVEN.",
                "DO HEROIC RULES. PROTOVENOM: MARKED PLAYERS TOUCH ANOTHER MARKED PLAYER ONLY; NEVER TOUCH A CLEAN PLAYER.",
                "AT STASIS MATCH EXACTLY 4 (1+3 OR 2+2); GROUPS HOLD PHYSICAL SIDES WHILE TANKS TAUNT-SWAP BOSSES. RE-ESTABLISH 40+ YARDS FAST.",
                "WATCH ADD + DROPLET + MIASMA OVERLAPS; PERSONAL DODGES, POOLS, DISPELS AND TANK EXECUTION STAY BOSSMOD/ROLE-OWNED.",
                BOSSMOD_RULE,
            },
            calls = mythicCalls,
        },
    },
})
