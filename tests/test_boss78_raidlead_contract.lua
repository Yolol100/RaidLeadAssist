local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
_G.issecretvalue = function() return false end
T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/VenomousAbyss/CoiledAltar.lua", ns)
T.Load("Encounters/VenomousAbyss/Ulatek.lua", ns)
T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss78AssignmentOverride.lua", ns)
local Registry = ns:GetModule("Encounters.Registry")
local AR = ns:GetModule("Encounters.AssignmentRegistry")
for _, d in ipairs({"normal","heroic","mythic"}) do
    local altar = Registry:GetProfile("altar",d)
    assert(altar.callsByKey.sever == nil)
    assert(altar.callsByKey.intermission.warning:find("BLOODLUST",1,true))
    assert(altar.callsByKey.final.warning == "PHASE 3 > KEEP BOTH EVEN > KILL TOGETHER")
    local defs = AR:GetDefinitions("altar",d)
    assert(defs[1].key == "orb_collectors" and defs[1].minPlayers == 2 and defs[1].required)
    local ulatek = Registry:GetProfile("ulatek",d)
    for _, call in ipairs(ulatek.calls) do assert(call.timing == false) end
end
local h = AR:GetDefinitions("altar","heroic")
local requiredWail=0
for _,def in ipairs(h) do if def.key:find("wail_kick_",1,true) and def.required then requiredWail=requiredWail+1 end end
assert(requiredWail == 2)
print("ok - Coiled Altar uses intermission Bloodlust, orb collectors and Heroic Wail coverage; Ulatek remains manual")
