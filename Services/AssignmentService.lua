local _, ns = ...

local AssignmentRegistry = ns:GetModule("Encounters.AssignmentRegistry")

local AssignmentService = {
    database = nil,
    runtimeCounters = {},
    MAX_VALUE_LENGTH = 96,
    MAX_WARNING_LENGTH = 200,
    MAX_PLAN_LINES = 12,
}

local VALID_DIFFICULTIES = { normal = true, heroic = true, mythic = true }

local function trim(value)
    if type(value) ~= "string" then return "" end
    return value:match("^%s*(.-)%s*$") or ""
end

local function normalizeValue(value)
    value = type(value) == "string" and value or ""
    value = value:gsub("[\r\n]+", " ")
    value = value:gsub("%s*,%s*", ", ")
    value = value:gsub("%s+", " ")
    return trim(value)
end

local function containsControl(value)
    return value:find("[%z\1-\8\11\12\14-\31\127]") ~= nil
end

local function parsePlayers(value)
    local players = {}
    local seen = {}
    for part in tostring(value or ""):gmatch("[^,]+") do
        local name = trim(part)
        if name ~= "" then
            local key = name:lower()
            if seen[key] then return nil, name end
            seen[key] = true
            players[#players + 1] = { name = name, key = key }
        end
    end
    return players
end

local function getProfile(database, bossKey, difficultyKey, create)
    if type(database.assignments) ~= "table" then database.assignments = {} end
    local boss = database.assignments[bossKey]
    if boss ~= nil and type(boss) ~= "table" then
        database.assignments[bossKey] = nil
        boss = nil
    end
    if not boss and create then
        boss = {}
        database.assignments[bossKey] = boss
    end
    if not boss then return nil end

    local profile = boss[difficultyKey]
    if profile ~= nil and type(profile) ~= "table" then
        boss[difficultyKey] = nil
        profile = nil
    end
    if not profile and create then
        profile = {}
        boss[difficultyKey] = profile
    end
    return profile
end

local function cleanEmpty(database, bossKey, difficultyKey)
    local boss = database.assignments and database.assignments[bossKey]
    if type(boss) ~= "table" then return end
    local profile = boss[difficultyKey]
    if type(profile) == "table" and next(profile) == nil then boss[difficultyKey] = nil end
    if next(boss) == nil then database.assignments[bossKey] = nil end
end

local function definitionMap(bossKey, difficultyKey)
    local map = {}
    local definitions = AssignmentRegistry:GetDefinitions(bossKey, difficultyKey)
    for index = 1, #definitions do map[definitions[index].key] = definitions[index] end
    return map
end

local function counterKey(bossKey, difficultyKey, rotation)
    return table.concat({ bossKey, difficultyKey, rotation }, ":")
end

local function appendFragment(base, fragment, maxLength)
    if type(fragment) ~= "string" or fragment == "" then return base, true end
    local candidate = base == "" and fragment or (base .. " > " .. fragment)
    if #candidate <= maxLength then return candidate, true end
    return base, false
end

function AssignmentService:Initialize(database)
    self.database = database
    if type(database.assignments) ~= "table" then database.assignments = {} end
    self:NormalizeStored()
    self:ResetRuntime()
end

function AssignmentService:NormalizeStored()
    if not self.database then return end
    local stored = self.database.assignments
    for bossKey, difficulties in pairs(stored) do
        if type(difficulties) ~= "table" then
            stored[bossKey] = nil
        else
            for difficultyKey, values in pairs(difficulties) do
                if not VALID_DIFFICULTIES[difficultyKey] or type(values) ~= "table" then
                    difficulties[difficultyKey] = nil
                else
                    local allowed = definitionMap(bossKey, difficultyKey)
                    for assignmentKey, value in pairs(values) do
                        if not allowed[assignmentKey] then
                            values[assignmentKey] = nil
                        else
                            local ok, normalized = self:ValidateValue(value)
                            if not ok or normalized == "" then values[assignmentKey] = nil else values[assignmentKey] = normalized end
                        end
                    end
                    if next(values) == nil then difficulties[difficultyKey] = nil end
                end
            end
            if next(difficulties) == nil then stored[bossKey] = nil end
        end
    end
end

function AssignmentService:ValidateValue(value)
    if value == nil or value == "" then return true, "" end
    if type(value) ~= "string" then return false, "Assignment must be text." end
    if containsControl(value) then return false, "Assignment contains unsupported control characters." end
    local normalized = normalizeValue(value)
    if #normalized > self.MAX_VALUE_LENGTH then
        return false, ("Assignment must be %d characters or less."):format(self.MAX_VALUE_LENGTH)
    end
    return true, normalized
end

function AssignmentService:ValidateDefinitionValue(definition, value)
    local ok, normalized = self:ValidateValue(value)
    if not ok or normalized == "" then return ok, normalized end

    local kind = definition and definition.kind or "assignee"
    if kind == "assignee" or kind == "rotation" then
        local players, duplicate = parsePlayers(normalized)
        if not players then return false, "contains duplicate player " .. duplicate .. "." end
        if definition.exactPlayers and #players ~= definition.exactPlayers then
            return false, ("requires exactly %d unique players; found %d."):format(definition.exactPlayers, #players)
        end
        if definition.minPlayers and #players < definition.minPlayers then
            return false, ("requires at least %d unique players; found %d."):format(definition.minPlayers, #players)
        end
    end

    return true, normalized
end

function AssignmentService:GetDefinitions(bossKey, difficultyKey)
    return AssignmentRegistry:GetDefinitions(bossKey, difficultyKey)
end

function AssignmentService:GetValue(bossKey, difficultyKey, assignmentKey)
    if not self.database then return "" end
    local profile = getProfile(self.database, bossKey, difficultyKey, false)
    local value = profile and profile[assignmentKey]
    return type(value) == "string" and value or ""
end

function AssignmentService:GetValues(bossKey, difficultyKey)
    local result = {}
    local definitions = self:GetDefinitions(bossKey, difficultyKey)
    for index = 1, #definitions do
        local definition = definitions[index]
        result[definition.key] = self:GetValue(bossKey, difficultyKey, definition.key)
    end
    return result
end

function AssignmentService:ValidateBossDraft(bossKey, difficultyKey, values)
    if type(values) ~= "table" then return false, { message = "Assignment values are missing." } end

    local definitions = self:GetDefinitions(bossKey, difficultyKey)
    local clean = {}
    local exclusive = {}

    for index = 1, #definitions do
        local definition = definitions[index]
        local ok, normalized = self:ValidateDefinitionValue(definition, values[definition.key])
        if not ok then
            return false, { assignmentKey = definition.key, message = definition.label .. " " .. normalized }
        end
        if normalized ~= "" then
            clean[definition.key] = normalized
            if definition.exclusiveGroup then
                local players = assert(parsePlayers(normalized))
                local bucket = exclusive[definition.exclusiveGroup]
                if not bucket then
                    bucket = {}
                    exclusive[definition.exclusiveGroup] = bucket
                end
                for playerIndex = 1, #players do
                    local player = players[playerIndex]
                    local previous = bucket[player.key]
                    if previous then
                        return false, {
                            assignmentKey = definition.key,
                            message = ("%s overlaps %s: %s is assigned to both."):format(definition.label, previous.label, player.name),
                        }
                    end
                    bucket[player.key] = { label = definition.label, assignmentKey = definition.key }
                end
            end
        end
    end

    return true, clean
end

function AssignmentService:ApplyBossDraft(bossKey, difficultyKey, values)
    if not self.database then return false, { message = "Assignments are not initialized." } end

    local ok, result = self:ValidateBossDraft(bossKey, difficultyKey, values)
    if not ok then return false, result end
    local clean = result

    local boss = self.database.assignments[bossKey]
    if type(boss) ~= "table" then
        boss = {}
        self.database.assignments[bossKey] = boss
    end
    boss[difficultyKey] = clean
    cleanEmpty(self.database, bossKey, difficultyKey)
    self:ResetRuntime()
    return true, clean
end

function AssignmentService:ResetBoss(bossKey, difficultyKey)
    if not self.database or type(self.database.assignments) ~= "table" then return end
    local boss = self.database.assignments[bossKey]
    if type(boss) == "table" then boss[difficultyKey] = nil end
    cleanEmpty(self.database, bossKey, difficultyKey)
    self:ResetRuntime()
end

function AssignmentService:GetMissingRequired(bossKey, difficultyKey, values)
    values = values or self:GetValues(bossKey, difficultyKey)
    local missing = {}
    local definitions = self:GetDefinitions(bossKey, difficultyKey)
    for index = 1, #definitions do
        local definition = definitions[index]
        if definition.required and normalizeValue(values[definition.key]) == "" then missing[#missing + 1] = definition.label end
    end
    return missing
end

function AssignmentService:GetPlanLines(bossKey, difficultyKey)
    local lines = {}
    local definitions = self:GetDefinitions(bossKey, difficultyKey)
    for index = 1, #definitions do
        local definition = definitions[index]
        local value = self:GetValue(bossKey, difficultyKey, definition.key)
        if value ~= "" then
            local line = "ASSIGN > " .. definition.label .. ": " .. value
            if #line <= self.MAX_WARNING_LENGTH then
                lines[#lines + 1] = line
                if #lines >= self.MAX_PLAN_LINES then break end
            end
        end
    end
    return lines
end

function AssignmentService:GetCallFragments(bossKey, difficultyKey, callKey)
    local definitions = AssignmentRegistry:GetCallDefinitions(bossKey, difficultyKey, callKey)
    if #definitions == 0 then return {} end

    local fragments = {}
    local rotations = {}
    for index = 1, #definitions do
        local definition = definitions[index]
        local value = self:GetValue(bossKey, difficultyKey, definition.key)
        if value ~= "" then
            if definition.rotation then
                local bucket = rotations[definition.rotation]
                if not bucket then
                    bucket = {}
                    rotations[definition.rotation] = bucket
                end
                bucket[#bucket + 1] = { definition = definition, value = value }
            else
                fragments[#fragments + 1] = (definition.callLabel or definition.label) .. ": " .. value
            end
        end
    end

    local rotationNames = {}
    for rotation in pairs(rotations) do rotationNames[#rotationNames + 1] = rotation end
    table.sort(rotationNames)
    for index = 1, #rotationNames do
        local rotation = rotationNames[index]
        local bucket = rotations[rotation]
        if #bucket > 0 then
            local count = self.runtimeCounters[counterKey(bossKey, difficultyKey, rotation)] or 0
            local selected = bucket[(count % #bucket) + 1]
            local definition = selected.definition
            fragments[#fragments + 1] = (definition.callLabel or definition.label) .. ": " .. selected.value
        end
    end

    return fragments
end

function AssignmentService:BuildCallWarning(baseWarning, bossKey, difficultyKey, callKey)
    if type(baseWarning) ~= "string" or baseWarning == "" then return baseWarning, true end
    local result = baseWarning
    local fragments = self:GetCallFragments(bossKey, difficultyKey, callKey)
    for index = 1, #fragments do
        local appended
        result, appended = appendFragment(result, fragments[index], self.MAX_WARNING_LENGTH)
        if not appended then return baseWarning, false end
    end
    return result, true
end

function AssignmentService:AdvanceCall(bossKey, difficultyKey, callKey)
    local definitions = AssignmentRegistry:GetCallDefinitions(bossKey, difficultyKey, callKey)
    local seen = {}
    for index = 1, #definitions do
        local definition = definitions[index]
        if definition.rotation and not seen[definition.rotation] and self:GetValue(bossKey, difficultyKey, definition.key) ~= "" then
            local key = counterKey(bossKey, difficultyKey, definition.rotation)
            self.runtimeCounters[key] = (self.runtimeCounters[key] or 0) + 1
            seen[definition.rotation] = true
        end
    end
end

function AssignmentService:ResetRuntime()
    self.runtimeCounters = {}
end

ns:RegisterModule("Services.AssignmentService", AssignmentService)
