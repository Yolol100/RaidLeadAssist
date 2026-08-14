local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

T.Load("Core/Constants.lua", ns)
local Constants = ns:GetModule("Core.Constants")

local defaultCall = { key = "default" }
assert(Constants.GetCallState(defaultCall, 5.01, true) == Constants.CallState.IDLE)
assert(Constants.GetCallState(defaultCall, 5.00, true) == Constants.CallState.PREPARE)
assert(Constants.GetCallState(defaultCall, 3.01, true) == Constants.CallState.PREPARE)
assert(Constants.GetCallState(defaultCall, 3.00, true) == Constants.CallState.PRESS)

local coordination = { key = "coordination", prepareSeconds = 8, pressSeconds = 5 }
assert(Constants.GetCallState(coordination, 8.01, true) == Constants.CallState.IDLE)
assert(Constants.GetCallState(coordination, 8.00, true) == Constants.CallState.PREPARE)
assert(Constants.GetCallState(coordination, 5.01, true) == Constants.CallState.PREPARE)
assert(Constants.GetCallState(coordination, 5.00, true) == Constants.CallState.PRESS)

local interrupt = { key = "interrupt", prepareSeconds = 4, pressSeconds = 1 }
assert(Constants.GetCallState(interrupt, 4.00, true) == Constants.CallState.PREPARE)
assert(Constants.GetCallState(interrupt, 1.01, true) == Constants.CallState.PREPARE)
assert(Constants.GetCallState(interrupt, 1.00, true) == Constants.CallState.PRESS)
assert(Constants.GetCallState(interrupt, 0.50, false) == Constants.CallState.IDLE,
    "approximate/non-actionable timers must never produce PREPARE or PRESS")

print("ok - per-call timing windows and actionable precision gate")
