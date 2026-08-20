local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local SECRET = {}

_G.issecretvalue = function(value) return value == SECRET end
T.Load("Core/Constants.lua", ns)
local Constants = ns:GetModule("Core.Constants")

local defaultCall = { key = "default" }
assert(Constants.GetCallState(defaultCall, 5.01, true) == Constants.CallState.IDLE)
assert(Constants.GetCallState(defaultCall, 5.00, true) == Constants.CallState.PREPARE)
assert(Constants.GetCallState(defaultCall, 3.01, true) == Constants.CallState.PREPARE)
assert(Constants.GetCallState(defaultCall, 3.00, true) == Constants.CallState.PRESS)

_G.RaidLeadAssistDB = { timingLead = { prepare = 9, press = 4 } }
assert(Constants.GetCallState(defaultCall, 9.01, true) == Constants.CallState.IDLE)
assert(Constants.GetCallState(defaultCall, 9.00, true) == Constants.CallState.PREPARE)
assert(Constants.GetCallState(defaultCall, 4.01, true) == Constants.CallState.PREPARE)
assert(Constants.GetCallState(defaultCall, 4.00, true) == Constants.CallState.PRESS)

local coordination = { key = "coordination", prepareSeconds = 8, pressSeconds = 5 }
assert(Constants.GetCallState(coordination, 8.01, true) == Constants.CallState.IDLE)
assert(Constants.GetCallState(coordination, 8.00, true) == Constants.CallState.PREPARE)
assert(Constants.GetCallState(coordination, 5.01, true) == Constants.CallState.PREPARE)
assert(Constants.GetCallState(coordination, 5.00, true) == Constants.CallState.PRESS,
    "encounter-specific lead windows must remain authoritative over global preferences")

local interrupt = { key = "interrupt", prepareSeconds = 4, pressSeconds = 1 }
assert(Constants.GetCallState(interrupt, 4.00, true) == Constants.CallState.PREPARE)
assert(Constants.GetCallState(interrupt, 1.01, true) == Constants.CallState.PREPARE)
assert(Constants.GetCallState(interrupt, 1.00, true) == Constants.CallState.PRESS)
assert(Constants.GetCallState(interrupt, 0.50, false) == Constants.CallState.IDLE,
    "approximate/non-actionable timers must never produce PREPARE or PRESS")

_G.RaidLeadAssistDB.timingLead = { prepare = 2, press = 8 }
assert(Constants.GetCallState(defaultCall, 5.00, true) == Constants.CallState.PREPARE)
assert(Constants.GetCallState(defaultCall, 3.00, true) == Constants.CallState.PRESS,
    "invalid inverted saved windows must fail closed to defaults")

local prepare, press, valid = Constants.NormalizeTimingLead({ prepare = 12, press = 5 })
assert(valid and prepare == 12 and press == 5)
local fallbackPrepare, fallbackPress, invalid = Constants.NormalizeTimingLead({ prepare = 31, press = 1 })
assert(invalid == false and fallbackPrepare == Constants.PREPARE_SECONDS and fallbackPress == Constants.PRESS_SECONDS)
local secretPrepare, secretPress, secretValid = Constants.NormalizeTimingLead({ prepare = SECRET, press = 2 })
assert(secretValid == false and secretPrepare == Constants.PREPARE_SECONDS and secretPress == Constants.PRESS_SECONDS,
    "secret timing values must fail closed without arithmetic/coercion")

_G.RaidLeadAssistDB = nil
_G.issecretvalue = nil
print("ok - configurable per-user/per-call timing windows, secret guards and actionable precision gate")
