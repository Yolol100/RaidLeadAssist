local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function sharedCalls()
    return {
        {
            key = "stasis",
            ability = "Vitriolic Stasis",
            action = "Match to exactly 4",
            warning = "MATCH TO 4 > 1+3 OR 2+2",
            voice = "Match to four",
            spellIDs = { 1284588 },
            prepareSeconds = 8,
            pressSeconds = 5,
            uiGroup = "shared",
        },
        {
            key = "side_swap",
            ability = "Side Swap",
            action = "Swap boss sides",
            warning = "SWAP BOSS SIDES",
            voice = "Swap sides",
            timing = false,
            uiGroup = "shared",
        },
        {
            key = "balance",
            ability = "Boss Health Balance",
            action = "Check bars > high boss stops",
            warning = "KEEP HEALTH EVEN > HIGH BOSS STOP DPS",
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

local function breathCalls(includeLiving)
    local calls = {
        {
            key = "coagulation",
            ability = "Venom Coagulation",
            action = "Kill add",
            warning = "KILL ADD",
            voice = "Kill add",
            spellIDs = { 1284251 },
            uiGroup = "breath",
        },
        {
            key = "droplets",
            ability = "Toxic Droplets",
            action = "Run over green droplets",
            warning = "RUN OVER GREEN DROPLETS",
            voice = "Green droplets",
            spellIDs = { 1284434 },
            prepareSeconds = 6,
            pressSeconds = 3,
            uiGroup = "breath",
        },
    }
    if includeLiving then
        calls[#calls + 1] = {
            key = "living",
            ability = "Living Venom",
            action = "Dodge venom",
            warning = "DODGE VENOM",
            voice = "Dodge venom",
            timing = false,
            uiGroup = "breath",
        }
    end
    return calls
end

local function bloodCalls(includePool)
    local calls = {
        {
            key = "miasma",
            ability = "Unstable Miasma",
            action = "Soak circle",
            warning = "SOAK CIRCLE",
            voice = "Soak circle",
            spellIDs = { 1288232 },
            uiGroup = "blood",
        },
    }
    if includePool then
        calls[#calls + 1] = {
            key = "bloodvenom",
            ability = "Blood Venom",
            action = "Go to corner",
            warning = "GO TO CORNER",
            voice = "Go corner",
            timing = false,
            uiGroup = "blood",
        }
    end
    calls[#calls + 1] = {
        key = "blood",
        ability = "Blighted Blood",
        action = "Dispel dots",
        warning = "DISPEL DOTS",
        voice = "Dispel dots",
        spellIDs = { 1284483 },
        uiGroup = "blood",
    }
    return calls
end

local function combine(...)
    local result = {}
    for index = 1, select("#", ...) do
        local list = select(index, ...)
        for itemIndex = 1, #list do result[#result + 1] = list[itemIndex] end
    end
    return result
end

local normalCalls = combine(breathCalls(false), bloodCalls(false), sharedCalls())
local heroicCalls = combine(breathCalls(true), bloodCalls(true), sharedCalls())
local mythicCalls = combine(breathCalls(true), bloodCalls(true), sharedCalls())
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
    strategyStatus = "12.1 Journal + current community/PTR strategy source-reviewed 2026-08-18; split layout and secret-safe HP display; live validation pending",
    profiles = {
        normal = {
            explanation = {
                "PLAN: GROUPS 1+2 GO GREEN/BREATH. GROUPS 3+4 GO RED/BLOOD. KEEP BOSSES 40+ YARDS APART AND KEEP HP EVEN.",
                "GREEN: KILL THE ADD AND RUN OVER GREEN DROPLETS. RED: SOAK THE CIRCLE TOGETHER AND HEALERS DISPEL THE DOTS.",
                "AT STASIS: MATCH TO EXACTLY 4 TOXIN STACKS (1+3 OR 2+2), CLEAR IT, THEN GROUPS 1+2 AND 3+4 SWAP BOSS SIDES.",
            },
            calls = normalCalls,
        },
        heroic = {
            explanation = {
                "PLAN: GROUPS 1+2 GO GREEN/BREATH. GROUPS 3+4 GO RED/BLOOD. KEEP BOSSES 40+ YARDS APART AND KEEP HP EVEN.",
                "GREEN: KILL ADD, RUN OVER GREEN DROPLETS, DODGE RETURNING VENOM. RED: SOAK CIRCLE; DOT TARGETS MOVE OUT, THEN DISPEL.",
                "AT STASIS: MATCH TO EXACTLY 4 TOXIN STACKS (1+3 OR 2+2), CLEAR IT, THEN SWAP BOSS SIDES. KEEP HP EVEN.",
            },
            calls = heroicCalls,
        },
        mythic = {
            explanation = {
                "PLAN: GROUPS 1+2 GO GREEN/BREATH. GROUPS 3+4 GO RED/BLOOD. KEEP BOSSES 40+ YARDS APART AND KEEP HP EVEN.",
                "DO HEROIC RULES. PROTOVENOM: MARKED PLAYERS TOUCH ANOTHER MARKED PLAYER ONLY; NEVER TOUCH A CLEAN PLAYER.",
                "AT STASIS: MATCH TO EXACTLY 4 TOXIN STACKS (1+3 OR 2+2), CLEAR IT, THEN SWAP SIDES AND RESET THE SPLIT FAST.",
                "WATCH ADD + DROPLET + MIASMA OVERLAPS.",
            },
            calls = mythicCalls,
        },
    },
})
