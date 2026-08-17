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
        for _, line in ipairs(profile.explanation) do assert(#line <= 250) end
        for _, call in ipairs(profile.calls) do
            assert(#call.action <= 72)
            assert(#call.warning <= 96)
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
for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
    assert(contains(planText("explorers", difficultyKey), "FINISH TOGETHER"))
    assert(contains(planText("explorers", difficultyKey), "UNUSED"))
end
assert(contains(planText("explorers", "heroic"), "UNITED DEFENSE"))
assert(not contains(planText("explorers", "heroic"), "35+ YARDS"))
assert(not contains(planText("explorers", "mythic"), "35+ YARDS"))
for _, profile in ipairs({ explorersNormal, explorersHeroic, explorersMythic }) do
    assert(profile.callsByKey.balance)
    assert(profile.callsByKey.balance.timing == false)
    assert(contains(profile.callsByKey.balance.warning, "KEEP ALL 3 EVEN"))
    assert(profile.callsByKey.killorder == nil)
end
assert(explorersNormal.callsByKey.crates.warning ~= explorersHeroic.callsByKey.crates.warning)
assert(explorersHeroic.callsByKey.crates.warning ~= explorersMythic.callsByKey.crates.warning)
assert(contains(explorersMythic.callsByKey.crates.warning, "ONE AT A TIME"))
assert(contains(explorersNormal.callsByKey.fish.warning, "UNUSED"))
assert(explorersNormal.callsByKey.icebound.prepareSeconds == 4)
assert(explorersNormal.callsByKey.icebound.pressSeconds == 1)

local sentinelsNormal = Registry:GetProfile("sentinels", "normal")
local sentinelsHeroic = Registry:GetProfile("sentinels", "heroic")
local sentinelsMythic = Registry:GetProfile("sentinels", "mythic")
for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
    local profile = Registry:GetProfile("sentinels", difficultyKey)
    local plan = planText("sentinels", difficultyKey)
    assert(contains(plan, "GROUPS 1+2"))
    assert(contains(plan, "GROUPS 3+4"))
    assert(contains(plan, "40+"))
    assert(profile.callsByKey.tankswap)
    assert(profile.callsByKey.side_swap.warning == "SWAP BOSS SIDES")
    assert(profile.callsByKey.stasis.warning == "MATCH TO EXACTLY 4")
    assert(profile.callsByKey.balance)
    assert(profile.callsByKey.balance_stop_breath.warning == "STOP DPS > BREATH OF ULA'TEK")
    assert(profile.callsByKey.balance_stop_blood.warning == "STOP DPS > BLOOD OF ULA'TEK")
    assert(profile.callsByKey.balance_resume.warning == "RESUME DPS > KEEP BOTH EVEN")
end
assert(sentinelsNormal.callsByKey.coagulation.warning == "KILL ADD")
assert(sentinelsNormal.callsByKey.droplets.warning == "RUN OVER GREEN DROPLETS")
assert(sentinelsNormal.callsByKey.miasma.warning == "SOAK CIRCLE")
assert(sentinelsNormal.callsByKey.blood.warning == "DISPEL DOTS")
assert(sentinelsNormal.callsByKey.living == nil)
assert(sentinelsNormal.callsByKey.bloodvenom == nil)
assert(sentinelsHeroic.callsByKey.living.warning == "DODGE VENOM")
assert(sentinelsHeroic.callsByKey.bloodvenom.warning == "GO TO CORNER")
assert(sentinelsMythic.callsByKey.living.warning == "DODGE VENOM")
assert(sentinelsMythic.callsByKey.bloodvenom.warning == "GO TO CORNER")
assert(sentinelsMythic.callsByKey.protovenom)
assert(contains(sentinelsMythic.callsByKey.protovenom.warning, "MARKED + MARKED"))
assert(sentinelsNormal.callsByKey.stasis.prepareSeconds == 8)

local vashnikNormal = Registry:GetProfile("vashnik", "normal")
local vashnikHeroic = Registry:GetProfile("vashnik", "heroic")
local vashnikMythic = Registry:GetProfile("vashnik", "mythic")
for _, profile in ipairs({ vashnikNormal, vashnikHeroic, vashnikMythic }) do
    assert(profile.callsByKey.imbibe.warning == "KILL ADDS")
    assert(profile.callsByKey.fire_stagger.warning == "SKULL FIRST > WAIT > X")
    assert(profile.callsByKey.shadow_dodge.warning == "DODGE SWIRLIES")
    assert(profile.callsByKey.siphon.warning == "SIPHON > STACK TO HELP HEAL")
    assert(profile.callsByKey.exploding.warning == "BIG CIRCLE > MOVE FAR OUT")
    assert(profile.callsByKey.stygian.warning == "SPREAD > KEEP MOVING")
    assert(profile.callsByKey.tankswap == nil)
end
assert(contains(planText("vashnik", "normal"), "FLAME > SHADOW > SHADOW > BLOOD > BLOOD > FLAME"))
assert(contains(planText("vashnik", "heroic"), "FLAME > SHADOW > SHADOW > BLOOD > BLOOD > FLAME"))
assert(contains(planText("vashnik", "normal"), "TWO NEAREST FOUNTAINS"))
assert(not contains(planText("vashnik", "normal"), "TANK"))
assert(not contains(planText("vashnik", "heroic"), "TANK"))
assert(not contains(planText("vashnik", "mythic"), "TANK"))
assert(vashnikNormal.callsByKey.catalyst == nil)
assert(vashnikHeroic.callsByKey.catalyst.warning == "SOAK BILE")
assert(vashnikMythic.callsByKey.catalyst.warning == "SOAK BILE")
assert(vashnikNormal.callsByKey.froth.warning == "FROTH > MOVE OUT > AIM AWAY")
assert(vashnikHeroic.callsByKey.froth.warning == "FROTH > MOVE OUT > AIM AWAY")
assert(vashnikMythic.callsByKey.froth.warning == "FROTH > AIM AT TUMORS")
assert(vashnikNormal.callsByKey.imbibe.prepareSeconds == 8)
assert(vashnikNormal.callsByKey.froth.prepareSeconds == 6)
assert(vashnikHeroic.callsByKey.catalyst.prepareSeconds == 7)
assert(vashnikMythic.callsByKey.tumors.warning == "KILL TUMORS")
assert(vashnikNormal.callsByKey.tumors == nil)
assert(vashnikHeroic.callsByKey.tumors == nil)

local nekzaliNormal = Registry:GetProfile("nekzali", "normal")
local nekzaliHeroic = Registry:GetProfile("nekzali", "heroic")
local nekzaliMythic = Registry:GetProfile("nekzali", "mythic")
for _, profile in ipairs({ nekzaliNormal, nekzaliHeroic, nekzaliMythic }) do
    assert(profile.callsByKey.rend.warning == "GO TO THE EDGE")
    assert(profile.callsByKey.adds.warning == "KILL ADS")
    assert(profile.callsByKey.phase2.warning == "PHASE 2 > BLOODLUST > BURN BOSS")
end
assert(nekzaliNormal.callsByKey.pyre.warning == "MELEE SOAK")
assert(nekzaliNormal.callsByKey.flame.warning == "RANGED SPREAD OUT")
assert(not contains(planText("nekzali", "normal"), "CREMATION"))
assert(nekzaliHeroic.callsByKey.pyre.warning == "MELEE SOAK")
assert(nekzaliHeroic.callsByKey.flame.warning == "RANGED BURN ADS")
assert(contains(planText("nekzali", "heroic"), "CREMATION"))
assert(nekzaliMythic.callsByKey.pyre.warning == "GROUP 1 + 2 SOAK")
assert(nekzaliMythic.callsByKey.flame.warning == "GROUP 3 + 4 BURN ADS")
assert(nekzaliMythic.callsByKey.grasping)
assert(nekzaliHeroic.callsByKey.grasping == nil)
assert(nekzaliNormal.callsByKey.grasping == nil)
assert(contains(nekzaliMythic.callsByKey.grasping.warning, "KICK CURSE"))
assert(nekzaliMythic.callsByKey.invoke)
assert(nekzaliHeroic.callsByKey.invoke == nil)
assert(nekzaliNormal.callsByKey.invoke == nil)
assert(nekzaliMythic.callsByKey.invoke.pressSeconds == 2)
assert(contains(planText("nekzali", "mythic"), "SOUL EXHAUSTION"))

local sszorakMythic = Registry:GetProfile("sszorak", "mythic")
assert(sszorakMythic.callsByKey.serpent)
for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
    assert(Registry:GetProfile("sszorak", difficultyKey).callsByKey.crosswinds)
end
assert(contains(sszorakMythic.callsByKey.serpent.warning, "14+"))
assert(contains(Registry:GetProfile("sszorak", "heroic").callsByKey.apex.warning, "5+"))
assert(Registry:MatchCall("sszorak", "normal", 1285430, nil).key == "apex")

for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
    local twin = Registry:GetProfile("twinfangs", difficultyKey)
    assert(twin.callsByKey.balance)
    assert(twin.callsByKey.balance.timing == false)
    assert(contains(planText("twinfangs", difficultyKey), "BOSSES TOGETHER"))
    assert(twin.callsByKey.globules)
    assert(twin.callsByKey.stone)
    assert(contains(twin.callsByKey.feast.warning, "A > B > C"))
    assert(twin.callsByKey.feast.prepareSeconds == 8)
end
assert(not contains(planText("twinfangs", "normal"), "SAME SOAKERS"))
local twinMythic = Registry:GetProfile("twinfangs", "mythic")
assert(twinMythic.callsByKey.blood)
assert(contains(twinMythic.callsByKey.blood.warning, "STOP BULWARKS"))
assert(twinMythic.callsByKey.brood)
assert(contains(twinMythic.callsByKey.brood.warning, "INTERRUPT"))
assert(twinMythic.callsByKey.tainted)
assert(Registry:MatchCall("twinfangs", "normal", 1289237, nil).key == "globules")
assert(Registry:MatchCall("twinfangs", "normal", 1289192, nil).key == "globules")
assert(Registry:MatchCall("twinfangs", "normal", 1289092, nil).key == "stone")
assert(Registry:MatchCall("twinfangs", "normal", 1288538, nil).key == "stone")
assert(Registry:MatchCall("twinfangs", "normal", 1288484, nil).key == "stone")

for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
    assert(Registry:GetProfile("altar", difficultyKey).callsByKey.toxic)
    assert(contains(Registry:GetProfile("altar", difficultyKey).callsByKey.guillotine.warning, "5+"))
    assert(contains(Registry:GetProfile("altar", difficultyKey).callsByKey.guillotine.warning, "40+"))
end
assert(contains(Registry:GetProfile("altar", "heroic").callsByKey.toxic.warning, "NO CHAIN RUPTURES"))
assert(contains(Registry:GetProfile("altar", "mythic").callsByKey.toxic.warning, "CLEAR MUTATIONS"))
assert(Registry:GetProfile("altar", "normal").callsByKey.guillotine.prepareSeconds == 8)

local ulatekNormal = Registry:GetProfile("ulatek", "normal")
local ulatekHeroic = Registry:GetProfile("ulatek", "heroic")
local ulatekMythic = Registry:GetProfile("ulatek", "mythic")
assert(ulatekNormal.callsByKey.sting == nil)
assert(ulatekHeroic.callsByKey.sting)
assert(ulatekMythic.callsByKey.sting)
assert(not contains(ulatekHeroic.callsByKey.coils.warning, "NEXT"))
assert(contains(ulatekMythic.callsByKey.coils.warning, "NEXT SOAK GROUP"))
assert(ulatekNormal.callsByKey.fangs == nil)
assert(ulatekHeroic.callsByKey.fangs)
assert(ulatekMythic.callsByKey.fangs)
assert(ulatekNormal.callsByKey.bite)
assert(ulatekHeroic.callsByKey.bite)
assert(ulatekMythic.callsByKey.bite)
assert(contains(Registry:Get("ulatek").strategyStatus, "2026-08-17"))
assert(contains(Registry:Get("ulatek").strategyStatus, "not PTR-tested"))
assert(contains(Registry:Get("ulatek").strategyStatus, "live validation required"))
for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
    for _, call in ipairs(Registry:GetProfile("ulatek", difficultyKey).calls) do
        assert(call.timing == false)
    end
end

assert(Registry:SetActiveDifficulty("normal"))
assert(Registry:Get("vashnik").callsByKey.catalyst == nil)
assert(Registry:SetActiveDifficulty("mythic"))
assert(Registry:Get("vashnik").callsByKey.tumors)
assert(Registry:MatchCall("twinfangs", "mythic", 1308356, nil).key == "brood")
assert(Registry:SetActiveDifficulty("heroic"))

print("ok - difficulty profiles, concise actions, and Season 2 tactic alignment")
