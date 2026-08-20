local _, ns = ...

local Util = ns:GetModule("Core.Util")
local Assignments = ns:GetModule("Services.AssignmentService")
local Roster = ns:GetModule("Services.RosterService")

local PersonalAssignments = {
    MAX_LINES = 12,
}

local function trim(value)
    if type(value) ~= "string" or Util.IsSecret(value) then return nil end
    return value:match("^%s*(.-)%s*$")
end

local function normalizePlayer(value)
    local name = trim(value)
    if not name or name == "" then return nil, nil end
    local full = name:lower()
    return full, full:match("^([^%-]+)")
end

local function groupTokenContains(token, subgroup)
    subgroup = tonumber(subgroup)
    if not subgroup or subgroup < 1 or subgroup > 8 then return false end
    local lowered = token:lower()
    local body = lowered:match("^group%s+(%d+)$") or lowered:match("^groups%s+([%d+]+)$")
    if not body then return false end
    for number in body:gmatch("%d+") do
        if tonumber(number) == subgroup then return true end
    end
    return false
end

local function valueTargetsPlayer(value, playerFull, playerShort, subgroup)
    if type(value) ~= "string" or Util.IsSecret(value) then return false end
    for raw in value:gmatch("[^,]+") do
        local token = trim(raw)
        if token and token ~= "" then
            if groupTokenContains(token, subgroup) then return true end
            local full, short = normalizePlayer(token)
            if full and (full == playerFull or full == playerShort or short == playerFull or short == playerShort) then
                return true
            end
        end
    end
    return false
end

function PersonalAssignments:ResolvePlayer()
    local playerName = type(UnitName) == "function" and UnitName("player") or nil
    local full, short = normalizePlayer(playerName)
    if not full then return nil, nil, nil end

    local subgroup
    local roster = Roster:GetRoster()
    for index = 1, #roster do
        local rosterFull, rosterShort = normalizePlayer(roster[index].name)
        if rosterFull and (rosterFull == full or rosterFull == short or rosterShort == full or rosterShort == short) then
            subgroup = tonumber(roster[index].subgroup)
            break
        end
    end
    return playerName, subgroup, short
end

function PersonalAssignments:GetLines(bossKey, difficultyKey, playerName, subgroup)
    local playerFull, playerShort = normalizePlayer(playerName)
    if not playerFull then return {} end

    local lines = {}
    local definitions = Assignments:GetDefinitions(bossKey, difficultyKey)
    for index = 1, #definitions do
        local definition = definitions[index]
        if definition.kind == "assignee" or definition.kind == "rotation" then
            local value = Assignments:GetValue(bossKey, difficultyKey, definition.key)
            if valueTargetsPlayer(value, playerFull, playerShort, subgroup) then
                lines[#lines + 1] = {
                    key = definition.key,
                    label = definition.label,
                    value = value,
                    kind = definition.kind,
                }
                if #lines >= self.MAX_LINES then break end
            end
        end
    end
    return lines
end

ns:RegisterModule("Services.PersonalAssignmentService", PersonalAssignments)
