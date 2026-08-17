local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local balance = { key="balance", ability="Boss Health", action="Keep both even", warning="BOSS HEALTH > KEEP BOTH EVEN", voice="Balance", timing=false }
local adds = { key="adds", ability="Venomous Emergence", action="Kill adds", warning="VENOMOUS EMERGENCE > KILL ADDS", voice="Adds", spellIDs={1291404}, prepareSeconds=6, pressSeconds=3 }
local globules = {
    key="globules",
    ability="Caustic Globules",
    action="Assigned players soak globules",
    warning="GLOBULES > ASSIGNED PLAYERS SOAK",
    voice="Globules",
    spellIDs={1289237,1289192},
    timerNames={"Caustic Deluge","Caustic Globules"},
    prepareSeconds=7,
    pressSeconds=4,
}
local stone = {
    key="stone",
    ability="Stone Breaker",
    action="Next assigned soaker in",
    warning="STONE BREAKER > NEXT SOAKER IN",
    voice="Stone breaker",
    spellIDs={1289092,1310371,1288538,1288484},
    prepareSeconds=7,
    pressSeconds=4,
}
local function feast()
    return { key="feast", ability="Ravenous Feast", action="Groups A > B > C", warning="RAVENOUS FEAST > GROUPS A > B > C", voice="Feast", spellIDs={1290516}, prepareSeconds=8, pressSeconds=5 }
end

Registry:Register({
    key="twinfangs", name="The Twin Fangs", encounterID=3421,
    strategyStatus="12.1 Journal + current community/PTR strategy source-reviewed 2026-08-17; volatile tuning not hard-coded; live validation pending",
    profiles={
        normal={
            explanation={
                "PLAN: KEEP BOTH BOSSES TOGETHER FOR CLEAVE, KEEP HEALTH EVEN, AND FINISH TOGETHER. NEVER LET ETERNAL VENOM REACH LETHAL STACKS.",
                "FEAST HITS THREE TIMES: USE DISTINCT 3+ PLAYER GROUPS A, B, C. ASSIGNED PLAYERS SOAK CAUSTIC GLOBULES AND ROTATE STONE BREAKER SOAKERS.",
                "KILL VENOMOUS EMERGENCE ADDS FAST. AT 100 ENERGY DODGE VILE FLOOD AND SANGUINE STORM.",
            },
            calls={ balance, feast(), globules, stone, adds },
        },
        heroic={
            explanation={
                "PLAN: KEEP BOSSES TOGETHER, HEALTH EVEN, FINISH TOGETHER. MANAGE ETERNAL VENOM WITH THREE DISTINCT FEAST GROUPS; FEASTED PLAYERS DO NOT REPEAT.",
                "ASSIGNED PLAYERS SOAK GLOBULES BEFORE RUPTURE. ROTATE DISTINCT STONE BREAKER SOAKERS. KILL EMERGENCE ADDS FAST.",
                "AT 100 ENERGY DODGE VILE FLOOD/STORM AND KEEP NEW PUDDLES FROM TRAPPING THE RAID.",
            },
            calls={ balance, feast(), globules, stone, adds },
        },
        mythic={
            explanation={
                "PLAN: HEROIC FEAST/GLOBULE/STONE ROTATIONS PLUS BLOOD FOUNT AND BROODLING COVERAGE. KEEP BOTH BOSSES EVEN AND FINISH TOGETHER.",
                "BLOOD TORRENT: HEAL THE TANK ABSORB AND STOP BARBED BULWARK CASTS. TAINTED BLOOD GROUPS ENTER FOUNTS AND GET HEALED OUT BEFORE EXPIRY.",
                "ROUSE THE BROOD: EACH BROODLING GETS A SEPARATE INTERRUPT OWNER. KILL EMERGENCE ADDS; KEEP ETERNAL VENOM UNDER CONTROL.",
            },
            calls={
                balance,
                feast(),
                globules,
                stone,
                adds,
                { key="blood", ability="Blood Torrent", action="Heal absorb > stop Bulwarks", warning="BLOOD TORRENT > HEAL ABSORB > STOP BULWARKS", voice="Blood", spellIDs={1303230}, prepareSeconds=7, pressSeconds=4 },
                { key="brood", ability="Rouse the Brood", action="Interrupt every Broodling", warning="ROUSE THE BROOD > INTERRUPT EVERY BROODLING", voice="Interrupt", spellIDs={1308356}, prepareSeconds=4, pressSeconds=1 },
                { key="tainted", ability="Tainted Blood", action="Groups in founts > heal out", warning="TAINTED BLOOD > GROUPS IN FOUNTS > HEAL OUT", voice="Heal founts", timing=false },
            },
        },
    },
})
