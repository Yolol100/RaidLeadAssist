local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function baseCalls()
    return {
        { key="venom", ability="Venomous Surge", action="Debuff to markers > drop cysts", warning="VENOM > DEBUFF TO MARKERS > DROP CYSTS", voice="Venom", spellIDs={1305959}, prepareSeconds=6, pressSeconds=3 },
        { key="crosswinds", ability="Raging Crosswinds", action="Pair opposites > collide", warning="CROSSWINDS > PAIR OPPOSITES > COLLIDE", voice="Crosswinds", spellIDs={1285425}, prepareSeconds=7, pressSeconds=4 },
        { key="maelstrom", ability="Howling Maelstrom", action="Use cyst knockback > stay in", warning="MAELSTROM > USE CYST KNOCKBACK > STAY IN", voice="Maelstrom", spellIDs={1285732}, prepareSeconds=8, pressSeconds=5 },
        { key="apex", ability="Apex Predator", action="Next assigned group soaks green Mutilate", warning="GREEN MUTILATE > 5+ SOAK GROUP", voice="Soak", spellIDs={1277025,1285430}, prepareSeconds=7, pressSeconds=4 },
    }
end

Registry:Register({
    key="sszorak", name="Sszorak", encounterID=3420,
    strategyStatus="12.1 Journal + current Wowhead/Icy Veins/Raidstrats + Ready Check Pull visual guide + DBM/BigWigs source-reviewed 2026-08-18; live validation pending",
    profiles={
        normal={
            explanation={
                "PLAN: 1 PHASE. BLOODLUST ON PULL. PLACE 3 WORLD MARKERS OPPOSITE THE 3 TORNADO CLUSTERS. VENOM DEBUFF TARGETS TAKE THE GREEN ARROWS TO THOSE MARKERS AND DROP CYSTS THERE; KEEP CENTER OPEN.",
                "THE CYSTS ARE SETUP FOR MAELSTROM/DIG IN: THE WIND PUSHES THE RAID INTO A SAFE CYST AND ITS KNOCKBACK SENDS EVERYONE BACK IN. CROSSWINDS PAIR OPPOSITES AND COLLIDE.",
                "APEX: WHITE RAVAGE IS DBM-ONLY. GREEN MUTILATE ALTERNATES THE TWO ASSIGNED RAID SOAK GROUPS. BOSS TAKES 30% MORE DAMAGE FOR 25 SEC DURING DIG IN; SAVE DPS COOLDOWNS FOR THIS WINDOW.",
            }, calls=baseCalls(),
        },
        heroic={
            explanation={
                "PLAN: 1 PHASE. BLOODLUST ON PULL. PLACE 3 WORLD MARKERS OPPOSITE THE TORNADO CLUSTERS. VENOM DEBUFF TARGETS DROP CYSTS ON THOSE MARKERS; KEEP CYSTS AND CAUSTIC PUDDLES OUTSIDE, CENTER OPEN.",
                "THE CYSTS ARE SETUP FOR MAELSTROM/DIG IN: LET THE WIND PUSH THE RAID INTO A SAFE CYST SO ITS KNOCKBACK SENDS EVERYONE BACK IN. CROSSWINDS PAIR OPPOSITE DIRECTIONS AND COLLIDE.",
                "APEX: WHITE RAVAGE IS DBM-ONLY. GREEN MUTILATE ALTERNATES SOAK GROUP 1 AND SOAK GROUP 2; REPEAT MUTILATE DAMAGE IS HEAVILY INCREASED. SAVE DPS COOLDOWNS FOR THE 30% DIG IN WINDOW.",
            }, calls=baseCalls(),
        },
        mythic={
            explanation={
                "PLAN: BLOODLUST ON PULL. USE THE HEROIC MARKER, CYST AND CROSSWIND RULES. VENOM TARGETS BUILD THE CYST SETUP FOR EACH MAELSTROM/DIG IN.",
                "APEX: WHITE RAVAGE IS DBM-ONLY. GREEN MUTILATE ALTERNATES SOAK GROUP 1 AND SOAK GROUP 2. SERPENT'S FURY: 14+ PLAYERS STACK WITHIN 8 YARDS OF THE MARK BEFORE 100 RAGE.",
                "AFTER SERPENT'S FURY, VIRULENCE TARGETS SPREAD AND DROP RESIDUE CLEAR OF THE RAID. SAVE DPS COOLDOWNS FOR EACH DIG IN 30% DAMAGE WINDOW.",
            },
            calls={
                baseCalls()[1], baseCalls()[2], baseCalls()[3], baseCalls()[4],
                { key="serpent", ability="Serpent's Fury", action="14+ stack on mark", warning="SERPENT'S FURY > 14+ STACK ON MARK", voice="Stack", timing=false, iconSpellID=1305621 },
            },
        },
    },
})
