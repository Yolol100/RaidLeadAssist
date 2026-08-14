local _, ns = ...

local RosterService = {}

local ROLE_ORDER = { TANK = 1, HEALER = 2, DAMAGER = 3, NONE = 4 }

local function safeName(value)
    if type(value) ~= "string" or value == "" then return nil end
    return value
end

function RosterService:GetRoster()
    local result = {}
    local count = type(GetNumGroupMembers) == "function" and GetNumGroupMembers() or 0

    if type(IsInRaid) == "function" and IsInRaid() and type(GetRaidRosterInfo) == "function" then
        for index = 1, count do
            local name, _, subgroup, _, className, classFileName, _, _, _, role = GetRaidRosterInfo(index)
            name = safeName(name)
            if name then
                result[#result + 1] = {
                    name = name,
                    subgroup = tonumber(subgroup) or 1,
                    role = type(role) == "string" and role or "NONE",
                    className = className,
                    classFileName = classFileName,
                    raidIndex = index,
                }
            end
        end
    else
        local partyCount = math.max(0, count - 1)
        local units = { "player" }
        for index = 1, partyCount do units[#units + 1] = "party" .. index end
        for index = 1, #units do
            local unit = units[index]
            local name = type(UnitName) == "function" and safeName(UnitName(unit)) or nil
            if name then
                local role = type(UnitGroupRolesAssigned) == "function" and UnitGroupRolesAssigned(unit) or "NONE"
                local className, classFileName
                if type(UnitClass) == "function" then className, classFileName = UnitClass(unit) end
                result[#result + 1] = {
                    name = name,
                    subgroup = 1,
                    role = type(role) == "string" and role or "NONE",
                    className = className,
                    classFileName = classFileName,
                    raidIndex = index,
                }
            end
        end
    end

    table.sort(result, function(a, b)
        if a.subgroup ~= b.subgroup then return a.subgroup < b.subgroup end
        local ar = ROLE_ORDER[a.role] or 9
        local br = ROLE_ORDER[b.role] or 9
        if ar ~= br then return ar < br end
        return a.name < b.name
    end)
    return result
end

function RosterService:GetGroupMembers(subgroup)
    local result = {}
    subgroup = tonumber(subgroup)
    if not subgroup then return result end
    local roster = self:GetRoster()
    for index = 1, #roster do
        if roster[index].subgroup == subgroup then result[#result + 1] = roster[index].name end
    end
    return result
end

ns:RegisterModule("Services.RosterService", RosterService)
