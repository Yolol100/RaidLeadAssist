local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
_G.issecretvalue = function() return false end
T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/TwinFangsAssignmentOverride.lua", ns)
T.Load("Encounters/VenomousAbyss/TwinFangs.lua", ns)
local Registry = ns:GetModule("Encounters.Registry")
local AR = ns:GetModule("Encounters.AssignmentRegistry")

assert(Registry:GetProfile("twinfangs", "normal") == nil)
local heroic = Registry:GetProfile("twinfangs", "heroic")
assert(table.concat(heroic.explanation, "\n") == table.concat({
    "FEAST = 3 FRESH GROUPS — ONE HIT EACH",
    "NO ONE SOAKS TWO FEAST HITS",
}, "\n"))
assert(#heroic.calls == 8)
local expected = {
    "SOAK ALL GLOBULES — ONE PLAYER EACH",
    "KILL ADDS — LINES AWAY FROM RAID",
    "RED CIRCLES — EDGE",
    "WAVES — DODGE",
    "FEAST 1 — GROUP 1 SOAK",
    "FEAST 2 — GROUP 2 SOAK",
    "FEAST 3 — GROUP 3 SOAK",
    "ROTATING BEAM — CROSS EARLY, STAY BEHIND",
}
for index = 1, #expected do assert(heroic.calls[index].warning == expected[index]) end
assert(heroic.callsByKey.feast1.spellIDs[1] == 1290516)
assert(heroic.callsByKey.feast1.sequenceKey == "feast")
assert(table.concat(heroic.callsByKey.feast1.sequenceKeys, ",") == "feast1,feast2,feast3")
assert(heroic.callsByKey.feast1.warningTemplate:find("feast_heroic_a", 1, true))
assert(heroic.callsByKey.feast2.warningTemplate:find("feast_heroic_b", 1, true))
assert(heroic.callsByKey.feast3.warningTemplate:find("feast_heroic_c", 1, true))
assert(heroic.callsByKey.beam.spellIDs[1] == 1294293)

local heroicDefs = AR:GetDefinitions("twinfangs", "heroic")
assert(#heroicDefs == 3, "Heroic must expose three fresh Feast teams")
for index = 1, 3 do
    local definition = heroicDefs[index]
    assert(definition.required and definition.compactGroups)
    assert(definition.exclusiveGroup == "heroic_feast")
    assert(definition.minPlayers == 3 and definition.minRaidFraction == 0.30)
    assert(definition.callKey == "feast" .. tostring(index))
end

local mythicDefs = AR:GetDefinitions("twinfangs", "mythic")
assert(#mythicDefs == 6, "Mythic retains three Feast teams and three Broodling interrupt slots")
assert(Registry:GetProfile("twinfangs", "mythic").callsByKey.feast)
print("ok - Twin Fangs Heroic uses three fresh assigned Feast groups and Mythic stays separate")
