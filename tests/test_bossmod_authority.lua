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
local fallbackCall = { key = "fallback" }
ns:RegisterModule("Encounters.Registry", {
    MatchCall = function(_, _, key, name)
        if key == 123 or name == "Mechanic" then return call end
        if key == 456 or name == "Fallback Mechanic" then return fallbackCall end
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
assert(Timeline.timers["Blizzard|native-1"] == nil, "native Blizzard duplicate must be removed when a direct bossmod timer exists")
assert(Timeline.timers["BigWigs|bridge-1"] == nil, "BigWigs Blizzard duplicate must be removed when a direct bossmod timer exists")
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

Timeline:ProviderTimerStarted("Blizzard", "native-fallback", {
    key = 456,
    name = "Fallback Mechanic",
    duration = 12,
    nativeEventID = 80,
    precision = "native",
})
assert(Timeline.timers["Blizzard|native-fallback"] ~= nil,
    "suppressed Blizzard timing must remain available for an RLA call with no direct bossmod timer")

Timeline:ProviderTimerStarted("Blizzard", "native-unknown", {
    key = 999,
    name = "Unknown Mechanic",
    duration = 12,
    nativeEventID = 81,
    precision = "native",
})
assert(Timeline.timers["Blizzard|native-unknown"] == nil,
    "suppression must not reopen unrelated Blizzard timeline events")

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

assert(Timeline:SetBlizzardSuppressedByProvider("DBM", true) == true)
assert(Timeline.timers["Blizzard|native-3"] == nil,
    "restored suppression must still remove native duplicates covered by direct bossmods")
assert(Timeline.timers["Blizzard|native-fallback"] ~= nil,
    "a pre-existing required fallback must survive suppression when no direct timer covers its call")

Timeline:ProviderTimerStarted("BigWigs", "direct-fallback", {
    key = 456,
    name = "Fallback Mechanic",
    duration = 12,
    precision = "exact",
})
local selected = Timeline:GetTimerForCall("fallback")
assert(selected and selected.providerName == "BigWigs",
    "a direct bossmod timer must outrank a retained native fallback for the same occurrence")

assert(Timeline:ProviderEncounterHint("DBM", 3421) == true)
local hint = emitted[#emitted]
assert(hint.name == "PROVIDER_ENCOUNTER_HINT" and hint.args[1] == "DBM" and hint.args[2] == 3421)

print("ok - DBM authority suppresses duplicates while preserving only missing-call Blizzard fallbacks")
