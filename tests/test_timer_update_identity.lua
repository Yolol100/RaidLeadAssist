local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local now = 100
local call = { key = "kick" }

_G.GetTime = function() return now end
_G.C_Timer = { After = function(_, callback) callback() end }
_G.CreateFrame = function() return T.Frame() end
_G.table.wipe = _G.table.wipe or function(tbl) for key in pairs(tbl) do tbl[key] = nil end end
_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
ns:RegisterModule("Core.EventBus", { Emit = function() end })
ns:RegisterModule("Encounters.Registry", {
    MatchCall = function(_, encounterKey, key)
        if encounterKey == "boss" and key == 123 then return call end
    end,
})

local function provider()
    return {
        IsAvailable = function() return true end,
        Start = function() return true end,
        Stop = function() end,
    }
end
ns:RegisterModule("Services.Providers.BigWigs", provider())
ns:RegisterModule("Services.Providers.DBM", provider())
ns:RegisterModule("Services.Providers.Blizzard", provider())

T.Load("Services/TimelineService.lua", ns)
local Timeline = ns:GetModule("Services.TimelineService")
Timeline:Initialize()
Timeline:SetEncounter("boss")

Timeline:ProviderTimerStarted("DBM", "dbm-1", {
    key = 123,
    duration = 10,
    precision = "exact",
})
local timer = assert(Timeline.timers["DBM|dbm-1"])
local occurrenceID = assert(timer.occurrenceID)
local nextOccurrenceID = Timeline.nextOccurrenceID

now = 101
Timeline:ProviderTimerUpdated("DBM", "dbm-1", 1, 10)
assert(timer.occurrenceID == occurrenceID,
    "DBM_TimerUpdate must keep the same occurrence identity")
assert(Timeline.nextOccurrenceID == nextOccurrenceID,
    "timer updates must not allocate new occurrence IDs")

now = 102
Timeline:ProviderTimerUpdated("DBM", "dbm-1", 2, 10)
assert(timer.occurrenceID == occurrenceID,
    "repeated updates must not re-arm PREPARE/PRESS audio under a new identity")

assert(Timeline:AcknowledgeCall("kick") == true)
assert(timer.acknowledged == true)
now = 103
Timeline:ProviderTimerUpdated("DBM", "dbm-1", 3, 10)
assert(timer.acknowledged == true and Timeline:GetTimerForCall("kick") == nil,
    "updates to an acknowledged bar must not re-arm the call")

print("ok - timer update identity and acknowledgement stability")
