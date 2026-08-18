local _, ns = ...

local AssignmentRegistry = ns:GetModule("Encounters.AssignmentRegistry")

local originalGetLayout = AssignmentRegistry.GetLayout

local function groupSlot(key, label, callLabel)
    return {
        key = key,
        label = label,
        kind = "rule",
        callKey = "apex",
        callLabel = callLabel,
        rotation = "mutilate_groups",
        required = true,
        helper = "Enter the raid group assignment, for example Groups 1+2 or Groups 3+4. Do not enter individual player names.",
    }
end

local SSZORAK_GROUP_LAYOUT = {
    summary = "Assign two raid groups for the green Mutilate soak. White Ravage stays DBM-owned.",
    sections = {
        {
            key = "mutilate",
            title = "Green Mutilate Soak Rotation",
            description = "Alternate two raid groups for the green Mutilate hit. Configure group labels/numbers only; RLA rotates Group 1 then Group 2 on each successful Mutilate call.",
            columns = 2,
            slots = {
                groupSlot("mutilate_group_1", "Soak Group 1", "GROUP 1"),
                groupSlot("mutilate_group_2", "Soak Group 2", "GROUP 2"),
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
