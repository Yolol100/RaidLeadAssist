local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local BOSSMOD_RULE = "CALL PRIORITY: FOLLOW DBM OR BIGWIGS FOR YOUR PERSONAL DEBUFFS, DODGES, ROLE WARNINGS AND TIMERS. FOLLOW RLA/RAID-LEADER CALLS FOR GROUPS, MARKERS, SOAKS, TARGET PRIORITY AND SHARED RAID MOVEMENT."

local function manualCall(key, ability, action, warning, voice, iconSpellID)
    return {
        key = key,
        ability = ability,
        action = action,
        warning = warning,
        voice = voice,
        timing = false,
        iconSpellID = iconSpellID,
    }
end

local function calls(coilText, eggText, includeFangs, includeMythic)
    local result = {
        manualCall("coils", "Spectral Coils", coilText, coilText, "Coils", 1300530),
        manualCall("warden", "Doomscale Warden", "Kill Warden > no egg touch until dead", "WARDEN > KILL > NO EGG TOUCH UNTIL DEAD", "Warden", 1298559),
        manualCall("eggs", "Doomscale Eggs", eggText, eggText, "Eggs", 1299650),
        manualCall("serpents", "Call of the Serpent", "Kill serpent adds", includeMythic and "CALL OF SERPENT > KILL ADDS BEFORE BOIL" or "CALL OF SERPENT > KILL ADDS", "Adds", 1300751),
        manualCall("heart", "Rage of the Shackled", "Burn exposed Venomous Heart", "RAGE > BURN VENOMOUS HEART", "Heart", 1286860),
    }

    if includeFangs then
        result[#result + 1] = manualCall("fangs", "Grasping Fangs", "Break one at a time", "FANGS > BREAK ONE AT A TIME", "Fangs", 1311611)
    end

    if includeMythic then
        result[#result + 1] = manualCall("incubation", "Toxic Incubation", "Four interceptors > one hit each", "INCUBATION > 4 INTERCEPTORS > ONE HIT EACH", "Intercept", 1299759)
    end

    result[#result + 1] = manualCall("phase3", "Ula'tek's Ascension", "Bloodlust > preserve safe space", "PHASE 3 > BLOODLUST > PRESERVE SAFE SPACE", "Bloodlust", 1286905)
    result[#result + 1] = manualCall("circling", "Circling Prey", "Move raid to next safe space", "CIRCLING PREY > MOVE TO NEXT SAFE SPACE", "Move", 1301510)
    return result
end

Registry:Register({
    key = "ulatek",
    name = "Ula'tek",
    encounterID = 3492,
    strategyStatus = "12.1 Journal + current strategy + DBM/BigWigs source-reviewed 2026-08-18; final boss was not PTR-tested; live validation required; timing remains manual",
    profiles = {
        normal = {
            explanation = {
                "P1: KEEP CAUSTIC WAVES OFF UNPLANNED EGGS. SPECTRAL COILS: RAID STACKS AT THE SOAK MARK. DURING RAGE, DODGE DEBRIS AND BURN THE EXPOSED HEART.",
                "P2: KILL THE DOOMSCALE WARDEN, THEN THE ASSIGNED EGG HANDLER USES THE PLANNED EGG. WARDEN'S PROTECTION FORBIDS TOUCHING EGGS WHILE IT LIVES.",
                "CALL OF SERPENT ADDS DIE FAST. BITE, PURGE, PETRIFYING STING, DODGES AND TANK-ONLY REACTIONS STAY DBM/BIGWIGS-OWNED.",
                "P3: BLOODLUST. CIRCLING PREY DESTROYS SAFE SPACE; MOVE AS A RAID TO THE NEXT SAFE AREA, KEEP WAVES OFF EGGS, AND BURN BEFORE FURY UNLEASHED.",
                BOSSMOD_RULE,
            },
            calls = calls(
                "COILS > STACK AT SOAK MARK",
                "EGG > ASSIGNED HANDLER AFTER WARDEN",
                false,
                false
            ),
        },
        heroic = {
            explanation = {
                "P1: KEEP WAVES OFF EGGS. COIL TEAM A/B ALTERNATE BECAUSE SOUL CONSTRICTOR PREVENTS THE SAME PLAYERS FROM MITIGATING THE NEXT COILS.",
                "P2: KILL WARDEN, THEN HANDLE ONLY THE PLANNED EGG SIDE; MASS GESTATION STARTS THE REMAINING EGGS ON THAT SIDE.",
                "BREAK GRASPING FANGS ONE AT A TIME TO SPACE RAIDWIDE BLIGHT VEIN. PETRIFYING STING, BITE, DODGES AND INDIVIDUAL ADD DEBUFFS STAY BOSSMOD-OWNED.",
                "RAGE: BURN HEART. CALL OF SERPENT: KILL ADDS. P3: BLOODLUST; MOVE TO EACH NEXT SAFE SPACE FOR CIRCLING PREY AND PRESERVE THE PLATFORM.",
                BOSSMOD_RULE,
            },
            calls = calls(
                "COILS > NEXT SOAK GROUP IN",
                "EGGS > PLANNED SIDE ONLY > OWNER IN",
                true,
                false
            ),
        },
        mythic = {
            explanation = {
                "P1: KEEP WAVES OFF EGGS. COIL TEAMS A/B ALTERNATE FOR SOUL CONSTRICTOR. TOXIC INCUBATION HAS FOUR IMPACTS; USE 4+ DISTINCT INTERCEPTORS, ONE HIT EACH.",
                "P2: KILL WARDEN. BREAK HARDENED EGG SHELLS; LEFT/RIGHT CARRIERS STAY 3+ YARDS APART. MASS GESTATION STARTS THE PLANNED SIDE.",
                "RANCID YOLK MAKES REPEAT SHELL DAMAGE DANGEROUS. BREAK FANGS ONE AT A TIME BECAUSE RAIDWIDE BLIGHT VEIN STACKS. KILL RAWLINGS BEFORE BOILING VENOM.",
                "CALL OF SERPENT ADDS DIE IMMEDIATELY. RAGE: BURN HEART. P3: BLOODLUST; MOVE WITH CIRCLING PREY, PRESERVE SAFE SPACE, AND BURN BEFORE FURY UNLEASHED.",
                "FINAL-BOSS TIMERS STAY MANUAL UNTIL LIVE RETAIL EVIDENCE CONFIRMS STABLE DBM/BIGWIGS/BLIZZARD EVENT IDENTITY AND CADENCE.",
                BOSSMOD_RULE,
            },
            calls = calls(
                "COILS > NEXT SOAK GROUP IN",
                "EGGS > PLANNED SIDE ONLY > CARRIERS 3+ YARDS",
                true,
                true
            ),
        },
    },
})
