local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Core/EventBus.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss12AssignmentOverride.lua", ns)
T.Load("Encounters/VenomousAbyss/Nekzali.lua", ns)
T.Load("Services/AssignmentService.lua", ns)

local Assignments = ns:GetModule("Services.AssignmentService")
local database = { assignments = {} }
Assignments:Initialize(database)

local ok, reason = Assignments:ValidateBossDraft("nekzali", "normal", {})
assert(ok == false and reason.message == "Unknown boss or difficulty.",
    "retired Normal assignment drafts must fail closed")
ok, reason = Assignments:ApplyBossDraft("nekzali", "normal", {})
assert(ok == false and reason.message == "Unknown boss or difficulty.",
    "retired Normal assignments must never be persisted")
assert(database.assignments.nekzali == nil,
    "failed Normal assignment write must leave storage untouched")

ok, reason = Assignments:ValidateBossDraft("missing-boss", "heroic", {})
assert(ok == false and reason.message == "Unknown boss or difficulty.",
    "unknown encounter assignment drafts must fail closed")

ok = Assignments:ValidateBossDraft("nekzali", "heroic", {})
assert(ok == true, "supported Heroic profile must remain valid")

print("ok - assignment service accepts only registered Heroic/Mythic profiles")
