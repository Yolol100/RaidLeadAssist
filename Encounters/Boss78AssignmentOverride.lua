local _, ns = ...

local AssignmentRegistry = ns:GetModule("Encounters.AssignmentRegistry")
local originalGetLayout = AssignmentRegistry.GetLayout

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
            callLabel = "COLLECTORS",
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
        slot("guillotine_a", "Team A", { callKey = "guillotine", callLabel = "TEAM A", rotation = "guillotine", required = true, minPlayers = 5 }),
        slot("guillotine_b", "Team B", { callKey = "guillotine", callLabel = "TEAM B", rotation = "guillotine", minPlayers = 5 }),
    },
}

local ALTAR_GUILLOTINE_HEROIC = {
    key = "guillotine",
    title = "Guillotine Soak Rotation",
    description = "Heroic: alternate two distinct 5+ teams because Guillotined makes repeating the same players unsafe.",
    columns = 2,
    slots = {
        slot("guillotine_a", "Team A", { callKey = "guillotine", callLabel = "TEAM A", rotation = "guillotine", required = true, minPlayers = 5, exclusiveGroup = "guillotine" }),
        slot("guillotine_b", "Team B", { callKey = "guillotine", callLabel = "TEAM B", rotation = "guillotine", required = true, minPlayers = 5, exclusiveGroup = "guillotine" }),
    },
}

local ALTAR_GUILLOTINE_MYTHIC = {
    key = "guillotine",
    title = "Guillotine Soak Rotation",
    description = "Mythic Guillotined is permanent, so plan fresh 5+ player teams for later axes.",
    columns = 4,
    slots = {
        slot("guillotine_a", "Team A", { callKey = "guillotine", callLabel = "TEAM A", rotation = "guillotine", required = true, minPlayers = 5, exclusiveGroup = "guillotine" }),
        slot("guillotine_b", "Team B", { callKey = "guillotine", callLabel = "TEAM B", rotation = "guillotine", required = true, minPlayers = 5, exclusiveGroup = "guillotine" }),
        slot("guillotine_c", "Team C", { callKey = "guillotine", callLabel = "TEAM C", rotation = "guillotine", required = true, minPlayers = 5, exclusiveGroup = "guillotine" }),
        slot("guillotine_d", "Team D", { callKey = "guillotine", callLabel = "TEAM D", rotation = "guillotine", minPlayers = 5, exclusiveGroup = "guillotine" }),
    },
}

local ALTAR_WAIL_NORMAL = {
    key = "kicks",
    title = "Soulcoiler Interrupts",
    description = "Normal: preassign a primary Wail of Terror kick; additional backups are optional.",
    columns = 3,
    slots = {
        slot("wail_kick_a", "Wail Kick A", { callKey = "spiritcackle", callLabel = "WAIL A", rotation = "wail", required = true, exclusiveGroup = "altar_wail" }),
        slot("wail_kick_b", "Wail Kick B", { callKey = "spiritcackle", callLabel = "WAIL B", rotation = "wail", exclusiveGroup = "altar_wail" }),
        slot("wail_kick_c", "Wail Kick C", { callKey = "spiritcackle", callLabel = "WAIL C", rotation = "wail", exclusiveGroup = "altar_wail" }),
    },
}

local ALTAR_WAIL_HARD = {
    key = "kicks",
    title = "Soulcoiler Interrupts",
    description = "Heroic/Mythic: assign 2-3 distinct Wail of Terror interrupts. On Mythic each successful interrupt also briefly reveals hidden Manifestations of Dread.",
    columns = 3,
    slots = {
        slot("wail_kick_a", "Wail Kick A", { callKey = "spiritcackle", callLabel = "WAIL A", rotation = "wail", required = true, exclusiveGroup = "altar_wail" }),
        slot("wail_kick_b", "Wail Kick B", { callKey = "spiritcackle", callLabel = "WAIL B", rotation = "wail", required = true, exclusiveGroup = "altar_wail" }),
        slot("wail_kick_c", "Wail Kick C", { callKey = "spiritcackle", callLabel = "WAIL C", rotation = "wail", exclusiveGroup = "altar_wail" }),
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

local ULATEK_EGG_NORMAL = {
    key = "eggs",
    title = "Doomscale Egg Handler",
    description = "Assign the player who handles the planned Doomscale Egg after the Warden dies. Warden's Protection forbids touching eggs while it lives.",
    columns = 1,
    slots = {
        slot("egg_handler", "Egg Handler", {
            callKey = "eggs",
            callLabel = "HANDLER",
            required = true,
        }),
    },
}

local ULATEK_COILS = {
    key = "coils",
    title = "Spectral Coil Rotation",
    description = "Heroic/Mythic: alternate distinct soak groups because Soul Constrictor prevents affected players from mitigating the next Spectral Coils.",
    columns = 2,
    slots = {
        slot("coil_a", "Coil Group A", {
            callKey = "coils",
            callLabel = "GROUP A",
            rotation = "coils",
            required = true,
            exclusiveGroup = "coils",
        }),
        slot("coil_b", "Coil Group B", {
            callKey = "coils",
            callLabel = "GROUP B",
            rotation = "coils",
            required = true,
            exclusiveGroup = "coils",
        }),
    },
}

local ULATEK_EGGS_HEROIC = {
    key = "eggs",
    title = "Doomscale Egg Sides",
    description = "Assign one distinct owner to each side. Trigger only the planned side after the Warden dies because Mass Gestation starts the remaining eggs on that side.",
    columns = 2,
    slots = {
        slot("egg_left", "Left Egg Owner", {
            callKey = "eggs",
            callLabel = "LEFT",
            required = true,
            exclusiveGroup = "ulatek_eggs",
        }),
        slot("egg_right", "Right Egg Owner", {
            callKey = "eggs",
            callLabel = "RIGHT",
            required = true,
            exclusiveGroup = "ulatek_eggs",
        }),
    },
}

local ULATEK_EGGS_MYTHIC = {
    key = "eggs",
    title = "Doomscale Egg Carriers",
    description = "Assign one distinct carrier to each side. Noxious Shell carriers stay more than 3 yards apart and trigger only the planned side after the Warden dies.",
    columns = 2,
    slots = {
        slot("egg_left", "Left Egg Carrier", {
            callKey = "eggs",
            callLabel = "LEFT",
            required = true,
            exclusiveGroup = "ulatek_eggs",
        }),
        slot("egg_right", "Right Egg Carrier", {
            callKey = "eggs",
            callLabel = "RIGHT",
            required = true,
            exclusiveGroup = "ulatek_eggs",
        }),
    },
}

local ULATEK_INCUBATION = {
    key = "incubation",
    title = "Toxic Incubation Intercepts",
    description = "Mythic: one Incubation applies four impacts over four seconds. Assign at least four distinct interceptors so each planned player takes one hit instead of stacking Toxic Burn.",
    columns = 1,
    slots = {
        slot("incubation_team", "Incubation Team", {
            callKey = "incubation",
            callLabel = "INTERCEPTORS",
            required = true,
            minPlayers = 4,
        }),
    },
}

local ULATEK_LAYOUTS = {
    normal = {
        summary = "Assign one egg handler. Coils are a full-raid stack on Normal; personal Bite, Purge and dodge reactions remain bossmod-owned.",
        sections = { ULATEK_EGG_NORMAL },
    },
    heroic = {
        summary = "Assign two alternating Coil groups plus distinct left/right egg owners. Fangs are broken one at a time as a live raid-leader call.",
        sections = { ULATEK_COILS, ULATEK_EGGS_HEROIC },
    },
    mythic = {
        summary = "Assign alternating Coil groups, distinct egg-side carriers and a 4+ player Toxic Incubation intercept team.",
        sections = { ULATEK_COILS, ULATEK_EGGS_MYTHIC, ULATEK_INCUBATION },
    },
}

function AssignmentRegistry:GetLayout(bossKey, difficultyKey)
    if bossKey == "altar" and ALTAR_LAYOUTS[difficultyKey] then
        return ALTAR_LAYOUTS[difficultyKey]
    end

    if bossKey == "ulatek" and ULATEK_LAYOUTS[difficultyKey] then
        return ULATEK_LAYOUTS[difficultyKey]
    end

    return originalGetLayout(self, bossKey, difficultyKey)
end
