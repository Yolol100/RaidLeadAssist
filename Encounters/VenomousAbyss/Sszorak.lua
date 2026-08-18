local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local BOSSMOD_RULE = "CALL PRIORITY: FOLLOW DBM OR BIGWIGS FOR YOUR PERSONAL DEBUFFS, DODGES, ROLE WARNINGS AND TIMERS. FOLLOW RLA/RAID-LEADER CALLS FOR GROUPS, MARKERS, SOAKS, TARGET PRIORITY AND SHARED RAID MOVEMENT."

local function baseCalls()
    return {
        { key="venom", ability="Venomous Surge", action="Debuff to markers > drop cysts", warning="VENOM > DEBUFF TO MARKERS > DROP CYSTS", voice="Venom", spellIDs={1305959}, prepareSeconds=6, pressSeconds=3 },
        { key="crosswinds", ability="Raging Crosswinds", action="Pair opposites > collide", warning="CROSSWINDS > PAIR OPPOSITES > COLLIDE", voice="Crosswinds", spellIDs={1285425}, prepareSeconds=7, pressSeconds=4 },
        { key="maelstrom", ability="Howling Maelstrom", action="Cyst poppers 1/2/3 counter each wind", warning="MAELSTROM > POPPERS 1/2/3 > KNOCK AGAINST EACH WIND", voice="Maelstrom", spellIDs={1285732}, prepareSeconds=8, pressSeconds=5 },
        { key="apex", ability="Apex Predator", action="Next assigned team soaks green Mutilate", warning="GREEN MUTILATE > NEXT 5+ SOAK TEAM", voice="Soak", spellIDs={1277025,1285430}, prepareSeconds=7, pressSeconds=4 },
    }
end

Registry:Register({
    key="sszorak", name="Sszorak", encounterID=3420,
    strategyStatus="12.1 Journal + current Wowhead + DBM/BigWigs source-reviewed 2026-08-18; explicit three-Cyst-Popper Maelstrom ownership; live validation pending",
    profiles={
        normal={
            explanation={
                "PLAN: 1 PHASE. BLOODLUST ON PULL. PLACE 3 WORLD MARKERS OPPOSITE THE 3 TORNADO CLUSTERS. VENOM TARGETS DROP ONE CYST AT EACH MARK; KEEP CENTER OPEN.",
                "ASSIGN THREE CYST POPPERS. DURING MAELSTROM, POPPER 1/2/3 TRIGGERS THE PREPARED CYST AS EACH WIND STARTS SO THE KNOCKBACK PUSHES THE RAID AGAINST THE GALE.",
                "CROSSWINDS PAIR OPPOSITES AND COLLIDE. GREEN MUTILATE ALTERNATES TWO DISTINCT 5+ SOAK TEAMS: TEAM A THEN TEAM B. WHITE RAVAGE STAYS BOSSMOD/ROLE-OWNED.",
                "BOSS TAKES 30% MORE DAMAGE FOR 25 SEC DURING DIG IN; SAVE DPS COOLDOWNS FOR THAT WINDOW.",
                BOSSMOD_RULE,
            }, calls=baseCalls(),
        },
        heroic={
            explanation={
                "PLAN: BLOODLUST ON PULL. PLACE 3 WORLD MARKERS OPPOSITE THE TORNADO CLUSTERS. VENOM TARGETS DROP ONE CYST AT EACH MARK; KEEP CYSTS/PUDDLES OUTSIDE.",
                "ASSIGN THREE CYST POPPERS. POPPER 1/2/3 TRIGGERS THE PREPARED CYST AS EACH MAELSTROM WIND STARTS SO THE KNOCKBACK COUNTERS THE GALE.",
                "CROSSWINDS PAIR OPPOSITE DIRECTIONS AND COLLIDE. GREEN MUTILATE ALTERNATES DISTINCT 5+ TEAM A THEN B; REPEAT DAMAGE IS HEAVILY INCREASED.",
                "SAVE DPS COOLDOWNS FOR THE 30% DIG IN WINDOW. WHITE RAVAGE AND PERSONAL WIND DIRECTION STAY BOSSMOD/ROLE-OWNED.",
                BOSSMOD_RULE,
            }, calls=baseCalls(),
        },
        mythic={
            explanation={
                "PLAN: BLOODLUST ON PULL. USE THE HEROIC MARKER/CYST/CROSSWIND RULES AND THREE DISTINCT CYST POPPERS FOR THE THREE MAELSTROM WINDS.",
                "GREEN MUTILATE ALTERNATES TWO DISTINCT 5+ TEAMS: A THEN B. SERPENT'S FURY: 14+ PLAYERS STACK WITHIN 8 YARDS OF THE MARK BEFORE 100 RAGE.",
                "AFTER SERPENT'S FURY, VIRULENCE TARGETS SPREAD AND DROP RESIDUE CLEAR OF THE RAID. SAVE DPS COOLDOWNS FOR EACH 30% DIG IN WINDOW.",
                "WHITE RAVAGE AND PERSONAL WIND/VIRULENCE EXECUTION STAY BOSSMOD/ROLE-OWNED.",
                BOSSMOD_RULE,
            },
            calls={
                baseCalls()[1], baseCalls()[2], baseCalls()[3], baseCalls()[4],
                { key="serpent", ability="Serpent's Fury", action="14+ stack on mark", warning="SERPENT'S FURY > 14+ STACK ON MARK", voice="Stack", timing=false, iconSpellID=1305621 },
            },
        },
    },
})
