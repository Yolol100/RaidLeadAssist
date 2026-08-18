local _, ns = ...

local AssignmentRegistry = ns:GetModule("Encounters.AssignmentRegistry")

local originalGetLayout = AssignmentRegistry.GetLayout

local EXPLORERS_NORMAL = {
    summary = "Only crate and fish ownership are editable. Mighty Thud uses the fixed three-soak-point raid plan; personal mechanics stay bossmod-owned.",
    sections = {
        {
            key = "resources",
            title = "Crates & Fish",
            description = "Choose the players responsible for opening crates and carrying the fish to the next unused controlled explorer.",
            columns = 2,
            slots = {
                {
                    key = "crate_a",
                    label = "Crate Breaker",
                    kind = "assignee",
                    callKey = "crates",
                    callLabel = "BREAKER",
                    required = true,
                },
                {
                    key = "fish_a",
                    label = "Fish Runner",
                    kind = "assignee",
                    callKey = "fish",
                    callLabel = "RUNNER",
                    required = true,
                },
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
                    {
                        key = "crate_a",
                        label = "Breaker 1",
                        kind = "rotation",
                        callKey = "crates",
                        callLabel = "BREAKER 1",
                        rotation = "crates",
                        required = true,
                        exclusiveGroup = "crates",
                    },
                    {
                        key = "crate_b",
                        label = "Breaker 2",
                        kind = "rotation",
                        callKey = "crates",
                        callLabel = "BREAKER 2",
                        rotation = "crates",
                        required = true,
                        exclusiveGroup = "crates",
                    },
                    {
                        key = "crate_c",
                        label = "Breaker 3",
                        kind = "rotation",
                        callKey = "crates",
                        callLabel = "BREAKER 3",
                        rotation = "crates",
                        exclusiveGroup = "crates",
                    },
                },
            },
            {
                key = "fish",
                title = "Fish Runners",
                description = "Choose one or two reliable runners for the Final Ascension fish handoff.",
                columns = 2,
                slots = {
                    {
                        key = "fish_a",
                        label = "Runner 1",
                        kind = "rotation",
                        callKey = "fish",
                        callLabel = "RUNNER 1",
                        rotation = "fish",
                        required = true,
                    },
                    {
                        key = "fish_b",
                        label = "Runner 2",
                        kind = "rotation",
                        callKey = "fish",
                        callLabel = "RUNNER 2",
                        rotation = "fish",
                    },
                },
            },
        },
    }
end

local EXPLORERS_HEROIC = explorerRotationLayout(
    "Only the crate-breaker rotation and fish runners are editable. Positioning, Thud points and personal mechanics stay in the raid plan."
)
local EXPLORERS_MYTHIC = explorerRotationLayout(
    "Only the crate-breaker rotation and fish runners are editable. Mythic crate clearance, Thud points and personal mechanics stay in the raid plan."
)

local VASHNIK_NORMAL = {
    summary = "No editable assignment is needed. The fountain route is fixed in the raid plan and personal debuffs stay bossmod-owned.",
    sections = {},
}

local VASHNIK_BILE = {
    key = "bile",
    title = "Catalytic Bile Coverage",
    description = "Choose the mobile soak team. RLA calls the team before Catalyst; the live impact locations remain dynamic.",
    columns = 1,
    slots = {
        {
            key = "bile_team",
            label = "Bile Soak Team",
            kind = "assignee",
            callKey = "catalyst",
            callLabel = "SOAK TEAM",
            required = true,
        },
    },
}

local VASHNIK_HEROIC = {
    summary = "Only Catalytic Bile coverage is editable. The fountain route and personal infection responses stay in the raid plan.",
    sections = { VASHNIK_BILE },
}

local VASHNIK_MYTHIC = {
    summary = "Only Catalytic Bile coverage is editable. Tumor aiming is a live Froth-target rule, not a fixed roster assignment.",
    sections = { VASHNIK_BILE },
}

function AssignmentRegistry:GetLayout(bossKey, difficultyKey)
    if bossKey == "explorers" then
        if difficultyKey == "normal" then return EXPLORERS_NORMAL end
        if difficultyKey == "heroic" then return EXPLORERS_HEROIC end
        if difficultyKey == "mythic" then return EXPLORERS_MYTHIC end
    elseif bossKey == "vashnik" then
        if difficultyKey == "normal" then return VASHNIK_NORMAL end
        if difficultyKey == "heroic" then return VASHNIK_HEROIC end
        if difficultyKey == "mythic" then return VASHNIK_MYTHIC end
    end
    return originalGetLayout(self, bossKey, difficultyKey)
end
