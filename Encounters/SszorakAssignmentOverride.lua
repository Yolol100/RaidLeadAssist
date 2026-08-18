local _, ns = ...

local AssignmentRegistry = ns:GetModule("Encounters.AssignmentRegistry")

local function teamSlot(key, label, callLabel, helper)
    return {
        key = key, label = label, kind = "rotation", callKey = "apex", callLabel = callLabel,
        rotation = "mutilate_teams", required = true, minPlayers = 5, exclusiveGroup = "mutilate", helper = helper,
    }
end

local function popperSlot(key, label, callLabel, helper)
    return {
        key = key, label = label, kind = "assignee", callKey = "maelstrom", callLabel = callLabel,
        required = true, exclusiveGroup = "cyst_poppers", helper = helper,
    }
end

local SSZORAK_GROUP_LAYOUT = {
    summary = "Build two distinct 5+ Mutilate teams and assign three distinct Cyst Poppers, one for each Maelstrom wind. White Ravage stays bossmod/role-owned.",
    sections = {
        {
            key = "mutilate",
            title = "Green Mutilate Soak Rotation",
            description = "Use actual roster teams instead of hardcoded raid-group numbers. RLA alternates Team A then Team B.",
            columns = 2,
            slots = {
                teamSlot("mutilate_group_1", "Soak Team A", "Team A", "Select at least 5 unique players for the first green Mutilate soak."),
                teamSlot("mutilate_group_2", "Soak Team B", "Team B", "Select at least 5 different players for the second green Mutilate soak."),
            },
        },
        {
            key = "cyst_poppers",
            title = "Howling Maelstrom Cyst Poppers",
            description = "Assign one distinct player per wind. Each popper triggers the prepared Cyst as that wind begins so its knockback counters the gale.",
            columns = 3,
            slots = {
                popperSlot("cyst_popper_1", "Wind 1 Popper", "Popper 1", "Triggers the prepared Cyst when the first wind begins."),
                popperSlot("cyst_popper_2", "Wind 2 Popper", "Popper 2", "Triggers the prepared Cyst when the second wind begins."),
                popperSlot("cyst_popper_3", "Wind 3 Popper", "Popper 3", "Triggers the prepared Cyst when the third wind begins."),
            },
        },
    },
}

AssignmentRegistry:RegisterLayouts("sszorak", {
    normal = SSZORAK_GROUP_LAYOUT,
    heroic = SSZORAK_GROUP_LAYOUT,
    mythic = SSZORAK_GROUP_LAYOUT,
})
