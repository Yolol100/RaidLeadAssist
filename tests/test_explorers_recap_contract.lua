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
    assert(contains(plan(difficulty), "FISH ORDER: NAMA > IKU > GEBBO"))
    assert(contains(plan(difficulty), "MUSHROOM"))
    assert(contains(plan(difficulty), "INTERRUPT ICEBOUND FLAMES"))

    assert(profile.callsByKey.crates and profile.callsByKey.crates.spellIDs[1] == 1291933)
    assert(profile.callsByKey.crates.prepareSeconds == 6 and profile.callsByKey.crates.pressSeconds == 3)
    assert(profile.callsByKey.fish and profile.callsByKey.fish.spellIDs[1] == 1292779)
    assert(profile.callsByKey.fish.prepareSeconds == 8 and profile.callsByKey.fish.pressSeconds == 5)
    assert(profile.callsByKey.thud and profile.callsByKey.thud.spellIDs[1] == 1296092)
    assert(profile.callsByKey.thud.warning == "MIGHTY THUD > 3 TARGETS > 3 SOAK POINTS")
    assert(profile.callsByKey.thud.prepareSeconds == 7 and profile.callsByKey.thud.pressSeconds == 4)

    assert(profile.callsByKey.icebound == nil, "Icebound interrupt is bossmod-owned")
    assert(profile.callsByKey.shell == nil, "Shell Spin is a personal bossmod dodge")
    assert(profile.callsByKey.blink == nil, "Blink Nova target handling is bossmod-owned")
    assert(profile.callsByKey.volley == nil, "Frostfire target handling is bossmod-owned")
    assert(profile.callsByKey.bomb == nil, "Explosive Surprise target handling is bossmod-owned")
    assert(profile.callsByKey.position == nil, "fixed positioning belongs in the pre-pull plan")
    assert(profile.callsByKey.tankswap == nil)
end

assert(contains(plan("heroic"), "NAMA 30+ YARDS AWAY"))
assert(contains(plan("mythic"), "NAMA 30+ YARDS AWAY"))
assert(contains(plan("mythic"), "RAID CLEARS 15+ YARDS"))

assert(Registry:MatchCall("explorers", "normal", 1291933, nil).key == "crates")
assert(Registry:MatchCall("explorers", "normal", 1292779, nil).key == "fish")
assert(Registry:MatchCall("explorers", "normal", 1296092, nil).key == "thud")
assert(Registry:MatchCall("explorers", "normal", 1291759, nil) == nil)
assert(Registry:MatchCall("explorers", "normal", 1290711, nil) == nil)
assert(Registry:MatchCall("explorers", "normal", 1295886, nil) == nil)
assert(Registry:MatchCall("explorers", "normal", 1296249, nil) == nil)

print("ok - Lost Explorers keeps resource and group coordination while bossmods own personal mechanics")
