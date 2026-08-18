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
    assert(not contains(planText("explorers", difficultyKey), "TANK"))
    assert(not contains(planText("explorers", difficultyKey), "INTERRUPT ICEBOUND"))
end
assert(contains(planText("explorers", "heroic"), "UNITED DEFENSE"))
assert(contains(planText("explorers", "normal"), "STACK IKU + NAMA + GEBBO"))
assert(contains(planText("explorers", "heroic"), "STACK IKU + GEBBO"))
assert(contains(planText("explorers", "heroic"), "NAMA 30+ YARDS AWAY"))
assert(contains(planText("explorers", "mythic"), "STACK IKU + GEBBO"))
assert(contains(planText("explorers", "mythic"), "NAMA 30+ YARDS AWAY"))
for _, profile in ipairs({ explorersNormal, explorersHeroic, explorersMythic }) do
    assert(profile.callsByKey.balance == nil)
    assert(profile.callsByKey.icebound == nil)
    assert(profile.callsByKey.killorder == nil)
    assert(profile.callsByKey.tankswap == nil)
    assert(profile.callsByKey.shell.warning == "SHELL SPIN > DODGE SHELLS")
    assert(profile.callsByKey.blink.warning == "BLINK NOVA > TARGET EDGE > RAID AWAY")
    assert(profile.callsByKey.volley.warning == "FROST/FIRE > CLEAR WITH OPPOSITE")
    assert(profile.callsByKey.bomb.warning == "BOMB > MOVE OUT")
    assert(profile.callsByKey.shell.prepareSeconds == 6 and profile.callsByKey.shell.pressSeconds == 3)
    assert(profile.callsByKey.blink.prepareSeconds == 6 and profile.callsByKey.blink.pressSeconds == 3)
    assert(profile.callsByKey.volley.prepareSeconds == 6 and profile.callsByKey.volley.pressSeconds == 3)
    assert(profile.callsByKey.bomb.prepareSeconds == 6 and profile.callsByKey.bomb.pressSeconds == 3)
end
assert(explorersNormal.callsByKey.position == nil)
assert(explorersHeroic.callsByKey.position.warning == "STACK IKU + GEBBO > NAMA 30+ YARDS AWAY")
assert(explorersMythic.callsByKey.position.warning == "STACK IKU + GEBBO > NAMA 30+ YARDS AWAY")
assert(explorersNormal.callsByKey.crates.warning ~= explorersHeroic.callsByKey.crates.warning)
assert(explorersHeroic.callsByKey.crates.warning ~= explorersMythic.callsByKey.crates.warning)
assert(explorersMythic.callsByKey.crates.warning == "CRATE > BREAKER IN > RAID 15+ YARDS OUT")
assert(contains(explorersNormal.callsByKey.fish.warning, "UNUSED"))
assert(explorersNormal.callsByKey.crates.spellIDs[1] == 1291933)
assert(explorersNormal.callsByKey.fish.spellIDs[1] == 1292779)

local sentinelsNormal = Registry:GetProfile("sentinels", "normal")
local sentinelsHeroic = Registry:GetProfile("sentinels", "heroic")
local sentinelsMythic = Registry:GetProfile("sentinels", "mythic")
for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
    local profile = Registry:GetProfile("sentinels", difficultyKey)
    local plan = planText("sentinels", difficultyKey)
    assert(contains(plan, "GROUPS 1+2"))
    assert(contains(plan, "GROUPS 3+4"))
    assert(contains(plan, "40+"))
    assert(contains(plan, "1+3 OR 2+2"))
    assert(not contains(plan, "TANK"))
    assert(profile.callsByKey.tankswap == nil)
    assert(profile.callsByKey.side_swap.warning == "SWAP BOSS SIDES")
    assert(profile.callsByKey.stasis.warning == "MATCH TO 4 > 1+3 OR 2+2")
    assert(profile.callsByKey.balance.warning == "KEEP HP EVEN > STOP LOWER HP BOSS")
    assert(profile.callsByKey.balance_stop_breath.warning == "STOP DPS > BREATH OF ULA'TEK")
    assert(profile.callsByKey.balance_stop_blood.warning == "STOP DPS > BLOOD OF ULA'TEK")
    assert(profile.callsByKey.balance_resume.warning == "RESUME DPS > KEEP BOTH EVEN")
    assert(profile.callsByKey.living == nil)
    assert(profile.callsByKey.bloodvenom == nil)
    assert(profile.callsByKey.blood == nil)
end
assert(sentinelsNormal.callsByKey.coagulation.warning == "KILL ADD")
assert(sentinelsNormal.callsByKey.coagulation.timing == false)
assert(sentinelsNormal.callsByKey.droplets.warning == "RUN OVER GREEN DROPLETS")
assert(sentinelsNormal.callsByKey.miasma.warning == "GROUPS 3+4 > SOAK TARGET")
assert(sentinelsNormal.callsByKey.miasma.prepareSeconds == 5 and sentinelsNormal.callsByKey.miasma.pressSeconds == 1)
assert(sentinelsMythic.callsByKey.protovenom)
assert(contains(sentinelsMythic.callsByKey.protovenom.warning, "MARKED + MARKED"))
assert(sentinelsNormal.callsByKey.stasis.prepareSeconds == 6 and sentinelsNormal.callsByKey.stasis.pressSeconds == 2)

local vashnikNormal = Registry:GetProfile("vashnik", "normal")
local vashnikHeroic = Registry:GetProfile("vashnik", "heroic")
local vashnikMythic = Registry:GetProfile("vashnik", "mythic")
for _, profile in ipairs({ vashnikNormal, vashnikHeroic, vashnikMythic }) do
    assert(profile.callsByKey.imbibe.warning == "KILL ADDS")
    assert(profile.callsByKey.shadow_dodge.warning == "DODGE SWIRLIES")
    assert(profile.callsByKey.infection.warning == "INFECTION > CHECK TYPE")
    assert(profile.callsByKey.siphon.warning == "SIPHON > STACK HELPERS ON TARGET")
    assert(profile.callsByKey.exploding.warning == "BIG CIRCLE > MOVE FAR OUT")
    assert(profile.callsByKey.stygian.warning == "SPREAD > KEEP MOVING")
    assert(profile.callsByKey.tankswap == nil)
end
assert(vashnikNormal.callsByKey.fire_stagger.warning == "KILL FIRE ADDS")
assert(vashnikHeroic.callsByKey.fire_stagger.warning == "SKULL FIRST > WAIT > X")
assert(vashnikMythic.callsByKey.fire_stagger.warning == "SKULL FIRST > WAIT > X")
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
assert(vashnikNormal.callsByKey.infection.prepareSeconds == 6)
assert(vashnikHeroic.callsByKey.catalyst.prepareSeconds == 7)
assert(vashnikMythic.callsByKey.tumors.warning == "KILL TUMORS")
assert(vashnikNormal.callsByKey.tumors == nil)
assert(vashnikHeroic.callsByKey.tumors == nil)
assert(Registry:MatchCall("vashnik", "normal", 1282114, nil).key == "infection")
assert(Registry:MatchCall("vashnik", "normal", 1282117, nil).key == "infection")

local nekzaliNormal = Registry:GetProfile("nekzali", "normal")
local nekzaliHeroic = Registry:GetProfile("nekzali", "heroic")
local nekzaliMythic = Registry:GetProfile("nekzali", "mythic")
for _, profile in ipairs({ nekzaliNormal, nekzaliHeroic, nekzaliMythic }) do
    assert(profile.callsByKey.adds.warning == "KILL ADS")
    assert(profile.callsByKey.echoes.warning == "KILL ECHOES")
    assert(profile.callsByKey.phase2.warning == "PHASE 2 > BLOODLUST > BURN BOSS")
    assert(profile.callsByKey.rend == nil)
    assert(profile.callsByKey.barrage == nil)
    assert(profile.callsByKey.ignition == nil)
    assert(profile.callsByKey.invoke == nil)
end
for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
    assert(not contains(planText("nekzali", difficultyKey), "TANK"))
end
assert(nekzaliNormal.callsByKey.pyre.warning == "MELEE SOAK")
assert(nekzaliNormal.callsByKey.flame.warning == "RANGED SPREAD OUT")
assert(not contains(planText("nekzali", "normal"), "CREMATION"))
assert(nekzaliHeroic.callsByKey.pyre.warning == "MELEE SOAK")
assert(nekzaliHeroic.callsByKey.flame.warning == "RANGED BURN CORPSES")
assert(contains(planText("nekzali", "heroic"), "CREMATION"))
assert(nekzaliMythic.callsByKey.pyre.warning == "GROUPS 1+2 SOAK")
assert(nekzaliMythic.callsByKey.flame.warning == "GROUPS 3+4 BURN CORPSES")
assert(nekzaliMythic.callsByKey.grasping)
assert(nekzaliHeroic.callsByKey.grasping == nil)
assert(nekzaliNormal.callsByKey.grasping == nil)
assert(contains(nekzaliMythic.callsByKey.grasping.warning, "NEXT WELL GROUP"))
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
    assert(twin.callsByKey.balance == nil)
    assert(twin.callsByKey.stone == nil)
    assert(contains(planText("twinfangs", difficultyKey), "FINISH TOGETHER"))
    assert(twin.callsByKey.globules.warning == "GREEN ORBS > SOAK BEFORE RUPTURE")
    assert(twin.callsByKey.adds.warning == "KILL ADDS")
    assert(twin.callsByKey.energy.warning == "100 ENERGY > MOVE TO ITHRAZ")
    assert(twin.callsByKey.feast.prepareSeconds == 8)
end
assert(Registry:GetProfile("twinfangs", "normal").callsByKey.feast.warning == "FEAST > GROUPS 1+2 > 3+4 > 5+6")
assert(Registry:GetProfile("twinfangs", "heroic").callsByKey.feast.warning == "FEAST > GROUPS 1+2 > 3+4 > 5+6")
assert(not contains(planText("twinfangs", "normal"), "SAME SOAKERS"))
local twinMythic = Registry:GetProfile("twinfangs", "mythic")
assert(twinMythic.callsByKey.feast.warning == "FEAST > GROUP 1 > GROUP 2 > GROUPS 3+4")
assert(not contains(planText("twinfangs", "mythic"), "GROUPS 5+6"))
assert(twinMythic.callsByKey.bulwark)
assert(twinMythic.callsByKey.bulwark.warning == "BULWARKS > INTERRUPT")
assert(twinMythic.callsByKey.brood)
assert(twinMythic.callsByKey.brood.warning == "BROODLINGS > INTERRUPT ALL")
assert(twinMythic.callsByKey.tainted)
assert(Registry:MatchCall("twinfangs", "normal", 1289237, nil).key == "globules")
assert(Registry:MatchCall("twinfangs", "normal", 1289192, nil).key == "globules")
assert(Registry:MatchCall("twinfangs", "normal", 1306872, nil).key == "energy")

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
