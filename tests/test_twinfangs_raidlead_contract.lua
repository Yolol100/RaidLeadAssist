local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/TwinFangsAssignmentOverride.lua", ns)
T.Load("Services/AssignmentService.lua", ns)
T.Load("Encounters/VenomousAbyss/TwinFangs.lua", ns)

local Registry = ns:GetModule("Encounters.Registry")
local AssignmentRegistry = ns:GetModule("Encounters.AssignmentRegistry")
local Assignments = ns:GetModule("Services.AssignmentService")
Assignments:Initialize({ assignments = {} })

local function contains(value, needle)
    return string.find(value, needle, 1, true) ~= nil
end

local function plan(difficulty)
    return table.concat(Registry:GetProfile("twinfangs", difficulty).explanation, "\n")
end

for _, difficulty in ipairs({ "normal", "heroic", "mythic" }) do
    local profile = Registry:GetProfile("twinfangs", difficulty)
    assert(profile.callsByKey.balance == nil, "health balance must stay in the plan")
    assert(profile.callsByKey.stone == nil, "Stone Breaker live execution stays bossmod/role-owned")
    assert(profile.callsByKey.globules.warning == "GREEN ORBS > SOAK BEFORE RUPTURE")
    assert(profile.callsByKey.adds.warning == "KILL ADDS")
    assert(profile.callsByKey.feast.warning == "FEAST > TEAM A > TEAM B > TEAM C")
    assert(profile.callsByKey.energy.warning == "100 ENERGY > MOVE TO ITHRAZ > DODGE FLOOD/STORM")
    assert(profile.callsByKey.globules.prepareSeconds == 7 and profile.callsByKey.globules.pressSeconds == 4)
    assert(profile.callsByKey.adds.prepareSeconds == 6 and profile.callsByKey.adds.pressSeconds == 3)
    assert(profile.callsByKey.feast.prepareSeconds == 8 and profile.callsByKey.feast.pressSeconds == 5)
    assert(profile.callsByKey.energy.prepareSeconds == 8 and profile.callsByKey.energy.pressSeconds == 5)
    assert(#profile.callsByKey.energy.spellIDs == 1 and profile.callsByKey.energy.spellIDs[1] == 1306872,
        "100-energy call must use one Sanguine Storm anchor so simultaneous boss bars cannot double-arm it")
    assert(#profile.callsByKey.energy.timerNames == 1 and profile.callsByKey.energy.timerNames[1] == "Sanguine Storm")
    assert(contains(plan(difficulty), "FINISH TOGETHER"))
    assert(contains(plan(difficulty), "THREE FRESH 3+ TEAMS"))
    assert(contains(plan(difficulty), "TEAM A > TEAM B > TEAM C"))
    assert(contains(plan(difficulty), "AT LEAST ONE PLAYER MUST BE HIT BY EACH SLAM"))
    assert(contains(plan(difficulty), "FOLLOW DBM OR BIGWIGS"))
    assert(not contains(plan(difficulty), "GROUPS 5+6"), "flex-safe Feast plans must never require nonexistent fixed raid groups")

    local definitions = AssignmentRegistry:GetDefinitions("twinfangs", difficulty)
    assert(#definitions >= 3)
    assert(definitions[1].key == "feast_team_a" and definitions[1].label == "Hit 1 · Team A")
    assert(definitions[2].key == "feast_team_b" and definitions[2].label == "Hit 2 · Team B")
    assert(definitions[3].key == "feast_team_c" and definitions[3].label == "Hit 3 · Team C")
    for index = 1, 3 do
        local definition = definitions[index]
        assert(definition.kind == "assignee", "Feast teams must be real roster assignments")
        assert(definition.callKey == "feast")
        assert(definition.minPlayers == 3, "each Feast hit must enforce at least three players")
        assert(definition.exclusiveGroup == "feast", "Feast teams must be mutually exclusive within a cast")
        assert(definition.required == true)
    end
end

local ok, values = Assignments:ApplyBossDraft("twinfangs", "heroic", {
    feast_team_a = "Alpha, Bravo, Charlie",
    feast_team_b = "Delta, Echo, Foxtrot",
    feast_team_c = "Golf, Hotel, India",
})
assert(ok, values and values.message)
local feastWarning = Assignments:BuildCallWarning("FEAST > TEAM A > TEAM B > TEAM C", "twinfangs", "heroic", "feast")
assert(contains(feastWarning, "TEAM A: Alpha, Bravo, Charlie"))
assert(contains(feastWarning, "TEAM B: Delta, Echo, Foxtrot"))
assert(contains(feastWarning, "TEAM C: Golf, Hotel, India"))

local overlapOk = Assignments:ApplyBossDraft("twinfangs", "heroic", {
    feast_team_a = "Alpha, Bravo, Charlie",
    feast_team_b = "Alpha, Echo, Foxtrot",
    feast_team_c = "Golf, Hotel, India",
})
assert(overlapOk == false, "the same player must not be accepted in two fresh Feast teams")

local mythic = Registry:GetProfile("twinfangs", "mythic")
assert(mythic.callsByKey.tainted.warning == "TAINTED BLOOD > FOUNTS > HEAL OUT")
assert(mythic.callsByKey.bulwark.warning == "BULWARKS > INTERRUPT")
assert(mythic.callsByKey.brood.warning == "BROODLINGS > INTERRUPT ALL")
assert(mythic.callsByKey.bulwark.spellIDs[1] == 1303230)
assert(mythic.callsByKey.brood.spellIDs[1] == 1308356)

print("ok - Twin Fangs fresh Feast teams, shared raid calls, bossmod ownership and timer identities stay aligned")
