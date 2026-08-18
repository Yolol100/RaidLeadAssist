local _, ns = ...

local AssignmentRegistry = ns:GetModule("Encounters.AssignmentRegistry")

local originalGetLayout = AssignmentRegistry.GetLayout

local function teamSlot(key, label, callLabel, helper)
    return {
        key = key,
        label = label,
        kind = "rotation",
        callKey = "apex",
        callLabel = callLabel,
        rotation = "mutilate_teams",
        required = true,
        minPlayers = 5,
        exclusiveGroup = "mutilate",
        helper = helper,
    }
end

local SSZORAK_GROUP_LAYOUT = {
    summary = "Build two distinct 5+ player teams for alternating green Mutilate soaks. White Ravage stays bossmod/role-owned.",
    sections = {
        {
            key = "mutilate",
            title = "Green Mutilate Soak Rotation",
            description = "Use actual roster teams instead of hardcoded raid-group numbers so the plan remains valid at every supported raid size. RLA alternates Team A then Team B.",
            columns = 2,
            slots = {
                teamSlot(
                    "mutilate_group_1",
                    "Soak Team A",
                    "TEAM A",
                    "Select at least 5 unique players for the first green Mutilate soak."
                ),
                teamSlot(
                    "mutilate_group_2",
                    "Soak Team B",
                    "TEAM B",
                    "Select at least 5 different players for the second green Mutilate soak."
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
