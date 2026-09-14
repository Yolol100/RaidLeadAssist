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
local timelineAcknowledged

_G.GetTime = function() return now end
_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
local Constants = ns:GetModule("Core.Constants")

local callA = { key = "a", timing = true }
local callB = { key = "b", timing = true }
local profile = { calls = { callA, callB }, callsByKey = { a = callA, b = callB } }
ns:RegisterModule("Encounters.Registry", { GetProfile = function() return profile end })
ns:RegisterModule("Core.EventBus", { On = function() end })
ns:RegisterModule("Services.AudioService", {
    Prepare = function() audioPrepare = audioPrepare + 1 end,
    Press = function() audioPress = audioPress + 1 end,
})
ns:RegisterModule("Services.TimelineService", {
    AcknowledgeCall = function(_, callKey) timelineAcknowledged = callKey return true end,
})

local nextMechanic
local Guidance = {}
function Guidance:GetNextMechanic() return nextMechanic end
function Guidance:Reset() end
function Guidance:Acknowledge(callKey)
    acknowledged = callKey
    if callKey == "b" then return "underlying" end
    return callKey
end
ns:RegisterModule("Services.TimingGuidance", Guidance)

local UI = { timeline = {} }
function UI:SetCallState(callKey, state) uiStates[callKey] = state end
function UI.timeline:SetIdle(label) idleLabel = label timerShown = false end
function UI.timeline:SetTimer() timerShown = true idleLabel = nil end
function UI.timeline:SetState(state) timerState = state end
ns:RegisterModule("UI.MainFrame", UI)

local App = {
    activeBossKey = "boss", activeDifficultyKey = "heroic",
    db = { automaticTimingEnabled = true }, timingAllowed = true,
    visualCalledUntil = {}, manualLockUntil = {}, audioStates = {},
}
function App:IsAutomaticTimingEnabled()
    return self.timingAllowed == true and self.db.automaticTimingEnabled ~= false
end
function App:SendCall(callKey) self.manualLockUntil[callKey] = GetTime() + 1 end
ns:RegisterModule("Core.App", App)

T.Load("Core/TimingGuidanceIntegration.lua", ns)

nextMechanic = {
    timer = { sourceID = "one" }, call = callA, callKey = "a", timelineCallKey = "a",
    providerName = "DBM", sourceID = "one", occurrenceID = 1, remaining = 12,
    state = Constants.CallState.WAIT,
}
App:UpdateTiming()
assert(uiStates.a == Constants.CallState.WAIT)
assert(uiStates.b == Constants.CallState.IDLE)
assert(timerShown and timerState == Constants.CallState.WAIT)

nextMechanic.remaining = 6
nextMechanic.state = Constants.CallState.PREPARE
App:UpdateTiming()
App:UpdateTiming()
assert(uiStates.a == Constants.CallState.PREPARE and audioPrepare == 1)

nextMechanic.remaining = 3
nextMechanic.state = Constants.CallState.PRESS
App:UpdateTiming()
App:UpdateTiming()
assert(uiStates.a == Constants.CallState.PRESS and audioPress == 1)

nextMechanic = {
    timer = { sourceID = "two" }, call = callB, callKey = "b", timelineCallKey = "underlying",
    providerName = "BigWigs", sourceID = "two", occurrenceID = 2, remaining = 5,
    state = Constants.CallState.PREPARE,
}
App:UpdateTiming()
assert(uiStates.a == Constants.CallState.IDLE and uiStates.b == Constants.CallState.PREPARE)

nextMechanic = nil
App:UpdateTiming()
assert(uiStates.a == Constants.CallState.IDLE and uiStates.b == Constants.CallState.IDLE)
assert(idleLabel == "NO VERIFIED TIMER")

App:SendCall("a")
assert(acknowledged == "a")
assert(timelineAcknowledged == nil, "ordinary call should use the original App acknowledgement path")

App:SendCall("b")
assert(acknowledged == "b")
assert(timelineAcknowledged == "underlying", "sequence display call must acknowledge underlying stable timer")

App.db.automaticTimingEnabled = false
idleLabel = nil
App:UpdateTiming()
assert(idleLabel == "AUTO TIMING OFF")

print("ok - guidance integration keeps one mechanic, manual ownership, audio dedupe and sequence acknowledgement")
