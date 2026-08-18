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
    strategyStatus="12.1 Journal + current Wowhead + DBM/BigWigs source-reviewed 2026-08-19; Normal Feast corrected to fresh 3+ groups; player briefing split from raidleader prep; live validation pending",
    profiles={
        normal={
            explanation={
                "Keep both bosses at similar health and kill them together.",
                "Green globule appears: assigned player soaks it before it bursts.",
                "Feast starts: Team A, then Team B, then Team C soak.",
                "Already soaked this Feast: stay out of the remaining hits.",
                "Stone Breaker circles: assigned players soak every impact.",
                "Adds spawn: kill them quickly and face targeted spit away.",
                "At 100 energy: regroup and dodge the incoming waves.",
            },
            calls={ globules, adds, feastFresh, energy },
        },
        heroic={
            explanation={
                "Storm leaves blood pools: keep them outside movement paths.",
            },
            calls={ globules, adds, feastFresh, energy },
        },
        mythic={
            explanation={
                "Blood founts appear after Feast: heal every fount completely.",
                "Shielded globules: interrupt Protected Gestation immediately.",
                "Broodlings spawn: interrupt every Visceral Burst.",
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
