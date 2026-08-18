local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/VenomousAbyss/Sszorak.lua", ns)

local Registry = ns:GetModule("Encounters.Registry")

local function plan(difficulty)
    return table.concat(Registry:GetProfile("sszorak", difficulty).explanation, "\n")
end

local function contains(value, needle)
    return string.find(value, needle, 1, true) ~= nil
end

for _, difficulty in ipairs({ "normal", "heroic", "mythic" }) do
    local profile = Registry:GetProfile("sszorak", difficulty)
    assert(profile.callsByKey.venom.warning == "VENOM > DEBUFF TO MARKERS > DROP CYSTS")
    assert(profile.callsByKey.venom.spellIDs[1] == 1305959)
    assert(profile.callsByKey.venom.prepareSeconds == 6 and profile.callsByKey.venom.pressSeconds == 3)

    assert(profile.callsByKey.crosswinds.warning == "CROSSWINDS > PAIR OPPOSITES > COLLIDE")
    assert(profile.callsByKey.crosswinds.spellIDs[1] == 1285425)
    assert(profile.callsByKey.crosswinds.prepareSeconds == 7 and profile.callsByKey.crosswinds.pressSeconds == 4)

    assert(profile.callsByKey.maelstrom.warning == "MAELSTROM > USE CYST KNOCKBACK > STAY IN")
    assert(profile.callsByKey.maelstrom.spellIDs[1] == 1285732)
    assert(profile.callsByKey.maelstrom.prepareSeconds == 8 and profile.callsByKey.maelstrom.pressSeconds == 5)

    assert(profile.callsByKey.apex.warning == "GREEN MUTILATE > 5+ SOAK GROUP")
    assert(profile.callsByKey.apex.prepareSeconds == 7 and profile.callsByKey.apex.pressSeconds == 4)

    assert(contains(plan(difficulty), "30%"))
    assert(contains(plan(difficulty), "BLOODLUST"))
    assert(contains(plan(difficulty), "WHITE RAVAGE IS DBM-ONLY"))
    assert(contains(plan(difficulty), "GREEN MUTILATE"))
    assert(contains(plan(difficulty), "CYST"))
    assert(not contains(plan(difficulty), "TANK"))
end

assert(contains(plan("normal"), "3 WORLD MARKERS"))
assert(contains(plan("heroic"), "CAUSTIC PUDDLES"))
assert(contains(plan("heroic"), "SOAK GROUP 1 AND SOAK GROUP 2"))

local mythic = Registry:GetProfile("sszorak", "mythic")
assert(mythic.callsByKey.serpent.warning == "SERPENT'S FURY > 14+ STACK ON MARK")
assert(contains(plan("mythic"), "WITHIN 8 YARDS"))
assert(contains(plan("mythic"), "VIRULENCE TARGETS SPREAD"))

assert(Registry:MatchCall("sszorak", "normal", 1305959, nil).key == "venom")
assert(Registry:MatchCall("sszorak", "normal", 1285425, nil).key == "crosswinds")
assert(Registry:MatchCall("sszorak", "normal", 1285732, nil).key == "maelstrom")
assert(Registry:MatchCall("sszorak", "normal", 1285430, nil).key == "apex")

print("ok - Sszorak marker cyst setup, group Mutilate soak and timer identities stay aligned")
