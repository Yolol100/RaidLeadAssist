local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/VenomousAbyss/Explorers.lua", ns)

local Registry = ns:GetModule("Encounters.Registry")
local Assignments = ns:GetModule("Encounters.AssignmentRegistry")

local normal = Registry:GetProfile("explorers", "normal")
local heroic = Registry:GetProfile("explorers", "heroic")
local mythic = Registry:GetProfile("explorers", "mythic")

local function plan(profile)
    return table.concat(profile.explanation, "\n")
end

assert(plan(normal):find("STACK IKU + NAMA + GEBBO", 1, true), "Normal should explicitly allow stacking all three")
assert(plan(heroic):find("STACK IKU + GEBBO", 1, true) and plan(heroic):find("NAMA 30+ YARDS AWAY", 1, true), "Heroic should keep Nama away from stacked Iku + Gebbo")
assert(plan(mythic):find("STACK IKU + GEBBO", 1, true) and plan(mythic):find("NAMA 30+ YARDS AWAY", 1, true), "Mythic should keep Nama away from stacked Iku + Gebbo")

for _, profile in ipairs({ normal, heroic, mythic }) do
    assert(profile.callsByKey.tankswap == nil and profile.callsByKey.tank == nil, "Tank calls stay DBM-owned")
    assert(profile.callsByKey.crates.spellIDs[1] == 1291933, "Crate call must bind Throw Junk")
    assert(profile.callsByKey.fish.spellIDs[1] == 1292779, "Fish call must bind Final Ascension")
    assert(profile.callsByKey.shell.spellIDs[1] == 1291759, "Shell Spin needs a timed dodge call")
    assert(profile.callsByKey.volley.spellIDs[1] == 1295886 and profile.callsByKey.volley.spellIDs[2] == 1295935, "Frostfire Volley must accept BigWigs/DBM identities")
    assert(profile.callsByKey.bomb.spellIDs[1] == 1296249, "Explosive Surprise needs a timed move-out call")
end

assert(normal.callsByKey.position == nil, "Normal has no United Defense positioning restriction")
assert(heroic.callsByKey.position.warning == "STACK IKU + GEBBO > NAMA 30+ YARDS AWAY")
assert(mythic.callsByKey.position.warning == "STACK IKU + GEBBO > NAMA 30+ YARDS AWAY")
assert(mythic.callsByKey.crates.warning == "CRATE > BREAKER IN > RAID 15+ YARDS OUT")
assert(plan(mythic):find("RAID CLEARS 15+ YARDS", 1, true), "Mythic crate plan must describe the local 15-yard rupture")

local mythicLayout = Assignments:GetLayout("explorers", "mythic")
assert(mythicLayout.summary:find("15+ yards", 1, true), "Mythic settings must match the local crate-break rule")
assert(mythicLayout.summary:find("breaks hit the raid", 1, true) == nil, "Mythic settings must not claim the crate stomp is raidwide")

print("ok - Lost Explorers positioning, raidlead calls, timers and Mythic crate settings")
