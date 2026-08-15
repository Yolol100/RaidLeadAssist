local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local now = 500
local call = { key = "kick" }

_G.GetTime = function() return now end
_G.C_Timer = { After = function(_, callback) callback() end }
_G.CreateFrame = function() return T.Frame() end
_G.C_AddOns = nil
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

local serial = 0
local function start(source, duration, count)
    serial = serial + 1
    local id = source:lower() .. "-" .. tostring(serial)
    Timeline:ProviderTimerStarted(source, id, {
        key = 123,
        duration = duration,
        count = count,
        precision = source == "Blizzard" and "native" or "exact",
    })
    return Timeline.timers[source .. "|" .. id]
end

local bwSame = start("BigWigs", 10, 3)
now = now + 0.1
local dbmSame = start("DBM", 9.9, 3)
assert(bwSame.occurrenceID == dbmSame.occurrenceID,
    "matching counts should keep normal cross-provider deduplication")

Timeline:Reset()
now = now + 20

local bwDifferent = start("BigWigs", 5, 3)
now = now + 0.1
local dbmDifferent = start("DBM", 5, 4)
assert(bwDifferent.occurrenceID ~= dbmDifferent.occurrenceID,
    "different counts must remain separate occurrences")
assert(Timeline:AcknowledgeCall("kick") == true)
assert(bwDifferent.acknowledged == true)
assert(dbmDifferent.acknowledged ~= true,
    "acknowledging one count must not acknowledge an adjacent different count")

Timeline:Reset()
now = now + 20

local bwUncounted = start("BigWigs", 10, nil)
now = now + 0.1
local dbmUncounted = start("DBM", 9.9, nil)
assert(bwUncounted.occurrenceID == dbmUncounted.occurrenceID,
    "missing count metadata must preserve previous fallback behavior")

Timeline:Reset()
now = now + 20

Timeline:ProviderTimerStarted("BigWigs", "same-source", {
    key = 123, duration = 10, count = 1, precision = "exact",
})
local firstOccurrence = Timeline.timers["BigWigs|same-source"].occurrenceID
now = now + 0.1
Timeline:ProviderTimerStarted("BigWigs", "same-source", {
    key = 123, duration = 10, count = 2, precision = "exact",
})
assert(Timeline.timers["BigWigs|same-source"].occurrenceID ~= firstOccurrence,
    "same source ID with a new explicit count must become a new occurrence")

print("ok - occurrence counts refine existing timer correlation")
