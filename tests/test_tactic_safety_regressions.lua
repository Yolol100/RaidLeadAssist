local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
_G.issecretvalue = function() return false end
T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
for _, file in ipairs({"Explorers.lua","Sszorak.lua","TwinFangs.lua","CoiledAltar.lua","Ulatek.lua","Sentinels.lua","Vashnik.lua"}) do T.Load("Encounters/VenomousAbyss/"..file,ns) end
local R=ns:GetModule("Encounters.Registry")
local function text(k,d) return table.concat(R:GetProfile(k,d).explanation,"\n") end

assert(R:GetProfile("twinfangs","normal").callsByKey.feast.warning == "FEAST > FRESH 3+ SOAKERS EACH HIT")
assert(text("twinfangs","normal"):find("at least 3 fresh players",1,true))
for _,d in ipairs({"heroic","mythic"}) do assert(R:GetProfile("twinfangs",d).callsByKey.feast.warning == "FEAST > TEAM A > TEAM B > TEAM C") end

assert(text("altar","normal"):find("Green poison orb on you",1,true))
assert(text("altar","heroic"):find("Guillotine gives a repeat-hit debuff",1,true))
assert(R:GetProfile("altar","normal").callsByKey.intermission.warning:find("BLOODLUST",1,true))
assert(not R:GetProfile("altar","normal").callsByKey.final.warning:find("BLOODLUST",1,true))

for _,d in ipairs({"normal","heroic","mythic"}) do
    assert(R:GetProfile("sentinels",d).callsByKey.side_swap.warning == "GROUPS HOLD SIDES > BOSSES SWAP")
    assert(R:GetProfile("sszorak",d).callsByKey.maelstrom.warning:find("POPPERS 1/2/3",1,true))
end
for _,d in ipairs({"heroic","mythic"}) do assert(R:GetProfile("vashnik",d).callsByKey.catalyst.warning == "BILE > SOAK EVERY GREEN CIRCLE") end
for _,d in ipairs({"normal","heroic","mythic"}) do for _,call in ipairs(R:GetProfile("ulatek",d).calls) do assert(call.timing==false) end end
assert(R:GetProfile("ulatek","heroic").callsByKey.coils.warning == "COILS > STACK AT SOAK MARK")
assert(R:GetProfile("ulatek","mythic").callsByKey.coils.warning == "COILS > NEXT SOAK GROUP IN")

print("ok - strategy regressions cover player plans, raidleader-owned rotations and conservative Ula'tek difficulty split")
