local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/SszorakAssignmentOverride.lua", ns)
local Registry = ns:GetModule("Encounters.AssignmentRegistry")

assert(#Registry:GetDefinitions("sszorak", "normal") == 0)
assert(#Registry:GetDefinitions("sszorak", "heroic") == 0,
    "Heroic BLUE/X teams are generated from populated raid subgroups")
local defs = Registry:GetDefinitions("sszorak", "mythic")
assert(#defs == 5, "Mythic Sszorak keeps two Mutilate teams plus three Cyst Poppers")
assert(defs[1].minPlayers == 5 and defs[2].minPlayers == 5)
for index = 3, 5 do
    assert(defs[index].key == "cyst_popper_" .. tostring(index - 2))
    assert(defs[index].callKey == "maelstrom" and defs[index].required)
end
print("ok - Sszorak Heroic uses dynamic BLUE/X split and Mythic retains explicit Mutilate/Cyst assignments")
