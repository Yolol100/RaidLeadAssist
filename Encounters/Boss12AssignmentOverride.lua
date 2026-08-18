local _, ns = ...

local AssignmentRegistry = ns:GetModule("Encounters.AssignmentRegistry")

local NEKZALI_NORMAL = {
    summary = "No pre-pull assignment is required on Normal; melee/ranged responsibilities are fixed in the raid plan.",
    sections = {},
}

local NEKZALI_HEROIC = {
    summary = "No editable assignment is required on Heroic; melee soaks and ranged Cremation corpse burns are fixed raid-plan responsibilities.",
    sections = {},
}

local NEKZALI_MYTHIC = {
    summary = "Only the alternating fresh Grasping Depths well groups need a pre-pull assignment. Pyre and Cremation roles stay fixed in the raid plan.",
    sections = {
        {
            key = "well",
            title = "Grasping Depths Well Rotation",
            description = "Enter two distinct raid-group labels. RLA alternates them after successful Grasping calls because Soul Exhaustion requires a fresh group.",
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
                    helper = "Use a different raid-group label such as Groups 3+4 so the next entry is fresh.",
                },
            },
        },
    },
}

local SENTINELS_SPLIT = {
    summary = "Define two physical-side teams. Team A starts with Breath/green and Team B starts with Blood/red; after Stasis the groups hold their sides while the bosses are tank-swapped across them.",
    sections = {
        {
            key = "split",
            title = "Fixed Raid Sides",
            description = "Use group selectors or short team rules instead of fixed raid-group numbers. These rosters stay on their physical side for the fight; only which boss is on that side changes after Stasis.",
            columns = 2,
            slots = {
                {
                    key = "team_a",
                    label = "Team A · Green Side",
                    kind = "rule",
                    callKey = "side_swap",
                    callLabel = "TEAM A",
                    required = true,
                    helper = "Example: Group 1 in a 10-player raid or Groups 1+2 in a 20-player raid. Team A starts with Breath/green and holds this side.",
                },
                {
                    key = "team_b",
                    label = "Team B · Red Side",
                    kind = "rule",
                    callKey = "side_swap",
                    callLabel = "TEAM B",
                    required = true,
                    helper = "Example: Group 2 in a 10-player raid or Groups 3+4 in a 20-player raid. Team B starts with Blood/red and holds this side.",
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
