local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function baseCalls(pyreAction, pyreWarning, flameAction, flameWarning)
    local calls = {
        {
            key = "adds",
            ability = "Restless Amani",
            action = "Kill the Amani before the Well",
            warning = "Amani adds: kill them before the Well.",
            voice = "Adds",
            spellIDs = { 1295397, 1297630 },
            prepareSeconds = 7,
            pressSeconds = 4,
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
            action = pyreAction,
            warning = pyreWarning,
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
            warning = flameWarning,
            voice = "Flame",
            timing = false,
        }
    end
    calls[#calls + 1] = {
        key = "phase2",
        ability = "Phase 2",
        action = "Bloodlust and burn the boss",
        warning = "Phase 2: Bloodlust and burn the boss.",
        voice = "Phase two",
        timing = false,
        iconSpellID = 1299673,
    }
    return calls
end

local normalCalls = baseCalls(
    "Melee soak together",
    "Hungering Pyre: melee soak together."
)
local heroicCalls = baseCalls(
    "Called soak group stacks in",
    "Hungering Pyre: called soak group stack in.",
    "Take fire circles to dead Amani",
    "Fire circles: take them to dead Amani corpses."
)
local mythicCalls = baseCalls(
    "Called soak group stacks in",
    "Hungering Pyre: called soak group stack in.",
    "Take fire circles to dead Amani",
    "Fire circles: take them to dead Amani corpses."
)
table.insert(mythicCalls, 2, {
    key = "grasping",
    ability = "Grasping Depths",
    action = "Enter, interrupt, kill the Echo, then exit",
    warning = "Grasping Depths: called well group enter, interrupt, kill the Echo, then exit.",
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
