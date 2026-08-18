local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
_G.issecretvalue = function() return false end
T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/VenomousAbyss/Vashnik.lua", ns)
local Registry = ns:GetModule("Encounters.Registry")
local function plan(d) return table.concat(Registry:GetProfile("vashnik", d).explanation, "\n") end
for _, d in ipairs({"normal","heroic","mythic"}) do
    assert(plan(d):find("BLOODLUST ON PULL",1,true))
    assert(Registry:GetProfile("vashnik",d).callsByKey.imbibe.warning == "IMBIBE > KILL ADDS")
end
assert(Registry:GetProfile("vashnik","normal").callsByKey.catalyst == nil)
for _, d in ipairs({"heroic","mythic"}) do
    local catalyst = Registry:GetProfile("vashnik",d).callsByKey.catalyst
    assert(catalyst.warning == "BILE > SOAK EVERY GREEN CIRCLE")
    assert(plan(d):find("EACH IMPACT MUST HIT AT LEAST ONE PLAYER",1,true))
end
assert(plan("mythic"):find("NO FIXED BILE TEAM IS REQUIRED",1,true))
assert(Registry:GetProfile("vashnik","mythic").callsByKey.froth.warning == "FROTH > AIM WAVES THROUGH TUMORS")
print("ok - Vashnik uses dynamic Catalyst soaking with no fixed Bile-team assignment")
