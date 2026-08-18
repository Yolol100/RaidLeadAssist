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
    local plan = table.concat(profile.explanation, "\n")

    assert(plan:find("BLOODLUST ON PULL", 1, true), difficulty .. " should preserve the pull-lust plan")
    assert(profile.callsByKey.imbibe and profile.callsByKey.imbibe.warning == "IMBIBE > KILL ADDS")
    assert(profile.callsByKey.imbibe.spellIDs[1] == 1283164)
    assert(profile.callsByKey.imbibe.prepareSeconds == 8 and profile.callsByKey.imbibe.pressSeconds == 5)
    assert(profile.callsByKey.siphon and profile.callsByKey.siphon.warning == "SIPHON > STACK HELPERS ON TARGET")

    assert(profile.callsByKey.tankswap == nil, "tank calls stay bossmod-owned")
    assert(profile.callsByKey.infection == nil, "Adaptive Infection needs bossmod per-type aura handling, not a generic RLA call")
    assert(profile.callsByKey.shadow_dodge == nil, "Shadow swirlies are personal bossmod execution")
    assert(profile.callsByKey.exploding == nil, "Exploding Infection is a personal bossmod run-out")
    assert(profile.callsByKey.stygian == nil, "Stygian Infection is a personal bossmod movement mechanic")
    assert(not plan:find("TANK", 1, true), difficulty .. " Vashnik raidplan must stay tank-call free")
end

local normal = Registry:GetProfile("vashnik", "normal")
local heroic = Registry:GetProfile("vashnik", "heroic")
local mythic = Registry:GetProfile("vashnik", "mythic")

assert(normal.callsByKey.fire_stagger == nil, "Normal does not need a second generic add-kill button")
assert(normal.callsByKey.catalyst == nil, "Malignant Catalyst is Heroic/Mythic only")
assert(normal.callsByKey.froth == nil, "Normal Froth run-out is personal bossmod execution")

assert(heroic.callsByKey.fire_stagger.warning == "SKULL FIRST > WAIT > X")
assert(heroic.callsByKey.catalyst.warning == "BILE > SOAK TEAM")
assert(heroic.callsByKey.catalyst.spellIDs[1] == 1282525 and heroic.callsByKey.catalyst.spellIDs[2] == 1282509)
assert(heroic.callsByKey.catalyst.prepareSeconds == 7 and heroic.callsByKey.catalyst.pressSeconds == 4)
assert(heroic.callsByKey.froth == nil, "Heroic Froth run-out is personal bossmod execution")

assert(mythic.callsByKey.fire_stagger.warning == "SKULL FIRST > WAIT > X")
assert(mythic.callsByKey.catalyst.warning == "BILE > SOAK TEAM")
assert(mythic.callsByKey.froth.warning == "FROTH > AIM WAVES THROUGH TUMORS")
assert(mythic.callsByKey.froth.spellIDs[1] == 1281907)
assert(mythic.callsByKey.froth.prepareSeconds == 6 and mythic.callsByKey.froth.pressSeconds == 3)
assert(mythic.callsByKey.tumors.warning == "KILL EXPOSED TUMORS")

assert(Registry:MatchCall("vashnik", "normal", 1282114, nil) == nil)
assert(Registry:MatchCall("vashnik", "normal", 1282117, nil) == nil)
assert(Registry:MatchCall("vashnik", "heroic", 1282525, nil).key == "catalyst")
assert(Registry:MatchCall("vashnik", "heroic", 1282509, nil).key == "catalyst")
assert(Registry:MatchCall("vashnik", "mythic", 1281907, nil).key == "froth")

print("ok - Vashnik keeps raid coordination while bossmods own personal infection and movement alerts")
