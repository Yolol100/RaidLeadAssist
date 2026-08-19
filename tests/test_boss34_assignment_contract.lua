local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss34AssignmentOverride.lua", ns)
local Assignments = ns:GetModule("Encounters.AssignmentRegistry")

local normal = Assignments:GetDefinitions("explorers", "normal")
assert(#normal == 1 and normal[1].key == "crate_a" and normal[1].callKey == "crates")
for _, difficulty in ipairs({"heroic","mythic"}) do
    local defs = Assignments:GetDefinitions("explorers", difficulty)
    assert(#defs == 3, difficulty .. " Lost Explorers needs only the crate rotation")
    for _, definition in ipairs(defs) do
        assert(definition.callKey == "crates")
        assert(not definition.key:find("fish", 1, true))
    end
end
for _, difficulty in ipairs({"normal","heroic","mythic"}) do
    local defs = Assignments:GetDefinitions("vashnik", difficulty)
    assert(#defs == 0, difficulty .. " Vashnik must expose no fixed roster assignment")
    assert(#Assignments:GetLayout("vashnik", difficulty).sections == 0)
end
print("ok - boss 3/4 configure only true roster choices")
