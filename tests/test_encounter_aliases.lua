local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/VenomousAbyss/CoiledAltar.lua", ns)

local Registry = ns:GetModule("Encounters.Registry")
local byID = Registry:FindByEncounterID(3429)
assert(byID and byID.key == "altar")
assert(Registry:FindByEncounterName("The Coiled Altar") == byID)
assert(Registry:FindByEncounterName("The Bargained Crown") == byID,
    "BigWigs v419.2 encounter name must resolve to the Coiled Altar profile")
assert(Registry:FindByEncounterName("the-bargained crown") == byID,
    "encounter name fallback should retain normalization semantics")

print("ok - encounter aliases cover BigWigs v419.2 naming")
