local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
_G.issecretvalue = function() return false end
T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/VenomousAbyss/Nekzali.lua", ns)
T.Load("Encounters/VenomousAbyss/Sentinels.lua", ns)
local Registry = ns:GetModule("Encounters.Registry")
local function text(key, difficulty) return table.concat(Registry:GetProfile(key, difficulty).explanation, "\n") end
local function has(value, needle) return value:find(needle, 1, true) ~= nil end
for _, difficulty in ipairs({"normal","heroic","mythic"}) do
    local sent = Registry:GetProfile("sentinels", difficulty)
    local plan = text("sentinels", difficulty)
    assert(sent.callsByKey.coagulation.warning == "BREATH SIDE > KILL ADD")
    assert(sent.callsByKey.miasma.warning == "BLOOD SIDE > SOAK TARGET")
    assert(sent.callsByKey.stasis.warning == "MATCH TO 4 > 1+3 OR 2+2")
    assert(sent.callsByKey.side_swap.warning == "GROUPS HOLD SIDES > BOSSES SWAP")
    assert(sent.callsByKey.side_swap.timing == false)
    assert(has(plan, "TEAM A HOLDS GREEN SIDE") and has(plan, "TEAM B HOLDS RED SIDE"))
    assert(has(plan, "GROUPS HOLD") and has(plan, "TAUNT-SWAP"))
    assert(not has(plan, "SWAP BOSS SIDES"), "raid groups must not be told to cross sides after Stasis")
    assert(has(plan, "BLOODLUST ON PULL"))
end
assert(Registry:GetProfile("sentinels","normal").callsByKey.protovenom == nil)
assert(Registry:GetProfile("sentinels","mythic").callsByKey.protovenom.warning == "PROTOVENOM > MARKED + MARKED")
for _, difficulty in ipairs({"normal","heroic","mythic"}) do
    local nek = Registry:GetProfile("nekzali", difficulty)
    assert(nek.callsByKey.adds.warning == "KILL ADS")
    assert(nek.callsByKey.phase2.warning == "PHASE 2 > BLOODLUST > BURN BOSS")
end
print("ok - boss 1/2 raidlead contract keeps Sentinels groups fixed while bosses swap after Stasis")
