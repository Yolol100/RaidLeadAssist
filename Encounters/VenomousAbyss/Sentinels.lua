local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local heroicCalls = {
    {
        key = "droplets",
        ability = "Toxic Droplets",
        action = "GREEN — SOAK DROPLETS",
        warning = "GREEN — SOAK DROPLETS",
        voice = "Soak droplets",
        timing = false,
    },
    {
        key = "blob",
        ability = "Venom Coagulation",
        action = "GREEN — KILL BLOB",
        warning = "GREEN — KILL BLOB",
        voice = "Kill blob",
        timing = false,
        iconSpellID = 1284251,
    },
    {
        key = "return_lines",
        ability = "Returning Venom",
        action = "GREEN — DODGE RETURN LINES",
        warning = "GREEN — DODGE RETURN LINES",
        voice = "Dodge return lines",
        timing = false,
    },
    {
        key = "miasma",
        ability = "Unstable Miasma",
        action = "RED — GROUP SOAK",
        warning = "RED — GROUP SOAK",
        voice = "Group soak",
        spellIDs = { 1288232 },
        prepareSeconds = 5,
        pressSeconds = 1,
    },
    {
        key = "stasis",
        ability = "Vitriolic Stasis",
        action = "STASIS — 1+3 / 2+2",
        warning = "STASIS — 1+3 / 2+2",
        voice = "One three or two two",
        spellIDs = { 1284588 },
        prepareSeconds = 6,
        pressSeconds = 2,
    },
}

local mythicCalls = {
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
    {
        key = "stasis",
        ability = "Vitriolic Stasis",
        action = "Pair toxins to exactly 4",
        warning = "Stasis: pair toxins to exactly 4.",
        voice = "Match to four",
        spellIDs = { 1284588 },
        prepareSeconds = 6,
        pressSeconds = 2,
        uiGroup = "shared",
    },
    {
        key = "side_swap",
        ability = "After Stasis",
        action = "Swap sides after Stasis",
        warning = "After Stasis: swap sides.",
        actionTemplate = "{{team_a}} / {{team_b}} swap sides",
        warningTemplate = "After Stasis: {{team_a}} / {{team_b}} swap sides.",
        voice = "Swap sides",
        timing = false,
        uiGroup = "shared",
    },
    {
        key = "protovenom",
        ability = "Shifting Protovenom",
        action = "Marked players pair together",
        warning = "Protovenom: marked players pair together.",
        voice = "Match marked",
        spellIDs = { 1296878, 1296880, 1296882 },
        prepareSeconds = 7,
        pressSeconds = 4,
        uiGroup = "shared",
    },
}

Registry:Register({
    key = "sentinels",
    name = "Entombed Sentinels",
    encounterID = 3445,
    strategyStatus = "Heroic raid-lead profile refreshed against current 2026-09 split/stasis strategy and Blizzard hotfixes; Mythic Protovenom retained separately; PASS-LIVE pending",
    profiles = {
        heroic = {
            explanation = { "{{GROUP_SPLIT:RED:GREEN}}" },
            calls = heroicCalls,
        },
        mythic = {
            explanation = {
                "Split into two balanced sides and keep both bosses 40+ yards apart.",
                "Swap sides after Stasis so the opposite Mark can fall off.",
                "Protovenom on you: find another Protovenom-marked player and pair safely.",
            },
            calls = mythicCalls,
        },
    },
})
