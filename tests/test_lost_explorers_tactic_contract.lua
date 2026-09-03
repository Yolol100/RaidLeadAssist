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
local encounter = Registry:Get("explorers")

local function plan(profile)
    return table.concat(profile.explanation, "\n")
end

assert(encounter and encounter.encounterID == 3497, "Lost Explorers encounter identity must stay DBM-compatible")
assert(Registry:FindByEncounterID(3497) == encounter, "Lost Explorers encounter-ID lookup must resolve the same registry entry")
assert(encounter.strategyStatus:find("DBM/BigWigs source-reviewed 2026-09-03", 1, true), "current provider review date missing")
assert(encounter.strategyStatus:find("DBM Mythic timer routing reviewed", 1, true), "Mythic DBM routing review must remain explicit")
assert(plan(normal):find("Keep all three bosses even", 1, true))
assert(plan(normal):find("Crates appear: break them until a fish appears", 1, true))
assert(plan(normal):find("Fish order: Nama, then Iku, then Gebbo", 1, true))
assert(plan(heroic):find("Keep Nama away", 1, true) and plan(heroic):find("Iku and Gebbo together", 1, true))
assert(not plan(mythic):find("Keep Nama away", 1, true), "Mythic should not repeat Heroic positioning")

for _, profile in ipairs({ normal, heroic, mythic }) do
    assert(profile.callsByKey.crates and profile.callsByKey.fish and profile.callsByKey.thud)
    assert(profile.callsByKey.crates.spellIDs[1] == 1291933, "Throw Junk timer identity drifted")
    assert(profile.callsByKey.fish.spellIDs[1] == 1292779, "Final Ascension timer identity drifted")
    assert(profile.callsByKey.thud.spellIDs[1] == 1296092, "Mighty Thud timer identity drifted")
    assert(profile.callsByKey.fish.warning == "Fish: Nama, then Iku, then Gebbo.")
    assert(profile.callsByKey.shell == nil and profile.callsByKey.blink == nil)
    assert(profile.callsByKey.volley == nil and profile.callsByKey.bomb == nil)
    assert(profile.callsByKey.position == nil and profile.callsByKey.icebound == nil)
    assert(profile.callsByKey.tankswap == nil and profile.callsByKey.tank == nil)
end
assert(normal.callsByKey.crates.warning == "Crates: open them until fish appears.")
assert(heroic.callsByKey.crates.warning == "Crates: open them until fish appears.")
assert(mythic.callsByKey.crates.warning == "Crate: clear 15+ yards, then break.")
assert(plan(mythic):find("15+ yards away", 1, true))

assert(#Assignments:GetDefinitions("explorers", "normal") == 0,
    "Normal settings need no fixed crate owner")
assert(#Assignments:GetDefinitions("explorers", "heroic") == 0,
    "Heroic settings need no fixed crate owner")
local mythicDefs = Assignments:GetDefinitions("explorers", "mythic")
assert(#mythicDefs == 3, "Mythic should contain only the controlled breaker rotation")
for _, definition in ipairs(mythicDefs) do
    assert(not definition.key:find("thud", 1, true), "Thud points are fixed setup markers, not roster assignments")
    assert(not definition.key:find("fish", 1, true), "Fish order is fixed strategy, not roster ownership")
    assert(definition.kind == "rotation" and definition.callKey == "crates")
end

print("ok - Lost Explorers fixed strategy, difficulty deltas, current DBM identities and assignments stay separated")
