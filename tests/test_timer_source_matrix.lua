local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local now = 500
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

local sourceDefaults = {
    BigWigs = { precision = "exact" },
    DBM = { precision = "exact" },
    Blizzard = { precision = "native" },
}

local serial = 0
local function reset()
    Timeline:Reset()
    now = now + 20
end

local function start(source, duration, overrides)
    serial = serial + 1
    local data = {
        key = 123,
        duration = duration,
        precision = sourceDefaults[source].precision,
    }
    for key, value in pairs(overrides or {}) do data[key] = value end
    local id = source:lower() .. "-" .. tostring(serial)
    Timeline:ProviderTimerStarted(source, id, data)
    return Timeline.timers[source .. "|" .. id], id
end

-- Every supported source must work independently.
for _, source in ipairs({ "BigWigs", "DBM", "Blizzard" }) do
    reset()
    local timer = start(source, 10)
    local selected = Timeline:GetActionableTimerForCall("kick")
    assert(selected and selected.id == timer.id, source .. " must work as a standalone timer source")
end

-- Every two-source combination must reconcile one mechanic and prefer the
-- configured bossmod order: BigWigs, then DBM, then Blizzard.
local pairsToCheck = {
    { "BigWigs", "DBM", "BigWigs" },
    { "BigWigs", "Blizzard", "BigWigs" },
    { "DBM", "Blizzard", "DBM" },
}
for _, entry in ipairs(pairsToCheck) do
    reset()
    local first = start(entry[1], 10)
    now = now + 0.1
    local second = start(entry[2], 9.9)
    assert(first.occurrenceID == second.occurrenceID,
        entry[1] .. "+" .. entry[2] .. " must reconcile one occurrence")
    local selected = Timeline:GetActionableTimerForCall("kick")
    assert(selected and selected.providerName == entry[3],
        entry[1] .. "+" .. entry[2] .. " selected the wrong provider")
end

-- With all three sources present, stopping the preferred source must fall back
-- in order without changing the mechanic into a new occurrence.
reset()
local bw, bwID = start("BigWigs", 10)
now = now + 0.1
local dbm, dbmID = start("DBM", 9.9)
now = now + 0.1
local blizzard, blizzardID = start("Blizzard", 9.8)
assert(bw.occurrenceID == dbm.occurrenceID and dbm.occurrenceID == blizzard.occurrenceID,
    "all three sources must reconcile one occurrence")
assert(Timeline:GetActionableTimerForCall("kick").providerName == "BigWigs")
Timeline:ProviderTimerStopped("BigWigs", bwID)
assert(Timeline:GetActionableTimerForCall("kick").providerName == "DBM",
    "DBM must take over when BigWigs disappears")
Timeline:ProviderTimerStopped("DBM", dbmID)
assert(Timeline:GetActionableTimerForCall("kick").providerName == "Blizzard",
    "Blizzard must remain a usable final fallback")
Timeline:ProviderTimerStopped("Blizzard", blizzardID)
assert(Timeline:GetActionableTimerForCall("kick") == nil)

-- Approximate bossmod bars may preview, but an exact/native representation of
-- the same occurrence must be the actionable source.
reset()
local approx = start("BigWigs", 10, { precision = "approximate" })
now = now + 0.1
local native = start("Blizzard", 9.9, { nativeEventID = 700 })
assert(approx.occurrenceID == native.occurrenceID)
local selected = Timeline:GetActionableTimerForCall("kick")
assert(selected and selected.providerName == "Blizzard",
    "approximate BigWigs data must not displace native Blizzard timing")

-- Reconciliation must be bounded. Two same-call timers far apart are separate
-- mechanics; acknowledging the earlier one must not suppress the later one.
reset()
local early = start("BigWigs", 5)
local later = start("DBM", 15)
assert(early.occurrenceID ~= later.occurrenceID,
    "timers outside duplicate tolerance must remain separate occurrences")
assert(Timeline:AcknowledgeCall("kick") == true)
local remaining = Timeline:GetActionableTimerForCall("kick")
assert(remaining and remaining.id == later.id and not later.acknowledged,
    "acknowledging one occurrence must not suppress a later mechanic")

print("ok - complete BigWigs/DBM/Blizzard source matrix and bounded deduplication")
