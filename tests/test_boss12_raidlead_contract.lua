local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/VenomousAbyss/Nekzali.lua", ns)
T.Load("Encounters/VenomousAbyss/Sentinels.lua", ns)

local Registry = ns:GetModule("Encounters.Registry")
local difficulties = { "normal", "heroic", "mythic" }

local function contains(value, needle)
    return string.find(value, needle, 1, true) ~= nil
end

local function plan(encounterKey, difficultyKey)
    return table.concat(Registry:GetProfile(encounterKey, difficultyKey).explanation, "\n")
end

for _, difficulty in ipairs(difficulties) do
    local nek = Registry:GetProfile("nekzali", difficulty)
    assert(nek.callsByKey.adds and nek.callsByKey.adds.warning == "KILL ADS")
    assert(nek.callsByKey.adds.prepareSeconds == 7 and nek.callsByKey.adds.pressSeconds == 4)
    assert(nek.callsByKey.echoes and nek.callsByKey.echoes.warning == "KILL ECHOES" and nek.callsByKey.echoes.timing == false)
    assert(nek.callsByKey.pyre and nek.callsByKey.pyre.prepareSeconds == 8 and nek.callsByKey.pyre.pressSeconds == 5)
    assert(nek.callsByKey.phase2 and nek.callsByKey.phase2.timing == false)

    assert(nek.callsByKey.rend == nil, "Essence Rend is a personal bossmod responsibility, not an RLA button")
    assert(nek.callsByKey.barrage == nil, "Possession Barrage is tank/target bossmod responsibility, not an RLA button")
    assert(nek.callsByKey.ignition == nil, "Soulcoil Ignition dodge/healing micro-call must stay out of RLA")
    assert(nek.callsByKey.invoke == nil, "Invoke stop-casting is bossmod/personal responsibility, not an RLA button")
    assert(not contains(plan("nekzali", difficulty), "TANK"), "Nek'zali raid plan must remain tank-call free")
end

assert(Registry:GetProfile("nekzali", "normal").callsByKey.pyre.warning == "MELEE SOAK")
assert(Registry:GetProfile("nekzali", "normal").callsByKey.flame == nil,
    "Normal Slithering Flame spreading is personal bossmod execution and should stay in the plan only")
assert(Registry:GetProfile("nekzali", "heroic").callsByKey.pyre.warning == "MELEE SOAK")
assert(Registry:GetProfile("nekzali", "heroic").callsByKey.flame.warning == "RANGED BURN CORPSES")
assert(Registry:GetProfile("nekzali", "mythic").callsByKey.pyre.warning == "GROUPS 1+2 SOAK")
assert(Registry:GetProfile("nekzali", "mythic").callsByKey.flame.warning == "GROUPS 3+4 BURN CORPSES")
assert(Registry:GetProfile("nekzali", "mythic").callsByKey.grasping)
assert(Registry:GetProfile("nekzali", "mythic").callsByKey.grasping.warning == "GRASPING > NEXT WELL GROUP IN > KICK > KILL ECHO > OUT")
assert(Registry:GetProfile("nekzali", "mythic").callsByKey.grasping.prepareSeconds == 8)
assert(Registry:GetProfile("nekzali", "mythic").callsByKey.grasping.pressSeconds == 5)
assert(Registry:GetProfile("nekzali", "normal").callsByKey.grasping == nil)
assert(Registry:GetProfile("nekzali", "heroic").callsByKey.grasping == nil)

assert(Registry:MatchCall("nekzali", "normal", 1295397, nil).key == "adds")
assert(Registry:MatchCall("nekzali", "normal", 1297630, nil).key == "adds")
assert(Registry:MatchCall("nekzali", "normal", 1305421, nil).key == "pyre")
assert(Registry:MatchCall("nekzali", "normal", 1290679, nil).key == "pyre")
assert(Registry:MatchCall("nekzali", "mythic", 1293212, nil).key == "grasping")
assert(Registry:MatchCall("nekzali", "normal", 1287426, nil) == nil)
assert(Registry:MatchCall("nekzali", "normal", 1292036, nil) == nil)
assert(Registry:MatchCall("nekzali", "normal", 1285681, nil) == nil)
assert(Registry:MatchCall("nekzali", "mythic", 1299673, nil) == nil)

for _, difficulty in ipairs(difficulties) do
    local sent = Registry:GetProfile("sentinels", difficulty)
    local sentPlan = plan("sentinels", difficulty)
    assert(sent.callsByKey.coagulation and sent.callsByKey.coagulation.warning == "GREEN TEAM > KILL ADD")
    assert(sent.callsByKey.coagulation.timing == false,
        "Coagulation must stay manual because BigWigs publishes both the parent bar and a same-key add-spawn follow-up")
    assert(sent.callsByKey.droplets == nil,
        "Toxic Droplets already has a bossmod help-soak warning; RLA should teach it in the plan without duplicating the live call")
    assert(sent.callsByKey.miasma and sent.callsByKey.miasma.warning == "RED TEAM > SOAK TARGET")
    assert(sent.callsByKey.miasma.prepareSeconds == 5 and sent.callsByKey.miasma.pressSeconds == 1)
    assert(sent.callsByKey.stasis and sent.callsByKey.stasis.warning == "MATCH TO 4 > 1+3 OR 2+2")
    assert(sent.callsByKey.stasis.prepareSeconds == 6 and sent.callsByKey.stasis.pressSeconds == 2)
    assert(sent.callsByKey.side_swap and sent.callsByKey.side_swap.timing == false)
    assert(sent.callsByKey.balance and sent.callsByKey.balance.warning == "KEEP HP EVEN > STOP LOWER HP BOSS")

    assert(contains(sentPlan, "GREEN TEAM/BREATH") and contains(sentPlan, "RED TEAM/BLOOD"),
        "Sentinels plan must use roster-scalable team identities")
    assert(not contains(sentPlan, "GROUPS 1+2 GO GREEN") and not contains(sentPlan, "GROUPS 3+4 GO RED"),
        "Sentinels flex plan must not hard-code a 20-player raid split")
    assert(sent.callsByKey.living == nil, "Returning venom is a personal dodge and must stay bossmod-owned")
    assert(sent.callsByKey.bloodvenom == nil, "Heroic pool placement is personal and must stay bossmod-owned")
    assert(sent.callsByKey.blood == nil, "Blighted Blood dispels are healer/bossmod-owned, not an RLA button")
    assert(sent.callsByKey.tankswap == nil)
    assert(not contains(sentPlan, "TANK"), "Sentinels raid plan must remain tank-call free")
end

assert(Registry:GetProfile("sentinels", "normal").callsByKey.protovenom == nil)
assert(Registry:GetProfile("sentinels", "heroic").callsByKey.protovenom == nil)
local proto = Registry:GetProfile("sentinels", "mythic").callsByKey.protovenom
assert(proto and proto.warning == "PROTOVENOM > MARKED + MARKED")
assert(proto.prepareSeconds == 7 and proto.pressSeconds == 4)

assert(Registry:MatchCall("sentinels", "normal", 1284251, nil) == nil)
assert(Registry:MatchCall("sentinels", "normal", 1284434, nil) == nil)
assert(Registry:MatchCall("sentinels", "normal", 1288232, nil).key == "miasma")
assert(Registry:MatchCall("sentinels", "normal", 1284588, nil).key == "stasis")
assert(Registry:MatchCall("sentinels", "normal", 1284483, nil) == nil)
assert(Registry:MatchCall("sentinels", "mythic", 1296878, nil).key == "protovenom")

print("ok - boss 1/2 use raidleader-only calls with source-backed timers and flex-safe Sentinels teams")
