local _, ns = ...

local AssignmentRegistry = ns:GetModule("Encounters.AssignmentRegistry")

local function slot(key, label, options)
    options = options or {}
    return {
        key = key,
        label = label,
        kind = options.rotation and "rotation" or "assignee",
        callKey = options.callKey,
        callLabel = options.callLabel,
        rotation = options.rotation,
        required = options.required == true,
        exactPlayers = options.exactPlayers,
        minPlayers = options.minPlayers,
        minRaidFraction = options.minRaidFraction,
        exclusiveGroup = options.exclusiveGroup,
        compactGroups = options.compactGroups == true,
        helper = options.helper,
    }
end

local ALTAR_ORBS = {
    key = "orbs",
    title = "Coalesced Venom Collectors",
    description = "Assign 2-3 mobile players who move new venom orbs to Triangle for Sever.",
    columns = 1,
    slots = {
        slot("orb_collectors", "Orb Collectors", {
            callKey = "toxic",
            callLabel = "Collectors",
            required = true,
            minPlayers = 2,
            helper = "Choose 2-3 mobile players. Tank-facing Sever remains tank/bossmod-owned.",
        }),
    },
}

local ALTAR_GUILLOTINE_HEROIC = {
    key = "guillotine",
    title = "Guillotine Soak Rotation",
    description = "Heroic: alternate two different 3+ teams; the repeat-hit debuff still makes immediate reuse unsafe.",
    columns = 2,
    slots = {
        slot("guillotine_a", "Guillotine Group 1", { callKey = "guillotine", callLabel = "Guillotine", rotation = "guillotine", required = true, minPlayers = 3, exclusiveGroup = "guillotine", compactGroups = true }),
        slot("guillotine_b", "Guillotine Group 2", { callKey = "guillotine", callLabel = "Guillotine", rotation = "guillotine", required = true, minPlayers = 3, exclusiveGroup = "guillotine", compactGroups = true }),
    },
}

local ALTAR_GUILLOTINE_MYTHIC = {
    key = "guillotine",
    title = "Guillotine Soak Rotation",
    description = "Mythic: Guillotined is permanent, so later axes need fresh 5+ players.",
    columns = 4,
    slots = {
        slot("guillotine_a", "Guillotine Group 1", { callKey = "guillotine", callLabel = "Guillotine", rotation = "guillotine", required = true, minPlayers = 5, exclusiveGroup = "guillotine", compactGroups = true }),
        slot("guillotine_b", "Guillotine Group 2", { callKey = "guillotine", callLabel = "Guillotine", rotation = "guillotine", required = true, minPlayers = 5, exclusiveGroup = "guillotine", compactGroups = true }),
        slot("guillotine_c", "Guillotine Group 3", { callKey = "guillotine", callLabel = "Guillotine", rotation = "guillotine", required = true, minPlayers = 5, exclusiveGroup = "guillotine", compactGroups = true }),
        slot("guillotine_d", "Guillotine Group 4", { callKey = "guillotine", callLabel = "Guillotine", rotation = "guillotine", minPlayers = 5, exclusiveGroup = "guillotine", compactGroups = true }),
    },
}

local ALTAR_WAIL_NORMAL = {
    key = "kicks",
    title = "Soulcoiler Interrupt",
    description = "Preassign one primary Wail of Terror interrupt; backups are optional.",
    columns = 3,
    slots = {
        slot("wail_kick_a", "Wail Kick 1", { callKey = "spiritcackle", callLabel = "Wail", rotation = "wail", required = true, exclusiveGroup = "altar_wail" }),
        slot("wail_kick_b", "Wail Kick 2", { callKey = "spiritcackle", callLabel = "Wail", rotation = "wail", exclusiveGroup = "altar_wail" }),
        slot("wail_kick_c", "Wail Kick 3", { callKey = "spiritcackle", callLabel = "Wail", rotation = "wail", exclusiveGroup = "altar_wail" }),
    },
}

local ALTAR_WAIL_HARD = {
    key = "kicks",
    title = "Soulcoiler Interrupts",
    description = "Heroic/Mythic: assign at least two different Wail of Terror interrupt owners.",
    columns = 3,
    slots = {
        slot("wail_kick_a", "Wail Kick 1", { callKey = "spiritcackle", callLabel = "Wail", rotation = "wail", required = true, exclusiveGroup = "altar_wail" }),
        slot("wail_kick_b", "Wail Kick 2", { callKey = "spiritcackle", callLabel = "Wail", rotation = "wail", required = true, exclusiveGroup = "altar_wail" }),
        slot("wail_kick_c", "Wail Kick 3", { callKey = "spiritcackle", callLabel = "Wail", rotation = "wail", exclusiveGroup = "altar_wail" }),
    },
}

local ALTAR_LAYOUTS = {
    normal = {
        summary = "Assign Orb Collectors and Wail interrupt ownership. Normal Guillotine needs 3+ soakers but no fixed team.",
        sections = { ALTAR_ORBS, ALTAR_WAIL_NORMAL },
    },
    heroic = {
        summary = "Assign Orb Collectors, two different 3+ Guillotine groups and at least two Wail interrupts.",
        sections = { ALTAR_ORBS, ALTAR_GUILLOTINE_HEROIC, ALTAR_WAIL_HARD },
    },
    mythic = {
        summary = "Assign Orb Collectors, fresh 5+ Guillotine groups and 2-3 Wail interrupt owners.",
        sections = { ALTAR_ORBS, ALTAR_GUILLOTINE_MYTHIC, ALTAR_WAIL_HARD },
    },
}

local ULATEK_COILS_HARD = {
    key = "coils",
    title = "Spectral Coils Teams",
    description = "Heroic/Mythic: split into two near-equal teams and alternate the active Coil; each impact still needs 40%+ of the raid.",
    columns = 2,
    slots = {
        slot("coil_a", "Coils Team 1", {
            callKey = "coils",
            callLabel = "Coils",
            rotation = "coils",
            required = true,
            minRaidFraction = 0.4,
            exclusiveGroup = "coils",
            compactGroups = true,
            helper = "Use roughly half the raid; validation requires at least 40% of the current roster when roster data is available.",
        }),
        slot("coil_b", "Coils Team 2", {
            callKey = "coils",
            callLabel = "Coils",
            rotation = "coils",
            required = true,
            minRaidFraction = 0.4,
            exclusiveGroup = "coils",
            compactGroups = true,
            helper = "Use roughly half the raid; validation requires at least 40% of the current roster when roster data is available.",
        }),
    },
}

local ULATEK_EGG_CARRIERS = {
    key = "eggs",
    title = "Doomscale Egg Carriers",
    description = "Assign one mobile Doomscale egg carrier to each Phase 2 side.",
    columns = 2,
    slots = {
        slot("egg_left", "Triangle / Left Carrier", {
            callKey = "eggs",
            callLabel = "Left",
            required = true,
            exactPlayers = 1,
            exclusiveGroup = "ulatek_eggs",
        }),
        slot("egg_right", "Cross / Right Carrier", {
            callKey = "eggs",
            callLabel = "Right",
            required = true,
            exactPlayers = 1,
            exclusiveGroup = "ulatek_eggs",
        }),
    },
}

local ULATEK_BITE_GROUPS = {
    key = "bite",
    title = "Serpent's Bite Helper Groups",
    description = "Pre-split Phase 3 into melee, ranged and healer helper groups; each group fully clears its matching Bite before Purge spreads.",
    columns = 3,
    slots = {
        slot("bite_melee", "Melee Bite Group", {
            callKey = "bite",
            callLabel = "Melee",
            required = true,
            exclusiveGroup = "ulatek_bite",
            compactGroups = true,
        }),
        slot("bite_ranged", "Ranged Bite Group", {
            callKey = "bite",
            callLabel = "Ranged",
            required = true,
            exclusiveGroup = "ulatek_bite",
            compactGroups = true,
        }),
        slot("bite_healer", "Healer Bite Group", {
            callKey = "bite",
            callLabel = "Healer",
            required = true,
            exclusiveGroup = "ulatek_bite",
            compactGroups = true,
            helper = "Include enough nearby ranged/short-range DPS so the healer-target soak is not healer-only.",
        }),
    },
}

local ULATEK_INCUBATION = {
    key = "incubation",
    title = "Toxic Incubation Intercepts",
    description = "Mythic: assign at least four different interceptors so each takes one impact.",
    columns = 1,
    slots = {
        slot("incubation_team", "Incubation Group", {
            callKey = "incubation",
            callLabel = "Incubation",
            required = true,
            minPlayers = 4,
            compactGroups = true,
        }),
    },
}

local ULATEK_LAYOUTS = {
    normal = {
        summary = "Assign left/right egg carriers and three Serpent's Bite helper groups. Normal Coils can be soaked as one raid group.",
        sections = { ULATEK_EGG_CARRIERS, ULATEK_BITE_GROUPS },
    },
    heroic = {
        summary = "Assign two alternating Coils/side teams, left/right egg carriers and three Serpent's Bite helper groups.",
        sections = { ULATEK_COILS_HARD, ULATEK_EGG_CARRIERS, ULATEK_BITE_GROUPS },
    },
    mythic = {
        summary = "Assign alternating Coils teams, left/right egg carriers, Bite helper groups and a 4+ Incubation group.",
        sections = { ULATEK_COILS_HARD, ULATEK_EGG_CARRIERS, ULATEK_BITE_GROUPS, ULATEK_INCUBATION },
    },
}

AssignmentRegistry:RegisterLayouts("altar", ALTAR_LAYOUTS)
AssignmentRegistry:RegisterLayouts("ulatek", ULATEK_LAYOUTS)
