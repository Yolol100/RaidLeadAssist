local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local now = 100
local SECRET = {}
local emitted = {}

_G.GetTime = function() return now end
_G.issecretvalue = function(value) return value == SECRET end
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
ns:RegisterModule("Services.Providers.Blizzard", {})

T.Load("Services/TimelineService.lua", ns)
local Timeline = ns:GetModule("Services.TimelineService")
Timeline.activeProviders.DBM = ns:GetModule("Services.Providers.DBM")
Timeline:SetEncounter("boss")

Timeline:ProviderTimerStarted("DBM", "fade-1", {
    key = 123,
    name = "Mechanic",
    duration = 10,
    precision = "exact",
    faded = true,
})

local timer = Timeline.timers["DBM|fade-1"]
assert(timer, "faded DBM timers must be retained")
assert(timer.faded == true and Timeline:IsActionable(timer) == false)
local occurrenceID = timer.occurrenceID
local expiration = timer.expiration
assert(occurrenceID ~= nil)

now = 103
assert(Timeline:GetRemaining(timer) == 7)
Timeline:ProviderTimerFaded("DBM", "fade-1", false)
assert(timer.faded == false and Timeline:IsActionable(timer) == true)
assert(timer.occurrenceID == occurrenceID, "unfade must keep the same occurrence identity")
assert(timer.expiration == expiration and Timeline:GetRemaining(timer) == 7, "unfade must not reset timer timing")

Timeline:ProviderTimerFaded("DBM", "fade-1", true)
assert(timer.faded == true and Timeline:IsActionable(timer) == false)
assert(timer.occurrenceID == occurrenceID and timer.expiration == expiration)

Timeline:ProviderTimerFaded("DBM", "fade-1", SECRET)
assert(timer.faded == true, "secret fade state must leave timer state unchanged")

assert(Timeline:AcknowledgeCall("mechanic") == true)
assert(timer.acknowledged == true)
Timeline:ProviderTimerFaded("DBM", "fade-1", false)
assert(timer.acknowledged == true, "unfade must not re-arm an acknowledged occurrence")
assert(timer.occurrenceID == occurrenceID)

Timeline:ProviderTimerStarted("DBM", "secret-fade", {
    key = 123,
    name = "Mechanic",
    duration = 10,
    precision = "exact",
    faded = SECRET,
})
assert(Timeline.timers["DBM|secret-fade"] == nil, "secret faded state must fail closed")

print("ok - faded timers preserve timing, occurrence identity, and acknowledgement across unfade")
