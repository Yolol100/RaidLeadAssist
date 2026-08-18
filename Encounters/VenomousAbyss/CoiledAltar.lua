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
    action = "Burn Zul'jan > stomp fragments one at a time",
    warning = "SOULBINDING > BURN ZUL'JAN > STOMP FRAGMENTS ONE AT A TIME",
    voice = "Fragments",
    timing = false,
}

local final = {
    key = "final",
    ability = "Coiled Union",
    action = "Bloodlust > keep both even > kill together",
    warning = "PHASE 3 > BLOODLUST > KEEP BOTH EVEN > KILL TOGETHER",
    voice = "Bloodlust",
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
    strategyStatus = "12.1 Journal + current strategy + DBM/BigWigs source-reviewed 2026-08-18; Heroic/Mythic PTR evidence; live Retail validation pending",
    profiles = {
        normal = {
            explanation = {
                "P1: ORB COLLECTORS MOVE COALESCED VENOM TO THE SEVER MARK; TANK AIMS SEVER THROUGH IT. GUILLOTINE NEEDS 5+ ASSIGNED SOAKERS, THEN RAID MOVES 40+ YARDS.",
                "P2: BREAK DREADMARCH SHIELDS AND GUIDE GHOSTS TO THE SOUL SEVER MARK. BREAK NIGHTFALL SHIELD; KILL SOULCOILERS AND KICK WAIL.",
                "GLOOMBOMB TARGETS SPREAD 15+ YARDS AND RECLAIM SOUL FRAGMENTS. PERSONAL FIXATE ORIENTATION AND TANK FRONTALS STAY BOSSMOD-OWNED.",
                "INTERMISSION: BURN ZUL'JAN WHILE HE TAKES DOUBLE DAMAGE; STOMP MALACRASS FRAGMENTS ONE AT A TIME SO THEY DO NOT REACH HIM.",
                "P3: BLOODLUST. P1/P2 MECHANICS OVERLAP; KEEP ZUL'JAN AND MALACRASS EVEN AND KILL THEM TOGETHER OR THE SURVIVOR GAINS 500% DAMAGE.",
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
                "P1: ORB COLLECTORS MOVE VENOM TO THE SEVER MARK. GUILLOTINE TEAMS A/B ALTERNATE 5+ SOAKS; AFTER EACH AXE THE RAID MOVES 40+ YARDS.",
                "SEVER CLEARS THE STACKED ORBS; SPACE VENOM RUPTURES. P2: BREAK DREADMARCH, GUIDE GHOSTS TO SOUL SEVER, BREAK NIGHTFALL, KILL SOULCOILERS AND KICK WAIL.",
                "GLOOMBOMBS GO 15+ YARDS OUT; GRAVEBOUND PLAYERS RECLAIM FRAGMENTS. TANK FRONTALS, FIXATE FACING AND PERSONAL BOMB POSITIONING STAY BOSSMOD-OWNED.",
                "INTERMISSION: BURN ZUL'JAN AT DOUBLE DAMAGE AND STOMP FRAGMENTS ONE AT A TIME. P3: BLOODLUST, HANDLE OVERLAPS, KEEP BOTH EVEN AND KILL TOGETHER.",
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
                "P1: COLLECT ORBS AT THE SEVER MARK AND CLEAR VIRULENT MUTATIONS BEFORE THE NEXT DELUGE. GUILLOTINED IS PERMANENT, SO USE FRESH 5+ TEAMS.",
                "P2: BREAK DREADMARCH AND GUIDE GHOSTS TO SOUL SEVER. WAIL INTERRUPTS BRIEFLY REVEAL HIDDEN GHOSTS; KEEP THE PREASSIGNED KICK ROTATION CLEAN.",
                "SPITEFUL SOULCOILERS TAKE 99% LESS DAMAGE UNTIL GLOOMBOMBS STRIP SPIRIT SHIELD. AIM BOMBS INTO ADDS, THEN SPREAD AND RECLAIM FRAGMENTS.",
                "INTERMISSION: BURN ZUL'JAN AT DOUBLE DAMAGE; STOMP FRAGMENTS ONE AT A TIME. P3: BLOODLUST, HANDLE BOTH KITS, KEEP BOTH BOSSES EVEN AND KILL TOGETHER.",
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
