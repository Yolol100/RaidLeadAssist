local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local SECRET = {}

_G.issecretvalue = function(value) return value == SECRET end
T.Load("Core/Util.lua", ns)
local Util = ns:GetModule("Core.Util")

assert(Util.Normalize("  |cffffffffTest Value|r  ") == "cfffffffftestvaluer", "Normalize should remain intentionally generic")
assert(Util.NormalizeTimerName("|cffffffff[B] Test Value (2)|r") == "testvalue", "timer normalization should remove WoW formatting and suffixes")
assert(Util.ToNumericID("123") == 123, "numeric strings should normalize")
assert(Util.ToNumericID(SECRET) == nil, "secret numeric identity must fail closed")
assert(Util.Normalize(SECRET) == nil, "secret text must fail closed")

RaidLeadAssistDB = {
    schemaVersion = 99,
    selectedBossKey = 123,
    audioEnabled = "yes",
    forceShown = "yes",
    customMessages = "invalid",
    position = { point = "INVALID", relativePoint = "CENTER", x = "0", y = 5 },
}

T.Load("Core/Database.lua", ns)
local Database = ns:GetModule("Core.Database")
Database:Initialize()
local data = Database:Get()

assert(Database:HasNewerSchema() == true, "newer settings schema must be detected")
assert(data.schemaVersion == 99, "newer schema marker must be preserved")
assert(data.selectedBossKey == "nekzali", "known fields from a newer schema should be normalized in the working copy")
assert(data.audioEnabled == true and data.forceShown == false, "invalid booleans should be normalized")
assert(type(data.customMessages) == "table", "invalid custom message storage should be normalized")
assert(data.position.point == "CENTER" and data.position.x == 0 and data.position.y == 40, "invalid position should reset safely")
assert(RaidLeadAssistDB.schemaVersion == 99 and RaidLeadAssistDB.selectedBossKey == 123, "newer persisted settings must not be rewritten by an older addon")

print("ok - util/database secret and newer-schema guards")
