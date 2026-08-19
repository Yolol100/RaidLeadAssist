local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function calls(crateAction, crateWarning, crateActionTemplate, crateWarningTemplate)
    return {
        {
            key = "crates",
            ability = "Throw Junk",
            action = crateAction,
            warning = crateWarning,
            actionTemplate = crateActionTemplate,
            warningTemplate = crateWarningTemplate,
            voice = "Crates",
            spellIDs = { 1291933 },
            prepareSeconds = 6,
            pressSeconds = 3,
        },
        {
            key = "fish",
            ability = "Final Ascension",
            action = "Nama, then Iku, then Gebbo",
            warning = "Fish: Nama, then Iku, then Gebbo.",
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
end

Registry:Register({
    key = "explorers",
    name = "The Lost Explorers",
    encounterID = 3497,
    strategyStatus = "12.1 Journal + current Wowhead/Raidstrats + Ready Check Pull recap + DBM/BigWigs source-reviewed 2026-08-19; player briefing split from raidleader prep; live validation pending",
    profiles = {
        normal = {
            explanation = {
                "Keep all three bosses even and finish them together.",
                "Crates appear: assigned breaker opens them until fish appears.",
                "Fish order: Nama, then Iku, then Gebbo.",
                "Feed the next fish before Final Ascension finishes.",
                "Three players marked: go to Star, Circle and Diamond.",
                "Soakers stack with each marked player before impact.",
                "Fire clears with Frost; Frost clears with Fire.",
                "Icebound Flames starts: interrupt it immediately.",
            },
            calls = calls(
                "Assigned breaker opens next crate",
                "Crate: assigned breaker open next.",
                "{{crate_a}} opens next crate",
                "Crate: {{crate_a}} open next."
            ),
        },
        heroic = {
            explanation = {
                "Keep Nama away; stack Iku and Gebbo together.",
                "Spreading fire appears: keep it away from usable space.",
            },
            calls = calls(
                "Next breaker opens crate",
                "Crate: next breaker open it.",
                "{{rotation:crates}} opens next crate",
                "Crate: {{rotation:crates}} open next."
            ),
        },
        mythic = {
            explanation = {
                "Before a crate breaks, everyone else moves 15+ yards away.",
            },
            calls = calls(
                "Clear 15+ yards; breaker opens",
                "Crate: clear 15+ yards, then break.",
                "Clear 15+ yards; {{rotation:crates}} breaks",
                "Crate: clear 15+ yards; {{rotation:crates}} break."
            ),
        },
    },
})
