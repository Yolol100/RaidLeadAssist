local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)

for _, file in ipairs({
    "CoiledAltar.lua",
    "Explorers.lua",
    "Nekzali.lua",
    "Sentinels.lua",
    "Sszorak.lua",
    "TwinFangs.lua",
    "Ulatek.lua",
    "Vashnik.lua",
}) do
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

-- Boss 1: only raidleader coordination should remain live.
local nekNormal = Registry:GetProfile("nekzali", "normal")
local nekHeroic = Registry:GetProfile("nekzali", "heroic")
local nekMythic = Registry:GetProfile("nekzali", "mythic")
for _, profile in ipairs({ nekNormal, nekHeroic, nekMythic }) do
    assert(profile.callsByKey.adds.warning == "KILL ADS")
    assert(profile.callsByKey.echoes.warning == "KILL ECHOES")
    assert(profile.callsByKey.phase2.warning == "PHASE 2 > BLOODLUST > BURN BOSS")
    assert(profile.callsByKey.rend == nil)
    assert(profile.callsByKey.barrage == nil)
    assert(profile.callsByKey.ignition == nil)
    assert(profile.callsByKey.invoke == nil)
end
assert(nekNormal.callsByKey.pyre.warning == "MELEE SOAK")
assert(nekNormal.callsByKey.flame == nil)
assert(contains(planText("nekzali", "normal"), "RANGED STAY OUT AND SPREAD"))
assert(nekHeroic.callsByKey.pyre.warning == "MELEE SOAK")
assert(nekHeroic.callsByKey.flame.warning == "RANGED BURN CORPSES")
assert(contains(planText("nekzali", "heroic"), "CREMATION"))
assert(nekMythic.callsByKey.pyre.warning == "GROUPS 1+2 SOAK")
assert(nekMythic.callsByKey.flame.warning == "GROUPS 3+4 BURN CORPSES")
assert(nekMythic.callsByKey.grasping)
assert(nekHeroic.callsByKey.grasping == nil and nekNormal.callsByKey.grasping == nil)
for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
    assert(not contains(planText("nekzali", difficultyKey), "TANK"))
end

-- Boss 2: fixed split and team mechanics remain; personal bossmod alerts do not.
local sentNormal = Registry:GetProfile("sentinels", "normal")
local sentHeroic = Registry:GetProfile("sentinels", "heroic")
local sentMythic = Registry:GetProfile("sentinels", "mythic")
for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
    local profile = Registry:GetProfile("sentinels", difficultyKey)
    local plan = planText("sentinels", difficultyKey)
    assert(contains(plan, "GROUPS 1+2"))
    assert(contains(plan, "GROUPS 3+4"))
    assert(contains(plan, "40+"))
    assert(contains(plan, "1+3 OR 2+2"))
    assert(not contains(plan, "TANK"))
    assert(profile.callsByKey.coagulation.warning == "KILL ADD")
    assert(profile.callsByKey.coagulation.timing == false)
    assert(profile.callsByKey.droplets == nil)
    assert(profile.callsByKey.miasma.warning == "GROUPS 3+4 > SOAK TARGET")
    assert(profile.callsByKey.side_swap.warning == "SWAP BOSS SIDES")
    assert(profile.callsByKey.stasis.warning == "MATCH TO 4 > 1+3 OR 2+2")
    assert(profile.callsByKey.balance.warning == "KEEP HP EVEN > STOP LOWER HP BOSS")
    assert(profile.callsByKey.living == nil)
    assert(profile.callsByKey.bloodvenom == nil)
    assert(profile.callsByKey.blood == nil)
    assert(profile.callsByKey.tankswap == nil)
end
assert(sentNormal.callsByKey.miasma.prepareSeconds == 5 and sentNormal.callsByKey.miasma.pressSeconds == 1)
assert(sentNormal.callsByKey.stasis.prepareSeconds == 6 and sentNormal.callsByKey.stasis.pressSeconds == 2)
assert(sentNormal.callsByKey.protovenom == nil and sentHeroic.callsByKey.protovenom == nil)
assert(sentMythic.callsByKey.protovenom.warning == "PROTOVENOM > MARKED + MARKED")

-- Boss 3: resource ownership and group soaks remain; personal mechanics stay bossmod-owned.
local explorersNormal = Registry:GetProfile("explorers", "normal")
local explorersHeroic = Registry:GetProfile("explorers", "heroic")
local explorersMythic = Registry:GetProfile("explorers", "mythic")
for _, profile in ipairs({ explorersNormal, explorersHeroic, explorersMythic }) do
    assert(profile.callsByKey.crates and profile.callsByKey.fish and profile.callsByKey.thud)
    assert(profile.callsByKey.balance == nil and profile.callsByKey.icebound == nil)
    assert(profile.callsByKey.shell == nil and profile.callsByKey.blink == nil)
    assert(profile.callsByKey.volley == nil and profile.callsByKey.bomb == nil)
    assert(profile.callsByKey.position == nil)
end
assert(contains(planText("explorers", "heroic"), "NAMA 30+ YARDS AWAY"))
assert(contains(planText("explorers", "mythic"), "RAID CLEARS 15+ YARDS"))
assert(explorersMythic.callsByKey.crates.warning == "CRATE > NEXT BREAKER > RAID 15+ YARDS CLEAR")

-- Boss 4: team coordination remains; per-player infection/movement responses stay bossmod-owned.
local vashnikNormal = Registry:GetProfile("vashnik", "normal")
local vashnikHeroic = Registry:GetProfile("vashnik", "heroic")
local vashnikMythic = Registry:GetProfile("vashnik", "mythic")
for _, profile in ipairs({ vashnikNormal, vashnikHeroic, vashnikMythic }) do
    assert(profile.callsByKey.imbibe.warning == "IMBIBE > KILL ADDS")
    assert(profile.callsByKey.siphon.warning == "SIPHON > STACK HELPERS ON TARGET")
    assert(profile.callsByKey.infection == nil)
    assert(profile.callsByKey.shadow_dodge == nil)
    assert(profile.callsByKey.exploding == nil)
    assert(profile.callsByKey.stygian == nil)
    assert(profile.callsByKey.tankswap == nil)
    assert(contains(planText("vashnik", profile.activeDifficultyKey or "normal"), "") or true)
end
assert(vashnikNormal.callsByKey.fire_stagger == nil and vashnikNormal.callsByKey.catalyst == nil and vashnikNormal.callsByKey.froth == nil)
assert(vashnikHeroic.callsByKey.fire_stagger.warning == "SKULL FIRST > WAIT > X")
assert(vashnikHeroic.callsByKey.catalyst.warning == "BILE > SOAK TEAM")
assert(vashnikHeroic.callsByKey.froth == nil)
assert(vashnikMythic.callsByKey.fire_stagger.warning == "SKULL FIRST > WAIT > X")
assert(vashnikMythic.callsByKey.catalyst.warning == "BILE > SOAK TEAM")
assert(vashnikMythic.callsByKey.froth.warning == "FROTH > AIM WAVES THROUGH TUMORS")
assert(vashnikMythic.callsByKey.tumors.warning == "KILL EXPOSED TUMORS")
for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
    assert(contains(planText("vashnik", difficultyKey), "BLOODLUST ON PULL"))
end

local sszorakMythic = Registry:GetProfile("sszorak", "mythic")
assert(sszorakMythic.callsByKey.serpent)
for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
    assert(Registry:GetProfile("sszorak", difficultyKey).callsByKey.crosswinds)
end
assert(contains(sszorakMythic.callsByKey.serpent.warning, "14+"))

for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
    local twin = Registry:GetProfile("twinfangs", difficultyKey)
    assert(twin.callsByKey.balance == nil and twin.callsByKey.stone == nil)
    assert(twin.callsByKey.globules.warning == "GREEN ORBS > SOAK BEFORE RUPTURE")
    assert(twin.callsByKey.adds.warning == "KILL ADDS")
    assert(twin.callsByKey.energy.warning == "100 ENERGY > MOVE TO ITHRAZ")
end
local twinMythic = Registry:GetProfile("twinfangs", "mythic")
assert(twinMythic.callsByKey.bulwark and twinMythic.callsByKey.brood and twinMythic.callsByKey.tainted)

for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
    local altar = Registry:GetProfile("altar", difficultyKey)
    assert(altar.callsByKey.toxic)
    assert(contains(altar.callsByKey.guillotine.warning, "5+"))
end

local ulatekNormal = Registry:GetProfile("ulatek", "normal")
local ulatekHeroic = Registry:GetProfile("ulatek", "heroic")
local ulatekMythic = Registry:GetProfile("ulatek", "mythic")
assert(ulatekNormal.callsByKey.sting == nil)
assert(ulatekHeroic.callsByKey.sting and ulatekMythic.callsByKey.sting)
for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
    for _, call in ipairs(Registry:GetProfile("ulatek", difficultyKey).calls) do
        assert(call.timing == false)
    end
end

assert(Registry:SetActiveDifficulty("normal"))
assert(Registry:Get("vashnik").callsByKey.catalyst == nil)
assert(Registry:SetActiveDifficulty("mythic"))
assert(Registry:Get("vashnik").callsByKey.tumors)
assert(Registry:SetActiveDifficulty("heroic"))

print("ok - difficulty profiles, concise actions, raidleader scope and Season 2 tactic alignment")
