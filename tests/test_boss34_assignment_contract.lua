local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss34AssignmentOverride.lua", ns)

local Assignments = ns:GetModule("Encounters.AssignmentRegistry")

local explorerNormal = Assignments:GetDefinitions("explorers", "normal")
assert(#explorerNormal == 2)
assert(explorerNormal[1].key == "crate_a" and explorerNormal[1].callKey == "crates" and explorerNormal[1].required)
assert(explorerNormal[2].key == "fish_a" and explorerNormal[2].callKey == "fish" and explorerNormal[2].required)

for _, difficulty in ipairs({ "heroic", "mythic" }) do
    local defs = Assignments:GetDefinitions("explorers", difficulty)
    assert(#defs == 5, difficulty .. " explorers should expose three breaker slots and two fish-runner slots")
    for _, definition in ipairs(defs) do
        assert(definition.callKey == "crates" or definition.callKey == "fish")
        assert(definition.kind == "rotation")
        assert(not definition.key:find("thud", 1, true))
    end
end

assert(#Assignments:GetDefinitions("vashnik", "normal") == 0,
    "Normal Vashnik has no real pre-pull assignment after the route is fixed in the raid plan")
for _, difficulty in ipairs({ "heroic", "mythic" }) do
    local defs = Assignments:GetDefinitions("vashnik", difficulty)
    assert(#defs == 1, difficulty .. " Vashnik should expose only Catalytic Bile coverage")
    assert(defs[1].key == "bile_team" and defs[1].callKey == "catalyst" and defs[1].required)
    local layout = Assignments:GetLayout("vashnik", difficulty)
    assert(not layout.summary:find("Fountain Sequence", 1, true))
    assert(not layout.summary:find("Tumor lane", 1, true))
end

print("ok - boss 3/4 settings keep only operational ownership and remove fixed-strategy fields")
