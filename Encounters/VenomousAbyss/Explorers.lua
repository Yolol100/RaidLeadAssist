local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local heroicCalls = {
    {
        key = "fish_gebbo",
        ability = "Final Ascension",
        action = "FISH NOW → GEBBO",
        warning = "FISH NOW → GEBBO",
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
        action = "FISH NOW → NAMA",
        warning = "FISH NOW → NAMA",
        voice = "Fish Nama",
        timing = false,
        iconSpellID = 1292779,
    },
    {
        key = "fish_iku",
        ability = "Final Ascension — Iku",
        action = "FISH NOW → IKU",
        warning = "FISH NOW → IKU",
        voice = "Fish Iku",
        timing = false,
        iconSpellID = 1292779,
    },
    {
        key = "explosive_surprise",
        ability = "Explosive Surprise",
        action = "USE MUSHROOM FOR WAVE",
        warning = "USE MUSHROOM FOR WAVE",
        voice = "Use mushroom",
        timing = false,
        iconSpellID = 1297625,
    },
    {
        key = "thud",
        ability = "Mighty Thud",
        action = "SOAK MARKS",
        warning = "SOAK MARKS",
        voice = "Soak marks",
        spellIDs = { 1296092 },
        prepareSeconds = 7,
        pressSeconds = 4,
    },
    {
        key = "frostfire_volley",
        ability = "Frostfire Volley",
        action = "SPREAD FIRE/FROST — CLEAR WITH OPPOSITE",
        warning = "SPREAD FIRE/FROST — CLEAR WITH OPPOSITE",
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
            explanation = { "GEBBO → NAMA → IKU" },
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
