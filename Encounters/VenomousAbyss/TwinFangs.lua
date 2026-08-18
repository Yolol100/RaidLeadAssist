local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local BOSSMOD_RULE = "CALL PRIORITY: FOLLOW DBM OR BIGWIGS FOR YOUR PERSONAL DEBUFFS, DODGES, ROLE WARNINGS AND TIMERS. FOLLOW RLA/RAID-LEADER CALLS FOR GROUPS, MARKERS, SOAKS, TARGET PRIORITY AND SHARED RAID MOVEMENT."

local adds = {
    key="adds",
    ability="Venomous Emergence",
    action="Kill adds",
    warning="KILL ADDS",
    voice="Adds",
    spellIDs={1291404},
    prepareSeconds=6,
    pressSeconds=3,
}

local globules = {
    key="globules",
    ability="Caustic Globules",
    action="Soak green orbs before rupture",
    warning="GREEN ORBS > SOAK BEFORE RUPTURE",
    voice="Orbs",
    spellIDs={1289237,1289192},
    timerNames={"Caustic Deluge","Caustic Globules"},
    prepareSeconds=7,
    pressSeconds=4,
}

local feast = {
    key="feast",
    ability="Ravenous Feast",
    action="Fresh teams A > B > C",
    warning="FEAST > TEAM A > TEAM B > TEAM C",
    voice="Feast",
    spellIDs={1290516},
    prepareSeconds=8,
    pressSeconds=5,
}

-- Use Sanguine Storm as the single synchronization anchor for the shared
-- 100-energy movement call. DBM and BigWigs expose both simultaneous boss
-- mechanics as separate bars; matching both would let one RLA call arm twice.
local energy = {
    key="energy",
    ability="100 Energy",
    action="Move to Ithraz > dodge Flood/Storm",
    warning="100 ENERGY > MOVE TO ITHRAZ > DODGE FLOOD/STORM",
    voice="Move to Ithraz",
    spellIDs={1306872},
    timerNames={"Sanguine Storm"},
    prepareSeconds=8,
    pressSeconds=5,
}

Registry:Register({
    key="twinfangs",
    name="The Twin Fangs",
    encounterID=3421,
    strategyStatus="12.1 Journal + current Wowhead/Raidstrats + Ready Check Pull visual guide + DBM/BigWigs source-reviewed 2026-08-18; volatile tuning not hard-coded; live validation pending",
    profiles={
        normal={
            explanation={
                "PLAN: BLOODLUST ON PULL. CLEAVE BOTH BOSSES, KEEP THEIR HEALTH CLOSE, AND FINISH TOGETHER TO LIMIT UNCOILED WRATH. KEEP ETERNAL VENOM LOW.",
                "GREEN ORBS: SOAK BEFORE THEY RUPTURE. KILL VENOMOUS EMERGENCE ADDS; CORROSIVE SPIT TARGETS AIM LINES AWAY. RED CIRCLES GO TO THE EDGE.",
                "RAVENOUS FEAST: THREE FRESH 3+ TEAMS SOAK IN ORDER TEAM A > TEAM B > TEAM C. DO NOT REPEAT FEASTED PLAYERS WITHIN THE CAST; USE FEAST TO REMOVE ETERNAL VENOM.",
                "STONE BREAKER: AT LEAST ONE PLAYER MUST BE HIT BY EACH SLAM OR THE PLATFORM REVERBERATES; LIVE SOAK/ROLE EXECUTION FOLLOWS DBM/BIGWIGS. AT 100 ENERGY MOVE TO ITHRAZ AND DODGE FLOOD/STORM.",
                BOSSMOD_RULE,
            },
            calls={ globules, adds, feast, energy },
        },
        heroic={
            explanation={
                "PLAN: BLOODLUST ON PULL. CLEAVE BOTH BOSSES, KEEP THEIR HEALTH CLOSE, AND FINISH TOGETHER TO LIMIT UNCOILED WRATH. KEEP ETERNAL VENOM LOW.",
                "GREEN ORBS: SOAK BEFORE RUPTURE. KILL EMERGENCE ADDS; SPIT TARGETS AIM LINES AWAY. RED CIRCLES AND CONGEALED GORE STAY AT THE EDGE.",
                "RAVENOUS FEAST: THREE FRESH 3+ TEAMS SOAK IN ORDER TEAM A > TEAM B > TEAM C. FEASTED PLAYERS DO NOT REPEAT WITHIN THE SAME CAST.",
                "STONE BREAKER: AT LEAST ONE PLAYER MUST BE HIT BY EACH SLAM OR THE PLATFORM REVERBERATES; LIVE SOAK/ROLE EXECUTION FOLLOWS DBM/BIGWIGS. AT 100 ENERGY MOVE TO ITHRAZ AND DODGE FLOOD/STORM.",
                BOSSMOD_RULE,
            },
            calls={ globules, adds, feast, energy },
        },
        mythic={
            explanation={
                "PLAN: BLOODLUST ON PULL. MYTHIC IS FIXED AT 20 PLAYERS: CLEAVE BOTH BOSSES, KEEP HEALTH CLOSE, FINISH TOGETHER, AND KEEP ETERNAL VENOM LOW.",
                "GREEN ORBS: SOAK BEFORE RUPTURE. DYING WITH ETERNAL VENOM CREATES EXTRA GLOBULES. KILL EMERGENCE ADDS; SPIT TARGETS AIM LINES AWAY.",
                "RAVENOUS FEAST: THREE FRESH 3+ TEAMS SOAK IN ORDER TEAM A > TEAM B > TEAM C. TAINTED BLOOD FOUNTS MUST BE HEALED OUT BEFORE THEY BURST.",
                "BLOOD TORRENT CREATES BARBED BULWARKS AROUND GLOBULES: INTERRUPT PROTECTED GESTATION. ROUSE THE BROOD: INTERRUPT EVERY BROODLING.",
                "STONE BREAKER: AT LEAST ONE PLAYER MUST BE HIT BY EACH SLAM OR THE PLATFORM REVERBERATES; LIVE SOAK/ROLE EXECUTION FOLLOWS DBM/BIGWIGS. AT 100 ENERGY MOVE TO ITHRAZ AND DODGE FLOOD/STORM.",
                BOSSMOD_RULE,
            },
            calls={
                globules,
                adds,
                feast,
                { key="tainted", ability="Tainted Blood", action="Founts > heal out", warning="TAINTED BLOOD > FOUNTS > HEAL OUT", voice="Heal founts", timing=false },
                { key="bulwark", ability="Blood Torrent / Barbed Bulwark", action="Interrupt Bulwarks", warning="BULWARKS > INTERRUPT", voice="Interrupt", spellIDs={1303230}, prepareSeconds=7, pressSeconds=4 },
                { key="brood", ability="Rouse the Brood", action="Interrupt every Broodling", warning="BROODLINGS > INTERRUPT ALL", voice="Interrupt", spellIDs={1308356}, prepareSeconds=4, pressSeconds=1 },
                energy,
            },
        },
    },
})
