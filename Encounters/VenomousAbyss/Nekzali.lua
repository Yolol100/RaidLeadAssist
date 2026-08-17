local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function baseCalls(pyreAction, flameAction)
    return {
        {
            key = "adds",
            ability = "Restless Amani",
            action = "Kill ads",
            warning = "KILL ADS",
            voice = "Adds",
            spellIDs = { 1295397, 1297630 },
            prepareSeconds = 7,
            pressSeconds = 4,
        },
        {
            key = "rend",
            ability = "Essence Rend",
            action = "Go to the edge",
            warning = "GO TO THE EDGE",
            voice = "Rend",
            spellIDs = { 1287426 },
        },
        {
            key = "barrage",
            ability = "Possession Barrage",
            action = "Tank far > raid clear front",
            warning = "BARRAGE > TANK FAR > RAID CLEAR FRONT",
            voice = "Barrage",
            spellIDs = { 1292036, 1284103 },
        },
        {
            key = "ignition",
            ability = "Soulcoil Ignition",
            action = "Dodge impacts > healing CD",
            warning = "IGNITION > DODGE > HEALING CD",
            voice = "Ignition",
            spellIDs = { 1285681 },
        },
        {
            key = "echoes",
            ability = "Echoes of Jawae",
            action = "Kill Echoes",
            warning = "ECHOES > KILL ECHOES",
            voice = "Echoes",
            spellIDs = { 1289696 },
            timerNames = { "Tether of Awakening" },
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
        {
            key = "flame",
            ability = "Slithering Flame",
            action = flameAction,
            warning = flameAction,
            voice = "Flame",
            timing = false,
        },
        {
            key = "phase2",
            ability = "Phase 2",
            action = "Bloodlust > burn boss",
            warning = "PHASE 2 > BLOODLUST > BURN BOSS",
            voice = "Phase two",
            timing = false,
            iconSpellID = 1299673,
        },
    }
end

local normalCalls = baseCalls("MELEE SOAK", "RANGED SPREAD OUT")
local heroicCalls = baseCalls("MELEE SOAK", "RANGED BURN ADS")
local mythicCalls = baseCalls("GROUP 1 + 2 SOAK", "GROUP 3 + 4 BURN ADS")
mythicCalls[#mythicCalls + 1] = {
    key = "grasping",
    ability = "Grasping Depths",
    action = "Well team in > kick Curse > kill Echo > out",
    warning = "GRASPING > WELL TEAM IN > KICK CURSE > KILL ECHO > OUT",
    voice = "Well team",
    spellIDs = { 1293212 },
    prepareSeconds = 8,
    pressSeconds = 5,
}
mythicCalls[#mythicCalls + 1] = {
    key = "invoke",
    ability = "Invoke",
    action = "Stop casting",
    warning = "INVOKE > STOP CASTING",
    voice = "Stop casts",
    spellIDs = { 1299673 },
    prepareSeconds = 5,
    pressSeconds = 2,
}

Registry:Register({
    key = "nekzali",
    name = "Nek'zali the Soulcoiler",
    encounterID = 3470,
    strategyStatus = "12.1 Journal + current community strategy source-reviewed 2026-08-17; live validation pending",
    profiles = {
        normal = {
            explanation = {
                "PLAN: KEEP THE WELL EMPTY. BREAK AMANI SHIELDS AND KILL ADS BEFORE THEY REACH IT.",
                "ESSENCE REND GOES TO THE EDGE. BARRAGE TANK MOVES FAR; RAID CLEARS THE FRONT. DODGE IGNITION IMPACTS.",
                "AT 50% KILL ECHOES FAST. MELEE SOAK HUNGERING PYRE; RANGED STAY OUT AND SPREAD FOR SLITHERING FLAME.",
                "NORMAL HAS NO CREMATION/CORPSE BURN. PHASE 2: BLOODLUST WHEN NEK'ZALI BECOMES ACTIVE, THEN BURN BEFORE FULL ENERGY.",
            },
            calls = normalCalls,
        },
        heroic = {
            explanation = {
                "PLAN: NORMAL RULES PLUS CREMATION. NEVER FEED THE WELL; KILL AMANI BUT KEEP THEIR CORPSES AVAILABLE FOR THE INTERMISSION BURN.",
                "ESSENCE REND GOES TO THE EDGE. BARRAGE TANK FAR. AT 50% KILL ECHOES FAST.",
                "MELEE SOAK HUNGERING PYRE. RANGED STAY OUT FOR SLITHERING FLAME, THEN USE CREMATION TO BURN AMANI CORPSES.",
                "PHASE 2: BLOODLUST WHEN NEK'ZALI BECOMES ACTIVE, THEN BURN BEFORE FULL ENERGY.",
            },
            calls = heroicCalls,
        },
        mythic = {
            explanation = {
                "PLAN: HEROIC RULES PLUS ALTERNATING FRESH WELL TEAMS FOR GRASPING DEPTHS. KEEP THE WELL EMPTY OUTSIDE ASSIGNED ENTRIES.",
                "GROUPS 1+2 SOAK HUNGERING PYRE. GROUPS 3+4 STAY OUT FOR SLITHERING FLAME, THEN BURN AMANI CORPSES WITH CREMATION.",
                "WELL TEAM ENTERS, KICKS SOULCOILER'S CURSE, KILLS DROWNED ECHO, THEN EXITS; SOUL EXHAUSTION MEANS USE A FRESH TEAM NEXT TIME.",
                "INVOKE: STOP CASTING. PHASE 2: USE BLOODLUST WHEN NEK'ZALI BECOMES ACTIVE, THEN BURN BEFORE FULL ENERGY.",
            },
            calls = mythicCalls,
        },
    },
})
