local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss12AssignmentOverride.lua", ns)

local Registry = ns:GetModule("Encounters.AssignmentRegistry")

local normal = Registry:GetLayout("nekzali", "normal")
local heroic = Registry:GetLayout("nekzali", "heroic")
local mythic = Registry:GetLayout("nekzali", "mythic")

assert(#normal.sections == 0, "Normal Nek'zali uses fixed melee/ranged responsibilities")
assert(#heroic.sections == 1 and heroic.sections[1].key == "pyre",
    "Heroic Nek'zali needs only the Pyre soak group")
assert(#mythic.sections == 2 and mythic.sections[1].key == "pyre" and mythic.sections[2].key == "well",
    "Mythic Nek'zali adds the fresh well-group rotation")

local heroicDefinitions = Registry:GetDefinitions("nekzali", "heroic")
assert(#heroicDefinitions == 1)
assert(heroicDefinitions[1].key == "pyre_soakers")
assert(heroicDefinitions[1].kind == "assignee" and heroicDefinitions[1].compactGroups)
assert(heroicDefinitions[1].callKey == "pyre" and heroicDefinitions[1].required)

local definitions = Registry:GetDefinitions("nekzali", "mythic")
assert(#definitions == 3, "Mythic Nek'zali needs Pyre plus two fresh well groups")
assert(definitions[2].key == "well_a" and definitions[2].label == "Well Group 1")
assert(definitions[3].key == "well_b" and definitions[3].label == "Well Group 2")
for index = 2, 3 do
    local definition = definitions[index]
    assert(definition.kind == "rotation", "well groups must rotate after successful Grasping calls")
    assert(definition.rotation == "well", "both Mythic well groups must share one rotation")
    assert(definition.callKey == "grasping", "well settings must drive the Grasping raidleader call")
    assert(definition.required == true and definition.compactGroups,
        "both fresh well groups are required and roster-group aware")
end

print("ok - Nek'zali configures only difficulty-specific raidleader choices")
