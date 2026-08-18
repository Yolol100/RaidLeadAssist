local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/VenomousAbyss/Explorers.lua", ns)

local Registry = ns:GetModule("Encounters.Registry")

local function plan(difficulty)
    return table.concat(Registry:GetProfile("explorers", difficulty).explanation, "\n")
end

local function contains(value, needle)
    return string.find(value, needle, 1, true) ~= nil
end

for _, difficulty in ipairs({ "normal", "heroic", "mythic" }) do
    local profile = Registry:GetProfile("explorers", difficulty)
    assert(contains(plan(difficulty), "BLOODLUST ON PULL"))
    assert(contains(plan(difficulty), "NAMA > IKU > GEBBO"))
    assert(contains(plan(difficulty), "MUSHROOM"))
    assert(not contains(plan(difficulty), "ICEBOUND FLAMES"))
    assert(profile.callsByKey.icebound == nil)

    assert(profile.callsByKey.bomb.warning == "BOMB > MOVE OUT")
    assert(profile.callsByKey.bomb.spellIDs[1] == 1296249)
    assert(profile.callsByKey.bomb.prepareSeconds == 6 and profile.callsByKey.bomb.pressSeconds == 3)

    assert(profile.callsByKey.shell.spellIDs[1] == 1291759)
    assert(profile.callsByKey.blink.spellIDs[1] == 1290711)
    assert(profile.callsByKey.volley.spellIDs[1] == 1295886)
    assert(profile.callsByKey.crates.spellIDs[1] == 1291933)
    assert(profile.callsByKey.fish.spellIDs[1] == 1292779)
    assert(profile.callsByKey.thud.spellIDs[1] == 1296092)
end

assert(Registry:GetProfile("explorers", "heroic").callsByKey.position.warning == "STACK IKU + GEBBO > NAMA 30+ YARDS AWAY")
assert(Registry:GetProfile("explorers", "mythic").callsByKey.position.warning == "STACK IKU + GEBBO > NAMA 30+ YARDS AWAY")
assert(contains(plan("mythic"), "RAID CLEARS 15+ YARDS"))

print("ok - Lost Explorers recap strategy, concise calls and timer identities stay aligned")
