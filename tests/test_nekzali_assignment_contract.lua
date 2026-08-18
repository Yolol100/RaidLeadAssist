local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

T.Load("Encounters/AssignmentRegistry.lua", ns)

local Registry = ns:GetModule("Encounters.AssignmentRegistry")

local normal = Registry:GetLayout("nekzali", "normal")
local heroic = Registry:GetLayout("nekzali", "heroic")
local mythic = Registry:GetLayout("nekzali", "mythic")

assert(#normal.sections == 0, "Normal Nek'zali uses role-based melee/ranged calls and should not require a fixed soak roster")
assert(#heroic.sections == 1 and heroic.sections[1].key == "cremation", "Heroic Nek'zali should only configure static Cremation movement rules")
assert(#mythic.sections == 3, "Mythic Nek'zali should keep Pyre, Well and Cremation planning")

local mythicDefinitions = Registry:GetDefinitions("nekzali", "mythic")
local pyre
for _, definition in ipairs(mythicDefinitions) do
    if definition.key == "pyre_soak" then pyre = definition end
end
assert(pyre, "Mythic Nek'zali needs the configured Pyre soak team")
assert(pyre.label == "Groups 1+2 Soak Team", "Mythic Pyre settings must match the Groups 1+2 raid tactic")
assert(pyre.required == true and pyre.callKey == "pyre", "Mythic Pyre assignment must remain required and bound to the Pyre call")

print("ok - Nek'zali assignment settings match Normal/Heroic/Mythic raid tactics")
