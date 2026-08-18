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

local feastNormal = {
    key="feast",
    ability="Ravenous Feast",
    action="Raid soaks all three hits",
    warning="FEAST > RAID SOAK ALL 3 HITS",
    voice="Feast",
    spellIDs={1290516},
    prepareSeconds=8,
    pressSeconds=5,
}

local feastFresh = {
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
    strategyStatus="12.1 Journal + current Wowhead + Ready Check Pull recap screenshots + DBM/BigWigs source-reviewed 2026-08-18; volatile Venom thresholds not hard-coded; live validation pending",
    profiles={
        normal={
            explanation={
                "DAMAGE PLAN: BLOODLUST ON PULL. TWO-TARGET CLEAVE, KEEP BOTH BOSSES CLOSE IN HP, AND FINISH TOGETHER BEFORE UNCOILED WRATH RAMPS.",
                "KEEP ETERNAL VENOM LOW. GREEN ORBS: SOAK BEFORE RUPTURE. KILL EMERGENCE ADDS; SPIT TARGETS AIM LINES AWAY. RED CIRCLES EXPIRE AT THE EDGE.",
                "RAVENOUS FEAST: RAID SOAKS ALL THREE HITS TOGETHER TO REMOVE VENOM. NORMAL DOES NOT NEED THE HEROIC THREE-GROUP SPLIT.",
                "STONE BREAKER: AT LEAST ONE PLAYER MUST BE HIT BY EACH SLAM. TANK SOAKS ALL THREE MARKED IMPACTS IN SHOWN ORDER, THEN TANKS SWAP AFTER THE SET.",
                "AT 100 ENERGY MOVE TOWARD ITHRAZ, DODGE VEXHUL'S ROTATING FLOOD AND SANGUINE STORM, THEN REGROUP WHEN THE BOSSES RETURN.",
                BOSSMOD_RULE,
            },
            calls={ globules, adds, feastNormal, energy },
        },
        heroic={
            explanation={
                "DAMAGE PLAN: BLOODLUST ON PULL. TWO-TARGET CLEAVE, KEEP BOTH BOSSES CLOSE IN HP, AND FINISH TOGETHER BEFORE UNCOILED WRATH RAMPS.",
                "KEEP ETERNAL VENOM LOW. SOAK GREEN ORBS, KILL EMERGENCE ADDS, AIM SPIT LINES AWAY, AND DROP RED CIRCLES/CONGEALED GORE AT THE EDGE.",
                "RAVENOUS FEAST: THREE FRESH 3+ TEAMS SOAK IN ORDER TEAM A > TEAM B > TEAM C. FEASTED PLAYERS DO NOT REPEAT WITHIN THE SAME CAST.",
                "STONE BREAKER: AT LEAST ONE PLAYER MUST BE HIT BY EACH SLAM. TANK SOAKS ALL THREE MARKED IMPACTS IN SHOWN ORDER, THEN TANKS SWAP AFTER THE SET.",
                "AT 100 ENERGY MOVE TOWARD ITHRAZ, DODGE VEXHUL'S ROTATING FLOOD AND SANGUINE STORM, THEN REGROUP WHEN THE BOSSES RETURN.",
                BOSSMOD_RULE,
            },
            calls={ globules, adds, feastFresh, energy },
        },
        mythic={
            explanation={
                "DAMAGE PLAN: BLOODLUST ON PULL. MYTHIC IS FIXED AT 20 PLAYERS: TWO-TARGET CLEAVE, KEEP HP CLOSE, FINISH TOGETHER, AND KEEP ETERNAL VENOM LOW.",
                "SOAK GREEN ORBS BEFORE RUPTURE. DYING WITH ETERNAL VENOM CREATES EXTRA GLOBULES. KILL EMERGENCE ADDS; SPIT TARGETS AIM LINES AWAY.",
                "RAVENOUS FEAST: THREE FRESH 3+ TEAMS SOAK A > B > C. TAINTED BLOOD FOUNTS MUST BE HEALED OUT BEFORE THEY BURST.",
                "BLOOD TORRENT CREATES BARBED BULWARKS AROUND GLOBULES: INTERRUPT THEM. ROUSE THE BROOD: INTERRUPT EVERY BROODLING.",
                "STONE BREAKER: AT LEAST ONE PLAYER MUST BE HIT BY EACH SLAM. TANK SOAKS ALL THREE MARKED IMPACTS IN SHOWN ORDER, THEN TANKS SWAP AFTER THE SET.",
                "AT 100 ENERGY MOVE TOWARD ITHRAZ, DODGE THE ROTATING FLOOD AND SANGUINE STORM, THEN REGROUP WHEN THE BOSSES RETURN.",
                BOSSMOD_RULE,
            },
            calls={
                globules,
                adds,
                feastFresh,
                { key="tainted", ability="Tainted Blood", action="Founts > heal out", warning="TAINTED BLOOD > FOUNTS > HEAL OUT", voice="Heal founts", timing=false },
                { key="bulwark", ability="Blood Torrent / Barbed Bulwark", action="Interrupt Bulwarks", warning="BULWARKS > INTERRUPT", voice="Interrupt", spellIDs={1303230}, prepareSeconds=7, pressSeconds=4 },
                { key="brood", ability="Rouse the Brood", action="Interrupt every Broodling", warning="BROODLINGS > INTERRUPT ALL", voice="Interrupt", spellIDs={1308356}, prepareSeconds=4, pressSeconds=1 },
                energy,
            },
        },
    },
})
