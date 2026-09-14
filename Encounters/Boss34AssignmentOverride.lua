local _, ns = ...

local AssignmentRegistry = ns:GetModule("Encounters.AssignmentRegistry")

local EXPLORERS_HEROIC = {
    summary = "Heroic uses the fixed Gebbo → Nama → Iku fish plan and needs no roster assignment.",
    sections = {},
}

local EXPLORERS_MYTHIC = {
    summary = "Mythic: assign a crate-breaker rotation so everyone else can clear 15+ yards before each break.",
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

local VASHNIK_HEROIC = {
    summary = "Heroic Purple+Orange is shared raid strategy; no fixed player assignment is required.",
    sections = {},
}

local VASHNIK_MYTHIC = {
    summary = "Mythic uses its separate fountain/tumor execution and needs no fixed roster assignment here.",
    sections = {},
}

AssignmentRegistry:RegisterLayouts("explorers", {
    heroic = EXPLORERS_HEROIC,
    mythic = EXPLORERS_MYTHIC,
})
AssignmentRegistry:RegisterLayouts("vashnik", {
    heroic = VASHNIK_HEROIC,
    mythic = VASHNIK_MYTHIC,
})
