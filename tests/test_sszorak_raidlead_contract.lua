local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
_G.issecretvalue = function() return false end
T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/VenomousAbyss/Sszorak.lua", ns)
local Registry = ns:GetModule("Encounters.Registry")
local function plan(d) return table.concat(Registry:GetProfile("sszorak",d).explanation,"\n") end
for _, d in ipairs({"normal","heroic","mythic"}) do
    local p = Registry:GetProfile("sszorak",d)
    assert(p.callsByKey.maelstrom.warning == "MAELSTROM > POPPERS 1/2/3 > KNOCK AGAINST EACH WIND")
    assert(plan(d):find("CYST POPPER",1,true))
    assert(plan(d):find("BLOODLUST ON PULL",1,true))
    assert(p.callsByKey.apex.warning == "GREEN MUTILATE > NEXT 5+ SOAK TEAM")
end
assert(Registry:GetProfile("sszorak","mythic").callsByKey.serpent.warning == "SERPENT'S FURY > 14+ STACK ON MARK")
print("ok - Sszorak raidlead calls include explicit three-popper Maelstrom ownership")
