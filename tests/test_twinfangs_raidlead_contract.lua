local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
_G.issecretvalue = function() return false end
T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/TwinFangsAssignmentOverride.lua", ns)
T.Load("Services/AssignmentService.lua", ns)
T.Load("Encounters/VenomousAbyss/TwinFangs.lua", ns)
local Registry = ns:GetModule("Encounters.Registry")
local AR = ns:GetModule("Encounters.AssignmentRegistry")
local Assignments = ns:GetModule("Services.AssignmentService")
Assignments:Initialize({ assignments = {} })
local function plan(d) return table.concat(Registry:GetProfile("twinfangs",d).explanation,"\n") end
local normal = Registry:GetProfile("twinfangs","normal")
assert(normal.callsByKey.feast.warning == "FEAST > RAID SOAK ALL 3 HITS")
assert(#AR:GetDefinitions("twinfangs","normal") == 0)
assert(plan("normal"):find("NORMAL DOES NOT NEED THE HEROIC THREE-GROUP SPLIT",1,true))
for _, d in ipairs({"heroic","mythic"}) do
    local p = Registry:GetProfile("twinfangs",d)
    assert(p.callsByKey.feast.warning == "FEAST > TEAM A > TEAM B > TEAM C")
    local defs = AR:GetDefinitions("twinfangs",d)
    assert(#defs >= 3)
    for i=1,3 do assert(defs[i].minPlayers == 3 and defs[i].required and defs[i].exclusiveGroup == "feast") end
end
for _, d in ipairs({"normal","heroic","mythic"}) do
    local p = Registry:GetProfile("twinfangs",d)
    assert(p.callsByKey.stone == nil)
    assert(p.callsByKey.energy.warning == "100 ENERGY > MOVE TO ITHRAZ > DODGE FLOOD/STORM")
    assert(#p.callsByKey.energy.spellIDs == 1 and p.callsByKey.energy.spellIDs[1] == 1306872)
    assert(plan(d):find("TANK SOAKS ALL THREE MARKED IMPACTS",1,true))
    assert(plan(d):find("REGROUP WHEN THE BOSSES RETURN",1,true))
end
print("ok - Twin Fangs uses Normal raid-soak Feast, Heroic/Mythic fresh teams, tank Stone Breaker set and single energy anchor")
