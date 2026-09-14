local _, ns = ...

local AssignmentRegistry = ns:GetModule("Encounters.AssignmentRegistry")

local NEKZALI_HEROIC = {
    summary = "Heroic uses the role-based melee+tank Pyre call; no fixed roster assignment is required.",
    sections = {},
}

local NEKZALI_PYRE = {
    key = "pyre",
    title = "Hungering Pyre Soak",
    description = "Mythic: choose the players who soak Pyre. Everyone else stays outside and handles fire circles.",
    columns = 1,
    slots = {
        {
            key = "pyre_soakers",
            label = "Pyre Soak Group",
            kind = "assignee",
            callKey = "pyre",
            callLabel = "Pyre",
            required = true,
            compactGroups = true,
            helper = "Choose actual players or complete current raid groups. Called players soak; everyone else stays out.",
        },
    },
}

local NEKZALI_MYTHIC = {
    summary = "Assign the Mythic Pyre group and two fresh Grasping Depths well groups.",
    sections = {
        NEKZALI_PYRE,
        {
            key = "well",
            title = "Grasping Depths Rotation",
            description = "Use two different groups. RLA alternates them because Soul Exhaustion makes repeat entry unsafe.",
            columns = 2,
            slots = {
                {
                    key = "well_a", label = "Well Group 1", kind = "rotation", callKey = "grasping",
                    callLabel = "Well group", rotation = "well", required = true, exclusiveGroup = "well",
                    compactGroups = true, helper = "Choose the first fresh group that enters the Soulcoil Well.",
                },
                {
                    key = "well_b", label = "Well Group 2", kind = "rotation", callKey = "grasping",
                    callLabel = "Well group", rotation = "well", required = true, exclusiveGroup = "well",
                    compactGroups = true, helper = "Choose a different fresh group for the next Grasping Depths.",
                },
            },
        },
    },
}

local SENTINELS_HEROIC = {
    summary = "Heroic RED/GREEN sides are generated from the actually populated raid subgroups when the pre-pull briefing is sent.",
    sections = {},
}

local SENTINELS_MYTHIC = {
    summary = "Assign two non-overlapping Mythic sides. Players hold their physical side after Stasis while tanks swap bosses.",
    sections = {
        {
            key = "split",
            title = "Mythic Raid Sides",
            description = "Use actual players or complete current raid groups. Green stays on its side; red stays on its side; tanks swap bosses after Stasis.",
            columns = 2,
            slots = {
                {
                    key = "team_a", label = "Green Side", kind = "assignee", callKey = "side_swap",
                    callLabel = "Green", required = true, compactGroups = true, exclusiveGroup = "sentinels_sides",
                    helper = "Choose the players who remain on the green side.",
                },
                {
                    key = "team_b", label = "Red Side", kind = "assignee", callKey = "side_swap",
                    callLabel = "Red", required = true, compactGroups = true, exclusiveGroup = "sentinels_sides",
                    helper = "Choose the players who remain on the red side.",
                },
            },
        },
    },
}

AssignmentRegistry:RegisterLayouts("nekzali", {
    heroic = NEKZALI_HEROIC,
    mythic = NEKZALI_MYTHIC,
})
AssignmentRegistry:RegisterLayouts("sentinels", {
    heroic = SENTINELS_HEROIC,
    mythic = SENTINELS_MYTHIC,
})
