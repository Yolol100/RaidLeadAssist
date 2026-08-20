local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local SECRET = {}

_G.issecretvalue = function(value) return value == SECRET end

T.Load("Core/Util.lua", ns)

local definitions = {
    { key = "direct", label = "Direct", kind = "assignee" },
    { key = "rotation", label = "Rotation", kind = "rotation" },
    { key = "group", label = "Group duty", kind = "assignee" },
    { key = "other", label = "Other", kind = "assignee" },
    { key = "rule", label = "Rule", kind = "rule" },
}
local values = {
    direct = "Player-Realm, Other-Realm",
    rotation = "player, Third",
    group = "Groups 2+4",
    other = "SomeoneElse",
    rule = "Player do a generic rule",
}

ns:RegisterModule("Services.AssignmentService", {
    GetDefinitions = function() return definitions end,
    GetValue = function(_, _, _, key) return values[key] or "" end,
})
ns:RegisterModule("Services.RosterService", {
    GetRoster = function()
        return {
            { name = "Player-Realm", subgroup = 4 },
            { name = "Other-Realm", subgroup = 1 },
        }
    end,
})

T.Load("Services/PersonalAssignmentService.lua", ns)
local Personal = ns:GetModule("Services.PersonalAssignmentService")

local lines = Personal:GetLines("sentinels", "heroic", "Player-Realm", 4)
assert(#lines == 3, "direct, rotation and matching group assignments should be included")
assert(lines[1].key == "direct" and lines[2].key == "rotation" and lines[3].key == "group")

local shortLines = Personal:GetLines("sentinels", "heroic", "Player", 4)
assert(#shortLines == 3, "short and realm-qualified player names should match deterministically")

local wrongGroup = Personal:GetLines("sentinels", "heroic", "Player-Realm", 3)
assert(#wrongGroup == 2, "an unrelated raid subgroup must not inherit a group assignment")

local noPlayer = Personal:GetLines("sentinels", "heroic", nil, 4)
assert(#noPlayer == 0, "missing player identity must fail closed")
local secretPlayer = Personal:GetLines("sentinels", "heroic", SECRET, 4)
assert(#secretPlayer == 0, "secret player identity must fail closed")

_G.UnitName = function(unit)
    assert(unit == "player")
    return "Player-Realm"
end
local playerName, subgroup = Personal:ResolvePlayer()
assert(playerName == "Player-Realm" and subgroup == 4, "local player subgroup should resolve from the current roster")

-- Excessive matching definitions must remain bounded in output.
definitions = {}
values = {}
for index = 1, 20 do
    definitions[index] = { key = "slot" .. index, label = "Slot " .. index, kind = "assignee" }
    values["slot" .. index] = "Player"
end
local bounded = Personal:GetLines("sentinels", "heroic", "Player", 4)
assert(#bounded == Personal.MAX_LINES, "personal assignment output must remain bounded")

_G.UnitName = nil
_G.issecretvalue = nil
print("ok - personal assignments are local, scoped, bounded and fail closed")
