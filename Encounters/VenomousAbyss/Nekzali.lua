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
local heroicCalls = baseCalls("MELEE SOAK", "RANGED BURN CORPSES")
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
    strategyStatus = "12.1 Journal + current Wowhead/Ready Check Pull + DBM/BigWigs source-reviewed 2026-08-18; raidlead-only call scope; live validation pending",
    profiles = {
        normal = {
            explanation = {
                "PLAN: KEEP THE SOULCOIL WELL EMPTY. KILL RAISED AMANI BEFORE THEY REACH IT; NEVER DIE IN THE WELL.",
                "ESSENCE REND GOES TO THE EDGE. STAY CLEAR OF POSSESSION BARRAGE AND DODGE SOULCOIL IGNITION IMPACTS.",
                "AT 50% KILL EACH ECHO AS IT AWAKENS. MELEE SOAK HUNGERING PYRE; RANGED STAY OUT AND SPREAD FOR SLITHERING FLAME.",
                "PHASE 2: BLOODLUST WHEN NEK'ZALI BECOMES ACTIVE, THEN BURN BEFORE FULL ENERGY.",
            },
            calls = normalCalls,
        },
        heroic = {
            explanation = {
                "PLAN: KEEP THE WELL EMPTY. KILL AMANI BEFORE THEY REACH IT, BUT KEEP THEIR CORPSES AVAILABLE FOR THE INTERMISSION.",
                "ESSENCE REND GOES TO THE EDGE. STAY CLEAR OF POSSESSION BARRAGE AND DODGE SOULCOIL IGNITION IMPACTS.",
                "AT 50% KILL ECHOES. MELEE SOAK PYRE; RANGED STAY OUT, THEN TAKE CREMATION TO AMANI CORPSES TO BURN THEM.",
                "PHASE 2: BLOODLUST WHEN NEK'ZALI BECOMES ACTIVE, THEN BURN BEFORE FULL ENERGY.",
            },
            calls = heroicCalls,
        },
        mythic = {
            explanation = {
                "PLAN: HEROIC RULES PLUS ALTERNATING FRESH WELL GROUPS FOR GRASPING DEPTHS. KEEP THE WELL EMPTY OUTSIDE ASSIGNED ENTRIES.",
                "GROUPS 1+2 SOAK HUNGERING PYRE. GROUPS 3+4 STAY OUT, THEN BURN AMANI CORPSES WITH CREMATION.",
                "GRASPING: NEXT FRESH WELL GROUP ENTERS, KICKS SOULCOILER'S CURSE, KILLS DROWNED ECHO, THEN EXITS; SOUL EXHAUSTION FORCES A FRESH GROUP.",
                "INVOKE INTERRUPTS ACTIVE CASTS: STOP CASTING BEFORE IT LANDS. PHASE 2: BLOODLUST, THEN BURN BEFORE FULL ENERGY.",
            },
            calls = mythicCalls,
        },
    },
})
