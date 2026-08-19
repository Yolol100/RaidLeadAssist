local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss34AssignmentOverride.lua", ns)
T.Load("Encounters/VenomousAbyss/Explorers.lua", ns)

local Registry = ns:GetModule("Encounters.Registry")
local Assignments = ns:GetModule("Encounters.AssignmentRegistry")

local normal = Registry:GetProfile("explorers", "normal")
local heroic = Registry:GetProfile("explorers", "heroic")
local mythic = Registry:GetProfile("explorers", "mythic")

local function plan(profile)
    return table.concat(profile.explanation, "\n")
end

assert(plan(normal):find("Keep all three bosses even", 1, true))
assert(plan(normal):find("Fish order: Nama, then Iku, then Gebbo", 1, true))
assert(plan(heroic):find("Keep Nama away", 1, true) and plan(heroic):find("Iku and Gebbo together", 1, true))
assert(not plan(mythic):find("Keep Nama away", 1, true), "Mythic should not repeat Heroic positioning")

for _, profile in ipairs({ normal, heroic, mythic }) do
    assert(profile.callsByKey.crates and profile.callsByKey.fish and profile.callsByKey.thud)
    assert(profile.callsByKey.fish.warning == "Fish: Nama, then Iku, then Gebbo.")
    assert(profile.callsByKey.shell == nil and profile.callsByKey.blink == nil)
    assert(profile.callsByKey.volley == nil and profile.callsByKey.bomb == nil)
    assert(profile.callsByKey.position == nil and profile.callsByKey.icebound == nil)
    assert(profile.callsByKey.tankswap == nil and profile.callsByKey.tank == nil)
end

assert(mythic.callsByKey.crates.warning == "Crate: clear 15+ yards, then break.")
assert(plan(mythic):find("15+ yards away", 1, true))

local normalDefs = Assignments:GetDefinitions("explorers", "normal")
assert(#normalDefs == 1, "Normal settings should contain only crate ownership")
assert(normalDefs[1].key == "crate_a" and normalDefs[1].callKey == "crates")

for _, difficulty in ipairs({ "heroic", "mythic" }) do
    local defs = Assignments:GetDefinitions("explorers", difficulty)
    assert(#defs == 3, difficulty .. " should contain only the breaker rotation")
    for _, definition in ipairs(defs) do
        assert(not definition.key:find("thud", 1, true), "Thud points are fixed setup markers, not roster assignments")
        assert(not definition.key:find("fish", 1, true), "Fish order is fixed strategy, not roster ownership")
        assert(definition.kind == "rotation" and definition.callKey == "crates")
    end
end

print("ok - Lost Explorers fixed strategy, difficulty deltas and assignments stay separated")
