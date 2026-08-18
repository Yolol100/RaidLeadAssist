local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function baseCalls(pyreAction, flameAction)
    local calls = {
        {
            key = "adds",
            ability = "Restless Amani",
            action = "Kill adds",
            warning = "KILL ADS",
            voice = "Adds",
            spellIDs = { 1295397, 1297630 },
            prepareSeconds = 7,
            pressSeconds = 4,
        },
        {
            key = "echoes",
            ability = "Echoes of Jawae",
            action = "Kill each Echo as it awakens",
            warning = "KILL ECHOES",
            voice = "Echoes",
            timing = false,
            iconSpellID = 1289696,
        },
        {
            key = "pyre",
            ability = "Hungering Pyre",
            action = pyreAction,
            warning = pyreAction,
            voice = "Pyre",
            spellIDs = { 1305421, 1290679 },
            prepareSeconds = 8,
            pressSeconds = 5,
        },
    }
    if flameAction then
        calls[#calls + 1] = {
            key = "flame",
            ability = "Slithering Flame",
            action = flameAction,
            warning = flameAction,
            voice = "Flame",
            timing = false,
        }
    end
    calls[#calls + 1] = {
        key = "phase2",
        ability = "Phase 2",
        action = "Bloodlust > burn boss",
        warning = "PHASE 2 > BLOODLUST > BURN BOSS",
        voice = "Phase two",
        timing = false,
        iconSpellID = 1299673,
    }
    return calls
end

local normalCalls = baseCalls("MELEE SOAK", nil)
local heroicCalls = baseCalls("ASSIGNED SOAK GROUP IN", "FIRE CIRCLE > BURN AMANI CORPSE")
local mythicCalls = baseCalls("GROUPS 1+2 SOAK", "GROUPS 3+4 BURN CORPSES")
table.insert(mythicCalls, 2, {
    key = "grasping",
    ability = "Grasping Depths",
    action = "Next fresh well group in > kick > kill Echo > out",
    warning = "GRASPING > NEXT WELL GROUP IN > KICK > KILL ECHO > OUT",
    voice = "Well group",
    spellIDs = { 1293212 },
    prepareSeconds = 8,
    pressSeconds = 5,
})

Registry:Register({
    key = "nekzali",
    name = "Nek'zali the Soulcoiler",
    encounterID = 3470,
    strategyStatus = "12.1 Journal + current Wowhead/Ready Check Pull + DBM/BigWigs source-reviewed 2026-08-19; player briefing split from raidleader prep; live validation pending",
    profiles = {
        normal = {
            explanation = {
                "Keep the Soulcoil Well clear; kill Amani before they enter.",
                "At 50%, kill each Echo as it becomes active.",
                "Hungering Pyre: melee stay in and soak together.",
                "Ranged stay outside and spread for their fire circles.",
                "Phase 2: Bloodlust and burn before full energy.",
            },
            calls = normalCalls,
        },
        heroic = {
            explanation = {
                "Heroic Pyre: soak with your assigned group instead of melee-only.",
                "Fire circle on you: move onto a dead Amani corpse.",
                "Stay on the corpse until your fire explodes; keep 4+ yards from others.",
            },
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
