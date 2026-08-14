local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local now = 300
local call = { key = "kick" }

_G.GetTime = function() return now end
_G.C_Timer = { After = function(_, cb) cb() end }
_G.CreateFrame = function() return T.Frame() end
_G.table.wipe = _G.table.wipe or function(t) for k in pairs(t) do t[k] = nil end end
_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
ns:RegisterModule("Core.EventBus", { Emit = function() end })
ns:RegisterModule("Encounters.Registry", {
    MatchCall = function(_, encounterKey, key)
        if encounterKey == "boss" and key == 123 then return call end
    end,
})
local function provider()
    return { IsAvailable = function() return true end, Start = function() return true end, Stop = function() end }
end
ns:RegisterModule("Services.Providers.BigWigs", provider())
ns:RegisterModule("Services.Providers.DBM", provider())
ns:RegisterModule("Services.Providers.Blizzard", provider())
T.Load("Core/Util.lua", ns)
T.Load("Services/TimelineService.lua", ns)

local Timeline = ns:GetModule("Services.TimelineService")
Timeline:Initialize()
Timeline:SetEncounter("boss")

-- Blizzard and BigWigs' Blizzard-timeline bridge are two views of the same
-- native encounter event. Native identity must cluster them even when callback
-- timing is slightly different.
Timeline:ProviderTimerStarted("Blizzard", "native-900", {
    key = 123,
    duration = 12,
    nativeEventID = 900,
    precision = "native",
})
now = 300.2
Timeline:ProviderTimerStarted("BigWigs", "blizzard-timeline|event:900", {
    key = 123,
    duration = 11.8,
    nativeEventID = 900,
    bridge = "Blizzard",
    precision = "native",
})

local native = Timeline.timers["Blizzard|native-900"]
local bridge = Timeline.timers["BigWigs|blizzard-timeline|event:900"]
assert(native and bridge and native.occurrenceID == bridge.occurrenceID,
    "Blizzard and the BigWigs timeline bridge must share one occurrence")

-- A real BigWigs boss-module bar for that mechanic should join the occurrence
-- by bounded end-time reconciliation and remain the preferred bossmod source.
now = 300.3
Timeline:ProviderTimerStarted("BigWigs", "Boss|event:901", {
    key = 123,
    duration = 11.7,
    nativeEventID = 901,
    precision = "exact",
})
local bossmod = Timeline.timers["BigWigs|Boss|event:901"]
assert(bossmod and bossmod.occurrenceID == native.occurrenceID,
    "boss-module and native timers for one mechanic must reconcile")
assert(Timeline:GetActionableTimerForCall("kick").id == bossmod.id,
    "a real BigWigs boss-module timer should beat its mirrored Blizzard bridge")

-- Acknowledgement must fan out to every representation so removing one source
-- cannot re-arm the same raid-leader call from another source.
assert(Timeline:AcknowledgeCall("kick") == true)
assert(native.acknowledged and bridge.acknowledged and bossmod.acknowledged,
    "all representations of an acknowledged occurrence must be suppressed")
Timeline:ProviderTimerStopped("BigWigs", "Boss|event:901")
assert(Timeline:GetTimerForCall("kick") == nil,
    "removing the preferred source must not expose an already acknowledged mirror")

-- A late DBM representation inside the acknowledgement window must also stay
-- suppressed after the original providers disappear.
Timeline:ProviderTimerStopped("Blizzard", "native-900")
Timeline:ProviderTimerStopped("BigWigs", "blizzard-timeline|event:900")
now = 300.5
Timeline:ProviderTimerStarted("DBM", "dbm-late", {
    key = 123,
    duration = 11.5,
    precision = "exact",
})
assert(Timeline:GetTimerForCall("kick") == nil,
    "a late DBM timer must not re-arm an acknowledged cross-provider occurrence")

print("ok - Blizzard, BigWigs bridge, BigWigs boss bars, and DBM interoperate")
