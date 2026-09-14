local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local now = 100

_G.GetTime = function() return now end
_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
local Constants = ns:GetModule("Core.Constants")

local call = {
    key = "mechanic",
    ability = "Mechanic",
    spellIDs = { 123 },
    timing = true,
    prepareSeconds = 8,
    pressSeconds = 4,
}
local laterCall = {
    key = "later",
    ability = "Later",
    spellIDs = { 456 },
    timing = true,
    prepareSeconds = 8,
    pressSeconds = 4,
}
local profile = {
    calls = { call, laterCall },
    callsByKey = { mechanic = call, later = laterCall },
}

ns:RegisterModule("Encounters.Registry", {
    GetProfile = function(_, encounterKey, difficultyKey)
        assert(encounterKey == "boss" and difficultyKey == "heroic")
        return profile
    end,
})

local Timeline = { timers = {} }
function Timeline:IsActionable(timer)
    return timer.faded ~= true
        and (timer.precision == Constants.TimerPrecision.EXACT
            or timer.precision == Constants.TimerPrecision.NATIVE)
end
ns:RegisterModule("Services.TimelineService", Timeline)

T.Load("Services/TimingGuidanceService.lua", ns)
local Guidance = ns:GetModule("Services.TimingGuidance")

local function timer(id, key, timerCall, expiration, provider, occurrenceID, precision)
    return {
        id = id,
        sourceID = id,
        key = key,
        call = timerCall,
        duration = math.max(0.1, expiration - now),
        expiration = expiration,
        providerName = provider or "DBM",
        occurrenceID = occurrenceID or id,
        precision = precision or Constants.TimerPrecision.EXACT,
    }
end

-- Localized/name-only matches are deliberately not trusted for automatic guidance.
Timeline.timers = {
    nameOnly = timer("name-only", nil, call, now + 10, "BigWigs", 1),
}
assert(Guidance:GetNextMechanic("boss", "heroic") == nil,
    "name-only bossmod matches must fail closed")

-- Even a registry-mapped timer cannot drive a call when its numeric identity is not owned by that call.
Timeline.timers = {
    wrongID = timer("wrong-id", 999, call, now + 10, "DBM", 2),
}
assert(Guidance:GetNextMechanic("boss", "heroic") == nil,
    "wrong stable identity must fail closed")

-- A reviewed spell ID becomes the one normalized current mechanic.
local stable = timer("stable", 123, call, 112, "DBM", 3)
Timeline.timers = { stable = stable }
local mechanic = assert(Guidance:GetNextMechanic("boss", "heroic"))
assert(mechanic.callKey == "mechanic" and mechanic.providerName == "DBM")
assert(mechanic.state == Constants.CallState.WAIT and mechanic.remaining == 12)

now = 105
mechanic = assert(Guidance:GetNextMechanic("boss", "heroic"))
assert(mechanic.state == Constants.CallState.PREPARE and mechanic.remaining == 7,
    "prepare window must map to SOON guidance")

now = 109
mechanic = assert(Guidance:GetNextMechanic("boss", "heroic"))
assert(mechanic.state == Constants.CallState.PRESS and mechanic.remaining == 3,
    "press window must map to PRESS NOW guidance")

-- The bossmod may remove its bar at zero; retain only a bounded late snapshot.
-- Observe the timer inside the final grace window first so the service can prove
-- the bar survived until the mechanic rather than being cancelled earlier.
now = 111.5
mechanic = assert(Guidance:GetNextMechanic("boss", "heroic"))
assert(mechanic.state == Constants.CallState.PRESS)
Timeline.timers = {}
now = 112.25
mechanic = assert(Guidance:GetNextMechanic("boss", "heroic"))
assert(mechanic.state == Constants.CallState.LATE and mechanic.remaining < 0,
    "just-missed mechanic must remain visibly late for the grace window")
now = 113.25
assert(Guidance:GetNextMechanic("boss", "heroic") == nil,
    "late guidance must disappear after the bounded grace")

-- An early provider stop/cancel must never resurrect at the old deadline as LATE.
Guidance:Reset()
now = 300
local cancelled = timer("cancelled", 123, call, 310, "DBM", 20)
Timeline.timers = { cancelled = cancelled }
assert(Guidance:GetNextMechanic("boss", "heroic").state == Constants.CallState.WAIT)
Timeline.timers = {}
now = 301
assert(Guidance:GetNextMechanic("boss", "heroic") == nil,
    "early cancellation must clear retained guidance")
now = 310.25
assert(Guidance:GetNextMechanic("boss", "heroic") == nil,
    "cancelled timer must not create phantom LATE guidance at its former deadline")

-- A paused timer that disappears before its deadline is also a cancellation,
-- not evidence that a mechanic should later be marked missed.
Guidance:Reset()
now = 400
local paused = timer("paused", 123, call, 410, "BigWigs", 21)
paused.paused = true
paused.pausedRemaining = 10
Timeline.timers = { paused = paused }
assert(Guidance:GetNextMechanic("boss", "heroic").state == Constants.CallState.WAIT)
Timeline.timers = {}
now = 410.25
assert(Guidance:GetNextMechanic("boss", "heroic") == nil,
    "removed paused timer must never synthesize LATE guidance")

-- Same occurrence from multiple exact providers follows the configured authority order.
Guidance:Reset()
now = 500
local bw = timer("bw", 123, call, 505.0, "BigWigs", 8)
local dbm = timer("dbm", 123, call, 505.2, "DBM", 8)
Timeline.timers = { bw = bw, dbm = dbm }
mechanic = assert(Guidance:GetNextMechanic("boss", "heroic"))
assert(mechanic.providerName == "DBM",
    "same occurrence must prefer DBM over BigWigs")

-- Across different occurrences/calls, the earliest verified mechanic wins.
Guidance:Reset()
local first = timer("first", 123, call, 510, "DBM", 9)
local second = timer("second", 456, laterCall, 507, "BigWigs", 10)
Timeline.timers = { first = first, second = second }
mechanic = assert(Guidance:GetNextMechanic("boss", "heroic"))
assert(mechanic.callKey == "later" and mechanic.remaining == 7)

-- Equal-deadline mechanics must never depend on Lua pairs() iteration order.
-- The encounter profile order is the explicit raid-leader priority contract.
Guidance:Reset()
now = 600
local equalFirst = timer("z-source", 123, call, 606, "DBM", 30)
local equalSecond = timer("a-source", 456, laterCall, 606, "DBM", 31)
Timeline.timers = { second = equalSecond, first = equalFirst }
mechanic = assert(Guidance:GetNextMechanic("boss", "heroic"))
assert(mechanic.callKey == "mechanic",
    "simultaneous verified mechanics must resolve by profile call order")
Timeline.timers = { first = equalFirst, second = equalSecond }
mechanic = assert(Guidance:GetNextMechanic("boss", "heroic"))
assert(mechanic.callKey == "mechanic",
    "table insertion order must not change simultaneous mechanic guidance")

-- Approximate timers stay preview-only even with a correct spell ID.
Guidance:Reset()
Timeline.timers = {
    approximate = timer("approx", 123, call, 605, "BigWigs", 11, Constants.TimerPrecision.APPROXIMATE),
}
assert(Guidance:GetNextMechanic("boss", "heroic") == nil,
    "approximate timing must never produce automatic guidance")

print("ok - Phase 4/5 guidance is stable-ID-only, deterministic, cancel-safe and WAIT/SOON/PRESS/LATE bounded")
