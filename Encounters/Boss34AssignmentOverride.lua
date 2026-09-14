local _, ns = ...

local AssignmentRegistry = ns:GetModule("Encounters.AssignmentRegistry")

local EXPLORERS_BASE = {
    summary = "No roster assignment is needed. Crates are opportunistic; fish order and Thud markers are fixed strategy.",
    sections = {},
}

local EXPLORERS_MYTHIC = {
    summary = "Mythic only: assign a crate-breaker rotation so everyone else can clear 15+ yards before each break.",
    sections = {
        {
            key = "crates",
            title = "Mythic Crate Breaker Rotation",
            description = "Rotate distinct breakers. Everyone else clears 15+ yards before the called breaker opens the crate.",
            columns = 3,
            slots = {
                { key = "crate_a", label = "Breaker 1", kind = "rotation", callKey = "crates", callLabel = "Breaker", rotation = "crates", required = true, exclusiveGroup = "crates" },
                { key = "crate_b", label = "Breaker 2", kind = "rotation", callKey = "crates", callLabel = "Breaker", rotation = "crates", required = true, exclusiveGroup = "crates" },
                { key = "crate_c", label = "Breaker 3", kind = "rotation", callKey = "crates", callLabel = "Breaker", rotation = "crates", required = false, exclusiveGroup = "crates" },
            },
        },
    },
}

local VASHNIK_NONE = {
    summary = "No fixed player assignment is needed. Fountain route, Blood-circle help and Fire-add order are shared strategy.",
    sections = {},
}

AssignmentRegistry:RegisterLayouts("explorers", {
    normal = EXPLORERS_BASE,
    heroic = EXPLORERS_BASE,
    mythic = EXPLORERS_MYTHIC,
})
AssignmentRegistry:RegisterLayouts("vashnik", {
    normal = VASHNIK_NONE,
    heroic = VASHNIK_NONE,
    mythic = VASHNIK_NONE,
})
