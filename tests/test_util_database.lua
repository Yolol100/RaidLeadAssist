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
    selectedDifficultyKey = "impossible",
    audioEnabled = "yes",
    automaticTimingEnabled = "yes",
    forceShown = "yes",
    customMessages = "invalid",
    assignments = "invalid",
    position = { point = "INVALID", relativePoint = "CENTER", x = "0", y = 5 },
}

T.Load("Core/Database.lua", ns)
local Database = ns:GetModule("Core.Database")
Database:Initialize()
local data = Database:Get()

assert(Database:HasNewerSchema() == true, "newer settings schema must be detected")
assert(data.schemaVersion == 99, "newer schema marker must be preserved")
assert(data.selectedBossKey == "nekzali", "known fields from a newer schema should be normalized in the working copy")
assert(data.selectedDifficultyKey == "heroic", "invalid difficulty should fail back to Heroic")
assert(data.audioEnabled == true and data.automaticTimingEnabled == true and data.forceShown == false,
    "invalid booleans should be normalized")
assert(type(data.customMessages) == "table", "invalid custom message storage should be normalized")
assert(type(data.assignments) == "table", "invalid assignment storage should be normalized")
assert(data.position.point == "CENTER" and data.position.x == 0 and data.position.y == 40, "invalid position should reset safely")
assert(RaidLeadAssistDB.schemaVersion == 99 and RaidLeadAssistDB.selectedBossKey == 123,
    "newer persisted settings must not be rewritten by an older addon")

RaidLeadAssistDB = {
    schemaVersion = 5,
    position = { point = "CENTER", relativePoint = "CENTER", x = 0 / 0, y = math.huge },
}
Database:Initialize()
data = Database:Get()
assert(data.position.point == "CENTER" and data.position.x == 0 and data.position.y == 40,
    "non-finite saved frame coordinates must fail closed to the default position")

RaidLeadAssistDB = {
    schemaVersion = 2,
    selectedBossKey = "nekzali",
    customMessages = {
        nekzali = {
            explanation = { "OLD HEROIC PLAN" },
            calls = { adds = "OLD HEROIC CALL" },
        },
    },
}
Database:Initialize()
data = Database:Get()
assert(data.schemaVersion == 5, "v2 settings should migrate to schema 5")
assert(data.selectedDifficultyKey == "heroic", "v2 settings should default to Heroic")
assert(data.automaticTimingEnabled == true, "older settings should default automatic timing on")
assert(data.customMessages.nekzali.heroic.explanation[1] == "OLD HEROIC PLAN", "old explanation should migrate under Heroic")
assert(data.customMessages.nekzali.heroic.calls.adds == "OLD HEROIC CALL", "old call should migrate under Heroic")
assert(data.customMessages.nekzali.normal == nil and data.customMessages.nekzali.mythic == nil, "old Heroic overrides must not leak to other difficulties")
assert(type(data.assignments) == "table" and next(data.assignments) == nil, "older settings should gain empty assignment storage")

RaidLeadAssistDB = {
    schemaVersion = 4,
    automaticTimingEnabled = false,
}
Database:Initialize()
data = Database:Get()
assert(data.schemaVersion == 5 and data.automaticTimingEnabled == false,
    "schema 4 must preserve an explicit timing preference while migrating to schema 5")

print("ok - util/database secret, schema, difficulty, assignment, timing, and finite-position guards")
