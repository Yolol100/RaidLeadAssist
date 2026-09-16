local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local heroicCalls = {
    {
        key = "droplets",
        ability = "Toxic Droplets",
        action = "Green: soak droplets.",
        warning = "Green: soak droplets.",
        voice = "Soak droplets",
        timing = false,
        iconSpellID = 1284434,
    },
    {
        key = "blob",
        ability = "Venom Coagulation",
        action = "Green: kill the blob.",
        warning = "Green: kill the blob.",
        voice = "Kill blob",
        timing = false,
        iconSpellID = 1284251,
    },
    {
        key = "living_venom",
        ability = "Living Venom",
        action = "Green: dodge the return lines.",
        warning = "Green: dodge the return lines.",
        voice = "Dodge return lines",
        timing = false,
        iconSpellID = 1284207,
    },
    {
        key = "miasma",
        ability = "Unstable Miasma",
        action = "Red: group soak, then drop blood out.",
        warning = "Red: group soak, then drop blood out.",
        voice = "Group soak then drop out",
        spellIDs = { 1288232 },
        prepareSeconds = 5,
        pressSeconds = 1,
    },
    {
        key = "stasis",
        ability = "Vitriolic Stasis",
        action = "Stasis: pair toxins to four (1+3 or 2+2).",
        warning = "Stasis: pair toxins to four (1+3 or 2+2).",
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
        action = "Hold sides; tanks swap bosses",
        warning = "After Stasis: hold sides; tanks swap bosses.",
        actionTemplate = "{{team_a}} / {{team_b}} hold sides; tanks swap bosses",
        warningTemplate = "After Stasis: {{team_a}} / {{team_b}} hold sides; tanks swap bosses.",
        voice = "Tanks swap bosses",
        timing = false,
        iconSpellID = 1284588,
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
    strategyStatus = "Heroic raid-lead profile refreshed against current 2026-09 split/stasis strategy and Blizzard hotfixes; raid groups hold their physical sides after Stasis while tanks swap Sentinels; Mythic Protovenom retained separately; PASS-LIVE pending",
    profiles = {
        heroic = {
            legacyExplanation = {
                "Pre-pull: split the raid into balanced Red and Green sides.",
                "After Stasis, the raid holds sides while tanks swap bosses.",
            },
            explanation = {
                "Pre-pull: split the raid into balanced Red and Green sides.",
                "After Stasis, the raid holds sides while tanks swap bosses.",
            },
            calls = heroicCalls,
        },
        mythic = {
            explanation = {
                "Split into two balanced sides and keep both bosses 40+ yards apart.",
                "After Stasis players hold their physical sides while tanks swap bosses.",
                "Protovenom on you: find another Protovenom-marked player and pair safely.",
            },
            calls = mythicCalls,
        },
    },
})
