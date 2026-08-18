local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function baseCalls()
    return {
        { key="venom", ability="Venomous Surge", action="Green arrows to markers", warning="VENOM > GREEN ARROWS TO MARKERS", voice="Venom", spellIDs={1305959}, prepareSeconds=6, pressSeconds=3 },
        { key="crosswinds", ability="Raging Crosswinds", action="Pair opposites > collide", warning="CROSSWINDS > PAIR OPPOSITES > COLLIDE", voice="Crosswinds", spellIDs={1285425}, prepareSeconds=7, pressSeconds=4 },
        { key="maelstrom", ability="Howling Maelstrom", action="Use cyst knockback > stay in", warning="MAELSTROM > USE CYST KNOCKBACK > STAY IN", voice="Maelstrom", spellIDs={1285732}, prepareSeconds=8, pressSeconds=5 },
        { key="apex", ability="Apex Predator", action="Next 5+ soak team in", warning="MUTILATE > NEXT 5+ SOAK TEAM IN", voice="Soak", spellIDs={1277025,1285430}, prepareSeconds=7, pressSeconds=4 },
    }
end

Registry:Register({
    key="sszorak", name="Sszorak", encounterID=3420,
    strategyStatus="12.1 Journal + current Wowhead/Raidstrats + Ready Check Pull visual guide + DBM/BigWigs source-reviewed 2026-08-18; live validation pending",
    profiles={
        normal={
            explanation={
                "PLAN: 1 PHASE. PLACE 3 WORLD MARKERS OPPOSITE THE 3 TORNADO CLUSTERS. VENOM TARGETS TAKE GREEN ARROWS TO THE MARKERS AND DROP CYSTS THERE; KEEP CENTER OPEN.",
                "CROSSWINDS: PAIR WITH THE OPPOSITE DIRECTION AND LINE UP SO THE LAUNCHES COLLIDE. MUTILATE: NEXT ASSIGNED 5+ SOAK TEAM IN.",
                "MAELSTROM/DIG IN: LET THE WIND PUSH THE RAID INTO A SAFE CYST SO ITS KNOCKBACK SENDS EVERYONE BACK IN. BOSS TAKES 30% MORE DAMAGE FOR 25 SEC; BLOODLUST ON FIRST DIG IN.",
            }, calls=baseCalls(),
        },
        heroic={
            explanation={
                "PLAN: 1 PHASE. PLACE 3 WORLD MARKERS OPPOSITE THE 3 TORNADO CLUSTERS. VENOM TARGETS DROP CYSTS ON THE MARKERS; KEEP CYSTS AND CAUSTIC PUDDLES OUTSIDE, CENTER OPEN.",
                "CROSSWINDS: PAIR OPPOSITE DIRECTIONS AND COLLIDE AFTER THE LAUNCH. MUTILATE: ROTATE ASSIGNED 5+ SOAK TEAMS; REPEAT SOAK DAMAGE IS HEAVILY INCREASED.",
                "MAELSTROM/DIG IN: LET THE WIND PUSH THE RAID INTO A SAFE CYST SO ITS KNOCKBACK SENDS EVERYONE BACK IN. BOSS TAKES 30% MORE DAMAGE FOR 25 SEC; BLOODLUST ON FIRST DIG IN.",
            }, calls=baseCalls(),
        },
        mythic={
            explanation={
                "PLAN: USE THE HEROIC MARKER, CYST, CROSSWIND AND MUTILATE RULES. KEEP THE CENTER OPEN AND USE THE FIRST DIG IN 30% DAMAGE WINDOW FOR BLOODLUST.",
                "SERPENT'S FURY: 14+ PLAYERS STACK WITHIN 8 YARDS OF THE MARK BEFORE 100 RAGE. AFTER THE CHARGE, VIRULENCE TARGETS SPREAD AND DROP RESIDUE CLEAR OF THE RAID.",
                "MAELSTROM: LET THE WIND PUSH THE RAID INTO A SAFE CYST SO ITS KNOCKBACK SENDS EVERYONE BACK IN. ROTATE ASSIGNED 5+ MUTILATE SOAK TEAMS.",
            },
            calls={
                baseCalls()[1], baseCalls()[2], baseCalls()[3], baseCalls()[4],
                { key="serpent", ability="Serpent's Fury", action="14+ stack on mark", warning="SERPENT'S FURY > 14+ STACK ON MARK", voice="Stack", timing=false, iconSpellID=1305621 },
            },
        },
    },
})
