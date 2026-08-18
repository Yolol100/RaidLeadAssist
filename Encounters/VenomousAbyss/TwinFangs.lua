local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

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

local function feast(warning, action)
    return {
        key="feast",
        ability="Ravenous Feast",
        action=action,
        warning=warning,
        voice="Feast",
        spellIDs={1290516},
        prepareSeconds=8,
        pressSeconds=5,
    }
end

local energy = {
    key="energy",
    ability="100 Energy",
    action="Move toward Ithraz",
    warning="100 ENERGY > MOVE TO ITHRAZ",
    voice="Move to Ithraz",
    spellIDs={1294921,1293792,1306872},
    timerNames={"Vile Flood","Flood","Sanguine Storm"},
    prepareSeconds=8,
    pressSeconds=5,
}

local normalFeast = feast(
    "FEAST > GROUPS 1+2 > 3+4 > 5+6",
    "Groups 1+2 > 3+4 > 5+6"
)

local mythicFeast = feast(
    "FEAST > GROUP 1 > GROUP 2 > GROUPS 3+4",
    "Group 1 > Group 2 > Groups 3+4"
)

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
                "RAVENOUS FEAST: HIT 1 GROUPS 1+2, HIT 2 GROUPS 3+4, HIT 3 GROUPS 5+6. EACH HIT NEEDS 3+ PLAYERS; DO NOT REPEAT FEASTED PLAYERS.",
                "AT 100 ENERGY MOVE TOWARD ITHRAZ; DODGE VEXHUL'S FLOOD AND BLOOD IMPACTS. STONE BREAKER IS DBM-OWNED.",
            },
            calls={ globules, adds, normalFeast, energy },
        },
        heroic={
            explanation={
                "PLAN: BLOODLUST ON PULL. CLEAVE BOTH BOSSES, KEEP THEIR HEALTH CLOSE, AND FINISH TOGETHER TO LIMIT UNCOILED WRATH. KEEP ETERNAL VENOM LOW.",
                "GREEN ORBS: SOAK BEFORE RUPTURE. KILL EMERGENCE ADDS; SPIT TARGETS AIM LINES AWAY. RED CIRCLES AND CONGEALED GORE STAY AT THE EDGE.",
                "RAVENOUS FEAST: HIT 1 GROUPS 1+2, HIT 2 GROUPS 3+4, HIT 3 GROUPS 5+6. EACH HIT NEEDS 3+ PLAYERS; FEASTED PLAYERS DO NOT REPEAT.",
                "AT 100 ENERGY MOVE TOWARD ITHRAZ; DODGE VEXHUL'S FLOOD AND SANGUINE STORM. STONE BREAKER IS DBM-OWNED.",
            },
            calls={ globules, adds, normalFeast, energy },
        },
        mythic={
            explanation={
                "PLAN: BLOODLUST ON PULL. MYTHIC IS FIXED AT 20 PLAYERS: CLEAVE BOTH BOSSES, KEEP HEALTH CLOSE, FINISH TOGETHER, AND KEEP ETERNAL VENOM LOW.",
                "GREEN ORBS: SOAK BEFORE RUPTURE. DYING WITH ETERNAL VENOM CREATES EXTRA GLOBULES. KILL EMERGENCE ADDS; SPIT TARGETS AIM LINES AWAY.",
                "RAVENOUS FEAST: HIT 1 GROUP 1, HIT 2 GROUP 2, HIT 3 GROUPS 3+4. TAINTED BLOOD FOUNTS MUST BE HEALED OUT BEFORE THEY BURST.",
                "BLOOD TORRENT CREATES BARBED BULWARKS AROUND GLOBULES: INTERRUPT PROTECTED GESTATION. ROUSE THE BROOD: INTERRUPT EVERY BROODLING.",
                "AT 100 ENERGY MOVE TOWARD ITHRAZ; DODGE FLOOD AND SANGUINE STORM. STONE BREAKER IS DBM-OWNED.",
            },
            calls={
                globules,
                adds,
                mythicFeast,
                { key="tainted", ability="Tainted Blood", action="Founts > heal out", warning="TAINTED BLOOD > FOUNTS > HEAL OUT", voice="Heal founts", timing=false },
                { key="bulwark", ability="Blood Torrent / Barbed Bulwark", action="Interrupt Bulwarks", warning="BULWARKS > INTERRUPT", voice="Interrupt", spellIDs={1303230}, prepareSeconds=7, pressSeconds=4 },
                { key="brood", ability="Rouse the Brood", action="Interrupt every Broodling", warning="BROODLINGS > INTERRUPT ALL", voice="Interrupt", spellIDs={1308356}, prepareSeconds=4, pressSeconds=1 },
                energy,
            },
        },
    },
})
