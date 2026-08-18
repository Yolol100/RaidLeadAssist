local _, ns = ...

local AssignmentRegistry = ns:GetModule("Encounters.AssignmentRegistry")

local originalGetLayout = AssignmentRegistry.GetLayout

local function groupSlot(key, label, callLabel, helper)
    return {
        key = key,
        label = label,
        kind = "rule",
        callKey = "apex",
        callLabel = callLabel,
        rotation = "mutilate_groups",
        required = true,
        helper = helper,
    }
end

local SSZORAK_GROUP_LAYOUT = {
    summary = "Use raid Groups 1+2 for the first green Mutilate soak and Groups 3+4 for the second. White Ravage stays DBM-owned.",
    sections = {
        {
            key = "mutilate",
            title = "Green Mutilate Soak Rotation",
            description = "Left column is Soak Groups 1+2. Right column is Soak Groups 3+4. RLA alternates Groups 1+2 then Groups 3+4 on successful Mutilate calls.",
            columns = 2,
            slots = {
                groupSlot(
                    "mutilate_group_1",
                    "Soak Groups 1+2",
                    "GROUPS 1+2",
                    "Use this column for raid Groups 1+2. Do not enter individual player names."
                ),
                groupSlot(
                    "mutilate_group_2",
                    "Soak Groups 3+4",
                    "GROUPS 3+4",
                    "Use this column for raid Groups 3+4. Do not enter individual player names."
                ),
            },
        },
    },
}

function AssignmentRegistry:GetLayout(bossKey, difficultyKey)
    if bossKey == "sszorak" and (difficultyKey == "normal" or difficultyKey == "heroic" or difficultyKey == "mythic") then
        return SSZORAK_GROUP_LAYOUT
    end
    return originalGetLayout(self, bossKey, difficultyKey)
end
