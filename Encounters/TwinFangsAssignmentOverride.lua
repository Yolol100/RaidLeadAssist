local _, ns = ...

local AssignmentRegistry = ns:GetModule("Encounters.AssignmentRegistry")
local originalGetLayout = AssignmentRegistry.GetLayout

local function ruleSlot(key, label, helper)
    return {
        key = key,
        label = label,
        kind = "rule",
        required = false,
        helper = helper,
    }
end

local function assigneeSlot(key, label, callKey, callLabel, required, exclusiveGroup)
    return {
        key = key,
        label = label,
        kind = "assignee",
        callKey = callKey,
        callLabel = callLabel,
        required = required == true,
        exclusiveGroup = exclusiveGroup,
    }
end

local FEAST_NORMAL_HEROIC = {
    key = "feast",
    title = "Ravenous Feast Soak Order",
    description = "Use raid groups, not player lists: first Groups 1+2, then Groups 3+4, then Groups 5+6. These columns document the fixed raid plan; no individual names are required.",
    columns = 3,
    slots = {
        ruleSlot("feast_groups_12", "Hit 1 · Groups 1+2", "Fixed first Feast soak group."),
        ruleSlot("feast_groups_34", "Hit 2 · Groups 3+4", "Fixed second Feast soak group."),
        ruleSlot("feast_groups_56", "Hit 3 · Groups 5+6", "Fixed third Feast soak group."),
    },
}

local FEAST_MYTHIC = {
    key = "feast",
    title = "Ravenous Feast Soak Order",
    description = "Mythic is fixed at 20 players, so Groups 5+6 do not exist. Use Group 1, then Group 2, then Groups 3+4 so all three Feast hits have fresh players.",
    columns = 3,
    slots = {
        ruleSlot("feast_group_1", "Hit 1 · Group 1", "Fixed first Mythic Feast soak group."),
        ruleSlot("feast_group_2", "Hit 2 · Group 2", "Fixed second Mythic Feast soak group."),
        ruleSlot("feast_groups_34", "Hit 3 · Groups 3+4", "Fixed third Mythic Feast soak group."),
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
        summary = "Ravenous Feast uses fixed raid-group columns. Stone Breaker is DBM-owned and has no RaidLeadAssist assignment.",
        sections = { FEAST_NORMAL_HEROIC },
    },
    heroic = {
        summary = "Ravenous Feast uses Groups 1+2 > 3+4 > 5+6. Stone Breaker stays DBM-owned.",
        sections = { FEAST_NORMAL_HEROIC },
    },
    mythic = {
        summary = "20-player Mythic uses Group 1 > Group 2 > Groups 3+4 for Feast, plus Broodling kick and optional Tainted Blood coverage.",
        sections = { FEAST_MYTHIC, MYTHIC_BROOD, MYTHIC_FOUNTS },
    },
}

function AssignmentRegistry:GetLayout(bossKey, difficultyKey)
    if bossKey == "twinfangs" and LAYOUTS[difficultyKey] then
        return LAYOUTS[difficultyKey]
    end
    return originalGetLayout(self, bossKey, difficultyKey)
end
