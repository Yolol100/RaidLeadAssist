local _, ns = ...

local AssignmentRegistry = ns:GetModule("Encounters.AssignmentRegistry")

local function assigneeSlot(key, label, callKey, callLabel, required, exclusiveGroup, minPlayers, helper, compactGroups, minRaidFraction)
    return {
        key = key,
        label = label,
        kind = "assignee",
        callKey = callKey,
        callLabel = callLabel,
        required = required == true,
        exclusiveGroup = exclusiveGroup,
        minPlayers = minPlayers,
        minRaidFraction = minRaidFraction,
        helper = helper,
        compactGroups = compactGroups == true,
    }
end

local HEROIC_FEAST_TEAMS = {
    key = "feast",
    title = "Ravenous Feast Soak Order",
    description = "Heroic: use three fresh non-overlapping teams, one per hit. Nobody soaks twice while Feasted is active.",
    columns = 3,
    slots = {
        assigneeSlot("feast_heroic_a", "Feast Hit 1", "feast1", "Hit 1", true, "heroic_feast", 3,
            "Use a fresh team of roughly one third of the raid for hit 1.", true, 0.30),
        assigneeSlot("feast_heroic_b", "Feast Hit 2", "feast2", "Hit 2", true, "heroic_feast", 3,
            "Use a different fresh team of roughly one third of the raid for hit 2.", true, 0.30),
        assigneeSlot("feast_heroic_c", "Feast Hit 3", "feast3", "Hit 3", true, "heroic_feast", 3,
            "Use the remaining fresh team for hit 3; immunities may replace this only if your raid explicitly plans that strategy.", true, 0.30),
    },
}

local FEAST_TEAMS = {
    key = "feast",
    title = "Ravenous Feast Soak Order",
    description = "Mythic: build three different 3+ teams, one for each Feast hit.",
    columns = 3,
    slots = {
        assigneeSlot("feast_team_a", "Feast Hit 1", "feast", "Hit 1", true, "feast", 3, "Choose at least 3 players for Feast hit 1.", true),
        assigneeSlot("feast_team_b", "Feast Hit 2", "feast", "Hit 2", true, "feast", 3, "Choose at least 3 different players for Feast hit 2.", true),
        assigneeSlot("feast_team_c", "Feast Hit 3", "feast", "Hit 3", true, "feast", 3, "Choose at least 3 different players for Feast hit 3.", true),
    },
}

local MYTHIC_BROOD = {
    key = "brood",
    title = "Broodling Interrupts",
    description = "Mythic: assign separate kick owners for simultaneous Visceral Bursts.",
    columns = 3,
    slots = {
        assigneeSlot("brood_kick_a", "Broodling Kick 1", "brood", "Kick 1", true, "brood", nil, "Primary Broodling interrupt."),
        assigneeSlot("brood_kick_b", "Broodling Kick 2", "brood", "Kick 2", true, "brood", nil, "Second Broodling interrupt."),
        assigneeSlot("brood_kick_c", "Broodling Kick 3", "brood", "Kick 3", false, "brood", nil, "Optional extra interrupt coverage."),
    },
}

AssignmentRegistry:RegisterLayouts("twinfangs", {
    heroic = {
        summary = "Heroic requires three fresh non-overlapping Feast teams; each player soaks at most one of the three hits.",
        sections = { HEROIC_FEAST_TEAMS },
    },
    mythic = {
        summary = "Mythic keeps three Feast teams and Broodling interrupt owners.",
        sections = { FEAST_TEAMS, MYTHIC_BROOD },
    },
})
