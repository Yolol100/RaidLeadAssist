local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/VenomousAbyss/Vashnik.lua", ns)

local Registry = ns:GetModule("Encounters.Registry")

for _, difficulty in ipairs({ "normal", "heroic", "mythic" }) do
    local profile = Registry:GetProfile("vashnik", difficulty)
    assert(profile.callsByKey.tankswap == nil, difficulty .. " Vashnik tank calls are DBM-owned and must not appear in RaidLeadAssist")
    assert(profile.callsByKey.infection, difficulty .. " Vashnik needs an Adaptive Infection pre-call")
    assert(profile.callsByKey.infection.spellIDs[1] == 1282114)
    assert(profile.callsByKey.infection.spellIDs[2] == 1282117)
    local plan = table.concat(profile.explanation, "\n")
    assert(not plan:find("TANK", 1, true), difficulty .. " Vashnik raidplan must stay tank-call free")
end

assert(Registry:GetProfile("vashnik", "normal").callsByKey.fire_stagger.warning == "KILL FIRE ADDS",
    "Normal must not force the Heroic Caustic Surge stagger rule")
assert(Registry:GetProfile("vashnik", "heroic").callsByKey.fire_stagger.warning == "SKULL FIRST > WAIT > X")
assert(Registry:GetProfile("vashnik", "mythic").callsByKey.fire_stagger.warning == "SKULL FIRST > WAIT > X")
assert(Registry:GetProfile("vashnik", "normal").callsByKey.catalyst == nil,
    "Malignant Catalyst is Heroic/Mythic only")
assert(Registry:GetProfile("vashnik", "heroic").callsByKey.catalyst)
assert(Registry:GetProfile("vashnik", "mythic").callsByKey.tumors)

assert(Registry:MatchCall("vashnik", "normal", 1282114, nil).key == "infection")
assert(Registry:MatchCall("vashnik", "normal", 1282117, nil).key == "infection")

print("ok - Vashnik DBM-owned tank boundary, infection and difficulty-specific fire/catalyst contracts")
