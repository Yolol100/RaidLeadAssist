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
            key = "balance_stop_breath",
            ability = "Manual Boss Health Balance",
            action = "Raid leader: stop DPS on Breath",
            warning = "STOP DPS > BREATH OF ULA'TEK",
            voice = "Stop Breath",
            timing = false,
            uiGroup = "balance",
        },
        {
            key = "balance_stop_blood",
            ability = "Manual Boss Health Balance",
            action = "Raid leader: stop DPS on Blood",
            warning = "STOP DPS > BLOOD OF ULA'TEK",
            voice = "Stop Blood",
            timing = false,
            uiGroup = "balance",
        },
        {
            key = "balance_resume",
            ability = "Manual Boss Health Balance",
            action = "Raid leader: resume DPS",
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
    strategyStatus = "12.1 Journal + current Wowhead + DBM/BigWigs source-reviewed 2026-08-19; fixed-side split with difficulty deltas; live validation pending",
    profiles = {
        normal = {
            explanation = {
                "Stay with your assigned green or red group.",
                "Keep both bosses 40+ yards apart and their health even.",
                "Green side: kill the slime, then clear green droplets.",
                "Red mark on you: stack with your group to split damage.",
                "Stasis: pair toxin numbers to total exactly four.",
                "Use 1+3 or 2+2, then return to your side.",
                "After Stasis: stay put while tanks swap the bosses.",
            },
            calls = normalCalls,
        },
        heroic = {
            explanation = {
                "Returning green poison: move out of its path.",
                "Blood poison on you: move out and drop the puddle away.",
            },
            calls = heroicCalls,
        },
        mythic = {
            explanation = {
                "Protovenom on you: find another Protovenom-marked player.",
                "Touch that marked player; never touch an unmarked player.",
            },
            calls = mythicCalls,
        },
    },
})
