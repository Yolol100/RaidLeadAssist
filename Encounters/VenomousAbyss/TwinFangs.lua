local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local heroicCalls = {
    {
        key = "globules", ability = "Caustic Deluge", action = "SOAK ALL GLOBULES — ONE PLAYER EACH",
        warning = "SOAK ALL GLOBULES — ONE PLAYER EACH", voice = "Soak all globules",
        spellIDs = { 1289192 }, prepareSeconds = 7, pressSeconds = 4,
    },
    {
        key = "adds", ability = "Venomous Emergence", action = "KILL ADDS — LINES AWAY FROM RAID",
        warning = "KILL ADDS — LINES AWAY FROM RAID", voice = "Kill adds lines away",
        spellIDs = { 1291404 }, prepareSeconds = 8, pressSeconds = 5,
    },
    {
        key = "ichor", ability = "Coiling Ichor", action = "RED CIRCLES — EDGE",
        warning = "RED CIRCLES — EDGE", voice = "Red circles edge",
        spellIDs = { 1290809 }, prepareSeconds = 7, pressSeconds = 4,
    },
    {
        key = "waves", ability = "Stir the Depths", action = "WAVES — DODGE",
        warning = "WAVES — DODGE", voice = "Dodge waves",
        spellIDs = { 1290956 }, prepareSeconds = 7, pressSeconds = 4,
    },
    {
        key = "feast1", ability = "Ravenous Feast", action = "FEAST 1 — GROUP 1 SOAK",
        warning = "FEAST 1 — GROUP 1 SOAK", voice = "Feast one group one",
        actionTemplate = "FEAST 1 — {{feast_heroic_a}} SOAK",
        warningTemplate = "FEAST 1 — {{feast_heroic_a}} SOAK",
        spellIDs = { 1290516 }, prepareSeconds = 7, pressSeconds = 4,
        sequenceKey = "feast", sequenceKeys = { "feast1", "feast2", "feast3" },
    },
    {
        key = "feast2", ability = "Ravenous Feast — second", action = "FEAST 2 — GROUP 2 SOAK",
        warning = "FEAST 2 — GROUP 2 SOAK", voice = "Feast two group two",
        actionTemplate = "FEAST 2 — {{feast_heroic_b}} SOAK",
        warningTemplate = "FEAST 2 — {{feast_heroic_b}} SOAK",
        timing = false, iconSpellID = 1290516,
    },
    {
        key = "feast3", ability = "Ravenous Feast — third", action = "FEAST 3 — GROUP 3 SOAK",
        warning = "FEAST 3 — GROUP 3 SOAK", voice = "Feast three group three",
        actionTemplate = "FEAST 3 — {{feast_heroic_c}} SOAK",
        warningTemplate = "FEAST 3 — {{feast_heroic_c}} SOAK",
        timing = false, iconSpellID = 1290516,
    },
    {
        key = "beam", ability = "Vile Flood", action = "ROTATING BEAM — CROSS EARLY, STAY BEHIND",
        warning = "ROTATING BEAM — CROSS EARLY, STAY BEHIND", voice = "Cross beam early",
        spellIDs = { 1294293 }, prepareSeconds = 7, pressSeconds = 4,
    },
}

local mythicCalls = {
    {
        key = "globules", ability = "Caustic Deluge", action = "One player soak each green orb",
        warning = "Green orbs: one player soak each before they burst.", voice = "Orbs",
        spellIDs = { 1289192 }, prepareSeconds = 7, pressSeconds = 4,
    },
    {
        key = "adds", ability = "Venomous Emergence", action = "Kill adds fast",
        warning = "Adds: kill them fast.", voice = "Adds",
        spellIDs = { 1291404 }, prepareSeconds = 6, pressSeconds = 3,
    },
    {
        key = "feast", ability = "Ravenous Feast", action = "Assigned groups soak in order",
        warning = "Feast: assigned groups soak in order.",
        actionTemplate = "{{feast_team_a}}, {{feast_team_b}}, {{feast_team_c}}",
        warningTemplate = "Feast: {{feast_team_a}}, then {{feast_team_b}}, then {{feast_team_c}}.",
        voice = "Feast", spellIDs = { 1290516 }, prepareSeconds = 8, pressSeconds = 5,
    },
    {
        key = "tainted", ability = "Tainted Blood", action = "Heal every fount full",
        warning = "Blood founts: heal every one to full.", voice = "Heal founts", timing = false,
    },
    {
        key = "bulwark", ability = "Blood Torrent / Barbed Bulwark", action = "Interrupt Protected Gestation",
        warning = "Bulwarks: interrupt Protected Gestation.", voice = "Interrupt",
        spellIDs = { 1303230 }, prepareSeconds = 7, pressSeconds = 4,
    },
    {
        key = "brood", ability = "Rouse the Brood", action = "Assigned kicks stop Visceral Burst",
        warning = "Broodlings: assigned kicks interrupt Visceral Burst.",
        actionTemplate = "{{brood_kick_a}}/{{brood_kick_b}} interrupt Broodlings",
        warningTemplate = "Broodlings: {{brood_kick_a}} and {{brood_kick_b}} interrupt Visceral Burst.",
        voice = "Interrupt", spellIDs = { 1308356 }, prepareSeconds = 4, pressSeconds = 1,
    },
    {
        key = "energy", ability = "Sanguine Storm", action = "Move to Ithraz; dodge waves",
        warning = "100 energy: move to Ithraz; dodge waves.", voice = "Move to Ithraz",
        spellIDs = { 1306872 }, prepareSeconds = 8, pressSeconds = 5,
    },
}

Registry:Register({
    key = "twinfangs",
    name = "The Twin Fangs",
    encounterID = 3421,
    strategyStatus = "Heroic uses three fresh Ravenous Feast soak teams because Feasted adds 800% repeat-hit damage; exact-ID guidance stays sequence-aware; Mythic remains separate; source-reviewed 2026-09-14; PASS-LIVE pending",
    profiles = {
        heroic = {
            explanation = {
                "FEAST = 3 FRESH GROUPS — ONE HIT EACH",
                "NO ONE SOAKS TWO FEAST HITS",
            },
            calls = heroicCalls,
        },
        mythic = {
            explanation = {
                "Keep Mythic Feast teams separate and fresh; do not inherit the Heroic assignment sizes automatically.",
                "Blood founts, protected globules and Broodling interrupts remain Mythic-specific responsibilities.",
            },
            calls = mythicCalls,
        },
    },
})
