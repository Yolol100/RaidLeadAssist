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
            ability = "Side Swap",
            action = "Teams swap boss sides",
            warning = "TEAMS > SWAP BOSS SIDES",
            voice = "Swap sides",
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
    strategyStatus = "12.1 Journal + current Wowhead/Ready Check Pull/Raidstrats + DBM/BigWigs source-reviewed 2026-08-18; flex-safe rotating raid split; raidlead-only call scope; live validation pending",
    profiles = {
        normal = {
            explanation = {
                "PLAN: TEAM A STARTS BREATH/GREEN; TEAM B STARTS BLOOD/RED. KEEP BOSSES 40+ YARDS APART AND KEEP HP EVEN.",
                "CURRENT BREATH-SIDE TEAM: KILL THE COAGULATION ADD AND RUN OVER GREEN DROPLETS. CURRENT BLOOD-SIDE TEAM: SOAK MIASMA; HEALERS DISPEL BLIGHTED BLOOD.",
                "AT STASIS: MATCH TO EXACTLY 4 TOXIN STACKS (1+3 OR 2+2), CLEAR IT, THEN TEAM A AND TEAM B SWAP BOSS SIDES.",
                BOSSMOD_RULE,
            },
            calls = normalCalls,
        },
        heroic = {
            explanation = {
                "PLAN: TEAM A STARTS BREATH/GREEN; TEAM B STARTS BLOOD/RED. KEEP BOSSES 40+ YARDS APART AND KEEP HP EVEN.",
                "BREATH SIDE: KILL ADD, RUN OVER GREEN DROPLETS, DODGE RETURNING VENOM. BLOOD SIDE: SOAK MIASMA; POOL TARGETS MOVE OUT BEFORE EXPIRY.",
                "HEALERS DISPEL BLIGHTED BLOOD AFTER SAFE POSITIONING. AT STASIS MATCH EXACTLY 4 (1+3 OR 2+2), THEN TEAM A AND TEAM B SWAP BOSS SIDES.",
                BOSSMOD_RULE,
            },
            calls = heroicCalls,
        },
        mythic = {
            explanation = {
                "PLAN: TEAM A STARTS BREATH/GREEN; TEAM B STARTS BLOOD/RED. KEEP BOSSES 40+ YARDS APART AND KEEP HP EVEN.",
                "DO HEROIC RULES. PROTOVENOM: MARKED PLAYERS TOUCH ANOTHER MARKED PLAYER ONLY; NEVER TOUCH A CLEAN PLAYER.",
                "AT STASIS MATCH EXACTLY 4 (1+3 OR 2+2), CLEAR IT, THEN TEAM A AND TEAM B SWAP SIDES AND RESET THE SPLIT FAST.",
                "WATCH ADD + DROPLET + MIASMA OVERLAPS; PERSONAL DODGES, POOLS AND DISPELS STAY BOSSMOD/ROLE-OWNED.",
                BOSSMOD_RULE,
            },
            calls = mythicCalls,
        },
    },
})
