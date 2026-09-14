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
    "SOAK 1 = RAID — TANKS OUT",
    "SOAK 2 = MAIN TANK SOLO",
    "SOAK 3 = OFF TANK SOLO",
}, "\n"))
assert(#heroic.calls == 8)
local expected = {
    "SOAK ALL GLOBULES — ONE PLAYER EACH",
    "KILL ADDS — LINES AWAY FROM RAID",
    "RED CIRCLES — EDGE",
    "WAVES — DODGE",
    "FEAST 1 — RAID SOAK, TANKS OUT",
    "FEAST 2 — MAIN TANK SOLO",
    "FEAST 3 — OFF TANK SOLO",
    "ROTATING BEAM — CROSS EARLY, STAY BEHIND",
}
for index = 1, #expected do assert(heroic.calls[index].warning == expected[index]) end
assert(heroic.callsByKey.feast1.spellIDs[1] == 1290516)
assert(heroic.callsByKey.feast1.sequenceKey == "feast")
assert(table.concat(heroic.callsByKey.feast1.sequenceKeys, ",") == "feast1,feast2,feast3")
assert(heroic.callsByKey.beam.spellIDs[1] == 1294293)
assert(#AR:GetDefinitions("twinfangs", "heroic") == 0,
    "Heroic custom raid/MT/OT plan must not expose obsolete editable Feast teams")
local mythicDefs = AR:GetDefinitions("twinfangs", "mythic")
assert(#mythicDefs == 6, "Mythic retains three Feast teams and three Broodling interrupt slots")
assert(Registry:GetProfile("twinfangs", "mythic").callsByKey.feast)
print("ok - Twin Fangs Heroic uses the exact custom eight-call raid/MT/OT contract and Mythic stays separate")
