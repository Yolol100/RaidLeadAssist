local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local BOSSMOD_RULE = "CALL PRIORITY: FOLLOW DBM OR BIGWIGS FOR YOUR PERSONAL DEBUFFS, DODGES, ROLE WARNINGS AND TIMERS. FOLLOW RLA/RAID-LEADER CALLS FOR GROUPS, MARKERS, SOAKS, TARGET PRIORITY AND SHARED RAID MOVEMENT."

local dread = {
    key = "dreadmarch",
    ability = "Dreadmarch",
    action = "Break shields > ghosts to Sever mark",
    warning = "DREADMARCH > BREAK SHIELDS > GHOSTS TO SEVER MARK",
    voice = "Dreadmarch",
    spellIDs = { 1289900 },
    prepareSeconds = 7,
    pressSeconds = 4,
}

local night = {
    key = "nightfall",
    ability = "Eternal Nightfall",
    action = "Break shield > interrupt",
    warning = "NIGHTFALL > BREAK SHIELD > INTERRUPT",
    voice = "Nightfall",
    spellIDs = { 1286918 },
    prepareSeconds = 5,
    pressSeconds = 2,
}

local spirit = {
    key = "spiritcackle",
    ability = "Spiritcackle",
    action = "Kill Soulcoilers > kick Wail",
    warning = "SOULCOILERS > KILL > KICK WAIL",
    voice = "Add",
    spellIDs = { 1286441 },
}

local intermission = {
    key = "intermission",
    ability = "Soulbinding",
    action = "Bloodlust > burn Zul'jan > fragments one at a time",
    warning = "SOULBINDING > BLOODLUST > BURN ZUL'JAN > FRAGMENTS ONE AT A TIME",
    voice = "Bloodlust",
    timing = false,
}

local final = {
    key = "final",
    ability = "Coiled Union",
    action = "Keep both even > kill together",
    warning = "PHASE 3 > KEEP BOTH EVEN > KILL TOGETHER",
    voice = "Kill together",
    timing = false,
    iconSpellID = 1298381,
}

local function guillotine(text)
    return {
        key = "guillotine",
        ability = "Guillotine",
        action = text,
        warning = text,
        voice = "Guillotine",
        spellIDs = { 1283489, 1283485, 1299266 },
        timerNames = { "Guillotine", "Grim Guillotine" },
        prepareSeconds = 8,
        pressSeconds = 5,
    }
end

local function toxic(text)
    return {
        key = "toxic",
        ability = "Toxic Deluge",
        action = text,
        warning = text,
        voice = "Venom",
        spellIDs = { 1299960 },
        timerNames = { "Toxic Deluge" },
        prepareSeconds = 7,
        pressSeconds = 4,
    }
end

local function gloombomb(text)
    return {
        key = "gloombomb",
        ability = "Gloombomb",
        action = text,
        warning = text,
        voice = "Bomb",
        spellIDs = { 1286895 },
        prepareSeconds = 6,
        pressSeconds = 3,
    }
end

Registry:Register({
    key = "altar",
    name = "The Coiled Altar",
    encounterID = 3429,
    encounterAliases = { "The Bargained Crown" },
    strategyStatus = "12.1 Journal + current Wowhead + Ready Check Pull recap screenshot + DBM/BigWigs source-reviewed 2026-08-18; RCP intermission-Bloodlust tactic selected; live Retail validation pending",
    profiles = {
        normal = {
            explanation = {
                "DAMAGE PLAN: P1 + P2 SINGLE TARGET. PREPULL: PLACE SEVER / SOUL SEVER WORLD MARKS AT BOTH PLATFORM ENDS AND ASSIGN 2-3 MOBILE ORB COLLECTORS.",
                "P1: COLLECT GREEN ORBS AT THE ACTIVE SEVER MARK; TANK SEVER CLEARS A FEW AT A TIME. MINIMIZE LEFTOVER ORBS BEFORE ZUL'JAN DIES; USE HEALER CDS FOR THE RUPTURES.",
                "GUILLOTINE: 5+ ASSIGNED SOAKERS STACK NEAR THE EDGE, THEN THE RAID MOVES 40+ YARDS FROM THE AXE. VENOMFANG DISPELS AND TANK SWAPS STAY BOSSMOD/ROLE-OWNED.",
                "P2: BREAK DREADMARCH SHIELDS BEFORE PLAYERS REACH THE EDGE. FIXATE TARGETS GUIDE GHOSTS TO THE SOUL SEVER MARK; LOOK AT A GHOST TO STOP IT, LOOK AWAY TO MOVE IT.",
                "RECLAIM SOUL FRAGMENTS AFTER SOUL SEVER OR GLOOMBOMB. BREAK NIGHTFALL'S SHIELD, INTERRUPT IT, AND KILL SOULCOILERS WHILE KICKING WAIL.",
                "INTERMISSION: BLOODLUST AND BURN ZUL'JAN AT DOUBLE DAMAGE. STOMP MALACRASS FRAGMENTS ONE AT A TIME SO THEY DO NOT HEAL HIM AND RAID DAMAGE DOES NOT CHAIN.",
                "P3: REUSE THE ORB/GHOST MARKS FOR FRONTALS, HEAL THROUGH DEFILEMENT'S RAID-WIDE ABSORB, KEEP BOTH BOSSES EVEN, AND KILL THEM TOGETHER.",
                BOSSMOD_RULE,
            },
            calls = {
                toxic("DELUGE > COLLECTORS MOVE ORBS TO SEVER MARK"),
                guillotine("GUILLOTINE > 5+ SOAK > THEN RAID 40+ YARDS"),
                dread,
                night,
                spirit,
                intermission,
                final,
            },
        },
        heroic = {
            explanation = {
                "DAMAGE PLAN: P1 + P2 SINGLE TARGET. PREPULL: MARK BOTH PLATFORM ENDS, ASSIGN 2-3 MOBILE ORB COLLECTORS, TWO GUILLOTINE TEAMS, AND 2-3 WAIL INTERRUPTS.",
                "P1: STACK ORBS AT THE ACTIVE SEVER MARK AND CLEAR A FEW PER SEVER. EACH DESTROYED ORB ADDS STACKING VENOM RUPTURE; MINIMIZE LEFTOVERS BEFORE ZUL'JAN DIES.",
                "GUILLOTINE TEAMS A/B ALTERNATE 5+ SOAKS NEAR AN EDGE; AFTER EACH AXE THE RAID MOVES 40+ YARDS. VENOMFANG DISPELS AND TANK SWAPS STAY BOSSMOD/ROLE-OWNED.",
                "P2: BREAK DREADMARCH BEFORE THE EDGE; GUIDE FIXATE GHOSTS TO SOUL SEVER. LOOK AT A GHOST TO STOP IT, LOOK AWAY TO MOVE IT; RECLAIM EVERY SOUL FRAGMENT.",
                "BREAK NIGHTFALL'S SHIELD AND INTERRUPT. KILL SOULCOILERS AND KICK WAIL. GLOOMBOMBS GO 15+ YARDS OUT, THEN TARGETS RECLAIM THEIR FRAGMENTS.",
                "INTERMISSION: BLOODLUST AND BURN ZUL'JAN AT DOUBLE DAMAGE. STOMP FRAGMENTS ONE AT A TIME SO THEY DO NOT HEAL HIM AND SPIRIT ERASURE DAMAGE DOES NOT CHAIN.",
                "P3: REUSE THE ORB/GHOST MARKS, HEAL THROUGH DEFILEMENT, KEEP BOTH EVEN, AND KILL TOGETHER. GUILLOTINE FORCES THE RAID BACK AND FORTH BETWEEN ENDS.",
                BOSSMOD_RULE,
            },
            calls = {
                toxic("DELUGE > COLLECTORS MOVE ORBS TO SEVER MARK"),
                guillotine("GUILLOTINE > NEXT 5+ SOAK TEAM > RAID 40+ YARDS"),
                dread,
                night,
                spirit,
                intermission,
                final,
            },
        },
        mythic = {
            explanation = {
                "DAMAGE PLAN: P1 + P2 SINGLE TARGET. PREPULL: MARK BOTH PLATFORM ENDS, ASSIGN 2-3 ORB COLLECTORS, FRESH GUILLOTINE TEAMS, AND 2-3 WAIL INTERRUPTS.",
                "P1: COLLECT ORBS AT SEVER AND CLEAR VIRULENT MUTATIONS BEFORE THE NEXT DELUGE. GUILLOTINED IS PERMANENT, SO NEVER REUSE A FRESH 5+ TEAM.",
                "P2: BREAK DREADMARCH, GUIDE GHOSTS TO SOUL SEVER, AND RECLAIM ALL FRAGMENTS. WAIL INTERRUPTS BRIEFLY REVEAL HIDDEN GHOSTS; KEEP KICK COVERAGE CLEAN.",
                "SPITEFUL SOULCOILERS TAKE 99% LESS DAMAGE UNTIL GLOOMBOMBS STRIP SPIRIT SHIELD. AIM BOMBS INTO ADDS, THEN SPREAD AND RECLAIM FRAGMENTS.",
                "BREAK NIGHTFALL'S SHIELD AND INTERRUPT. PERSONAL FIXATE ORIENTATION, VENOMFANG DISPELS AND TANK FRONTALS/SWAPS STAY BOSSMOD/ROLE-OWNED.",
                "INTERMISSION: BLOODLUST AND BURN ZUL'JAN AT DOUBLE DAMAGE; STOMP FRAGMENTS ONE AT A TIME. P3: REUSE MARKS AND HEAL THROUGH DEFILEMENT.",
                "P3: HANDLE BOTH KITS, KEEP BOTH BOSSES EVEN, AND KILL TOGETHER. GRIM GUILLOTINE STILL REQUIRES FRESH 5+ SOAKERS AND SAFE RANGE AFTER THE HIT.",
                BOSSMOD_RULE,
            },
            calls = {
                toxic("DELUGE > CLEAR MUTATIONS > ORBS TO SEVER MARK"),
                guillotine("GUILLOTINE > FRESH 5+ TEAM > RAID 40+ YARDS"),
                dread,
                night,
                spirit,
                gloombomb("GLOOMBOMBS > HIT SOULCOILERS > THEN SPREAD"),
                intermission,
                final,
            },
        },
    },
})
