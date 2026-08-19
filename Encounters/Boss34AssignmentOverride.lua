local _, ns = ...

local AssignmentRegistry = ns:GetModule("Encounters.AssignmentRegistry")

local EXPLORERS_NORMAL = {
    summary = "Only the crate breaker is assigned. Fish order and Thud markers are fixed strategy, not roster fields.",
    sections = {
        {
            key = "crates",
            title = "Crate Breaker",
            description = "Choose who opens Gebbo's crates until the fish appears.",
            columns = 1,
            slots = {
                { key = "crate_a", label = "Crate Breaker", kind = "assignee", callKey = "crates", callLabel = "Breaker", required = true },
            },
        },
    },
}

local function explorerRotationLayout(summary)
    return {
        summary = summary,
        sections = {
            {
                key = "crates",
                title = "Crate Breaker Rotation",
                description = "Rotate distinct breakers to control Splinters. Fish order remains fixed in the Boss Plan.",
                columns = 3,
                slots = {
                    { key = "crate_a", label = "Breaker 1", kind = "rotation", callKey = "crates", callLabel = "Breaker", rotation = "crates", required = true, exclusiveGroup = "crates" },
                    { key = "crate_b", label = "Breaker 2", kind = "rotation", callKey = "crates", callLabel = "Breaker", rotation = "crates", required = true, exclusiveGroup = "crates" },
                    { key = "crate_c", label = "Breaker 3", kind = "rotation", callKey = "crates", callLabel = "Breaker", rotation = "crates", required = false, exclusiveGroup = "crates" },
                },
            },
        },
    }
end

local EXPLORERS_HEROIC = explorerRotationLayout("Only the crate-breaker rotation is assigned. Fish order and Thud points stay fixed.")
local EXPLORERS_MYTHIC = explorerRotationLayout("Only the crate-breaker rotation is assigned. Mythic adds raid clearance before each break.")

local VASHNIK_NONE = {
    summary = "No fixed player assignment is needed. Fountain route and Fire-add marks are fixed raidleader strategy.",
    sections = {},
}

AssignmentRegistry:RegisterLayouts("explorers", {
    normal = EXPLORERS_NORMAL,
    heroic = EXPLORERS_HEROIC,
    mythic = EXPLORERS_MYTHIC,
})
AssignmentRegistry:RegisterLayouts("vashnik", {
    normal = VASHNIK_NONE,
    heroic = VASHNIK_NONE,
    mythic = VASHNIK_NONE,
})
