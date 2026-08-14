local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)

local files = {
    "CoiledAltar.lua",
    "Explorers.lua",
    "Nekzali.lua",
    "Sentinels.lua",
    "Sszorak.lua",
    "TwinFangs.lua",
    "Ulatek.lua",
    "Vashnik.lua",
}
for _, file in ipairs(files) do
    T.Load("Encounters/VenomousAbyss/" .. file, ns)
end

local Constants = ns:GetModule("Core.Constants")
local Registry = ns:GetModule("Encounters.Registry")
local encounters = Registry:GetOrdered()
assert(#encounters == 8)

local function planText(encounterKey, difficultyKey)
    return table.concat(Registry:GetProfile(encounterKey, difficultyKey).explanation, "\n")
end

local function contains(text, needle)
    return string.find(text, needle, 1, true) ~= nil
end

local profileCount = 0
for _, encounter in ipairs(encounters) do
    for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
        local profile = Registry:GetProfile(encounter.key, difficultyKey)
        assert(profile, encounter.key .. "/" .. difficultyKey)
        profileCount = profileCount + 1
        assert(#profile.explanation >= 1 and #profile.explanation <= 8)
        for _, line in ipairs(profile.explanation) do assert(#line <= 110) end
        for _, call in ipairs(profile.calls) do
            assert(#call.action <= 70)
            assert(#call.warning <= 90)
            if call.timing ~= false then
                local prepare, press = Constants.GetCallTiming(call)
                assert(prepare >= press and press >= 0)
            else
                assert(call.prepareSeconds == nil and call.pressSeconds == nil)
            end
        end
    end
end
assert(profileCount == 24)

local explorersNormal = Registry:GetProfile("explorers", "normal")
local explorersHeroic = Registry:GetProfile("explorers", "heroic")
local explorersMythic = Registry:GetProfile("explorers", "mythic")
assert(planText("explorers", "normal") ~= planText("explorers", "heroic"))
assert(contains(planText("explorers", "normal"), "ONE FISH"))
assert(contains(planText("explorers", "heroic"), "ONE FISH"))
assert(contains(planText("explorers", "mythic"), "ONE FISH"))
assert(contains(planText("explorers", "heroic"), "35+ YARDS"))
assert(contains(planText("explorers", "mythic"), "35+ YARDS"))
assert(explorersNormal.callsByKey.crates.warning ~= explorersHeroic.callsByKey.crates.warning)
assert(explorersHeroic.callsByKey.crates.warning ~= explorersMythic.callsByKey.crates.warning)
assert(contains(explorersMythic.callsByKey.crates.warning, "ONE BREAK AT A TIME"))
assert(contains(explorersNormal.callsByKey.fish.warning, "UNUSED"))
assert(explorersNormal.callsByKey.icebound.prepareSeconds == 4)
assert(explorersNormal.callsByKey.icebound.pressSeconds == 1)

local sentinelsNormal = Registry:GetProfile("sentinels", "normal")
local sentinelsHeroic = Registry:GetProfile("sentinels", "heroic")
local sentinelsMythic = Registry:GetProfile("sentinels", "mythic")
for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
    assert(contains(planText("sentinels", difficultyKey), "40+"))
    assert(not contains(planText("sentinels", difficultyKey), "30+"))
end
assert(sentinelsNormal.callsByKey.living == nil)
assert(sentinelsHeroic.callsByKey.living)
assert(sentinelsMythic.callsByKey.living)
assert(not contains(sentinelsNormal.callsByKey.blood.warning, "EDGE"))
assert(contains(sentinelsHeroic.callsByKey.blood.warning, "EDGE"))
assert(sentinelsMythic.callsByKey.protovenom)
assert(sentinelsNormal.callsByKey.stasis.prepareSeconds == 8)

local vashnikNormal = Registry:GetProfile("vashnik", "normal")
local vashnikHeroic = Registry:GetProfile("vashnik", "heroic")
local vashnikMythic = Registry:GetProfile("vashnik", "mythic")
assert(vashnikNormal.callsByKey.catalyst == nil)
assert(vashnikHeroic.callsByKey.catalyst)
assert(vashnikMythic.callsByKey.totems)
assert(vashnikMythic.callsByKey.totems.ability == "Malignant Tumors")
assert(contains(vashnikMythic.callsByKey.totems.warning, "PLAGUE WAVES"))
assert(contains(vashnikMythic.callsByKey.froth.warning, "TUMORS"))
assert(contains(planText("vashnik", "mythic"), "PLAGUE WAVE"))
assert(vashnikNormal.callsByKey.imbibe.prepareSeconds == 8)

assert(Registry:GetProfile("nekzali", "mythic").callsByKey.grasping)
assert(Registry:GetProfile("nekzali", "heroic").callsByKey.grasping == nil)
assert(Registry:GetProfile("nekzali", "mythic").callsByKey.invoke.pressSeconds == 2)
assert(Registry:GetProfile("sszorak", "mythic").callsByKey.serpent)
assert(Registry:MatchCall("sszorak", "normal", 1285430, nil).key == "apex")

for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
    local twin = Registry:GetProfile("twinfangs", difficultyKey)
    assert(twin.callsByKey.globules)
    assert(twin.callsByKey.stone)
    assert(contains(twin.callsByKey.feast.warning, "A > B > C"))
    assert(twin.callsByKey.feast.prepareSeconds == 8)
end
assert(not contains(planText("twinfangs", "normal"), "SAME SOAKERS"))
assert(Registry:GetProfile("twinfangs", "mythic").callsByKey.blood)
assert(Registry:GetProfile("twinfangs", "mythic").callsByKey.brood)
assert(Registry:GetProfile("twinfangs", "mythic").callsByKey.tainted)
assert(Registry:MatchCall("twinfangs", "normal", 1289237, nil).key == "globules")
assert(Registry:MatchCall("twinfangs", "normal", 1289192, nil).key == "globules")
assert(Registry:MatchCall("twinfangs", "normal", 1289092, nil).key == "stone")
assert(Registry:MatchCall("twinfangs", "normal", 1288538, nil).key == "stone")
assert(Registry:MatchCall("twinfangs", "normal", 1288484, nil).key == "stone")

for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
    assert(Registry:GetProfile("altar", difficultyKey).callsByKey.toxic)
end
assert(contains(Registry:GetProfile("altar", "heroic").callsByKey.toxic.warning, "NEVER STACK RUPTURES"))
assert(contains(Registry:GetProfile("altar", "mythic").callsByKey.toxic.warning, "BEFORE NEXT DELUGE"))
assert(Registry:GetProfile("altar", "normal").callsByKey.guillotine.prepareSeconds == 8)

local ulatekNormal = Registry:GetProfile("ulatek", "normal")
local ulatekHeroic = Registry:GetProfile("ulatek", "heroic")
local ulatekMythic = Registry:GetProfile("ulatek", "mythic")
assert(ulatekNormal.callsByKey.sting == nil)
assert(ulatekHeroic.callsByKey.sting)
assert(ulatekMythic.callsByKey.sting)
assert(contains(ulatekHeroic.callsByKey.coils.warning, "ROTATE GROUPS"))
assert(contains(ulatekMythic.callsByKey.coils.warning, "ROTATE GROUPS"))
assert(contains(Registry:Get("ulatek").strategyStatus, "no dedicated public Mythic PTR test located"))
for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
    for _, call in ipairs(Registry:GetProfile("ulatek", difficultyKey).calls) do
        assert(call.timing == false)
    end
end

assert(Registry:SetActiveDifficulty("normal"))
assert(Registry:Get("vashnik").callsByKey.catalyst == nil)
assert(Registry:SetActiveDifficulty("mythic"))
assert(Registry:Get("vashnik").callsByKey.totems)
assert(Registry:MatchCall("twinfangs", "mythic", 1308356, nil).key == "brood")
assert(Registry:SetActiveDifficulty("heroic"))

print("ok - difficulty profiles, timer aliases, and tactic alignment")
