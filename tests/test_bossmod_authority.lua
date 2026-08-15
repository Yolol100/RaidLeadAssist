local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local now = 100
local emitted = {}
local seedCount = 0

_G.GetTime = function() return now end
_G.issecretvalue = function() return false end
_G.table.wipe = _G.table.wipe or function(tbl) for key in pairs(tbl) do tbl[key] = nil end end
_G.C_AddOns = nil

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
ns:RegisterModule("Core.EventBus", {
    Emit = function(_, name, ...)
        emitted[#emitted + 1] = { name = name, args = { ... } }
    end,
})
local call = { key = "mechanic" }
ns:RegisterModule("Encounters.Registry", {
    MatchCall = function(_, _, key, name)
        if key == 123 or name == "Mechanic" then return call end
    end,
})
ns:RegisterModule("Services.Providers.BigWigs", {})
ns:RegisterModule("Services.Providers.DBM", {})
ns:RegisterModule("Services.Providers.Blizzard", {
    SeedExistingEvents = function() seedCount = seedCount + 1 end,
})

T.Load("Services/TimelineService.lua", ns)
local Timeline = ns:GetModule("Services.TimelineService")
Timeline.activeProviders.BigWigs = ns:GetModule("Services.Providers.BigWigs")
Timeline.activeProviders.DBM = ns:GetModule("Services.Providers.DBM")
Timeline.activeProviders.Blizzard = ns:GetModule("Services.Providers.Blizzard")
Timeline:SetEncounter("boss")
seedCount = 0

Timeline:ProviderTimerStarted("Blizzard", "native-1", {
    key = 123,
    name = "Mechanic",
    duration = 10,
    nativeEventID = 77,
    precision = "native",
})
Timeline:ProviderTimerStarted("BigWigs", "bridge-1", {
    name = "Mechanic",
    duration = 10,
    nativeEventID = 77,
    bridge = "Blizzard",
    precision = "native",
})
Timeline:ProviderTimerStarted("DBM", "dbm-1", {
    key = 123,
    name = "Mechanic",
    duration = 10,
    precision = "exact",
})
assert(Timeline.timers["Blizzard|native-1"])
assert(Timeline.timers["BigWigs|bridge-1"])
assert(Timeline.timers["DBM|dbm-1"])

assert(Timeline:SetBlizzardSuppressedByProvider("DBM", true) == true)
assert(Timeline:IsBlizzardSuppressed() == true)
assert(Timeline.timers["Blizzard|native-1"] == nil, "native Blizzard timer must be removed when DBM takes authority")
assert(Timeline.timers["BigWigs|bridge-1"] == nil, "BigWigs Blizzard bridge must be removed with the native source")
assert(Timeline.timers["DBM|dbm-1"] ~= nil, "direct DBM timer must survive Blizzard suppression")

Timeline:ProviderTimerStarted("Blizzard", "native-2", {
    key = 123,
    name = "Mechanic",
    duration = 9,
    nativeEventID = 78,
    precision = "native",
})
Timeline:ProviderTimerStarted("BigWigs", "bridge-2", {
    name = "Mechanic",
    duration = 9,
    nativeEventID = 78,
    bridge = "Blizzard",
    precision = "native",
})
Timeline:ProviderTimerStarted("BigWigs", "direct-1", {
    key = 123,
    name = "Mechanic",
    duration = 9,
    precision = "exact",
})
assert(Timeline.timers["Blizzard|native-2"] == nil)
assert(Timeline.timers["BigWigs|bridge-2"] == nil)
assert(Timeline.timers["BigWigs|direct-1"] ~= nil, "direct BigWigs module timers remain valid while DBM suppresses Blizzard")

assert(Timeline:SetBlizzardSuppressedByProvider("DBM", false) == true)
assert(Timeline:IsBlizzardSuppressed() == false)
assert(seedCount == 1, "resuming Blizzard authority must reseed currently active native events")

Timeline:ProviderTimerStarted("Blizzard", "native-3", {
    key = 123,
    name = "Mechanic",
    duration = 8,
    nativeEventID = 79,
    precision = "native",
})
assert(Timeline.timers["Blizzard|native-3"] ~= nil)

assert(Timeline:ProviderEncounterHint("DBM", 3421) == true)
local hint = emitted[#emitted]
assert(hint.name == "PROVIDER_ENCOUNTER_HINT" and hint.args[1] == "DBM" and hint.args[2] == 3421)

print("ok - DBM authority suppresses only Blizzard-derived timer representations")
