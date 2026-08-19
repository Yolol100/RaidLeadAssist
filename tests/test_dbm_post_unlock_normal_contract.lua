local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/VenomousAbyss/Nekzali.lua", ns)
T.Load("Encounters/VenomousAbyss/TwinFangs.lua", ns)

local Registry = ns:GetModule("Encounters.Registry")

local function hasID(call, wanted)
    for _, id in ipairs(call.spellIDs or {}) do
        if id == wanted then return true end
    end
    return call.iconSpellID == wanted
end

local nekzali = Registry:GetProfile("nekzali", "normal")
assert(nekzali.callsByKey.adds.timing ~= false and hasID(nekzali.callsByKey.adds, 1297630),
    "Normal Nek'zali Amani must remain eligible for DBM's post-unlock hardcoded bar")
assert(nekzali.callsByKey.pyre.timing ~= false and hasID(nekzali.callsByKey.pyre, 1290679),
    "Normal Nek'zali Pyre must remain eligible for DBM's post-unlock hardcoded bar")

local twin = Registry:GetProfile("twinfangs", "normal")
assert(twin.callsByKey.globules.timing ~= false and hasID(twin.callsByKey.globules, 1289192),
    "Normal Twin Fangs Caustic Deluge must remain eligible for DBM's post-unlock hardcoded bar")
assert(twin.callsByKey.feast.timing ~= false and hasID(twin.callsByKey.feast, 1290516),
    "Normal Twin Fangs Feast must remain eligible for DBM's post-unlock hardcoded bar")
assert(twin.callsByKey.energy.timing ~= false and hasID(twin.callsByKey.energy, 1306872),
    "Normal Twin Fangs shared movement call must retain its current DBM timer identity")

print("ok - post-unlock DBM Normal hardcoded timer identities remain compatible")
