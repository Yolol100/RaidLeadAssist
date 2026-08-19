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

local normal = plan("normal")
assert(contains(normal, "Keep all three bosses even"))
assert(contains(normal, "Crates appear"))
assert(contains(normal, "Fish order: Nama, then Iku, then Gebbo"))
assert(contains(normal, "Three players marked"))
assert(contains(normal, "Star, Circle and Diamond"))
assert(contains(normal, "pair Fire with Frost and drop them together"))
assert(contains(normal, "step into the opposite elemental patch"))
assert(contains(normal, "Icebound Flames starts"))

local heroic = plan("heroic")
assert(contains(heroic, "Keep Nama away"))
assert(contains(heroic, "Spreading fire appears"))
assert(not contains(heroic, "Fish order"), "Heroic should only contain changes from Normal")

local mythic = plan("mythic")
assert(contains(mythic, "15+ yards away"))
assert(not contains(mythic, "Keep Nama away"), "Mythic should only contain changes from Heroic")

for _, difficulty in ipairs({ "normal", "heroic", "mythic" }) do
    local profile = Registry:GetProfile("explorers", difficulty)
    assert(profile.callsByKey.crates and profile.callsByKey.crates.spellIDs[1] == 1291933)
    assert(profile.callsByKey.crates.prepareSeconds == 6 and profile.callsByKey.crates.pressSeconds == 3)
    assert(profile.callsByKey.fish and profile.callsByKey.fish.spellIDs[1] == 1292779)
    assert(profile.callsByKey.fish.warning == "Fish: Nama, then Iku, then Gebbo.")
    assert(profile.callsByKey.fish.prepareSeconds == 8 and profile.callsByKey.fish.pressSeconds == 5)
    assert(profile.callsByKey.thud and profile.callsByKey.thud.spellIDs[1] == 1296092)
    assert(profile.callsByKey.thud.warning == "Thud: targets Star/Circle/Diamond; soakers stack.")
    assert(profile.callsByKey.thud.prepareSeconds == 7 and profile.callsByKey.thud.pressSeconds == 4)

    assert(profile.callsByKey.icebound == nil, "Icebound interrupt remains a player reaction, not a duplicate RLA button")
    assert(profile.callsByKey.shell == nil)
    assert(profile.callsByKey.blink == nil)
    assert(profile.callsByKey.volley == nil)
    assert(profile.callsByKey.bomb == nil)
    assert(profile.callsByKey.position == nil)
    assert(profile.callsByKey.tankswap == nil)
end

assert(Registry:MatchCall("explorers", "normal", 1291933, nil).key == "crates")
assert(Registry:MatchCall("explorers", "normal", 1292779, nil).key == "fish")
assert(Registry:MatchCall("explorers", "normal", 1296092, nil).key == "thud")

print("ok - Lost Explorers fixed strategy and shared calls stay aligned")
