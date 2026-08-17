local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/VenomousAbyss/Explorers.lua", ns)
T.Load("Encounters/VenomousAbyss/Sszorak.lua", ns)
T.Load("Encounters/VenomousAbyss/TwinFangs.lua", ns)
T.Load("Encounters/VenomousAbyss/CoiledAltar.lua", ns)
T.Load("Encounters/VenomousAbyss/Ulatek.lua", ns)

local Registry = ns:GetModule("Encounters.Registry")

local function text(encounter, difficulty)
    return table.concat(Registry:GetProfile(encounter, difficulty).explanation, "\n")
end

local function contains(value, needle)
    return string.find(value, needle, 1, true) ~= nil
end

for _, difficulty in ipairs({ "normal", "heroic", "mythic" }) do
    local profile = Registry:GetProfile("explorers", difficulty)
    local plan = text("explorers", difficulty)
    assert(profile.callsByKey.balance and profile.callsByKey.balance.timing == false,
        "Lost Explorers needs a manual boss-health coordination call on every difficulty")
    assert(contains(profile.callsByKey.balance.warning, "FINISH TOGETHER"),
        "Lost Explorers health call must coordinate a synchronized finish")
    assert(profile.callsByKey.killorder == nil,
        "Lost Explorers must not retain the obsolete fixed Nama > Iku > Gebbo kill-order call")
    assert(not contains(plan, "NAMA FIRST") and not contains(plan, "NAMA > IKU > GEBBO"),
        "Lost Explorers plan must not instruct an early Nama kill")
end
for _, difficulty in ipairs({ "heroic", "mythic" }) do
    local plan = text("explorers", difficulty)
    assert(contains(plan, "UNITED DEFENSE"),
        "Heroic/Mythic Lost Explorers must explicitly manage United Defense")
    assert(contains(plan, "DIE TOGETHER"),
        "Heroic/Mythic Lost Explorers must coordinate the three health pools")
    assert(not contains(plan, "35+ YARDS APART"),
        "Heroic/Mythic Lost Explorers must not hard-code the obsolete all-three 35+ yard split")
end

for _, difficulty in ipairs({ "normal", "heroic", "mythic" }) do
    local profile = Registry:GetProfile("twinfangs", difficulty)
    assert(profile.callsByKey.balance and profile.callsByKey.balance.timing == false,
        "Twin Fangs needs a manual boss-health coordination call on every difficulty")
    assert(contains(profile.callsByKey.balance.warning, "FINISH TOGETHER"),
        "Twin Fangs boss-health call must coordinate the joint finish")
    assert(contains(text("twinfangs", difficulty), "FINISH BOTH BOSSES TOGETHER"),
        "Twin Fangs plan must explain the Uncoiled Wrath finish requirement")
end

for _, difficulty in ipairs({ "normal", "heroic", "mythic" }) do
    local plan = text("sszorak", difficulty)
    local warning = Registry:GetProfile("sszorak", difficulty).callsByKey.apex.warning
    assert(contains(plan, "ROTATE DISTINCT 5+ SOAK TEAMS"),
        "Sszorak Mutilate copy must match the distinct-team assignment rotation")
    assert(contains(warning, "NEXT ASSIGNED 5+ SOAK TEAM"),
        "Sszorak combat call must request the next assigned team")
    assert(not contains(plan, "FIXED 5+ SOAK TEAM"),
        "Sszorak must not imply the same fixed Mutilate team repeats")
end

local altarNormal = Registry:GetProfile("altar", "normal")
local altarHeroic = Registry:GetProfile("altar", "heroic")
local altarMythic = Registry:GetProfile("altar", "mythic")
assert(contains(text("altar", "normal"), "SECOND COVERAGE TEAM IS OPTIONAL ON NORMAL"))
assert(not contains(text("altar", "normal"), "A/B ALTERNATE"),
    "Normal Guillotine must not require a Heroic-style fresh-team rotation")
assert(contains(altarNormal.callsByKey.guillotine.warning, "ASSIGNED 5+ SOAKERS"))
assert(contains(text("altar", "heroic"), "A/B ALTERNATE 5+ SOAKS"))
assert(contains(text("altar", "mythic"), "PERMANENT GUILLOTINED"))

local ulatek = Registry:Get("ulatek")
assert(ulatek and contains(ulatek.strategyStatus, "live validation pending"),
    "Ula'tek remains explicitly unverified until conflicting pre-release difficulty data is resolved live")
for _, difficulty in ipairs({ "normal", "heroic", "mythic" }) do
    for _, call in ipairs(Registry:GetProfile("ulatek", difficulty).calls) do
        assert(call.timing == false, "Ula'tek automatic timing must stay disabled before live verification")
    end
end

print("ok - tactic wording and pre-release safety regressions")
