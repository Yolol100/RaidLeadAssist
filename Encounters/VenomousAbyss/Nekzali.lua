local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function baseCalls(pyreWarning)
    return {
        {
            key = "adds",
            ability = "Restless Amani",
            action = "Break shields > kill before Well",
            warning = "ADDS > BREAK SHIELDS > KILL BEFORE WELL",
            voice = "Adds",
            spellIDs = { 1295397, 1297630 },
            prepareSeconds = 7,
            pressSeconds = 4,
        },
        {
            key = "rend",
            ability = "Essence Rend",
            action = "Targets out > drop Cultists away",
            warning = "REND > TARGETS MOVE OUT > DROP CULTISTS AWAY",
            voice = "Rend",
            spellIDs = { 1287426 },
        },
        {
            key = "barrage",
            ability = "Possession Barrage",
            action = "Tank far > clear tank line",
            warning = "BARRAGE > TANK FAR > RAID CLEAR THE LINE",
            voice = "Barrage",
            spellIDs = { 1292036, 1284103 },
        },
        {
            key = "ignition",
            ability = "Soulcoil Ignition",
            action = "Healing CD > dodge impacts",
            warning = "IGNITION > HEALING CD > DODGE IMPACTS",
            voice = "Ignition",
            spellIDs = { 1285681 },
        },
        {
            key = "echoes",
            ability = "Echoes of Jawae",
            action = "Kill Echoes > break Tethers",
            warning = "ECHOES > KILL THEM > BREAK TETHERS",
            voice = "Echoes",
            spellIDs = { 1289696 },
            timerNames = { "Tether of Awakening" },
        },
        {
            key = "pyre",
            ability = "Hungering Pyre",
            action = pyreWarning,
            warning = pyreWarning,
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

local normalCalls = baseCalls("PYRE > ASSIGNED SOAKERS IN")
local heroicCalls = baseCalls("PYRE > SOAKERS IN > FLAME TARGETS BURN AMANI REMAINS")
local mythicCalls = baseCalls("PYRE > SOAKERS IN > FLAME TARGETS BURN AMANI REMAINS")
mythicCalls[#mythicCalls + 1] = {
    key = "grasping",
    ability = "Grasping Depths",
    action = "Assigned team into Well > kill Echo",
    warning = "GRASPING DEPTHS > ASSIGNED TEAM IN WELL > KILL DROWNED ECHO > GET OUT",
    voice = "Well team",
    spellIDs = { 1293212 },
    prepareSeconds = 8,
    pressSeconds = 5,
}
mythicCalls[#mythicCalls + 1] = {
    key = "invoke",
    ability = "Invoke",
    action = "Stop casts before Invoke lands",
    warning = "INVOKE > STOP CASTING BEFORE IT HITS > THEN DODGE CULTISTS",
    voice = "Stop casts",
    spellIDs = { 1299673 },
    prepareSeconds = 5,
    pressSeconds = 2,
}

Registry:Register({
    key = "nekzali",
    name = "Nek'zali the Soulcoiler",
    encounterID = 3470,
    strategyStatus = "12.1 difficulty plans source-reviewed 2026-08-14; live validation pending",
    profiles = {
        normal = {
            explanation = {
                "PLAN: KEEP THE RAID AROUND THE OUTSIDE. NOBODY DIES IN THE WELL.",
                "ADDS: BREAK SHIELDS AND KILL THEM BEFORE THEY REACH THE WELL.",
                "REND TARGETS MOVE OUT. BARRAGE TANK MOVES FAR; RAID CLEARS THE LINE.",
                "AT 50%: KILL ECHOES FAST TO BREAK ALL TETHERS.",
                "PYRE: USE THE ASSIGNED SOAK GROUP. EVERYONE ELSE STAYS CLEAR.",
                "PHASE 2: LUST, DODGE THE MOVING DANGER, AND BURN THE BOSS.",
            },
            calls = normalCalls,
        },
        heroic = {
            explanation = {
                "PLAN: KEEP THE RAID AROUND THE OUTSIDE. NEVER FEED THE WELL.",
                "ADDS: BREAK SHIELDS AND KILL THEM BEFORE THEY REACH THE WELL.",
                "REND TARGETS OUT. BARRAGE TANK FAR; RAID CLEARS THE LINE.",
                "AT 50%: KILL ECHOES. LEAVE AMANI REMAINS AVAILABLE FOR PYRE.",
                "PYRE: ASSIGNED SOAKERS IN. NON-SOAKERS WITH FLAME BURN AMANI REMAINS.",
                "DO NOT LET RITUAL BURN STACK FROM WELL FAILURES.",
                "PHASE 2: LUST, DODGE, AND BURN THE BOSS.",
            },
            calls = heroicCalls,
        },
        mythic = {
            explanation = {
                "PLAN: HEROIC RULES PLUS A FIXED WELL TEAM FOR GRASPING DEPTHS.",
                "GRASPING: WELL TEAM GOES IN, KILLS THE DROWNED ECHO, THEN GETS OUT.",
                "ADDS DIE BEFORE THE WELL. REND OUT. BARRAGE TANK FAR; RAID CLEARS LINE.",
                "AT 50%: KILL ECHOES. SAVE AMANI REMAINS FOR PYRE FLAME TARGETS.",
                "PYRE: SOAK GROUP IN; FLAME TARGETS BURN AMANI REMAINS.",
                "INVOKE INTERRUPTS CASTS: STOP CASTING BEFORE IT HITS, THEN DODGE CULTISTS.",
                "PHASE 2: LUST AND BURN WHILE KEEPING EVERY SOUL OUT OF THE WELL.",
            },
            calls = mythicCalls,
        },
    },
})
