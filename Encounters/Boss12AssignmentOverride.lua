local _, ns = ...

local AssignmentRegistry = ns:GetModule("Encounters.AssignmentRegistry")

local NEKZALI_NORMAL = {
    summary = "No assignment is needed on Normal. Melee soak Pyre; ranged stay out and spread.",
    sections = {},
}

local NEKZALI_PYRE = {
    key = "pyre",
    title = "Hungering Pyre Soak",
    description = "Heroic/Mythic only: choose the players who soak Pyre. Everyone else stays outside and handles fire circles.",
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
            helper = "Choose actual players or complete current raid groups. No separate Cremation assignment is needed.",
        },
    },
}

local NEKZALI_HEROIC = {
    summary = "Only the Pyre soak group needs assigning. Fire-circle players are everyone outside that group.",
    sections = { NEKZALI_PYRE },
}

local NEKZALI_MYTHIC = {
    summary = "Keep the Heroic Pyre group and add two fresh Grasping Depths well groups.",
    sections = {
        NEKZALI_PYRE,
        {
            key = "well",
            title = "Grasping Depths Rotation",
            description = "Use two different groups. RLA alternates them because Soul Exhaustion makes repeat entry unsafe.",
            columns = 2,
            slots = {
                {
                    key = "well_a",
                    label = "Well Group 1",
                    kind = "rotation",
                    callKey = "grasping",
                    callLabel = "Well group",
                    rotation = "well",
                    required = true,
                    exclusiveGroup = "well",
                    compactGroups = true,
                    helper = "Choose the first fresh group that enters the Soulcoil Well.",
                },
                {
                    key = "well_b",
                    label = "Well Group 2",
                    kind = "rotation",
                    callKey = "grasping",
                    callLabel = "Well group",
                    rotation = "well",
                    required = true,
                    exclusiveGroup = "well",
                    compactGroups = true,
                    helper = "Choose a different fresh group for the next Grasping Depths.",
                },
            },
        },
    },
}

local SENTINELS_SPLIT = {
    summary = "Assign two non-overlapping physical sides. Players keep their side after Stasis; tanks swap bosses.",
    sections = {
        {
            key = "split",
            title = "Fixed Raid Sides",
            description = "Use actual players or complete current raid groups. Green stays Triangle; red stays Cross.",
            columns = 2,
            slots = {
                {
                    key = "team_a",
                    label = "Green Side",
                    kind = "assignee",
                    callKey = "side_swap",
                    callLabel = "Green",
                    required = true,
                    compactGroups = true,
                    exclusiveGroup = "sentinels_sides",
                    helper = "Choose the players who remain on the Triangle / green side for the fight.",
                },
                {
                    key = "team_b",
                    label = "Red Side",
                    kind = "assignee",
                    callKey = "side_swap",
                    callLabel = "Red",
                    required = true,
                    compactGroups = true,
                    exclusiveGroup = "sentinels_sides",
                    helper = "Choose the players who remain on the Cross / red side for the fight.",
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
