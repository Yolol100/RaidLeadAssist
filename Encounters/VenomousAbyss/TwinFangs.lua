local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local adds = { key="adds", ability="Venomous Emergence", action="Kill spawns now", warning="VENOMOUS EMERGENCE > KILL SPAWNS NOW", voice="Adds", spellIDs={1291404}, prepareSeconds=6, pressSeconds=3 }
local globules = {
    key="globules",
    ability="Caustic Globules",
    action="Assigned players touch each before rupture",
    warning="CAUSTIC GLOBULES > ASSIGNED SOAKERS TOUCH EACH BEFORE IT RUPTURES",
    voice="Globules",
    spellIDs={1289237,1289192},
    timerNames={"Caustic Deluge","Caustic Globules"},
    prepareSeconds=7,
    pressSeconds=4,
}
local stone = {
    key="stone",
    ability="Stone Breaker",
    action="Assigned players rotate into slams",
    warning="STONE BREAKER > ASSIGNED PLAYERS ROTATE INTO SLAMS > NEVER LEAVE ONE EMPTY",
    voice="Stone breaker",
    spellIDs={1289092,1310371,1288538,1288484},
    prepareSeconds=7,
    pressSeconds=4,
}
local function feast()
    return { key="feast", ability="Ravenous Feast", action="3 hits > rotate A > B > C", warning="RAVENOUS FEAST > 3 HITS > ROTATE SOAK GROUPS A > B > C", voice="Feast", spellIDs={1290516}, prepareSeconds=8, pressSeconds=5 }
end

Registry:Register({
    key="twinfangs", name="The Twin Fangs", encounterID=3421,
    strategyStatus="12.1 difficulty plans source-reviewed 2026-08-14; live validation pending",
    profiles={
        normal={
            explanation={
                "PLAN: KEEP BOTH BOSSES TOGETHER FOR CLEAVE AND WATCH YOUR ETERNAL VENOM.",
                "CAUSTIC GLOBULES: ASSIGN PLAYERS TO TOUCH EACH GLOBULE BEFORE IT RUPTURES.",
                "HIGH VENOM PLAYERS JOIN RAVENOUS FEAST TO REMOVE STACKS.",
                "FEAST HITS 3 TIMES. ROTATE A > B > C; FEASTED PLAYERS DO NOT REPEAT.",
                "STONE BREAKER: ASSIGNED PLAYERS ROTATE INTO SLAMS; NEVER LEAVE A SLAM EMPTY.",
                "VENOMOUS EMERGENCE: HARD SWAP AND KILL THE SPAWNS FAST.",
                "AT 100 ENERGY: DODGE VILE FLOOD AND SANGUINE STORM.",
            },
            calls={
                feast(),
                globules,
                stone,
                adds,
            },
        },
        heroic={
            explanation={
                "PLAN: KEEP BOTH BOSSES TOGETHER AND USE 3 ASSIGNED FEAST GROUPS.",
                "CAUSTIC GLOBULES: ASSIGNED PLAYERS TOUCH EACH GLOBULE BEFORE IT RUPTURES.",
                "RAVENOUS FEAST HITS 3 TIMES. ROTATE A > B > C; FEASTED PLAYERS DO NOT REPEAT.",
                "STONE BREAKER: ASSIGNED PLAYERS ROTATE INTO SLAMS; NEVER LEAVE A SLAM EMPTY.",
                "VENOMOUS EMERGENCE: HARD SWAP AND KILL SPAWNS FAST.",
                "AT 100 ENERGY: DODGE VILE FLOOD AND SANGUINE STORM.",
                "IF YOUR VENOM IS HIGH, MOVE INTO YOUR NEXT ASSIGNED FEAST GROUP.",
            },
            calls={
                feast(),
                globules,
                stone,
                adds,
            },
        },
        mythic={
            explanation={
                "PLAN: HEROIC FEAST ROTATION PLUS MYTHIC GLOBULE, BLOOD, AND BROOD CONTROL.",
                "GLOBULES: ASSIGN SOAKERS; DURING BLOOD TORRENT BREAK BULWARKS BEFORE TOUCHING.",
                "FEAST: ROTATE A > B > C. NEVER SEND FEASTED PLAYERS BACK IN EARLY.",
                "TAINTED BLOOD: ASSIGNED GROUPS STAND IN FOUNTS AND HEAL THEM OUT BEFORE EXPIRY.",
                "ROUSE THE BROOD: EACH BROODLING GETS AN INTERRUPT; A KICK MAKES IT RETREAT.",
                "STONE BREAKER: ROTATE ASSIGNED PLAYERS INTO SLAMS; NEVER LEAVE ONE EMPTY.",
                "VENOMOUS EMERGENCE ADDS DIE FAST. AVOID EXTRA DEATHS WITH ETERNAL VENOM.",
                "AT 100 ENERGY: DODGE VILE FLOOD AND SANGUINE STORM.",
            },
            calls={
                feast(),
                globules,
                stone,
                adds,
                { key="blood", ability="Blood Torrent", action="Heal tank absorb > break Bulwarks", warning="BLOOD TORRENT > HEAL TANK ABSORB > INTERRUPT BARBED BULWARKS", voice="Blood", spellIDs={1303230}, prepareSeconds=7, pressSeconds=4 },
                { key="brood", ability="Rouse the Brood", action="Interrupt every Broodling", warning="ROUSE THE BROOD > INTERRUPT EVERY BROODLING NOW", voice="Interrupt", spellIDs={1308356}, prepareSeconds=4, pressSeconds=1 },
                { key="tainted", ability="Tainted Blood", action="Groups in founts > heal out before expiry", warning="TAINTED BLOOD > ASSIGNED GROUPS IN FOUNTS > HEAL THEM OUT BEFORE EXPIRY", voice="Heal founts", timing=false },
            },
        },
    },
})
