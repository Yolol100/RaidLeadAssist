local _, ns = ...

local AssignmentRegistry = ns:GetModule("Encounters.AssignmentRegistry")

local originalGetLayout = AssignmentRegistry.GetLayout

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

local SENTINELS_FIXED = {
    summary = "No editable assignment is needed: Groups 1+2 start Breath/green, Groups 3+4 start Blood/red, and Helical Toxin matching is fixed at 1+3 or 2+2.",
    sections = {},
}

function AssignmentRegistry:GetLayout(bossKey, difficultyKey)
    if bossKey == "nekzali" then
        if difficultyKey == "normal" then return NEKZALI_NORMAL end
        if difficultyKey == "heroic" then return NEKZALI_HEROIC end
        if difficultyKey == "mythic" then return NEKZALI_MYTHIC end
    elseif bossKey == "sentinels" and (difficultyKey == "normal" or difficultyKey == "heroic" or difficultyKey == "mythic") then
        return SENTINELS_FIXED
    end
    return originalGetLayout(self, bossKey, difficultyKey)
end
