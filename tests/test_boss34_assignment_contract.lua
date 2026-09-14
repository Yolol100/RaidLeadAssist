local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss34AssignmentOverride.lua", ns)
local Assignments = ns:GetModule("Encounters.AssignmentRegistry")

assert(#Assignments:GetDefinitions("explorers", "normal") == 0, "Normal assignments must be inactive")
assert(#Assignments:GetDefinitions("explorers", "heroic") == 0,
    "Heroic Lost Explorers uses a fixed raid-lead sequence, not a roster assignment")
local mythic = Assignments:GetDefinitions("explorers", "mythic")
assert(#mythic == 3, "Mythic Lost Explorers keeps the controlled crate-breaker rotation")
for _, definition in ipairs(mythic) do
    assert(definition.callKey == "crates" and definition.kind == "rotation")
end
assert(#Assignments:GetDefinitions("vashnik", "heroic") == 0)
assert(#Assignments:GetDefinitions("vashnik", "mythic") == 0)
assert(#Assignments:GetDefinitions("vashnik", "normal") == 0)
print("ok - boss 3/4 assignments expose only Heroic/Mythic choices that are actually required")
