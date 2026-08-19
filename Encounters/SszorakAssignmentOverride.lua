local _, ns = ...

local AssignmentRegistry = ns:GetModule("Encounters.AssignmentRegistry")

local function teamSlot(key, label, helper)
    return {
        key = key,
        label = label,
        kind = "rotation",
        callKey = "apex",
        callLabel = "Mutilate",
        rotation = "mutilate_teams",
        required = true,
        minPlayers = 5,
        exclusiveGroup = "mutilate",
        compactGroups = true,
        helper = helper,
    }
end

local function popperSlot(key, label, helper)
    return {
        key = key,
        label = label,
        kind = "assignee",
        callKey = "maelstrom",
        callLabel = label,
        required = true,
        exclusiveGroup = "cyst_poppers",
        helper = helper,
    }
end

local SSZORAK_GROUP_LAYOUT = {
    summary = "Assign two different 5+ Mutilate teams and one Cyst Popper per Maelstrom wind.",
    sections = {
        {
            key = "mutilate",
            title = "Mutilate Soak Rotation",
            description = "Choose actual players or complete current raid groups. RLA alternates the two teams.",
            columns = 2,
            slots = {
                teamSlot("mutilate_group_1", "Mutilate Group 1", "Choose at least 5 players for the first Mutilate soak."),
                teamSlot("mutilate_group_2", "Mutilate Group 2", "Choose at least 5 different players for the next Mutilate soak."),
            },
        },
        {
            key = "cyst_poppers",
            title = "Maelstrom Cyst Poppers",
            description = "Assign one different player to each of the three winds.",
            columns = 3,
            slots = {
                popperSlot("cyst_popper_1", "Popper 1", "Triggers the prepared Cyst on wind 1."),
                popperSlot("cyst_popper_2", "Popper 2", "Triggers the prepared Cyst on wind 2."),
                popperSlot("cyst_popper_3", "Popper 3", "Triggers the prepared Cyst on wind 3."),
            },
        },
    },
}

AssignmentRegistry:RegisterLayouts("sszorak", {
    normal = SSZORAK_GROUP_LAYOUT,
    heroic = SSZORAK_GROUP_LAYOUT,
    mythic = SSZORAK_GROUP_LAYOUT,
})
