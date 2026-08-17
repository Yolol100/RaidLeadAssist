local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function baseCalls(pyreAction)
    return {
        {
            key = "adds",
            ability = "Restless Amani",
            action = "Break shields > kill adds",
            warning = "ADDS > BREAK SHIELDS > KILL",
            voice = "Adds",
            spellIDs = { 1295397, 1297630 },
            prepareSeconds = 7,
            pressSeconds = 4,
        },
        {
            key = "rend",
            ability = "Essence Rend",
            action = "Move to edge",
            warning = "ESSENCE REND > MOVE TO EDGE",
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
            key = "phase2",
            ability = "Phase 2",
            action = "Lust > burn boss",
            warning = "PHASE 2 > LUST > BURN BOSS",
            voice = "Phase two",
            timing = false,
            iconSpellID = 1299673,
        },
    }
end

local normalCalls = baseCalls("SOAK TEAM > IN")
local heroicCalls = baseCalls("SOAK TEAM > IN > FLAME TARGETS BURN CORPSES")
local mythicCalls = baseCalls("SOAK TEAM > IN > FLAME TARGETS BURN CORPSES")
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
                "PLAN: KEEP THE WELL EMPTY. BREAK AMANI SHIELDS AND KILL ADDS BEFORE THEY REACH IT.",
                "ESSENCE REND GOES EDGE. BARRAGE TANK MOVES FAR; RAID CLEARS THE FRONT. DODGE IGNITION IMPACTS.",
                "AT 50% KILL ECHOES FAST. PYRE USES THE ASSIGNED SOAK TEAM. PHASE 2: LUST AND BURN THE BOSS.",
            },
            calls = normalCalls,
        },
        heroic = {
            explanation = {
                "PLAN: NORMAL RULES PLUS RITUAL BURN. NEVER FEED THE WELL; KEEP AMANI CORPSES AVAILABLE FOR PYRE.",
                "REND GOES EDGE. BARRAGE TANK FAR. AT 50% KILL ECHOES; ASSIGNED PLAYERS SOAK PYRE.",
                "PYRE FLAME TARGETS BURN AMANI CORPSES WITH CREMATION. PHASE 2: LUST, DODGE, BURN.",
            },
            calls = heroicCalls,
        },
        mythic = {
            explanation = {
                "PLAN: HEROIC RULES PLUS ALTERNATING FRESH WELL TEAMS FOR GRASPING DEPTHS.",
                "WELL TEAM ENTERS, INTERRUPTS SOULCOILER'S CURSE, KILLS THE DROWNED ECHO, THEN EXITS; SOUL EXHAUSTION BLOCKS REPEATS.",
                "PYRE SOAKERS IN; FLAME TARGETS BURN AMANI CORPSES. INVOKE: STOP CASTING BEFORE THE INTERRUPT/SILENCE.",
                "KEEP EVERY SOUL OUT OF THE WELL. PHASE 2: LUST AND BURN.",
            },
            calls = mythicCalls,
        },
    },
})
