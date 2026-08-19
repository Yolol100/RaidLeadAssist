local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local dread = {
    key = "dreadmarch",
    ability = "Dreadmarch",
    action = "Break shields; ghosts to Cross",
    warning = "Dreadmarch: break shields; move ghosts to Cross.",
    voice = "Dreadmarch",
    spellIDs = { 1289900 },
    prepareSeconds = 7,
    pressSeconds = 4,
}

local night = {
    key = "nightfall",
    ability = "Eternal Nightfall",
    action = "Break shield; interrupt",
    warning = "Nightfall: break shield, then interrupt.",
    voice = "Nightfall",
    spellIDs = { 1286918 },
    prepareSeconds = 5,
    pressSeconds = 2,
}

local spirit = {
    key = "spiritcackle",
    ability = "Spiritcackle",
    action = "Kill Soulcoilers; assigned kick Wail",
    warning = "Soulcoilers: kill them; assigned player kicks Wail.",
    actionTemplate = "Kill Soulcoilers; {{rotation:wail}} kicks Wail",
    warningTemplate = "Soulcoilers: kill them; {{rotation:wail}} interrupt Wail.",
    voice = "Add",
    spellIDs = { 1286441 },
}

local intermission = {
    key = "intermission",
    ability = "Soulbinding",
    action = "Bloodlust; burn Zul'jan; stop fragments",
    warning = "Intermission: Bloodlust, burn Zul'jan; stop fragments.",
    voice = "Bloodlust",
    timing = false,
}

local final = {
    key = "final",
    ability = "Coiled Union",
    action = "Keep health even; kill together",
    warning = "Final phase: keep health even; kill together.",
    voice = "Kill together",
    timing = false,
    iconSpellID = 1298381,
}

local function guillotine(action, warning, actionTemplate, warningTemplate)
    return {
        key = "guillotine",
        ability = "Guillotine",
        action = action,
        warning = warning,
        actionTemplate = actionTemplate,
        warningTemplate = warningTemplate,
        voice = "Guillotine",
        spellIDs = { 1283489, 1283485, 1299266 },
        timerNames = { "Guillotine", "Grim Guillotine" },
        prepareSeconds = 8,
        pressSeconds = 5,
    }
end

local function toxic(action, warning, actionTemplate, warningTemplate)
    return {
        key = "toxic",
        ability = "Toxic Deluge",
        action = action,
        warning = warning,
        actionTemplate = actionTemplate,
        warningTemplate = warningTemplate,
        voice = "Venom",
        spellIDs = { 1299960 },
        timerNames = { "Toxic Deluge" },
        prepareSeconds = 7,
        pressSeconds = 4,
    }
end

local function gloombomb(action, warning)
    return {
        key = "gloombomb",
        ability = "Gloombomb",
        action = action,
        warning = warning,
        voice = "Bomb",
        spellIDs = { 1286895 },
        prepareSeconds = 6,
        pressSeconds = 3,
    }
end

local orbCall = toxic(
    "Collectors move orbs to Triangle",
    "Orbs: collectors move them to Triangle.",
    "{{orb_collectors}} move orbs to Triangle",
    "Orbs: {{orb_collectors}} move them to Triangle."
)

local normalGuillotine = guillotine(
    "5+ soak; raid move 40+ yards",
    "Guillotine: 5+ soak; raid move 40+ yards."
)
local heroicGuillotine = guillotine(
    "Assigned group soak; raid move",
    "Guillotine: assigned group soak; raid move 40+ yards.",
    "{{rotation:guillotine}} soak; raid move 40+ yards",
    "Guillotine: {{rotation:guillotine}} soak; raid move 40+ yards."
)
local mythicGuillotine = guillotine(
    "Fresh group soak; raid move",
    "Guillotine: fresh group soak; raid move 40+ yards.",
    "{{rotation:guillotine}} soak; raid move 40+ yards",
    "Guillotine: {{rotation:guillotine}} soak; raid move 40+ yards."
)

Registry:Register({
    key = "altar",
    name = "The Coiled Altar",
    encounterID = 3429,
    encounterAliases = { "The Bargained Crown" },
    strategyStatus = "12.1 Journal + current Wowhead/Raidstrats + Ready Check Pull + DBM/BigWigs source-reviewed 2026-08-19; difficulty-specific Guillotine prep; live validation pending",
    profiles = {
        normal = {
            explanation = {
                "Green poison orb on you: carry it to the Triangle orb marker.",
                "Huge axe marks a player: 5+ players stack, then run 40+ yards away.",
                "Possessed player walks toward the edge: break their absorb immediately.",
                "Ghost fixates you: face it to stop; look away to move it to Cross.",
                "Nightfall shield appears: break the shield, then interrupt the boss.",
                "Soulcoilers spawn: kill them quickly and interrupt Wail of Terror.",
                "Intermission: Bloodlust; stop fragments one at a time before Zul'jan.",
                "Final phase: keep both bosses even and kill them together.",
            },
            calls = { orbCall, normalGuillotine, dread, night, spirit, intermission, final },
        },
        heroic = {
            explanation = {
                "Destroyed green orbs now stack raid damage: clear only planned orbs.",
                "Guillotine gives a repeat-hit debuff: soak only with your assigned group.",
                "A ghost reaching you re-possesses you: control it until the frontal clears it.",
                "Gloombomb on you: move 15+ yards out, then collect your Soul Fragments.",
            },
            calls = { orbCall, heroicGuillotine, dread, night, spirit, intermission, final },
        },
        mythic = {
            explanation = {
                "Guillotined is permanent: soak only when your fresh group is called.",
                "Mutated venom: only assigned collectors touch it; everyone else stays clear.",
                "Your fixating ghost is only visible to you: bring it to Cross safely.",
                "Shielded Soulcoilers: aim Gloombombs into them, then kill them.",
            },
            calls = {
                toxic(
                    "Collectors clear mutations to Triangle",
                    "Mutations: collectors clear them to Triangle.",
                    "{{orb_collectors}} clear mutations to Triangle",
                    "Mutations: {{orb_collectors}} clear them to Triangle."
                ),
                mythicGuillotine,
                dread,
                night,
                spirit,
                gloombomb(
                    "Hit shielded Soulcoilers; spread",
                    "Gloombomb: hit shielded Soulcoilers, then spread."
                ),
                intermission,
                final,
            },
        },
    },
})
