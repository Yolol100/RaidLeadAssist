local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local now = 500
local call = { key = "mechanic" }

_G.GetTime = function() return now end
_G.C_Timer = { After = function(_, cb) cb() end }
_G.CreateFrame = function() return T.Frame() end
_G.table.wipe = _G.table.wipe or function(t) for k in pairs(t) do t[k] = nil end end
_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
local Constants = ns:GetModule("Core.Constants")
assert(Constants.PROVIDER_PRIORITY[1] == "DBM", "DBM must be the primary bossmod source")

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
assert(Timeline:GetProviderSummary() == "DBM, BigWigs, Blizzard")

Timeline:ProviderTimerStarted("BigWigs", "bw-1", {
    key = 123,
    name = "Mechanic",
    duration = 12,
    precision = "exact",
})
now = 500.1
Timeline:ProviderTimerStarted("DBM", "dbm-1", {
    key = 123,
    name = "Mechanic",
    duration = 11.9,
    precision = "exact",
    faded = false,
})

local bigwigs = Timeline.timers["BigWigs|bw-1"]
local dbm = Timeline.timers["DBM|dbm-1"]
assert(bigwigs and dbm and bigwigs.occurrenceID == dbm.occurrenceID,
    "matching BigWigs and DBM timers must reconcile to one occurrence")
assert(Timeline:GetActionableTimerForCall("mechanic") == dbm,
    "DBM must win when equally precise direct bossmod timers represent the same occurrence")

local occurrenceID = dbm.occurrenceID
Timeline:ProviderTimerFaded("DBM", "dbm-1", true)
assert(Timeline:GetActionableTimerForCall("mechanic") == bigwigs,
    "a faded DBM timer must temporarily fall back to another exact representation")
assert(dbm.occurrenceID == occurrenceID, "fading DBM must not create a new occurrence")

Timeline:ProviderTimerFaded("DBM", "dbm-1", false)
assert(Timeline:GetActionableTimerForCall("mechanic") == dbm,
    "unfading DBM must restore it as the preferred exact representation")
assert(dbm.occurrenceID == occurrenceID, "unfading DBM must preserve occurrence identity")

Timeline:ProviderTimerStopped("DBM", "dbm-1")
assert(Timeline:GetActionableTimerForCall("mechanic") == bigwigs,
    "BigWigs must remain a safe fallback if the preferred DBM timer stops")

print("ok - DBM is primary while BigWigs and Blizzard remain safe fallbacks")
