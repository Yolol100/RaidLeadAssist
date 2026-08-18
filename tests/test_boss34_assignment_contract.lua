local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss34AssignmentOverride.lua", ns)
local Assignments = ns:GetModule("Encounters.AssignmentRegistry")
assert(#Assignments:GetDefinitions("explorers","normal") == 2)
for _, difficulty in ipairs({"heroic","mythic"}) do assert(#Assignments:GetDefinitions("explorers",difficulty) == 5) end
for _, difficulty in ipairs({"normal","heroic","mythic"}) do
    local defs = Assignments:GetDefinitions("vashnik", difficulty)
    assert(#defs == 0, difficulty .. " Vashnik must expose no fixed roster assignment")
    assert(#Assignments:GetLayout("vashnik", difficulty).sections == 0)
end
print("ok - boss 3/4 assignments keep Explorers ownership while Vashnik has no fixed pre-pull roster")
