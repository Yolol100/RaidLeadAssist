local _, ns = ...

local AssignmentRegistry = ns:GetModule("Encounters.AssignmentRegistry")

local NEKZALI_NORMAL = {
    summary = "No pre-pull assignment is required on Normal; melee soak and ranged spread are fixed player responsibilities.",
    sections = {},
}

local NEKZALI_PYRE_ROLES = {
    key = "pyre_roles",
    title = "Pyre & Cremation Roles",
    description = "Define who soaks Hungering Pyre and who stays outside for the fire circles that burn Amani corpses.",
    columns = 2,
    slots = {
        {
            key = "pyre_soakers",
            label = "Pyre Soak Group",
            kind = "rule",
            callKey = "pyre",
            callLabel = "PYRE SOAKERS",
            required = true,
            helper = "Use a clear roster rule such as Groups 1+2 or a named melee-heavy team.",
        },
        {
            key = "cremation_players",
            label = "Cremation Group",
            kind = "rule",
            callKey = "flame",
            callLabel = "CREMATION",
            required = true,
            helper = "These players stay outside Pyre so their fire circles can be used on dead Amani corpses.",
        },
    },
}

local NEKZALI_HEROIC = {
    summary = "Set the Pyre soak group and the Cremation group before pull; the Boss Plan only tells players how to execute their assigned role.",
    sections = { NEKZALI_PYRE_ROLES },
}

local NEKZALI_MYTHIC = {
    summary = "Set Pyre/Cremation roles plus two fresh Grasping Depths well groups before pull.",
    sections = {
        NEKZALI_PYRE_ROLES,
        {
            key = "well",
            title = "Grasping Depths Well Rotation",
            description = "Set two distinct raid-group labels. RLA alternates them because Soul Exhaustion requires fresh players for the next entry.",
            columns = 2,
            slots = {
                {
                    key = "well_a",
                    label = "Well Group 1",
                    kind = "rotation",
                    callKey = "grasping",
                    callLabel = "WELL GROUP 1",
                    rotation = "well",
                    required = true,
                    exclusiveGroup = "well",
                    helper = "Use a raid-group label such as Groups 1+2. Individual names are not required.",
                },
                {
                    key = "well_b",
                    label = "Well Group 2",
                    kind = "rotation",
                    callKey = "grasping",
                    callLabel = "WELL GROUP 2",
                    rotation = "well",
                    required = true,
                    exclusiveGroup = "well",
                    helper = "Use a different group so the next Grasping entry is fresh.",
                },
            },
        },
    },
}

local SENTINELS_SPLIT = {
    summary = "Define two physical-side teams. Team A starts green and Team B starts red; after Stasis the groups stay while tanks swap the bosses.",
    sections = {
        {
            key = "split",
            title = "Fixed Raid Sides",
            description = "These rosters stay on their physical side for the fight. Only which boss is on that side changes after Stasis.",
            columns = 2,
            slots = {
                {
                    key = "team_a",
                    label = "Team A · Green Side",
                    kind = "rule",
                    callKey = "side_swap",
                    callLabel = "TEAM A",
                    required = true,
                    helper = "Example: Group 1 in a 10-player raid or Groups 1+2 in a 20-player raid.",
                },
                {
                    key = "team_b",
                    label = "Team B · Red Side",
                    kind = "rule",
                    callKey = "side_swap",
                    callLabel = "TEAM B",
                    required = true,
                    helper = "Use the remaining players so both physical sides have reliable coverage.",
                },
            },
        },
    },
}

AssignmentRegistry:RegisterLayouts("nekzali", {
    normal = NEKZALI_NORMAL,
    heroic = NEKZALI_HEROIC,
    mythic = NEKZALI_MYTHIC,
})
AssignmentRegistry:RegisterLayouts("sentinels", {
    normal = SENTINELS_SPLIT,
    heroic = SENTINELS_SPLIT,
    mythic = SENTINELS_SPLIT,
})
