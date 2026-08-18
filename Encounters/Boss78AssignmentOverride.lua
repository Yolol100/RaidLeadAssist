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
    description = "Assign the players who move Coalesced Venom to the raid's Sever mark. RLA calls the collector team; the tank-facing Sever remains bossmod/role-owned.",
    columns = 1,
    slots = {
        slot("orb_collectors", "Orb Collectors", {
            callKey = "toxic",
            callLabel = "COLLECTORS",
            required = true,
            helper = "Select the players responsible for moving new Coalesced Venom to the assigned Sever mark.",
        }),
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
    if bossKey == "altar" then
        local base = originalGetLayout(self, bossKey, difficultyKey)
        local sections = { ALTAR_ORBS }
        for index = 1, #base.sections do sections[#sections + 1] = base.sections[index] end
        local summary
        if difficultyKey == "normal" then
            summary = "Assign Orb Collectors, one required 5+ Guillotine team plus optional backup coverage, and Wail interrupts."
        elseif difficultyKey == "heroic" then
            summary = "Assign Orb Collectors, two distinct 5+ Guillotine teams and Wail interrupt coverage."
        else
            summary = "Assign Orb Collectors, fresh 5+ Guillotine teams and a dedicated Wail interrupt rotation."
        end
        return { summary = summary, sections = sections }
    end

    if bossKey == "ulatek" and ULATEK_LAYOUTS[difficultyKey] then
        return ULATEK_LAYOUTS[difficultyKey]
    end

    return originalGetLayout(self, bossKey, difficultyKey)
end
