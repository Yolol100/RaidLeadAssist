local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local dread = {
    key = "dreadmarch", ability = "Dreadmarch", action = "Break shields; ghosts to Cross",
    warning = "Dreadmarch: break shields; move ghosts to Cross.", voice = "Dreadmarch",
    spellIDs = { 1289900 }, prepareSeconds = 7, pressSeconds = 4,
}
local night = {
    key = "nightfall", ability = "Eternal Nightfall", action = "Break shield; interrupt",
    warning = "Nightfall: break shield, then interrupt.", voice = "Nightfall",
    spellIDs = { 1286918 }, prepareSeconds = 5, pressSeconds = 2,
}
local spirit = {
    key = "spiritcackle", ability = "Spiritcackle", action = "Kill Soulcoilers; assigned kick Wail",
    warning = "Soulcoilers: kill them; assigned player kicks Wail.",
    actionTemplate = "Kill Soulcoilers; {{rotation:wail}} kicks Wail",
    warningTemplate = "Soulcoilers: kill them; {{rotation:wail}} interrupt Wail.",
    voice = "Add", spellIDs = { 1286441 },
}
local intermission = {
    key = "intermission", ability = "Soulbinding", action = "Bloodlust; burn Zul'jan; stagger fragment stops",
    warning = "Intermission: Bloodlust, burn Zul'jan; stagger fragment stops.", voice = "Bloodlust", timing = false,
}
local final = {
    key = "final", ability = "Coiled Union", action = "Keep health even; kill together",
    warning = "Final phase: keep health even; kill together.", voice = "Kill together", timing = false,
    iconSpellID = 1298381,
}

local function guillotine(action, warning, actionTemplate, warningTemplate)
    return {
        key = "guillotine", ability = "Guillotine", action = action, warning = warning,
        actionTemplate = actionTemplate, warningTemplate = warningTemplate, voice = "Guillotine",
        spellIDs = { 1283489, 1283485, 1299266 }, timerNames = { "Guillotine", "Grim Guillotine" },
        prepareSeconds = 8, pressSeconds = 5,
    }
end

local function toxic(action, warning, actionTemplate, warningTemplate)
    return {
        key = "toxic", ability = "Toxic Deluge", action = action, warning = warning,
        actionTemplate = actionTemplate, warningTemplate = warningTemplate, voice = "Venom",
        spellIDs = { 1299960 }, timerNames = { "Toxic Deluge" }, prepareSeconds = 7, pressSeconds = 4,
    }
end

local function gloombomb(action, warning)
    return {
        key = "gloombomb", ability = "Gloombomb", action = action, warning = warning, voice = "Bomb",
        spellIDs = { 1286895 }, prepareSeconds = 6, pressSeconds = 3,
    }
end

local orbCall = toxic(
    "Collectors move orbs to Triangle", "Orbs: collectors move them to Triangle.",
    "{{orb_collectors}} move orbs to Triangle", "Orbs: {{orb_collectors}} move them to Triangle."
)
local heroicGuillotine = guillotine(
    "Assigned 3+ group soak; raid move", "Guillotine: assigned group soak; raid move 40+ yards.",
    "{{rotation:guillotine}} soak (3+); raid move 40+ yards",
    "Guillotine: {{rotation:guillotine}} soak (3+); raid move 40+ yards."
)
local mythicGuillotine = guillotine(
    "Fresh 5+ group soak; raid move", "Guillotine: fresh 5+ group soak; raid move 40+ yards.",
    "{{rotation:guillotine}} soak (5+); raid move 40+ yards",
    "Guillotine: {{rotation:guillotine}} soak (5+); raid move 40+ yards."
)

Registry:Register({
    key = "altar", name = "The Coiled Altar", encounterID = 3429, encounterAliases = { "The Bargained Crown" },
    strategyStatus = "Heroic/Mythic only; current 12.1 live hotfix and provider review retained; PASS-LIVE pending",
    profiles = {
        heroic = {
            explanation = {
                "Destroyed green orbs stack raid damage: clear only planned orbs and do not detonate the pile all at once.",
                "Guillotine needs 3 players to avoid failure damage; alternate assigned groups because the repeat-hit debuff remains unsafe.",
                "A ghost reaching you re-possesses you: control it until the tank frontal clears it.",
                "Gloombomb on you: move 15+ yards out, then collect your Soul Fragments.",
                "Soulcoilers and Eternal Nightfall must be stopped quickly; use the preassigned Wail interrupt order.",
                "Intermission: Bloodlust and burn Zul'jan while staggering fragment interceptions around healer cooldowns.",
                "Phase 3 combines orbs, ghosts, Guillotine and shields: preserve space and keep boss health even.",
            },
            calls = { orbCall, heroicGuillotine, dread, night, spirit, intermission, final },
        },
        mythic = {
            explanation = {
                "Guillotined is permanent: later axes need fresh 5+ players; the 3-player Heroic rule does not apply to Mythic.",
                "Mutated venom: only assigned collectors touch it; everyone else stays clear.",
                "Your fixating ghost is only visible to you: bring it to Cross safely for the tank frontal.",
                "Shielded Soulcoilers: aim Gloombombs into them, then kill them and maintain the Wail interrupt plan.",
                "Intermission: Bloodlust, burn Zul'jan and space fragment interceptions because Mythic punishes rapid successive stops.",
                "Phase 3 combines both phases: line up orbs and ghosts for the frontal and finish both bosses together.",
            },
            calls = {
                toxic("Collectors clear mutations to Triangle", "Mutations: collectors clear them to Triangle.",
                    "{{orb_collectors}} clear mutations to Triangle", "Mutations: {{orb_collectors}} clear them to Triangle."),
                mythicGuillotine, dread, night, spirit,
                gloombomb("Hit shielded Soulcoilers; spread", "Gloombomb: hit shielded Soulcoilers, then spread."),
                intermission, final,
            },
        },
    },
})
