local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

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
    strategyStatus = "12.1 Journal + current Wowhead/Raidstrats + Ready Check Pull + DBM/BigWigs source-reviewed 2026-08-19; player briefing split from raidleader prep; live validation pending",
    profiles = {
        normal = {
            explanation = {
                "Green poison orb on you: carry it to the Triangle orb marker.",
                "Huge axe marks a player: assigned soakers stack, then everyone runs 40+ yards away.",
                "Possessed player walks toward the edge: break their absorb immediately.",
                "Ghost fixates you: face it to stop; look away to move it to the Cross marker.",
                "Nightfall shield appears: break the shield, then interrupt the boss.",
                "Soulcoilers spawn: kill them quickly and interrupt Wail of Terror.",
                "Intermission: Bloodlust; stop fragments one at a time before they reach Zul'jan.",
                "Final phase: keep both bosses even and kill them together.",
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
                "Destroyed green orbs now stack raid damage: clear only the planned orbs.",
                "Guillotine gives a repeat-hit debuff: soak only with your assigned team.",
                "A ghost reaching you re-possesses you: keep it controlled until the frontal clears it.",
                "Purple Gloombomb on you: move 15+ yards out, then collect your Soul Fragments.",
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
                "Guillotined is permanent: soak only when a fresh team is called.",
                "Mutated green venom: only assigned collectors touch it; everyone else stays clear.",
                "Your fixating ghost is only visible to you: bring it to Cross without touching other ghosts.",
                "Shielded Soulcoilers: aim Gloombombs into them, then kill them after the shield breaks.",
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
