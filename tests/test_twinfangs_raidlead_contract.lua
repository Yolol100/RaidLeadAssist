local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/TwinFangsAssignmentOverride.lua", ns)
T.Load("Encounters/VenomousAbyss/TwinFangs.lua", ns)

local Registry = ns:GetModule("Encounters.Registry")
local Assignments = ns:GetModule("Encounters.AssignmentRegistry")

local function contains(value, needle)
    return string.find(value, needle, 1, true) ~= nil
end

local function plan(difficulty)
    return table.concat(Registry:GetProfile("twinfangs", difficulty).explanation, "\n")
end

for _, difficulty in ipairs({ "normal", "heroic", "mythic" }) do
    local profile = Registry:GetProfile("twinfangs", difficulty)
    assert(profile.callsByKey.balance == nil, "health balance must stay in the plan")
    assert(profile.callsByKey.stone == nil, "Stone Breaker is DBM-owned")
    assert(profile.callsByKey.globules.warning == "GREEN ORBS > SOAK BEFORE RUPTURE")
    assert(profile.callsByKey.adds.warning == "KILL ADDS")
    assert(profile.callsByKey.energy.warning == "100 ENERGY > MOVE TO ITHRAZ")
    assert(profile.callsByKey.globules.prepareSeconds == 7 and profile.callsByKey.globules.pressSeconds == 4)
    assert(profile.callsByKey.adds.prepareSeconds == 6 and profile.callsByKey.adds.pressSeconds == 3)
    assert(profile.callsByKey.feast.prepareSeconds == 8 and profile.callsByKey.feast.pressSeconds == 5)
    assert(profile.callsByKey.energy.prepareSeconds == 8 and profile.callsByKey.energy.pressSeconds == 5)
    assert(contains(plan(difficulty), "FINISH TOGETHER"))
    assert(contains(plan(difficulty), "STONE BREAKER IS DBM-OWNED"))
end

for _, difficulty in ipairs({ "normal", "heroic" }) do
    local profile = Registry:GetProfile("twinfangs", difficulty)
    assert(profile.callsByKey.feast.warning == "FEAST > GROUPS 1+2 > 3+4 > 5+6")
    local definitions = Assignments:GetDefinitions("twinfangs", difficulty)
    assert(#definitions == 3, "Normal/Heroic Feast settings must have exactly three group columns")
    assert(definitions[1].label == "Hit 1 · Groups 1+2")
    assert(definitions[2].label == "Hit 2 · Groups 3+4")
    assert(definitions[3].label == "Hit 3 · Groups 5+6")
    for _, definition in ipairs(definitions) do
        assert(definition.kind == "rule", "Feast settings must be group-level text, not player pickers")
        assert(definition.minPlayers == nil and definition.exactPlayers == nil)
    end
end

local mythic = Registry:GetProfile("twinfangs", "mythic")
assert(mythic.callsByKey.feast.warning == "FEAST > GROUP 1 > GROUP 2 > GROUPS 3+4")
assert(not contains(plan("mythic"), "GROUPS 5+6"), "20-player Mythic must never reference nonexistent raid Groups 5+6")
assert(mythic.callsByKey.tainted.warning == "TAINTED BLOOD > FOUNTS > HEAL OUT")
assert(mythic.callsByKey.bulwark.warning == "BULWARKS > INTERRUPT")
assert(mythic.callsByKey.brood.warning == "BROODLINGS > INTERRUPT ALL")
assert(mythic.callsByKey.bulwark.spellIDs[1] == 1303230)
assert(mythic.callsByKey.brood.spellIDs[1] == 1308356)

local mythicDefinitions = Assignments:GetDefinitions("twinfangs", "mythic")
assert(mythicDefinitions[1].label == "Hit 1 · Group 1")
assert(mythicDefinitions[2].label == "Hit 2 · Group 2")
assert(mythicDefinitions[3].label == "Hit 3 · Groups 3+4")

print("ok - Twin Fangs difficulty plans, raid-group Feast setup, DBM ownership and timers stay aligned")
