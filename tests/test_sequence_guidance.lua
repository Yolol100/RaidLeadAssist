local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local now = 100

_G.GetTime = function() return now end
_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
local Constants = ns:GetModule("Core.Constants")

local feast1 = {
    key = "feast1", ability = "Ravenous Feast", spellIDs = { 1290516 },
    sequenceKey = "feast", sequenceKeys = { "feast1", "feast2", "feast3" },
    prepareSeconds = 7, pressSeconds = 4,
}
local feast2 = { key = "feast2", ability = "Feast 2", timing = false }
local feast3 = { key = "feast3", ability = "Feast 3", timing = false }
local profile = {
    calls = { feast1, feast2, feast3 },
    callsByKey = { feast1 = feast1, feast2 = feast2, feast3 = feast3 },
}
ns:RegisterModule("Encounters.Registry", { GetProfile = function() return profile end })

local Timeline = { timers = {} }
function Timeline:IsActionable(timer)
    return timer.faded ~= true and timer.precision == Constants.TimerPrecision.EXACT
end
ns:RegisterModule("Services.TimelineService", Timeline)

T.Load("Services/TimingGuidanceService.lua", ns)
local Guidance = ns:GetModule("Services.TimingGuidance")

local function timer(id, occurrenceID, expiration, provider)
    return {
        sourceID = id,
        key = 1290516,
        call = feast1,
        expiration = expiration,
        providerName = provider or "DBM",
        occurrenceID = occurrenceID,
        precision = Constants.TimerPrecision.EXACT,
    }
end

Timeline.timers = { a = timer("a", 1, 110) }
local mechanic = assert(Guidance:GetNextMechanic("boss", "heroic"))
assert(mechanic.callKey == "feast1" and mechanic.timelineCallKey == "feast1")
assert(Guidance:Acknowledge("feast1") == "feast1")

Timeline.timers = { b = timer("b", 2, 120) }
mechanic = assert(Guidance:GetNextMechanic("boss", "heroic"))
assert(mechanic.callKey == "feast2", "second acknowledged occurrence must display Feast 2")
assert(Guidance:Acknowledge("feast2") == "feast1", "Feast 2 must acknowledge the stable underlying Feast timer")

Timeline.timers = {
    dbm = timer("dbm", 3, 130, "DBM"),
    bw = timer("bw", 3, 130.1, "BigWigs"),
}
mechanic = assert(Guidance:GetNextMechanic("boss", "heroic"))
assert(mechanic.callKey == "feast3" and mechanic.providerName == "DBM",
    "duplicate providers for one occurrence must keep one sequence step")
assert(Guidance:Acknowledge("feast3") == "feast1")

Timeline.timers = { cycle = timer("cycle", 4, 140) }
mechanic = assert(Guidance:GetNextMechanic("boss", "heroic"))
assert(mechanic.callKey == "feast1", "sequence must wrap after the third confirmed call")

-- Early cancellation does not advance the sequence.
Guidance:Reset()
now = 200
Timeline.timers = { early = timer("early", 10, 220) }
assert(Guidance:GetNextMechanic("boss", "heroic").callKey == "feast1")
Timeline.timers = {}
now = 202
assert(Guidance:GetNextMechanic("boss", "heroic") == nil)
Timeline.timers = { retry = timer("retry", 11, 230) }
assert(Guidance:GetNextMechanic("boss", "heroic").callKey == "feast1",
    "cancelled occurrence must not advance to Feast 2")

-- If no manual click happened but the prior cast was observed at its deadline,
-- the next true occurrence may advance without depending on localized timer text.
Guidance:Reset()
now = 300
Timeline.timers = { first = timer("first", 20, 300.5) }
assert(Guidance:GetNextMechanic("boss", "heroic").callKey == "feast1")
now = 302
Timeline.timers = { second = timer("second", 21, 310) }
assert(Guidance:GetNextMechanic("boss", "heroic").callKey == "feast2",
    "deadline-observed occurrence should advance when the next stable occurrence starts")

Guidance:Reset()
Timeline.timers = { reset = timer("reset", 30, 320) }
assert(Guidance:GetNextMechanic("boss", "heroic").callKey == "feast1",
    "wipe/context reset must return sequence to step one")

print("ok - sequence guidance is stable-ID-only, click-aware, duplicate-safe, cancel-safe and reset-safe")
