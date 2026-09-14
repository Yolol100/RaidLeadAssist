local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local heroicCalls = {
    {
        key = "adds",
        ability = "Restless Amani",
        action = "KILL ADDS",
        warning = "KILL ADDS",
        voice = "Kill adds",
        spellIDs = { 1295397, 1297630 },
        prepareSeconds = 7,
        pressSeconds = 4,
    },
    {
        key = "rend",
        ability = "Essence Rend",
        action = "DEBUFF — GO TO THE SIDE",
        warning = "DEBUFF — GO TO THE SIDE",
        voice = "Debuff side",
        timing = false,
        iconSpellID = 1287427,
    },
    {
        key = "burn_corpses",
        ability = "Corpse Burn",
        action = "BURN CORPSES",
        warning = "BURN CORPSES",
        voice = "Burn corpses",
        timing = false,
        iconSpellID = 1305421,
    },
    {
        key = "pyre",
        ability = "Hungering Pyre",
        action = "MELEE + TANK — SOAK",
        warning = "MELEE + TANK — SOAK",
        voice = "Melee tank soak",
        spellIDs = { 1305421, 1290679 },
        prepareSeconds = 8,
        pressSeconds = 5,
    },
}

local mythicCalls = {
    {
        key = "adds",
        ability = "Restless Amani",
        action = "Kill Amani before the Well",
        warning = "Amani: kill them before the Well.",
        voice = "Adds",
        spellIDs = { 1295397, 1297630 },
        prepareSeconds = 7,
        pressSeconds = 4,
    },
    {
        key = "grasping",
        ability = "Grasping Depths",
        action = "Assigned well group enters",
        warning = "Grasping: assigned well group enter.",
        actionTemplate = "{{rotation:well}} enter the Well",
        warningTemplate = "Grasping: {{rotation:well}} enter; interrupt and kill Echo.",
        voice = "Well group",
        spellIDs = { 1293212 },
        prepareSeconds = 8,
        pressSeconds = 5,
    },
    {
        key = "echoes",
        ability = "Echoes of Jawae",
        action = "Kill each Echo as it wakes",
        warning = "Echoes: kill each one as it wakes.",
        voice = "Echoes",
        timing = false,
        iconSpellID = 1289696,
    },
    {
        key = "pyre",
        ability = "Hungering Pyre",
        action = "Assigned group soaks; everyone else out",
        warning = "Pyre: assigned group soak; everyone else out.",
        actionTemplate = "{{pyre_soakers}} soak; everyone else out",
        warningTemplate = "Pyre: {{pyre_soakers}} soak; everyone else out.",
        voice = "Pyre",
        spellIDs = { 1305421, 1290679 },
        prepareSeconds = 8,
        pressSeconds = 5,
    },
    {
        key = "phase2",
        ability = "Phase 2",
        action = "Bloodlust; burn before full energy",
        warning = "Phase 2: Bloodlust; burn before full energy.",
        voice = "Phase two",
        timing = false,
        iconSpellID = 1299673,
    },
}

Registry:Register({
    key = "nekzali",
    name = "Nek'zali the Soulcoiler",
    encounterID = 3470,
    strategyStatus = "Heroic raid-lead profile refreshed against current 2026-09 guides; Mythic well/Pyre assignments retained separately; exact-ID timing only; PASS-LIVE pending",
    profiles = {
        heroic = {
            explanation = { "BL START" },
            calls = heroicCalls,
        },
        mythic = {
            explanation = {
                "When your well group is called, enter the Soulcoil Well.",
                "Inside: interrupt Soulcoiler's Curse and kill the Drowned Echo.",
                "Leave after it dies; Soul Exhaustion means do not enter again.",
                "Invoke starts: stop casting until it finishes.",
            },
            calls = mythicCalls,
        },
    },
})
