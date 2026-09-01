local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function sharedCalls()
    return {
        {
            key = "stasis",
            ability = "Vitriolic Stasis",
            action = "Spread; find 1+3 or 2+2 partner",
            warning = "Stasis: spread; find 1+3 or 2+2 partner.",
            voice = "Spread and match",
            spellIDs = { 1284588 },
            prepareSeconds = 6,
            pressSeconds = 2,
            uiGroup = "shared",
        },
        {
            key = "side_swap",
            ability = "After Stasis",
            action = "Hold assigned sides",
            warning = "After Stasis: hold assigned sides.",
            actionTemplate = "{{team_a}} green; {{team_b}} red",
            warningTemplate = "After Stasis: {{team_a}} hold green; {{team_b}} hold red.",
            voice = "Hold sides",
            timing = false,
            uiGroup = "shared",
        },
        {
            key = "balance_stop_breath",
            ability = "Stop DPS on Breath",
            action = "Stop Breath DPS",
            warning = "Breath: stop DPS.",
            voice = "Stop Breath",
            timing = false,
            uiGroup = "balance",
        },
        {
            key = "balance_stop_blood",
            ability = "Stop DPS on Blood",
            action = "Stop Blood DPS",
            warning = "Blood: stop DPS.",
            voice = "Stop Blood",
            timing = false,
            uiGroup = "balance",
        },
        {
            key = "balance_resume",
            ability = "Resume DPS",
            action = "Resume DPS; keep health even",
            warning = "Resume: keep both bosses even.",
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
            action = "Kill green slime",
            warning = "Green side: kill slime.",
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
            action = "Stack on red target",
            warning = "Red mark: stack together.",
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
    action = "Marked players pair together",
    warning = "Protovenom: marked players pair together.",
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
    strategyStatus = "12.1 Journal + current DBM/BigWigs source-reviewed 2026-09-02; Stasis partner call clarified; live validation pending",
    profiles = {
        normal = {
            explanation = {
                "Stay with your assigned green or red side.",
                "Keep both bosses 40+ yards apart and their health even.",
                "Green side: kill the slime, then clear green droplets.",
                "Red mark on you: stack with your group to split damage.",
                "Stasis: spread first, then find the player who makes your toxin total exactly four.",
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
