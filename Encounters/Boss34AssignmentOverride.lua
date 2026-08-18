local _, ns = ...

local AssignmentRegistry = ns:GetModule("Encounters.AssignmentRegistry")

local EXPLORERS_NORMAL = {
    summary = "Only crate and fish ownership are editable. Mighty Thud uses the fixed three-soak-point raid plan; personal mechanics stay bossmod-owned.",
    sections = {
        {
            key = "resources",
            title = "Crates & Fish",
            description = "Choose the players responsible for opening crates and carrying the fish to the next unused controlled explorer.",
            columns = 2,
            slots = {
                { key = "crate_a", label = "Crate Breaker", kind = "assignee", callKey = "crates", callLabel = "BREAKER", required = true },
                { key = "fish_a", label = "Fish Runner", kind = "assignee", callKey = "fish", callLabel = "RUNNER", required = true },
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
                description = "Rotate distinct breakers so Splinters stay controlled. Mythic still requires the raid to clear 15+ yards before the break.",
                columns = 3,
                slots = {
                    { key = "crate_a", label = "Breaker 1", kind = "rotation", callKey = "crates", callLabel = "BREAKER 1", rotation = "crates", required = true, exclusiveGroup = "crates" },
                    { key = "crate_b", label = "Breaker 2", kind = "rotation", callKey = "crates", callLabel = "BREAKER 2", rotation = "crates", required = true, exclusiveGroup = "crates" },
                    { key = "crate_c", label = "Breaker 3", kind = "rotation", callKey = "crates", callLabel = "BREAKER 3", rotation = "crates", required = false, exclusiveGroup = "crates" },
                },
            },
            {
                key = "fish",
                title = "Fish Runners",
                description = "Choose one or two reliable runners for the Final Ascension fish handoff.",
                columns = 2,
                slots = {
                    { key = "fish_a", label = "Runner 1", kind = "rotation", callKey = "fish", callLabel = "RUNNER 1", rotation = "fish", required = true },
                    { key = "fish_b", label = "Runner 2", kind = "rotation", callKey = "fish", callLabel = "RUNNER 2", rotation = "fish", required = false },
                },
            },
        },
    }
end

local EXPLORERS_HEROIC = explorerRotationLayout("Only the crate-breaker rotation and fish runners are editable. Positioning, Thud points and personal mechanics stay in the raid plan.")
local EXPLORERS_MYTHIC = explorerRotationLayout("Only the crate-breaker rotation and fish runners are editable. Mythic crate clearance, Thud points and personal mechanics stay in the raid plan.")

local VASHNIK_NONE = {
    summary = "No fixed pre-pull roster assignment is required. The route is fixed in the raid plan; Catalyst impacts, Froth targets and infections resolve dynamically with DBM/BigWigs.",
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
