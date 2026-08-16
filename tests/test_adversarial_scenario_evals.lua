local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local now = 1000
local SECRET = {}
local call = { key = "mechanic" }
local encounters = {
    boss = { encounterID = 1001 },
    other = { encounterID = 1002 },
}

_G.GetTime = function() return now end
_G.C_Timer = { After = function(_, cb) cb() end }
_G.CreateFrame = function() return T.Frame() end
_G.table.wipe = _G.table.wipe or function(tbl) for key in pairs(tbl) do tbl[key] = nil end end
_G.issecretvalue = function(value) return value == SECRET end
_G.C_AddOns = {
    GetAddOnMetadata = function(addon, field)
        if field ~= "Version" then return nil end
        local versions = {
            ["DBM-Core"] = "12.1.3",
            ["DBM-Raids-Midnight"] = "12.1.3",
            BigWigs = "v419.2",
            BigWigs_TheVenomousAbyss = "v419.2",
        }
        return versions[addon]
    end,
    IsAddOnLoaded = function() return true end,
}

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
local Constants = ns:GetModule("Core.Constants")
ns:RegisterModule("Core.EventBus", { Emit = function() end })
ns:RegisterModule("Encounters.Registry", {
    Get = function(_, key) return encounters[key] end,
    MatchCall = function(_, encounterKey, key, name)
        if encounterKey == "boss" and (key == 123 or name == "Mechanic") then return call end
        if encounterKey == "other" and (key == 456 or name == "Other") then return { key = "other" } end
    end,
})

local function provider()
    return {
        IsAvailable = function() return true end,
        Start = function() return true end,
        Stop = function() end,
        CanSupplyBossTimers = function() return true end,
    }
end
ns:RegisterModule("Services.Providers.DBM", provider())
ns:RegisterModule("Services.Providers.BigWigs", provider())
ns:RegisterModule("Services.Providers.Blizzard", provider())
T.Load("Services/TimelineService.lua", ns)
local Timeline = ns:GetModule("Services.TimelineService")
Timeline:Initialize()
Timeline:SetEncounter("boss")

local function timerCount()
    local count = 0
    for _ in pairs(Timeline.timers) do count = count + 1 end
    return count
end

local function assertNoCrash(fn, label)
    local ok, err = pcall(fn)
    assert(ok, label .. ": " .. tostring(err))
end

-- Explicitly unknown or secret precision is uncertainty, never exact/actionable.
Timeline:ProviderTimerStarted("DBM", "unknown-precision", {
    key = 123,
    name = "Mechanic",
    duration = 10,
    encounterID = 1001,
    precision = "estimated",
})
local unknown = Timeline.timers["DBM|unknown-precision"]
assert(unknown and unknown.precision == Constants.TimerPrecision.APPROXIMATE,
    "unknown precision must fail closed as approximate")
assert(not Timeline:IsActionable(unknown), "unknown precision must never be actionable")

Timeline:ProviderTimerStarted("DBM", "secret-precision", {
    key = 123,
    name = "Mechanic",
    duration = 10,
    encounterID = 1001,
    precision = SECRET,
})
local secretPrecision = Timeline.timers["DBM|secret-precision"]
assert(secretPrecision and secretPrecision.precision == Constants.TimerPrecision.APPROXIMATE,
    "secret precision must fail closed as approximate")
assert(not Timeline:IsActionable(secretPrecision), "secret precision must never be actionable")

-- Missing precision retains the documented source default for compatibility.
Timeline:ProviderTimerStarted("DBM", "implicit-direct", {
    key = 123, name = "Mechanic", duration = 10, encounterID = 1001,
})
assert(Timeline.timers["DBM|implicit-direct"].precision == Constants.TimerPrecision.EXACT)
Timeline:ProviderTimerStarted("Blizzard", "implicit-native", {
    key = 123, name = "Mechanic", duration = 10,
})
assert(Timeline.timers["Blizzard|implicit-native"].precision == Constants.TimerPrecision.NATIVE)

-- Malformed provider identities and source IDs must be inert instead of crashing or colliding.
local before = timerCount()
local invalidSourceIDs = { "", "   ", 0 / 0, math.huge, -math.huge }
for _, sourceID in ipairs(invalidSourceIDs) do
    Timeline:ProviderTimerStarted("DBM", sourceID, {
        key = 123, name = "Mechanic", duration = 10, encounterID = 1001, precision = "exact",
    })
end
assert(timerCount() == before, "invalid source IDs must not create timers")
assertNoCrash(function() Timeline:ProviderTimerStopped(nil, "x") end, "nil provider stop")
assertNoCrash(function() Timeline:ProviderTimerStopped(42, "x") end, "numeric provider stop")
assertNoCrash(function() Timeline:ProviderReset(nil) end, "nil provider reset")
assertNoCrash(function() Timeline:ProviderReset(42) end, "numeric provider reset")

-- Cross-encounter direct timers are always rejected.
before = timerCount()
Timeline:ProviderTimerStarted("BigWigs", "wrong-encounter", {
    key = 123, name = "Mechanic", duration = 10, encounterID = 1002, precision = "exact",
})
assert(timerCount() == before, "cross-encounter timer must be rejected")

-- Deterministic state-machine stress: thousands of mixed event-order transitions.
local seed = 0x51A7E
local function rnd(maximum)
    seed = (seed * 1103515245 + 12345) % 2147483648
    return (seed % maximum) + 1
end

local ids = {
    DBM = { "d1", "d2", "d3" },
    BigWigs = { "b1", "b2", "b3" },
    Blizzard = { "z1", "z2", "z3" },
}
local providers = { "DBM", "BigWigs", "Blizzard" }
local precisions = { nil, "exact", "native", "approximate", "estimated", SECRET }
local steps = 12000

for step = 1, steps do
    local op = rnd(9)
    local providerName = providers[rnd(#providers)]
    local sourceID = ids[providerName][rnd(3)]

    if op <= 3 then
        local precision = precisions[rnd(#precisions)]
        local data = {
            key = 123,
            name = "Mechanic",
            duration = rnd(20),
            encounterID = providerName == "Blizzard" and nil or 1001,
            precision = precision,
            faded = false,
            count = rnd(4),
        }
        Timeline:ProviderTimerStarted(providerName, sourceID, data)
    elseif op == 4 then
        Timeline:ProviderTimerUpdated(providerName, sourceID, rnd(5) - 1, rnd(20))
    elseif op == 5 then
        Timeline:ProviderTimerPaused(providerName, sourceID, true)
    elseif op == 6 then
        Timeline:ProviderTimerPaused(providerName, sourceID, false)
    elseif op == 7 then
        Timeline:ProviderTimerFaded(providerName, sourceID, rnd(2) == 1)
    elseif op == 8 then
        Timeline:ProviderTimerStopped(providerName, sourceID)
    else
        Timeline:AcknowledgeCall("mechanic")
    end

    if step % 23 == 0 then now = now + 0.75 end
    if step % 137 == 0 then
        Timeline:SetEncounter("other", true)
        for _, timer in pairs(Timeline.timers) do
            assert(not timer.encounterID or timer.encounterID == 1002,
                "preserved timer leaked across encounter boundary")
        end
        Timeline:SetEncounter("boss", false)
    end

    local actionable = Timeline:GetNextActionableTimer()
    if actionable then
        assert(Timeline:IsActionable(actionable), "selector returned non-actionable timer")
        assert(actionable.acknowledged ~= true, "selector returned acknowledged timer")
        assert(actionable.precision == Constants.TimerPrecision.EXACT
            or actionable.precision == Constants.TimerPrecision.NATIVE,
            "selector returned uncertain precision")
    end

    for _, timer in pairs(Timeline.timers) do
        assert(type(timer.expiration) == "number" and timer.expiration == timer.expiration
            and timer.expiration > -math.huge and timer.expiration < math.huge,
            "timer expiration must stay finite")
        assert(timer.precision == Constants.TimerPrecision.EXACT
            or timer.precision == Constants.TimerPrecision.NATIVE
            or timer.precision == Constants.TimerPrecision.APPROXIMATE,
            "timer precision escaped the closed enum")
        if timer.encounterID then assert(timer.encounterID == 1001, "wrong encounter timer retained") end
    end
end

print(("ok - adversarial scenario evals: %d deterministic state transitions plus malformed-input matrix"):format(steps))
