local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local adds = {
    key = "adds",
    ability = "Venomous Emergence",
    action = "Kill adds fast",
    warning = "Adds: kill them fast.",
    voice = "Adds",
    spellIDs = { 1291404 },
    prepareSeconds = 6,
    pressSeconds = 3,
}

local globules = {
    key = "globules",
    ability = "Caustic Globules",
    action = "One player soak green orb",
    warning = "Green orb: one player soak before it bursts.",
    voice = "Orbs",
    spellIDs = { 1289237, 1289192 },
    timerNames = { "Caustic Deluge", "Caustic Globules" },
    prepareSeconds = 7,
    pressSeconds = 4,
}

local feastNormal = {
    key = "feast",
    ability = "Ravenous Feast",
    action = "Fresh 3+ soak each hit",
    warning = "Feast: fresh 3+ players soak each hit.",
    voice = "Feast",
    spellIDs = { 1290516 },
    prepareSeconds = 8,
    pressSeconds = 5,
}

local feastAssigned = {
    key = "feast",
    ability = "Ravenous Feast",
    action = "Assigned groups soak in order",
    warning = "Feast: assigned groups soak in order.",
    actionTemplate = "{{feast_team_a}}, {{feast_team_b}}, {{feast_team_c}}",
    warningTemplate = "Feast: {{feast_team_a}}, then {{feast_team_b}}, then {{feast_team_c}}.",
    voice = "Feast",
    spellIDs = { 1290516 },
    prepareSeconds = 8,
    pressSeconds = 5,
}

local energy = {
    key = "energy",
    ability = "100 Energy",
    action = "Move to Ithraz; dodge waves",
    warning = "100 energy: move to Ithraz; dodge waves.",
    voice = "Move to Ithraz",
    spellIDs = { 1306872 },
    timerNames = { "Sanguine Storm" },
    prepareSeconds = 8,
    pressSeconds = 5,
}

Registry:Register({
    key = "twinfangs",
    name = "The Twin Fangs",
    encounterID = 3421,
    strategyStatus = "12.1 Journal + current Wowhead + Ready Check Pull + DBM/BigWigs source-reviewed 2026-08-19; Normal Feast stays dynamic, Heroic/Mythic use configured groups; live validation pending",
    profiles = {
        normal = {
            explanation = {
                "Keep both bosses at similar health and kill them together.",
                "Green globule appears: one nearby player soaks it before it bursts.",
                "Feast hits three times: at least 3 fresh players soak each hit.",
                "After you soak one Feast hit, stay out of the next hits.",
                "Red shrinking circle on you: take it to the arena edge.",
                "Adds spawn: kill them quickly and face targeted spit away.",
                "At 100 energy: regroup and dodge the incoming waves.",
            },
            calls = { globules, adds, feastNormal, energy },
        },
        heroic = {
            explanation = {
                "Feast is preassigned: soak only when your group is called.",
                "The 100-energy storm leaves blood pools; keep movement paths clear.",
            },
            calls = { globules, adds, feastAssigned, energy },
        },
        mythic = {
            explanation = {
                "Blood founts appear after Feast: heal every fount completely.",
                "Shielded globules: interrupt Protected Gestation immediately.",
                "Broodlings spawn: interrupt every Visceral Burst.",
            },
            calls = {
                globules,
                adds,
                feastAssigned,
                {
                    key = "tainted",
                    ability = "Tainted Blood",
                    action = "Heal every fount full",
                    warning = "Blood founts: heal every one to full.",
                    voice = "Heal founts",
                    timing = false,
                },
                {
                    key = "bulwark",
                    ability = "Blood Torrent / Barbed Bulwark",
                    action = "Interrupt Protected Gestation",
                    warning = "Bulwarks: interrupt Protected Gestation.",
                    voice = "Interrupt",
                    spellIDs = { 1303230 },
                    prepareSeconds = 7,
                    pressSeconds = 4,
                },
                {
                    key = "brood",
                    ability = "Rouse the Brood",
                    action = "Assigned kicks stop Visceral Burst",
                    warning = "Broodlings: assigned kicks interrupt Visceral Burst.",
                    actionTemplate = "{{brood_kick_a}}/{{brood_kick_b}} interrupt Broodlings",
                    warningTemplate = "Broodlings: {{brood_kick_a}} and {{brood_kick_b}} interrupt Visceral Burst.",
                    voice = "Interrupt",
                    spellIDs = { 1308356 },
                    prepareSeconds = 4,
                    pressSeconds = 1,
                },
                energy,
            },
        },
    },
})
