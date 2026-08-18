local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss12AssignmentOverride.lua", ns)

local Registry = ns:GetModule("Encounters.AssignmentRegistry")

local normal = Registry:GetLayout("nekzali", "normal")
local heroic = Registry:GetLayout("nekzali", "heroic")
local mythic = Registry:GetLayout("nekzali", "mythic")

assert(#normal.sections == 0, "Normal Nek'zali uses fixed melee/ranged responsibilities")
assert(#heroic.sections == 1 and heroic.sections[1].key == "pyre_roles",
    "Heroic Nek'zali exposes Pyre/Cremation raidleader prep")
assert(#mythic.sections == 2 and mythic.sections[1].key == "pyre_roles" and mythic.sections[2].key == "well",
    "Mythic Nek'zali adds the fresh well-group rotation to Heroic prep")

local heroicDefinitions = Registry:GetDefinitions("nekzali", "heroic")
assert(#heroicDefinitions == 2)
assert(heroicDefinitions[1].key == "pyre_soakers" and heroicDefinitions[1].kind == "rule")
assert(heroicDefinitions[2].key == "cremation_players" and heroicDefinitions[2].kind == "rule")

local definitions = Registry:GetDefinitions("nekzali", "mythic")
assert(#definitions == 4, "Mythic Nek'zali needs Pyre/Cremation prep plus two fresh well groups")
assert(definitions[3].key == "well_a" and definitions[3].label == "Well Group 1")
assert(definitions[4].key == "well_b" and definitions[4].label == "Well Group 2")
for index = 3, 4 do
    local definition = definitions[index]
    assert(definition.kind == "rotation", "well groups must rotate after successful Grasping calls")
    assert(definition.rotation == "well", "both Mythic well groups must share one rotation")
    assert(definition.callKey == "grasping", "well settings must append to the Grasping raidleader call")
    assert(definition.required == true, "both fresh well groups are required before Mythic progression")
end

print("ok - Nek'zali keeps player execution in Boss Plan and raidleader groups in prep")
