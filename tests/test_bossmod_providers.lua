local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local SECRET = {}
local bwMessages = {}
local dbmCallbacks = {}
local started, stopped, paused = {}, {}, {}

_G.issecretvalue = function(value) return value == SECRET end
_G.table.wipe = _G.table.wipe or function(tbl) for key in pairs(tbl) do tbl[key] = nil end end
_G.BigWigsLoader = {
    RegisterMessage = function(owner, name, callback) bwMessages[name] = callback end,
    UnregisterMessage = function() end,
}
_G.DBM = {
    RegisterCallback = function(_, name, callback) dbmCallbacks[name] = callback end,
    UnregisterCallback = function() end,
}

local sink = {}
function sink:ProviderTimerStarted(provider, id, data)
    started[#started + 1] = { provider = provider, id = id, data = data }
end
function sink:ProviderTimerStopped(provider, id, reason)
    stopped[#stopped + 1] = { provider = provider, id = id, reason = reason }
end
function sink:ProviderTimerPaused(provider, id, value)
    paused[#paused + 1] = { provider = provider, id = id, value = value }
end
function sink:ProviderTimerUpdated() end
function sink:ProviderReset() end

T.Load("Core/Util.lua", ns)
T.Load("Services/Providers/BigWigsProvider.lua", ns)
T.Load("Services/Providers/DBMProvider.lua", ns)

local BigWigs = ns:GetModule("Services.Providers.BigWigs")
assert(BigWigs:Start(sink) == true)
local module = { moduleName = "Boss" }
bwMessages.BigWigs_StartBar(nil, module, 123, "Cast", 10, 456, false, nil, 77, nil)
assert(#started == 1 and started[1].provider == "BigWigs")
assert(started[1].id == "Boss|event:77" and started[1].data.key == 123)

bwMessages.BigWigs_StartBar(nil, module, 123, "Approx", 10, 456, true, nil, 78, nil)
assert(#started == 1, "approximate BigWigs bars must be ignored")
bwMessages.BigWigs_StartBar(nil, module, 123, "Secret", SECRET, 456, false, nil, 79, nil)
assert(#started == 1, "secret BigWigs durations must fail closed")
bwMessages.BigWigs_PauseBar(nil, module, "Cast", 77)
assert(#paused == 1 and paused[1].value == true)
bwMessages.BigWigs_StopBar(nil, module, "Cast", 77)
assert(#stopped == 1 and stopped[1].id == "Boss|event:77")

started, stopped, paused = {}, {}, {}
local DBMProvider = ns:GetModule("Services.Providers.DBM")
assert(DBMProvider:Start(sink) == true)
dbmCallbacks.DBM_TimerBegin(nil, "dbm-1", "Cast", 10, 456, "cd", 123, nil, nil, nil, false, "Cast", nil, nil, nil, nil, false, nil, true)
assert(#started == 1 and started[1].provider == "DBM" and started[1].id == "dbm-1")
assert(started[1].data.key == 123 and started[1].data.name == "Cast")

dbmCallbacks.DBM_TimerBegin(nil, "dbm-variance", "Cast", 10, 456, "cd", 123, nil, nil, nil, false, "Cast", nil, nil, nil, nil, true, nil, true)
assert(#started == 1, "variable DBM timers must be ignored")
dbmCallbacks.DBM_TimerBegin(nil, "dbm-disabled", "Cast", 10, 456, "cd", 123, nil, nil, nil, false, "Cast", nil, nil, nil, nil, false, nil, false)
assert(#started == 1, "disabled DBM timers must be ignored")
dbmCallbacks.DBM_TimerPause(nil, "dbm-1")
assert(#paused == 1 and paused[1].value == true)
dbmCallbacks.DBM_TimerStop(nil, "dbm-1")
assert(#stopped == 1 and stopped[1].id == "dbm-1")

print("ok - BigWigs and DBM provider contracts")
