local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/VenomousAbyss/Explorers.lua", ns)

local Registry = ns:GetModule("Encounters.Registry")
local function plan(difficulty)
    local profile = assert(Registry:GetProfile("explorers", difficulty))
    return table.concat(profile.explanation, "\n")
end
local function contains(value, needle)
    return string.find(value, needle, 1, true) ~= nil
end

assert(Registry:GetProfile("explorers", "normal") == nil,
    "Normal Lost Explorers profile must remain retired")

local heroic = assert(Registry:GetProfile("explorers", "heroic"))
assert(plan("heroic") == "GEBBO → NAMA → IKU")
assert(#heroic.calls == 6)
assert(heroic.callsByKey.fish_gebbo and heroic.callsByKey.fish_gebbo.spellIDs[1] == 1292779)
assert(heroic.callsByKey.fish_gebbo.sequenceKey == "fish")
assert(table.concat(heroic.callsByKey.fish_gebbo.sequenceKeys, ",") == "fish_gebbo,fish_nama,fish_iku")
assert(heroic.callsByKey.fish_nama and heroic.callsByKey.fish_nama.timing == false)
assert(heroic.callsByKey.fish_iku and heroic.callsByKey.fish_iku.timing == false)
assert(heroic.callsByKey.thud and heroic.callsByKey.thud.spellIDs[1] == 1296092)
assert(heroic.callsByKey.mushroom and heroic.callsByKey.mushroom.timing == false)
assert(heroic.callsByKey.elements and heroic.callsByKey.elements.timing == false)
assert(heroic.callsByKey.crates == nil,
    "Heroic crate breaking is not a separate raid-lead timer/button in the current plan")

local mythic = assert(Registry:GetProfile("explorers", "mythic"))
local mythicPlan = plan("mythic")
assert(contains(mythicPlan, "15+ yards away"))
assert(contains(mythicPlan, "planned Mythic fish target"))
assert(#mythic.calls == 3)
assert(mythic.callsByKey.crates and mythic.callsByKey.crates.spellIDs[1] == 1291933)
assert(mythic.callsByKey.crates.prepareSeconds == 6 and mythic.callsByKey.crates.pressSeconds == 3)
assert(mythic.callsByKey.fish and mythic.callsByKey.fish.spellIDs[1] == 1292779)
assert(mythic.callsByKey.fish.prepareSeconds == 8 and mythic.callsByKey.fish.pressSeconds == 5)
assert(mythic.callsByKey.thud and mythic.callsByKey.thud.spellIDs[1] == 1296092)
assert(mythic.callsByKey.thud.prepareSeconds == 7 and mythic.callsByKey.thud.pressSeconds == 4)

for _, difficulty in ipairs({ "heroic", "mythic" }) do
    local profile = Registry:GetProfile("explorers", difficulty)
    assert(profile.callsByKey.icebound == nil, "Icebound interrupt remains player/bossmod-owned")
    assert(profile.callsByKey.shell == nil)
    assert(profile.callsByKey.blink == nil)
    assert(profile.callsByKey.volley == nil)
    assert(profile.callsByKey.bomb == nil)
    assert(profile.callsByKey.position == nil)
    assert(profile.callsByKey.tankswap == nil)
end

assert(Registry:MatchCall("explorers", "heroic", 1292779, nil).key == "fish_gebbo")
assert(Registry:MatchCall("explorers", "heroic", 1296092, nil).key == "thud")
assert(Registry:MatchCall("explorers", "mythic", 1291933, nil).key == "crates")
assert(Registry:MatchCall("explorers", "mythic", 1292779, nil).key == "fish")
assert(Registry:MatchCall("explorers", "mythic", 1296092, nil).key == "thud")

_G.issecretvalue = nil
print("ok - Lost Explorers Heroic fish sequence and Mythic timed recap stay aligned")
