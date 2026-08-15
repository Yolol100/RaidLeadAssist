local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function baseCalls()
    return {
        { key="venom", ability="Venomous Surge", action="Targets out > drop cysts away", warning="VENOMOUS SURGE > TARGETS OUT > DROP CYSTS AWAY", voice="Venom", spellIDs={1305959} },
        { key="maelstrom", ability="Howling Maelstrom", action="Pop cyst > stay on platform > DPS CDs", warning="MAELSTROM > POP CYST > STAY ON PLATFORM > DPS CDS", voice="Maelstrom", spellIDs={1285732}, prepareSeconds=8, pressSeconds=5 },
        { key="apex", ability="Apex Predator", action="Mutilate > next assigned 5+ soak team", warning="APEX PREDATOR > MUTILATE > NEXT ASSIGNED 5+ SOAK TEAM IN", voice="Soak", spellIDs={1277025,1285430}, prepareSeconds=7, pressSeconds=4 },
    }
end

Registry:Register({
    key="sszorak", name="Sszorak", encounterID=3420,
    strategyStatus="12.1 difficulty plans source-reviewed 2026-08-15; live validation pending",
    profiles={
        normal={
            explanation={
                "PLAN: DROP CYSTS AROUND THE OUTSIDE SO THE MIDDLE STAYS PLAYABLE.",
                "VENOM TARGETS MOVE OUT. DO NOT DROP CYSTS ON THE RAID.",
                "CROSSWINDS: FOLLOW YOUR PERSONAL KNOCK DIRECTION AND STAY ON PLATFORM.",
                "BEFORE MAELSTROM: POP A SAFE CYST SO THE RAID GETS KNOCKBACK PROTECTION.",
                "MAELSTROM: STAY ON PLATFORM AND USE DPS CDS DURING THE DAMAGE WINDOW.",
                "APEX PREDATOR: ROTATE DISTINCT 5+ SOAK TEAMS FOR MUTILATE WITH THE TANK.",
            }, calls=baseCalls(),
        },
        heroic={
            explanation={
                "PLAN: MAKE A CLEAN CYST RING AROUND THE OUTSIDE; KEEP CENTER OPEN.",
                "VENOM TARGETS OUT. CROSSWINDS FOLLOW YOUR PERSONAL KNOCK DIRECTION.",
                "SAVE ONE SAFE CYST FOR EACH MAELSTROM AND POP IT JUST BEFORE THE WIND.",
                "MAELSTROM: STAY ON PLATFORM AND USE DPS CDS ON THE BOSS.",
                "APEX PREDATOR: ROTATE DISTINCT 5+ SOAK TEAMS; REPEATS TAKE HEAVIER MUTILATE DAMAGE.",
                "DO NOT WASTE CYSTS EARLY; THEY ARE YOUR MAELSTROM SAFETY TOOL.",
            }, calls=baseCalls(),
        },
        mythic={
            explanation={
                "PLAN: HEROIC CYST RING PLUS A FIXED SERPENT'S FURY STACK POINT.",
                "SERPENT'S FURY: 14+ PLAYERS STACK ON THE MARK FAST TO DUMP BOSS RAGE.",
                "AFTER THE CHARGE, SPREAD VIRULENCE CLEANLY AND STAY OUT OF RESIDUE.",
                "SAVE A SAFE CYST FOR EACH MAELSTROM; POP IT JUST BEFORE THE WIND.",
                "MAELSTROM: STAY ON PLATFORM AND USE DPS CDS DURING DIG IN.",
                "APEX PREDATOR: ROTATE DISTINCT 5+ SOAK TEAMS FOR EVERY MUTILATE.",
            },
            calls={
                baseCalls()[1], baseCalls()[2], baseCalls()[3],
                { key="serpent", ability="Serpent's Fury", action="14+ stack on marked player", warning="SERPENT'S FURY > 14+ PLAYERS STACK ON MARK NOW", voice="Stack", timing=false, iconSpellID=1305621 },
            },
        },
    },
})
