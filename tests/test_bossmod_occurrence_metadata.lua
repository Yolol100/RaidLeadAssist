local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local now = 100
local bwMessages = {}
local dbmCallbacks = {}
local started = {}

_G.GetTime = function() return now end
_G.issecretvalue = function() return false end
_G.table.wipe = _G.table.wipe or function(tbl) for key in pairs(tbl) do tbl[key] = nil end end
_G.BigWigsLoader = {
    RegisterMessage = function(_, name, callback) bwMessages[name] = callback end,
    UnregisterMessage = function() end,
}
_G.DBM = {
    Options = { IgnoreBlizzAPI = false },
    Mods = {},
    RegisterCallback = function(_, name, callback) dbmCallbacks[name] = callback end,
    UnregisterCallback = function() end,
}

local sink = {}
function sink:ProviderTimerStarted(provider, id, data)
    started[#started + 1] = { provider = provider, id = id, data = data }
end
function sink:ProviderTimerStopped() end
function sink:ProviderTimerPaused() end
function sink:ProviderTimerUpdated() end
function sink:ProviderTimerFaded() end
function sink:ProviderReset() end
function sink:ProviderEncounterHint() end
function sink:SetBlizzardSuppressedByProvider() end

T.Load("Core/Util.lua", ns)
T.Load("Services/Providers/BigWigsProvider.lua", ns)
T.Load("Services/Providers/DBMProvider.lua", ns)

local module = {
    moduleName = "Boss",
    GetEncounterID = function() return 3420 end,
}

local BigWigsProvider = ns:GetModule("Services.Providers.BigWigs")
assert(BigWigsProvider:Start(sink) == true)

bwMessages.BigWigs_StartBar(nil, module, 123, "Counted", 10, 456, false, 10, nil, 77)
bwMessages.BigWigs_Timer(nil, module, 123, 10, 10, "Counted", 3, 456, false, true)
assert(#started == 1 and started[1].data.count == 3)
assert(started[1].data.nativeEventID == 77)

bwMessages.BigWigs_Timer(nil, module, 124, 10, 10, "Uncounted", 0, 456, false, true)
assert(#started == 2 and started[2].data.count == nil)

bwMessages.BigWigs_StartBar(nil, module, 125, "Stale", 10, 456, false, 10, nil, 78)
now = now + 2
bwMessages.BigWigs_Timer(nil, module, 125, 10, 10, "Stale", 4, 456, false, true)
assert(#started == 3 and started[3].data.count == 4)
assert(started[3].data.nativeEventID == nil,
    "stale StartBar metadata must not enrich a later direct BigWigs timer")

local DBMProvider = ns:GetModule("Services.Providers.DBM")
assert(DBMProvider:Start(sink) == true)
dbmCallbacks.DBM_TimerBegin(nil, "dbm-count", "Counted", 10, 456, "cd", 123,
    nil, nil, nil, false, "Counted", nil, 5, nil, nil, false, nil, true)
assert(#started == 4 and started[4].provider == "DBM")
assert(started[4].data.count == 5,
    "DBM timerCount must survive provider normalization")

print("ok - DBM and BigWigs occurrence metadata is consumed safely")
