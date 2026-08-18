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
local function has(text, needle) return text:find(needle,1,true) ~= nil end

local normal = Registry:GetProfile("twinfangs","normal")
assert(normal.callsByKey.feast.warning == "FEAST > FRESH 3+ SOAKERS EACH HIT")
assert(#AR:GetDefinitions("twinfangs","normal") == 0,
    "Normal may resolve fresh Feast soakers dynamically without a fixed roster")
assert(has(plan("normal"), "at least 3 fresh players soak each hit"))
assert(has(plan("normal"), "After you soak one Feast hit, stay out"))

for _, d in ipairs({"heroic","mythic"}) do
    local p = Registry:GetProfile("twinfangs",d)
    assert(p.callsByKey.feast.warning == "FEAST > TEAM A > TEAM B > TEAM C")
    local defs = AR:GetDefinitions("twinfangs",d)
    assert(#defs >= 3)
    for i=1,3 do assert(defs[i].minPlayers == 3 and defs[i].required and defs[i].exclusiveGroup == "feast") end
end
assert(has(plan("heroic"), "Team A, B or C"))
assert(not has(plan("heroic"), "Keep both bosses"), "Heroic briefing should only describe changes from Normal")
assert(has(plan("mythic"), "Blood founts"))
assert(has(plan("mythic"), "Protected Gestation"))
assert(has(plan("mythic"), "Visceral Burst"))
assert(not has(plan("mythic"), "Team A, B or C"), "Mythic briefing should only describe changes from Heroic")

for _, d in ipairs({"normal","heroic","mythic"}) do
    local p = Registry:GetProfile("twinfangs",d)
    assert(p.callsByKey.stone == nil, "tank Stone Breaker execution remains bossmod/role-owned")
    assert(p.callsByKey.energy.warning == "100 ENERGY > MOVE TO ITHRAZ > DODGE FLOOD/STORM")
    assert(#p.callsByKey.energy.spellIDs == 1 and p.callsByKey.energy.spellIDs[1] == 1306872)
end

print("ok - Twin Fangs uses fresh Feast soakers on Normal and explicit Heroic/Mythic deltas")
