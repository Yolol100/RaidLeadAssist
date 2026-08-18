local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/SszorakAssignmentOverride.lua", ns)
T.Load("Services/AssignmentService.lua", ns)

local Registry = ns:GetModule("Encounters.AssignmentRegistry")
local Assignments = ns:GetModule("Services.AssignmentService")
local db = { assignments = {} }
Assignments:Initialize(db)

for _, difficulty in ipairs({ "normal", "heroic", "mythic" }) do
    local definitions = Registry:GetDefinitions("sszorak", difficulty)
    assert(#definitions == 2, "Sszorak must expose exactly two raid-group soak assignments")
    assert(definitions[1].key == "mutilate_group_1" and definitions[1].rotation == "mutilate_groups")
    assert(definitions[2].key == "mutilate_group_2" and definitions[2].rotation == "mutilate_groups")
    assert(definitions[1].kind == "rule" and definitions[2].kind == "rule", "Sszorak soak settings must be group-text fields, not player pickers")
    assert(definitions[1].minPlayers == nil and definitions[2].minPlayers == nil, "group settings must not require individual player names")
end

local ok, values = Assignments:ApplyBossDraft("sszorak", "heroic", {
    mutilate_group_1 = "Groups 1+2",
    mutilate_group_2 = "Groups 3+4",
})
assert(ok, values and values.message)

local base = "GREEN MUTILATE > 5+ SOAK GROUP"
local first = Assignments:BuildCallWarning(base, "sszorak", "heroic", "apex")
assert(first:find("GROUP 1: Groups 1+2", 1, true), "first Mutilate call must use configured Soak Group 1")
Assignments:AdvanceCall("sszorak", "heroic", "apex")

local second = Assignments:BuildCallWarning(base, "sszorak", "heroic", "apex")
assert(second:find("GROUP 2: Groups 3+4", 1, true), "second Mutilate call must use configured Soak Group 2")
Assignments:AdvanceCall("sszorak", "heroic", "apex")

local third = Assignments:BuildCallWarning(base, "sszorak", "heroic", "apex")
assert(third:find("GROUP 1: Groups 1+2", 1, true), "Mutilate group rotation must loop back to Group 1")

Assignments:ResetRuntime()
local reset = Assignments:BuildCallWarning(base, "sszorak", "heroic", "apex")
assert(reset:find("GROUP 1: Groups 1+2", 1, true), "Mutilate rotation must reset to Group 1 between pulls")

print("ok - Sszorak Mutilate uses two group-level text assignments and rotates Group 1 > Group 2")
