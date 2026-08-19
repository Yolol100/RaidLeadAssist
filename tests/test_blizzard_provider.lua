local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local SECRET = {}
local frame = T.Frame()
local remainingCalls = 0

_G.issecretvalue = function(value) return value == SECRET end
_G.CreateFrame = function() return frame end
_G.Enum = { EncounterTimelineEventState = { Active = 0, Paused = 1, Finished = 2, Canceled = 3 } }
_G.C_EncounterTimeline = {
    GetEventList = function() return { 7 } end,
    GetEventState = function(eventID) assert(eventID == 7 or eventID == 8); return 0 end,
    GetEventInfo = function(eventID)
        assert(eventID == 7)
        return { id = 7, source = 0, duration = 12, spellID = 123, spellName = "Test Cast", iconFileID = 456, isApproximate = false }
    end,
    GetEventTimeRemaining = function(eventID)
        remainingCalls = remainingCalls + 1
        assert(eventID == 7)
        return 9
    end,
    GetEventTimeElapsed = function(eventID) assert(eventID == 7); return 3 end,
}

T.Load("Core/Util.lua", ns)
T.Load("Services/Providers/BlizzardProvider.lua", ns)
local Provider = ns:GetModule("Services.Providers.Blizzard")
local started = {}
local sink = {}
function sink:ProviderTimerStarted(provider, sourceID, data)
    started[#started + 1] = { provider = provider, sourceID = sourceID, data = data }
end
function sink:ProviderTimerPaused() end
function sink:ProviderTimerStopped() end

assert(Provider:Start(sink) == true, "current Blizzard timeline API should be detected")
Provider:SeedExistingEvents()
assert(#started == 1, "existing active timeline events should seed exactly once")
assert(started[1].provider == "Blizzard" and started[1].sourceID == "7", "seeded timer identity should be stable")
assert(started[1].data.duration == 9 and started[1].data.key == 123, "seed should prefer current remaining time and preserve spell identity")
assert(started[1].data.precision == "native", "non-approximate Blizzard Encounter Timeline events must remain native precision")

Provider:OnEvent("ENCOUNTER_TIMELINE_EVENT_ADDED", {
    id = 8,
    source = 0,
    duration = 15,
    spellID = 321,
    spellName = "Approximate Cast",
    iconFileID = 654,
    isApproximate = true,
})
assert(#started == 2, "new approximate encounter timeline event should be accepted for preview")
assert(started[2].sourceID == "8", "approximate timeline event identity should stay stable")
assert(started[2].data.precision == "approximate", "Blizzard isApproximate events must never become actionable native precision")

Provider:OnEvent("ENCOUNTER_TIMELINE_EVENT_ADDED", {
    id = 9,
    source = 0,
    duration = 10,
    spellID = 999,
    isApproximate = SECRET,
})
assert(#started == 2, "secret approximation metadata must fail closed")

C_EncounterTimeline.GetEventTimeRemaining = function()
    remainingCalls = remainingCalls + 1
    error("event already removed")
end
assert(Provider:GetRemaining({ nativeEventID = 7, duration = 12 }) == 9, "invalid-event race must fall back to elapsed time without escaping")

local callsBeforeSecret = remainingCalls
assert(Provider:GetSafeRemaining(SECRET) == nil, "secret timeline IDs must be rejected before API use")
assert(remainingCalls == callsBeforeSecret, "secret timeline IDs must never reach RequiresValidTimelineEvent APIs")

print("ok - Blizzard timeline validity, exact/approximate precision, and secret guards")
