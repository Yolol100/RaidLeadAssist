local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss12AssignmentOverride.lua", ns)

local Registry = ns:GetModule("Encounters.AssignmentRegistry")

local normal = Registry:GetLayout("nekzali", "normal")
local heroic = Registry:GetLayout("nekzali", "heroic")
local mythic = Registry:GetLayout("nekzali", "mythic")

assert(#normal.sections == 0, "Normal Nek'zali uses fixed role responsibilities and needs no editable assignment")
assert(#heroic.sections == 0, "Heroic Nek'zali Cremation is a fixed ranged responsibility, not an editable assignment")
assert(#mythic.sections == 1 and mythic.sections[1].key == "well",
    "Mythic Nek'zali should expose only the fresh Grasping Depths well-group rotation")

local definitions = Registry:GetDefinitions("nekzali", "mythic")
assert(#definitions == 2, "Mythic Nek'zali needs exactly two alternating well-group fields")
assert(definitions[1].key == "well_a" and definitions[1].label == "Well Group 1")
assert(definitions[2].key == "well_b" and definitions[2].label == "Well Group 2")
for _, definition in ipairs(definitions) do
    assert(definition.kind == "rotation", "well groups must rotate after successful Grasping calls")
    assert(definition.rotation == "well", "both Mythic well groups must share one rotation")
    assert(definition.callKey == "grasping", "well settings must append to the Grasping raidleader call")
    assert(definition.required == true, "both fresh well groups are required before Mythic progression")
end

print("ok - Nek'zali settings keep only the genuine Mythic well-group coordination")
