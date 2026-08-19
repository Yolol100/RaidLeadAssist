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
        minPlayers = options.minPlayers,
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
    description = "Heroic: alternate two different 5+ teams because the repeat-hit debuff makes immediate reuse unsafe.",
    columns = 2,
    slots = {
        slot("guillotine_a", "Guillotine Group 1", { callKey = "guillotine", callLabel = "Guillotine", rotation = "guillotine", required = true, minPlayers = 5, exclusiveGroup = "guillotine", compactGroups = true }),
        slot("guillotine_b", "Guillotine Group 2", { callKey = "guillotine", callLabel = "Guillotine", rotation = "guillotine", required = true, minPlayers = 5, exclusiveGroup = "guillotine", compactGroups = true }),
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
        summary = "Assign Orb Collectors and Wail interrupt ownership. Normal Guillotine needs 5+ soakers but no fixed team.",
        sections = { ALTAR_ORBS, ALTAR_WAIL_NORMAL },
    },
    heroic = {
        summary = "Assign Orb Collectors, two different 5+ Guillotine groups and at least two Wail interrupts.",
        sections = { ALTAR_ORBS, ALTAR_GUILLOTINE_HEROIC, ALTAR_WAIL_HARD },
    },
    mythic = {
        summary = "Assign Orb Collectors, fresh 5+ Guillotine groups and 2-3 Wail interrupt owners.",
        sections = { ALTAR_ORBS, ALTAR_GUILLOTINE_MYTHIC, ALTAR_WAIL_HARD },
    },
}

local ULATEK_EGG_HANDLER = {
    key = "eggs",
    title = "Doomscale Egg Handler",
    description = "Assign who handles the planned egg after the Warden dies.",
    columns = 1,
    slots = {
        slot("egg_handler", "Egg Handler", {
            callKey = "eggs",
            callLabel = "Handler",
            required = true,
            helper = "This player uses the planned egg only after Warden's Protection is gone.",
        }),
    },
}

local ULATEK_COILS_MYTHIC = {
    key = "coils",
    title = "Spectral Coils Rotation",
    description = "Mythic: alternate two different soak groups because Soul Constrictor prevents immediate reuse.",
    columns = 2,
    slots = {
        slot("coil_a", "Coils Group 1", {
            callKey = "coils",
            callLabel = "Coils",
            rotation = "coils",
            required = true,
            exclusiveGroup = "coils",
            compactGroups = true,
        }),
        slot("coil_b", "Coils Group 2", {
            callKey = "coils",
            callLabel = "Coils",
            rotation = "coils",
            required = true,
            exclusiveGroup = "coils",
            compactGroups = true,
        }),
    },
}

local ULATEK_EGGS_MYTHIC = {
    key = "eggs",
    title = "Doomscale Egg Carriers",
    description = "Mythic: assign one carrier per marked side. Use only the side called before pull/pull phase.",
    columns = 2,
    slots = {
        slot("egg_left", "Triangle / Left Carrier", {
            callKey = "eggs",
            callLabel = "Triangle",
            required = true,
            exclusiveGroup = "ulatek_eggs",
        }),
        slot("egg_right", "Cross / Right Carrier", {
            callKey = "eggs",
            callLabel = "Cross",
            required = true,
            exclusiveGroup = "ulatek_eggs",
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
        summary = "Assign one egg handler. Spectral Coils is a full-raid stack and needs no roster group.",
        sections = { ULATEK_EGG_HANDLER },
    },
    heroic = {
        summary = "Keep the Normal egg handler. Heroic adds reactions, but no extra fixed roster assignment.",
        sections = { ULATEK_EGG_HANDLER },
    },
    mythic = {
        summary = "Assign alternating Coils groups, left/right egg carriers and a 4+ Incubation group.",
        sections = { ULATEK_COILS_MYTHIC, ULATEK_EGGS_MYTHIC, ULATEK_INCUBATION },
    },
}

AssignmentRegistry:RegisterLayouts("altar", ALTAR_LAYOUTS)
AssignmentRegistry:RegisterLayouts("ulatek", ULATEK_LAYOUTS)
