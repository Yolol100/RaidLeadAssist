local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function calls(crateAction, crateWarning)
    return {
        {
            key = "crates",
            ability = "Throw Junk",
            action = crateAction,
            warning = crateWarning,
            voice = "Crates",
            spellIDs = { 1291933 },
            prepareSeconds = 6,
            pressSeconds = 3,
        },
        {
            key = "fish",
            ability = "Final Ascension",
            action = "Take fish to the next planned boss",
            warning = "Fish: take it to the next planned boss.",
            voice = "Fish",
            spellIDs = { 1292779 },
            prepareSeconds = 8,
            pressSeconds = 5,
        },
        {
            key = "thud",
            ability = "Mighty Thud",
            action = "Targets to separate markers; soakers stack in",
            warning = "Mighty Thud: targets to separate markers; soakers stack in.",
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
                "Fish appears: feed the next planned boss before Final Ascension.",
                "Three players marked: each goes to a different soak marker.",
                "Assigned soakers stack with their marked player before impact.",
                "Fire clears with Frost; Frost clears with Fire.",
                "Bomb appears: move away, then use a mushroom for the fire wave.",
                "Icebound Flames starts: interrupt it immediately.",
            },
            calls = calls(
                "Open the next crate",
                "Crate: open the next one."
            ),
        },
        heroic = {
            explanation = {
                "Keep Nama away; stack Iku and Gebbo together.",
                "Spreading fire appears: keep it away from usable space.",
            },
            calls = calls(
                "Open the next crate",
                "Crate: open the next one."
            ),
        },
        mythic = {
            explanation = {
                "Before a crate is broken, everyone else moves 15+ yards away.",
            },
            calls = calls(
                "Raid clear 15+ yards, then break",
                "Crate: raid clear 15+ yards, then break it."
            ),
        },
    },
})
