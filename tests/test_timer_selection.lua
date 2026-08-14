local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local now = 100
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
local function p()
    return { IsAvailable = function() return true end, Start = function() return true end, Stop = function() end }
end
ns:RegisterModule("Services.Providers.BigWigs", p())
ns:RegisterModule("Services.Providers.DBM", p())
ns:RegisterModule("Services.Providers.Blizzard", p())
T.Load("Core/Util.lua", ns)
T.Load("Services/TimelineService.lua", ns)
local Timeline = ns:GetModule("Services.TimelineService")
Timeline:Initialize()
Timeline:SetEncounter("boss")

-- Approximate BigWigs data can preview an occurrence, but cannot drive a button.
Timeline:ProviderTimerStarted("BigWigs", "approx-1", {
    key = 123, duration = 10, precision = "approximate",
})
local preview = Timeline:GetTimerForCall("kick")
assert(preview and preview.providerName == "BigWigs" and preview.precision == "approximate")
assert(Timeline:GetActionableTimerForCall("kick") == nil)

-- An exact source for the same occurrence must beat the approximate source.
now = 100.1
Timeline:ProviderTimerStarted("DBM", "exact-1", {
    key = 123, duration = 9.9, precision = "exact",
})
local best = Timeline:GetTimerForCall("kick")
local actionable = Timeline:GetActionableTimerForCall("kick")
assert(best and best.providerName == "DBM")
assert(actionable and actionable.providerName == "DBM")
assert(Timeline:AcknowledgeCall("kick") == true)
assert(Timeline:GetTimerForCall("kick") == nil)

-- Providers that disagree by several seconds still represent one occurrence.
Timeline:Reset()
now = 200
Timeline:ProviderTimerStarted("Blizzard", "b2", {
    key = 123, duration = 12, nativeEventID = 88, precision = "native",
})
now = 200.1
Timeline:ProviderTimerStarted("DBM", "d2", {
    key = 123, duration = 7.6, precision = "exact",
})
local blizzard = Timeline.timers["Blizzard|b2"]
local dbm = Timeline.timers["DBM|d2"]
assert(blizzard and dbm and blizzard.occurrenceID == dbm.occurrenceID,
    "cross-provider drift within tolerance must cluster as one occurrence")
assert(Timeline:GetActionableTimerForCall("kick").providerName == "DBM")
assert(Timeline:AcknowledgeCall("kick") == true)

-- Simulate those providers stopping, then a third provider arriving late.
Timeline:ProviderTimerStopped("Blizzard", "b2")
Timeline:ProviderTimerStopped("DBM", "d2")
now = 200.2
Timeline:ProviderTimerStarted("BigWigs", "late-2", {
    key = 123, duration = 11.4, precision = "exact",
})
assert(Timeline:GetTimerForCall("kick") == nil,
    "a late provider for an acknowledged occurrence must not re-arm the call")

print("ok - timer precision, selection, drift deduplication, and acknowledgement")
