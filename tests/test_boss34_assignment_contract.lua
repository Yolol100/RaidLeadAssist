local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss34AssignmentOverride.lua", ns)
local Assignments = ns:GetModule("Encounters.AssignmentRegistry")

assert(#Assignments:GetDefinitions("explorers", "normal") == 0,
    "Normal Lost Explorers needs no fixed crate roster")
assert(#Assignments:GetDefinitions("explorers", "heroic") == 0,
    "Heroic Lost Explorers still needs no fixed crate roster")
local mythic = Assignments:GetDefinitions("explorers", "mythic")
assert(#mythic == 3, "Mythic Lost Explorers needs only the controlled crate rotation")
for _, definition in ipairs(mythic) do
    assert(definition.callKey == "crates")
    assert(not definition.key:find("fish", 1, true))
end
for _, difficulty in ipairs({"normal","heroic","mythic"}) do
    local defs = Assignments:GetDefinitions("vashnik", difficulty)
    assert(#defs == 0, difficulty .. " Vashnik must expose no fixed roster assignment")
    assert(#Assignments:GetLayout("vashnik", difficulty).sections == 0)
end
print("ok - boss 3/4 configure only true difficulty-specific roster choices")
