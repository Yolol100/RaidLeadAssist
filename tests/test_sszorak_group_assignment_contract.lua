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
    assert(#definitions == 2, "Sszorak must expose exactly two Mutilate soak teams")
    assert(definitions[1].key == "mutilate_group_1" and definitions[1].rotation == "mutilate_teams")
    assert(definitions[2].key == "mutilate_group_2" and definitions[2].rotation == "mutilate_teams")
    assert(definitions[1].kind == "rotation" and definitions[2].kind == "rotation", "Sszorak soak settings must use valid roster rotations")
    assert(definitions[1].label == "Soak Team A" and definitions[1].callLabel == "TEAM A")
    assert(definitions[2].label == "Soak Team B" and definitions[2].callLabel == "TEAM B")
    assert(definitions[1].minPlayers == 5 and definitions[2].minPlayers == 5, "each Mutilate team must enforce 5+ players")
    assert(definitions[1].exclusiveGroup == "mutilate" and definitions[2].exclusiveGroup == "mutilate", "Mutilate teams must not overlap")
end

local ok, values = Assignments:ApplyBossDraft("sszorak", "heroic", {
    mutilate_group_1 = "Alpha, Bravo, Charlie, Delta, Echo",
    mutilate_group_2 = "Foxtrot, Golf, Hotel, India, Juliet",
})
assert(ok, values and values.message)

local base = "GREEN MUTILATE > NEXT 5+ SOAK TEAM"
local first = Assignments:BuildCallWarning(base, "sszorak", "heroic", "apex")
assert(first:find("TEAM A: Alpha, Bravo, Charlie, Delta, Echo", 1, true), "first Mutilate call must use Team A")
Assignments:AdvanceCall("sszorak", "heroic", "apex")

local second = Assignments:BuildCallWarning(base, "sszorak", "heroic", "apex")
assert(second:find("TEAM B: Foxtrot, Golf, Hotel, India, Juliet", 1, true), "second Mutilate call must use Team B")
Assignments:AdvanceCall("sszorak", "heroic", "apex")

local third = Assignments:BuildCallWarning(base, "sszorak", "heroic", "apex")
assert(third:find("TEAM A: Alpha, Bravo, Charlie, Delta, Echo", 1, true), "Mutilate team rotation must loop back to Team A")

Assignments:ResetRuntime()
local reset = Assignments:BuildCallWarning(base, "sszorak", "heroic", "apex")
assert(reset:find("TEAM A: Alpha, Bravo, Charlie, Delta, Echo", 1, true), "Mutilate rotation must reset to Team A between pulls")

print("ok - Sszorak Mutilate rotates two distinct validated 5+ roster teams")
