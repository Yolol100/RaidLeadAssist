local _, ns = ...

local AssignmentRegistry = ns:GetModule("Encounters.AssignmentRegistry")

local function assigneeSlot(key, label, callKey, callLabel, required, exclusiveGroup, minPlayers, helper, compactGroups)
    return {
        key = key,
        label = label,
        kind = "assignee",
        callKey = callKey,
        callLabel = callLabel,
        required = required == true,
        exclusiveGroup = exclusiveGroup,
        minPlayers = minPlayers,
        helper = helper,
        compactGroups = compactGroups == true,
    }
end

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
        summary = "Heroic uses the fixed raid → main tank → off tank Feast plan; no editable Feast teams are required.",
        sections = {},
    },
    mythic = {
        summary = "Mythic keeps three Feast teams and Broodling interrupt owners.",
        sections = { FEAST_TEAMS, MYTHIC_BROOD },
    },
})
