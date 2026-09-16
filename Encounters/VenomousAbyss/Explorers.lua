local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local heroicCalls = {
    {
        key = "fish_gebbo",
        ability = "Final Ascension",
        action = "Fish now: Gebbo.",
        warning = "Fish now: Gebbo.",
        voice = "Fish Gebbo",
        spellIDs = { 1292779 },
        prepareSeconds = 8,
        pressSeconds = 5,
        sequenceKey = "fish",
        sequenceKeys = { "fish_gebbo", "fish_nama", "fish_iku" },
    },
    {
        key = "fish_nama",
        ability = "Final Ascension — Nama",
        action = "Fish now: Nama.",
        warning = "Fish now: Nama.",
        voice = "Fish Nama",
        timing = false,
        iconSpellID = 1292779,
    },
    {
        key = "fish_iku",
        ability = "Final Ascension — Iku",
        action = "Fish now: Iku.",
        warning = "Fish now: Iku.",
        voice = "Fish Iku",
        timing = false,
        iconSpellID = 1292779,
    },
    {
        key = "explosive_surprise",
        ability = "Explosive Surprise",
        action = "Use the mushroom for the wave.",
        warning = "Use the mushroom for the wave.",
        voice = "Use mushroom",
        timing = false,
        iconSpellID = 1297625,
    },
    {
        key = "thud",
        ability = "Mighty Thud",
        action = "Soak the marks.",
        warning = "Soak the marks.",
        voice = "Soak marks",
        spellIDs = { 1296092 },
        prepareSeconds = 7,
        pressSeconds = 4,
    },
    {
        key = "frostfire_volley",
        ability = "Frostfire Volley",
        action = "Fire/Frost: spread, then clear with the opposite type.",
        warning = "Fire/Frost: spread, then clear with the opposite type.",
        voice = "Spread and clear opposite",
        timing = false,
        iconSpellID = 1295886,
    },
}

local mythicCalls = {
    {
        key = "crates",
        ability = "Throw Junk",
        action = "Clear 15+ yards; breaker breaks crate",
        warning = "Crate: clear 15+ yards, then break.",
        actionTemplate = "Clear 15+ yards; {{rotation:crates}} breaks",
        warningTemplate = "Crate: clear 15+ yards; {{rotation:crates}} break.",
        voice = "Crates",
        spellIDs = { 1291933 },
        prepareSeconds = 6,
        pressSeconds = 3,
    },
    {
        key = "fish",
        ability = "Final Ascension",
        action = "Use planned fish order",
        warning = "Fish: use the planned Mythic target.",
        voice = "Fish",
        spellIDs = { 1292779 },
        prepareSeconds = 8,
        pressSeconds = 5,
    },
    {
        key = "thud",
        ability = "Mighty Thud",
        action = "Targets Star/Circle/Diamond; soakers stack",
        warning = "Thud: targets Star/Circle/Diamond; soakers stack.",
        voice = "Three soak points",
        spellIDs = { 1296092 },
        prepareSeconds = 7,
        pressSeconds = 4,
    },
}

Registry:Register({
    key = "explorers",
    name = "The Lost Explorers",
    encounterID = 3497,
    strategyStatus = "Heroic fish order set to Gebbo → Nama → Iku with separate manual calls; Mythic crate-breaker route retained separately; exact-ID guidance is sequence-aware; PASS-LIVE pending",
    profiles = {
        heroic = {
            legacyExplanation = { "GEBBO → NAMA → IKU" },
            explanation = { "Fish order: Gebbo → Nama → Iku." },
            calls = heroicCalls,
        },
        mythic = {
            explanation = {
                "Before a crate breaks, everyone else moves 15+ yards away.",
                "Use the planned Mythic fish target and keep all three bosses controlled.",
            },
            calls = mythicCalls,
        },
    },
})
