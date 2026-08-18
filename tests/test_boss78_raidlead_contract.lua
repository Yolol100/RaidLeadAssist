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
    assert(altar.callsByKey.intermission.warning:find("Bloodlust",1,true))
    assert(altar.callsByKey.final.warning == "Final phase: keep both bosses even and kill together.")
    local defs = AR:GetDefinitions("altar",d)
    assert(defs[1].key == "orb_collectors" and defs[1].minPlayers == 2 and defs[1].required)
    local ulatek = Registry:GetProfile("ulatek",d)
    for _, call in ipairs(ulatek.calls) do assert(call.timing == false) end
end
local h = AR:GetDefinitions("altar","heroic")
local requiredWail=0
for _,def in ipairs(h) do if def.key:find("wail_kick_",1,true) and def.required then requiredWail=requiredWail+1 end end
assert(requiredWail == 2)

local uh = AR:GetDefinitions("ulatek","heroic")
assert(#uh == 1 and uh[1].key == "egg_handler", "Heroic Ula'tek keeps only the Normal egg-handler assignment")
local um = AR:GetDefinitions("ulatek","mythic")
local found = {}
for _,def in ipairs(um) do found[def.key] = true end
assert(found.coil_a and found.coil_b and found.egg_left and found.egg_right and found.incubation_team,
    "Mythic Ula'tek adds Coil rotation, egg carriers and Incubation team")
assert(Registry:GetProfile("ulatek","normal").callsByKey.demolish,
    "Ula'tek phase-3 shared movement uses the corrected Demolish identity")

print("ok - Coiled Altar prep remains complete and final shared calls stay concise")
