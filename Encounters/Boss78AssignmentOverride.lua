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
        helper = options.helper,
    }
end

local ALTAR_ORBS = {
    key = "orbs",
    title = "Coalesced Venom Collectors",
    description = "Assign 2-3 mobile players who move Coalesced Venom to the active Sever mark. RLA calls the collectors; tank-facing Sever remains bossmod/role-owned.",
    columns = 1,
    slots = {
        slot("orb_collectors", "Orb Collectors", {
            callKey = "toxic",
            callLabel = "Collectors",
            required = true,
            minPlayers = 2,
            helper = "Select 2-3 mobile players responsible for moving new Coalesced Venom to the assigned Sever mark.",
        }),
    },
}

local ALTAR_GUILLOTINE_NORMAL = {
    key = "guillotine",
    title = "Guillotine Soak Coverage",
    description = "Normal: every axe needs at least five players. A second team is optional because Normal does not require a Heroic-style fresh-team split.",
    columns = 2,
    slots = {
        slot("guillotine_a", "Team A", { callKey = "guillotine", callLabel = "Team A", rotation = "guillotine", required = true, minPlayers = 5 }),
        slot("guillotine_b", "Team B", { callKey = "guillotine", callLabel = "Team B", rotation = "guillotine", minPlayers = 5 }),
    },
}

local ALTAR_GUILLOTINE_HEROIC = {
    key = "guillotine",
    title = "Guillotine Soak Rotation",
    description = "Heroic: alternate two distinct 5+ teams because Guillotined makes repeating the same players unsafe.",
    columns = 2,
    slots = {
        slot("guillotine_a", "Team A", { callKey = "guillotine", callLabel = "Team A", rotation = "guillotine", required = true, minPlayers = 5, exclusiveGroup = "guillotine" }),
        slot("guillotine_b", "Team B", { callKey = "guillotine", callLabel = "Team B", rotation = "guillotine", required = true, minPlayers = 5, exclusiveGroup = "guillotine" }),
    },
}

local ALTAR_GUILLOTINE_MYTHIC = {
    key = "guillotine",
    title = "Guillotine Soak Rotation",
    description = "Mythic Guillotined is permanent, so plan fresh 5+ player teams for later axes.",
    columns = 4,
    slots = {
        slot("guillotine_a", "Team A", { callKey = "guillotine", callLabel = "Team A", rotation = "guillotine", required = true, minPlayers = 5, exclusiveGroup = "guillotine" }),
        slot("guillotine_b", "Team B", { callKey = "guillotine", callLabel = "Team B", rotation = "guillotine", required = true, minPlayers = 5, exclusiveGroup = "guillotine" }),
        slot("guillotine_c", "Team C", { callKey = "guillotine", callLabel = "Team C", rotation = "guillotine", required = true, minPlayers = 5, exclusiveGroup = "guillotine" }),
        slot("guillotine_d", "Team D", { callKey = "guillotine", callLabel = "Team D", rotation = "guillotine", minPlayers = 5, exclusiveGroup = "guillotine" }),
    },
}

local ALTAR_WAIL_NORMAL = {
    key = "kicks",
    title = "Soulcoiler Interrupts",
    description = "Normal: preassign a primary Wail of Terror kick; additional backups are optional.",
    columns = 3,
    slots = {
        slot("wail_kick_a", "Wail Kick A", { callKey = "spiritcackle", callLabel = "Wail A", rotation = "wail", required = true, exclusiveGroup = "altar_wail" }),
        slot("wail_kick_b", "Wail Kick B", { callKey = "spiritcackle", callLabel = "Wail B", rotation = "wail", exclusiveGroup = "altar_wail" }),
        slot("wail_kick_c", "Wail Kick C", { callKey = "spiritcackle", callLabel = "Wail C", rotation = "wail", exclusiveGroup = "altar_wail" }),
    },
}

local ALTAR_WAIL_HARD = {
    key = "kicks",
    title = "Soulcoiler Interrupts",
    description = "Heroic/Mythic: assign 2-3 distinct Wail of Terror interrupts. On Mythic each successful interrupt also briefly reveals hidden Manifestations of Dread.",
    columns = 3,
    slots = {
        slot("wail_kick_a", "Wail Kick A", { callKey = "spiritcackle", callLabel = "Wail A", rotation = "wail", required = true, exclusiveGroup = "altar_wail" }),
        slot("wail_kick_b", "Wail Kick B", { callKey = "spiritcackle", callLabel = "Wail B", rotation = "wail", required = true, exclusiveGroup = "altar_wail" }),
        slot("wail_kick_c", "Wail Kick C", { callKey = "spiritcackle", callLabel = "Wail C", rotation = "wail", exclusiveGroup = "altar_wail" }),
    },
}

local ALTAR_LAYOUTS = {
    normal = {
        summary = "Assign 2-3 Orb Collectors, one required 5+ Guillotine team plus optional backup coverage, and Wail interrupt ownership.",
        sections = { ALTAR_ORBS, ALTAR_GUILLOTINE_NORMAL, ALTAR_WAIL_NORMAL },
    },
    heroic = {
        summary = "Assign 2-3 Orb Collectors, two distinct 5+ Guillotine teams, and at least two distinct Wail interrupt owners.",
        sections = { ALTAR_ORBS, ALTAR_GUILLOTINE_HEROIC, ALTAR_WAIL_HARD },
    },
    mythic = {
        summary = "Assign 2-3 Orb Collectors, fresh 5+ Guillotine teams, and 2-3 Wail interrupt owners; Wail also reveals hidden Dreads.",
        sections = { ALTAR_ORBS, ALTAR_GUILLOTINE_MYTHIC, ALTAR_WAIL_HARD },
    },
}

local ULATEK_EGG_HANDLER = {
    key = "eggs",
    title = "Doomscale Egg Handler",
    description = "Assign the player who handles the planned Doomscale Egg after the Warden dies. Never touch the egg while Warden's Protection is active.",
    columns = 1,
    slots = {
        slot("egg_handler", "Egg Handler", {
            callKey = "eggs",
            callLabel = "Handler",
            required = true,
        }),
    },
}

local ULATEK_COILS_MYTHIC = {
    key = "coils",
    title = "Spectral Coil Rotation",
    description = "Mythic: alternate distinct soak groups because Soul Constrictor prevents the previous group from mitigating the next Spectral Coils.",
    columns = 2,
    slots = {
        slot("coil_a", "Coil Group A", {
            callKey = "coils",
            callLabel = "Group A",
            rotation = "coils",
            required = true,
            exclusiveGroup = "coils",
        }),
        slot("coil_b", "Coil Group B", {
            callKey = "coils",
            callLabel = "Group B",
            rotation = "coils",
            required = true,
            exclusiveGroup = "coils",
        }),
    },
}

local ULATEK_EGGS_MYTHIC = {
    key = "eggs",
    title = "Doomscale Egg Carriers",
    description = "Mythic: assign one carrier per planned side. Carriers stay more than 3 yards apart and only activate the called side after the Warden dies.",
    columns = 2,
    slots = {
        slot("egg_left", "Left Egg Carrier", {
            callKey = "eggs",
            callLabel = "Left",
            required = true,
            exclusiveGroup = "ulatek_eggs",
        }),
        slot("egg_right", "Right Egg Carrier", {
            callKey = "eggs",
            callLabel = "Right",
            required = true,
            exclusiveGroup = "ulatek_eggs",
        }),
    },
}

local ULATEK_INCUBATION = {
    key = "incubation",
    title = "Toxic Incubation Intercepts",
    description = "Mythic: one Incubation applies four impacts. Assign at least four distinct interceptors so each player takes one hit instead of stacking Toxic Burn.",
    columns = 1,
    slots = {
        slot("incubation_team", "Incubation Team", {
            callKey = "incubation",
            callLabel = "Interceptors",
            required = true,
            minPlayers = 4,
        }),
    },
}

local ULATEK_LAYOUTS = {
    normal = {
        summary = "Assign one egg handler. Spectral Coils is a full-raid stack; personal debuffs and dodges remain bossmod-owned.",
        sections = { ULATEK_EGG_HANDLER },
    },
    heroic = {
        summary = "Keep the Normal egg-handler setup. Heroic adds live Fang and add reactions, but no extra pre-pull roster assignment is required.",
        sections = { ULATEK_EGG_HANDLER },
    },
    mythic = {
        summary = "Assign alternating Coil groups, distinct egg-side carriers and a 4+ player Toxic Incubation intercept team.",
        sections = { ULATEK_COILS_MYTHIC, ULATEK_EGGS_MYTHIC, ULATEK_INCUBATION },
    },
}

AssignmentRegistry:RegisterLayouts("altar", ALTAR_LAYOUTS)
AssignmentRegistry:RegisterLayouts("ulatek", ULATEK_LAYOUTS)
