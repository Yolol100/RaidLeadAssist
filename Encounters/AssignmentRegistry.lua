local _, ns = ...

local AssignmentRegistry = {
    layouts = {},
}

local BOSS_KEYS = {
    "altar",
    "explorers",
    "nekzali",
    "sentinels",
    "sszorak",
    "twinfangs",
    "ulatek",
    "vashnik",
}

local VALID_BOSSES = {}
for index = 1, #BOSS_KEYS do VALID_BOSSES[BOSS_KEYS[index]] = true end

local VALID_DIFFICULTIES = { normal = true, heroic = true, mythic = true }
local VALID_KINDS = { assignee = true, rotation = true, rule = true, sequence = true }

local function fallbackLayout(bossKey, difficultyKey)
    return {
        summary = ("Assignment layout unavailable for %s/%s; fail closed with no editable fields."):format(
            tostring(bossKey), tostring(difficultyKey)
        ),
        sections = {},
    }
end

function AssignmentRegistry:ValidateLayout(bossKey, difficultyKey, profile)
    assert(VALID_BOSSES[bossKey], "Unknown assignment boss: " .. tostring(bossKey))
    assert(VALID_DIFFICULTIES[difficultyKey], "Invalid assignment difficulty: " .. tostring(difficultyKey))
    assert(type(profile) == "table", "Assignment layout must be a table")
    assert(type(profile.summary) == "string" and profile.summary ~= "", "Assignment layout requires summary")
    assert(type(profile.sections) == "table", "Assignment layout requires sections")

    local seen = {}
    for sectionIndex = 1, #profile.sections do
        local section = profile.sections[sectionIndex]
        assert(type(section) == "table", "Assignment section must be a table")
        assert(type(section.key) == "string" and section.key ~= "", "Assignment section requires key")
        assert(type(section.title) == "string" and section.title ~= "", "Assignment section requires title")
        assert(type(section.description) == "string", "Assignment section requires description")
        assert(type(section.columns) == "number" and section.columns >= 1 and section.columns <= 4,
            "Invalid assignment columns")
        assert(type(section.slots) == "table", "Assignment section requires slots")

        for slotIndex = 1, #section.slots do
            local definition = section.slots[slotIndex]
            assert(type(definition) == "table", "Assignment definition must be a table")
            assert(type(definition.key) == "string" and definition.key ~= "", "Assignment requires key")
            assert(type(definition.label) == "string" and definition.label ~= "", "Assignment requires label")
            assert(not seen[definition.key],
                "Duplicate assignment key: " .. bossKey .. "/" .. difficultyKey .. "/" .. definition.key)
            assert(VALID_KINDS[definition.kind], "Invalid assignment kind: " .. tostring(definition.kind))
            assert(type(definition.required) == "boolean", "Assignment required flag must be boolean")

            if definition.callKey ~= nil then
                assert(type(definition.callKey) == "string" and definition.callKey ~= "", "Invalid assignment callKey")
            end
            if definition.callLabel ~= nil then
                assert(type(definition.callLabel) == "string" and definition.callLabel ~= "", "Invalid assignment callLabel")
            end
            if definition.helper ~= nil then
                assert(type(definition.helper) == "string", "Invalid assignment helper")
            end
            if definition.compactGroups ~= nil then
                assert(type(definition.compactGroups) == "boolean", "compactGroups must be boolean")
                assert(definition.kind == "assignee" or definition.kind == "rotation",
                    "compactGroups requires a roster-like assignment")
            end
            if definition.rotation ~= nil then
                assert(definition.kind == "rotation", "Rotating assignment must use rotation kind")
                assert(type(definition.rotation) == "string" and definition.rotation ~= "", "Invalid rotation")
            end
            if definition.exactPlayers ~= nil then
                assert(type(definition.exactPlayers) == "number" and definition.exactPlayers >= 1,
                    "Invalid exactPlayers")
            end
            if definition.minPlayers ~= nil then
                assert(type(definition.minPlayers) == "number" and definition.minPlayers >= 1,
                    "Invalid minPlayers")
            end
            assert(not (definition.exactPlayers and definition.minPlayers),
                "Assignment cannot require both exactPlayers and minPlayers")
            if definition.exclusiveGroup ~= nil then
                assert(definition.kind == "assignee" or definition.kind == "rotation",
                    "exclusiveGroup requires a roster-like field")
                assert(type(definition.exclusiveGroup) == "string" and definition.exclusiveGroup ~= "",
                    "Invalid exclusiveGroup")
            end

            seen[definition.key] = true
        end
    end

    return profile
end

function AssignmentRegistry:Register(bossKey, difficultyKey, profile)
    self:ValidateLayout(bossKey, difficultyKey, profile)
    self.layouts[bossKey] = self.layouts[bossKey] or {}
    assert(self.layouts[bossKey][difficultyKey] == nil,
        "Duplicate assignment layout: " .. bossKey .. "/" .. difficultyKey)
    self.layouts[bossKey][difficultyKey] = profile
end

function AssignmentRegistry:RegisterLayouts(bossKey, layouts)
    assert(type(layouts) == "table", "Assignment layouts must be a table")
    for _, difficultyKey in ipairs({ "normal", "heroic", "mythic" }) do
        local profile = layouts[difficultyKey]
        if profile then self:Register(bossKey, difficultyKey, profile) end
    end
end

function AssignmentRegistry:GetLayout(bossKey, difficultyKey)
    local boss = self.layouts[bossKey]
    local profile = boss and boss[difficultyKey]
    return profile or fallbackLayout(bossKey, difficultyKey)
end

function AssignmentRegistry:GetDefinitions(bossKey, difficultyKey)
    if not VALID_BOSSES[bossKey] or not VALID_DIFFICULTIES[difficultyKey] then
        return {}
    end

    local result = {}
    local profile = self:ValidateLayout(bossKey, difficultyKey, self:GetLayout(bossKey, difficultyKey))
    for sectionIndex = 1, #profile.sections do
        local section = profile.sections[sectionIndex]
        for slotIndex = 1, #section.slots do
            result[#result + 1] = section.slots[slotIndex]
        end
    end
    return result
end

function AssignmentRegistry:GetCallDefinitions(bossKey, difficultyKey, callKey)
    local result = {}
    local definitions = self:GetDefinitions(bossKey, difficultyKey)
    for index = 1, #definitions do
        if definitions[index].callKey == callKey then result[#result + 1] = definitions[index] end
    end
    return result
end

function AssignmentRegistry:GetBossKeys()
    local result = {}
    for index = 1, #BOSS_KEYS do result[index] = BOSS_KEYS[index] end
    return result
end

ns:RegisterModule("Encounters.AssignmentRegistry", AssignmentRegistry)
