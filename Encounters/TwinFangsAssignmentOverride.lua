local _, ns = ...

local AssignmentRegistry = ns:GetModule("Encounters.AssignmentRegistry")
local originalGetLayout = AssignmentRegistry.GetLayout

local function assigneeSlot(key, label, callKey, callLabel, required, exclusiveGroup, minPlayers, helper)
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
    }
end

local FEAST_TEAMS = {
    key = "feast",
    title = "Ravenous Feast Soak Order",
    description = "Heroic/Mythic: build three fresh teams of at least 3 players because Feasted makes repeating within the same cast unsafe.",
    columns = 3,
    slots = {
        assigneeSlot("feast_team_a", "Hit 1 · Team A", "feast", "TEAM A", true, "feast", 3, "Select at least 3 unique players for the first Feast hit."),
        assigneeSlot("feast_team_b", "Hit 2 · Team B", "feast", "TEAM B", true, "feast", 3, "Select at least 3 different players for the second Feast hit."),
        assigneeSlot("feast_team_c", "Hit 3 · Team C", "feast", "TEAM C", true, "feast", 3, "Select at least 3 different players for the third Feast hit."),
    },
}

local MYTHIC_BROOD = {
    key = "brood",
    title = "Broodling Interrupt Coverage",
    description = "Mythic Broodlings can cast together. Keep separate kick owners so every Visceral Burst is stopped.",
    columns = 3,
    slots = {
        assigneeSlot("brood_kick_a", "Broodling 1 Kick", "brood", "KICK 1", true, "brood"),
        assigneeSlot("brood_kick_b", "Broodling 2 Kick", "brood", "KICK 2", true, "brood"),
        assigneeSlot("brood_kick_c", "Broodling 3 Kick", "brood", "KICK 3", false, "brood"),
    },
}

local MYTHIC_FOUNTS = {
    key = "tainted",
    title = "Tainted Blood Fount Coverage",
    description = "Optional distinct coverage for Mythic Tainted Blood founts after Ravenous Feast.",
    columns = 2,
    slots = {
        assigneeSlot("tainted_a", "Fount Team 1", "tainted", "FOUNT 1", false, "tainted"),
        assigneeSlot("tainted_b", "Fount Team 2", "tainted", "FOUNT 2", false, "tainted"),
    },
}

local LAYOUTS = {
    normal = {
        summary = "No fixed Feast roster is required on Normal: the raid stack soaks all three hits. Stone Breaker stays tank/bossmod-owned.",
        sections = {},
    },
    heroic = {
        summary = "Assign three fresh 3+ Feast teams so Feasted players never repeat within the same cast. Stone Breaker stays tank/bossmod-owned.",
        sections = { FEAST_TEAMS },
    },
    mythic = {
        summary = "Assign three fresh 3+ Feast teams plus Broodling kick coverage and optional Tainted Blood fount coverage. Stone Breaker stays tank/bossmod-owned.",
        sections = { FEAST_TEAMS, MYTHIC_BROOD, MYTHIC_FOUNTS },
    },
}

function AssignmentRegistry:GetLayout(bossKey, difficultyKey)
    if bossKey == "twinfangs" and LAYOUTS[difficultyKey] then
        return LAYOUTS[difficultyKey]
    end
    return originalGetLayout(self, bossKey, difficultyKey)
end
