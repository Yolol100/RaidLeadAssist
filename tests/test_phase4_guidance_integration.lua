local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local now = 100
local uiStates = {}
local idleLabel
local timerState
local timerShown
local audioPrepare = 0
local audioPress = 0
local acknowledged

_G.GetTime = function() return now end
_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
local Constants = ns:GetModule("Core.Constants")

local callA = { key = "a", timing = true }
local callB = { key = "b", timing = true }
local profile = { calls = { callA, callB }, callsByKey = { a = callA, b = callB } }
ns:RegisterModule("Encounters.Registry", {
    GetProfile = function() return profile end,
})

ns:RegisterModule("Core.EventBus", {
    On = function() end,
})

ns:RegisterModule("Services.AudioService", {
    Prepare = function() audioPrepare = audioPrepare + 1 end,
    Press = function() audioPress = audioPress + 1 end,
})

local nextMechanic
local Guidance = {}
function Guidance:GetNextMechanic() return nextMechanic end
function Guidance:Reset() end
function Guidance:Acknowledge(callKey) acknowledged = callKey return true end
ns:RegisterModule("Services.TimingGuidance", Guidance)

local UI = { timeline = {} }
function UI:SetCallState(callKey, state) uiStates[callKey] = state end
function UI.timeline:SetIdle(label)
    idleLabel = label
    timerShown = false
end
function UI.timeline:SetTimer()
    timerShown = true
    idleLabel = nil
end
function UI.timeline:SetState(state) timerState = state end
ns:RegisterModule("UI.MainFrame", UI)

local App = {
    activeBossKey = "boss",
    activeDifficultyKey = "heroic",
    db = { automaticTimingEnabled = true },
    timingAllowed = true,
    visualCalledUntil = {},
    manualLockUntil = {},
    audioStates = {},
}
function App:IsAutomaticTimingEnabled()
    return self.timingAllowed == true and self.db.automaticTimingEnabled ~= false
end
function App:SendCall(callKey)
    self.manualLockUntil[callKey] = GetTime() + 1
end
ns:RegisterModule("Core.App", App)

T.Load("Core/TimingGuidanceIntegration.lua", ns)

-- One normalized mechanic is emphasized; every other timed call is neutral.
nextMechanic = {
    timer = { sourceID = "one" },
    call = callA,
    callKey = "a",
    providerName = "DBM",
    sourceID = "one",
    occurrenceID = 1,
    remaining = 12,
    state = Constants.CallState.WAIT,
}
App:UpdateTiming()
assert(uiStates.a == Constants.CallState.WAIT)
assert(uiStates.b == Constants.CallState.IDLE,
    "only the normalized current mechanic may be emphasized")
assert(timerShown and timerState == Constants.CallState.WAIT)

-- SOON and PRESS NOW audio fire once per occurrence/state.
nextMechanic.remaining = 6
nextMechanic.state = Constants.CallState.PREPARE
App:UpdateTiming()
App:UpdateTiming()
assert(uiStates.a == Constants.CallState.PREPARE and audioPrepare == 1,
    "SOON audio must fire once per occurrence")

nextMechanic.remaining = 3
nextMechanic.state = Constants.CallState.PRESS
App:UpdateTiming()
App:UpdateTiming()
assert(uiStates.a == Constants.CallState.PRESS and audioPress == 1,
    "PRESS NOW audio must fire once per occurrence")

-- Advancing to another mechanic clears the former emphasis.
nextMechanic = {
    timer = { sourceID = "two" },
    call = callB,
    callKey = "b",
    providerName = "BigWigs",
    sourceID = "two",
    occurrenceID = 2,
    remaining = 5,
    state = Constants.CallState.PREPARE,
}
App:UpdateTiming()
assert(uiStates.a == Constants.CallState.IDLE and uiStates.b == Constants.CallState.PREPARE)

-- No stable/actionable mechanic fails closed instead of highlighting a guess.
nextMechanic = nil
App:UpdateTiming()
assert(uiStates.a == Constants.CallState.IDLE and uiStates.b == Constants.CallState.IDLE)
assert(idleLabel == "NO VERIFIED TIMER")

-- Manual Raid Warning remains the action boundary and clears retained guidance.
App:SendCall("a")
assert(acknowledged == "a", "successful manual call must clear retained guidance")

-- User timing disablement still overrides the guidance layer.
App.db.automaticTimingEnabled = false
idleLabel = nil
App:UpdateTiming()
assert(idleLabel == "AUTO TIMING OFF")

print("ok - Phase 4 integration emphasizes one mechanic, keeps manual click ownership and deduplicates guidance audio")
