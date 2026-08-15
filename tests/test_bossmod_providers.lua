local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local SECRET = {}
local bwMessages = {}
local dbmCallbacks = {}
local started, stopped, paused = {}, {}, {}
local hints, suppression = {}, {}

_G.issecretvalue = function(value) return value == SECRET end
_G.table.wipe = _G.table.wipe or function(tbl) for key in pairs(tbl) do tbl[key] = nil end end
_G.BigWigsLoader = {
    RegisterMessage = function(owner, name, callback) bwMessages[name] = callback end,
    UnregisterMessage = function() end,
}
_G.DBM = {
    Options = { IgnoreBlizzAPI = false },
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
function sink:ProviderEncounterHint(provider, encounterID)
    hints[#hints + 1] = { provider = provider, encounterID = encounterID }
end
function sink:SetBlizzardSuppressedByProvider(provider, value)
    suppression[#suppression + 1] = { provider = provider, value = value }
end

T.Load("Core/Util.lua", ns)
T.Load("Services/Providers/BigWigsProvider.lua", ns)
T.Load("Services/Providers/DBMProvider.lua", ns)

local BigWigs = ns:GetModule("Services.Providers.BigWigs")
assert(BigWigs:Start(sink) == true)
local module = {
    moduleName = "Boss",
    GetEncounterID = function() return 3420 end,
}

-- BigWigs v419.2/current upstream boss modules expose the canonical data bus as:
-- module, key, duration, maxTime, text, counter, icon, isApproximate, isBarEnabled.
bwMessages.BigWigs_Timer(nil, module, 123, 10, 10, "Cast", 0, 456, false, true)
assert(#started == 1 and started[1].provider == "BigWigs")
assert(started[1].id == "Boss|text:Cast" and started[1].data.key == 123)
assert(started[1].data.nativeEventID == nil and started[1].data.precision == "exact")

bwMessages.BigWigs_Timer(nil, module, 123, 10, 10, "Approx", 0, 456, true, true)
assert(#started == 2 and started[2].data.precision == "approximate")

bwMessages.BigWigs_Timer(nil, module, 123, 10, 10, "Disabled", 0, 456, false, false)
assert(#started == 2, "disabled BigWigs bars must stay disabled as an RLA data source")

-- A regular BigWigs_StartBar is visual-bar transport and must not be interpreted
-- as a second direct timer. In v419.2 its trailing slot can contain eventId/spell-indicator data.
bwMessages.BigWigs_StartBar(nil, module, 123, "Cast", 10, 456, false, 10, nil, 77)
assert(#started == 2, "regular StartBar must not duplicate the canonical BigWigs_Timer event")

-- BigWigs' Blizzard Timeline bridge is intentionally StartBar-based and has nil module/key.
bwMessages.BigWigs_StartBar(nil, nil, nil, "Timeline Cast", 9, 456, 3, 10, 79, nil)
assert(#started == 3)
assert(started[3].id == "blizzard-timeline|event:79")
assert(started[3].data.bridge == "Blizzard" and started[3].data.precision == "native")
assert(started[3].data.nativeEventID == 79)

-- Current bridge event callback can repeat the event ID in the final slot.
bwMessages.BigWigs_StartBar(nil, nil, nil, "Timeline Cast 2", 8, 456, 3, nil, 80, 80)
assert(#started == 4 and started[4].id == "blizzard-timeline|event:80")

bwMessages.BigWigs_Timer(nil, module, 123, SECRET, 10, "Secret", 0, 456, false, true)
assert(#started == 4, "secret BigWigs durations must fail closed")

bwMessages.BigWigs_PauseBar(nil, module, "Cast")
assert(#paused == 1 and paused[1].value == true)
bwMessages.BigWigs_StopBar(nil, module, "Cast")
assert(#stopped == 1 and stopped[1].id == "Boss|text:Cast")

bwMessages.BigWigs_OnBossEngageMidEncounter(nil, module)
assert(#hints == 1 and hints[1].provider == "BigWigs" and hints[1].encounterID == 3420)

started, stopped, paused = {}, {}, {}
local DBMProvider = ns:GetModule("Services.Providers.DBM")
assert(DBMProvider:Start(sink) == true)

-- DBM-Core 12.1.3/current upstream DBM_TimerBegin shape.
dbmCallbacks.DBM_TimerBegin(nil, "dbm-1", "Cast", 10, 456, "cd", 123, nil, nil, nil, false, "Cast", nil, nil, nil, nil, false, nil, true)
assert(#started == 1 and started[1].provider == "DBM" and started[1].id == "dbm-1")
assert(started[1].data.key == 123 and started[1].data.name == "Cast")
assert(started[1].data.precision == "exact")

dbmCallbacks.DBM_TimerBegin(nil, "dbm-variance", "Cast", 10, 456, "cd", 123, nil, nil, nil, false, "Cast", nil, nil, nil, nil, true, nil, true)
assert(#started == 1, "variable DBM timers must be ignored")
dbmCallbacks.DBM_TimerBegin(nil, "dbm-disabled", "Cast", 10, 456, "cd", 123, nil, nil, nil, false, "Cast", nil, nil, nil, nil, false, nil, false)
assert(#started == 1, "disabled DBM timers must be ignored")

dbmCallbacks.DBM_TimerPause(nil, "dbm-1")
assert(#paused == 1 and paused[1].value == true)
dbmCallbacks.DBM_TimerStop(nil, "dbm-1")
assert(#stopped == 1 and stopped[1].id == "dbm-1")

dbmCallbacks.DBM_IgnoreBlizzAPI()
assert(suppression[#suppression].provider == "DBM" and suppression[#suppression].value == true)
dbmCallbacks.DBM_ResumeBlizzAPI()
assert(suppression[#suppression].provider == "DBM" and suppression[#suppression].value == false)

dbmCallbacks.DBM_Pull(nil, { encounterId = 3421 })
assert(hints[#hints].provider == "DBM" and hints[#hints].encounterID == 3421)

print("ok - exact BigWigs v419.2 and DBM 12.1.3 provider contracts")
