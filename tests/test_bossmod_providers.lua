local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local SECRET = {}
local bwMessages = {}
local dbmCallbacks = {}
local started, stopped, paused, updated, faded = {}, {}, {}, {}, {}
local hints, suppression = {}, {}

_G.issecretvalue = function(value) return value == SECRET end
_G.table.wipe = _G.table.wipe or function(tbl) for key in pairs(tbl) do tbl[key] = nil end end
_G.BigWigsLoader = {
    RegisterMessage = function(owner, name, callback) bwMessages[name] = callback end,
    UnregisterMessage = function() end,
}
local dbmBossModule = { id = "2888", encounterId = 3421 }
_G.DBM = {
    Options = { IgnoreBlizzAPI = false },
    Mods = { dbmBossModule },
    GetModByName = function(_, id)
        if tostring(id) == dbmBossModule.id then return dbmBossModule end
    end,
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
function sink:ProviderTimerUpdated(provider, id, elapsed, total)
    updated[#updated + 1] = { provider = provider, id = id, elapsed = elapsed, total = total }
end
function sink:ProviderTimerFaded(provider, id, value)
    faded[#faded + 1] = { provider = provider, id = id, value = value }
end
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

local BigWigsProvider = ns:GetModule("Services.Providers.BigWigs")
assert(BigWigsProvider:Start(sink) == true)
local module = {
    moduleName = "Boss",
    GetEncounterID = function() return 3420 end,
    IsEngaged = function() return true end,
}
_G.BigWigs = {
    IterateBossModules = function()
        return next, { Boss = module }, nil
    end,
}

-- BigWigs v419.2/current upstream sends StartBar first when the visual bar is enabled,
-- then the canonical Timer event. The optional timeline event ID is in StartBar's final slot.
bwMessages.BigWigs_StartBar(nil, module, 123, "Cast", 10, 456, false, 10, nil, 77)
assert(#started == 0, "regular StartBar must never create a duplicate direct timer")
bwMessages.BigWigs_Timer(nil, module, 123, 10, 10, "Cast", 0, 456, false, true)
assert(#started == 1 and started[1].provider == "BigWigs")
assert(started[1].id == "Boss|text:Cast" and started[1].data.key == 123)
assert(started[1].data.encounterID == 3420)
assert(started[1].data.nativeEventID == 77 and started[1].data.precision == "exact")

bwMessages.BigWigs_StartBar(nil, module, 123, "Approx", 10, 456, true, 10, nil, 78)
bwMessages.BigWigs_Timer(nil, module, 123, 10, 10, "Approx", 0, 456, true, true)
assert(#started == 2 and started[2].data.precision == "approximate")
assert(started[2].data.nativeEventID == 78)

bwMessages.BigWigs_Timer(nil, module, 123, 10, 10, "Disabled", 0, 456, false, false)
assert(#started == 2, "disabled BigWigs bars must stay disabled as an RLA data source")

-- Plugins/API/test/wipe/keystone tools also emit BigWigs_Timer but do not own a boss encounter.
local plugin = { moduleName = "Bars" }
bwMessages.BigWigs_Timer(nil, plugin, 123, 10, 10, "Cast", 0, 456, false, true)
assert(#started == 2, "non-boss BigWigs plugin timers must never become RLA boss calls")

-- Cast bars use a separate canonical BigWigs_CastTimer bus but share the same one-shot
-- StartBar event-ID enrichment contract.
bwMessages.BigWigs_StartBar(nil, module, 1293792, "Flood", 18, 456, false, 18, nil, 81)
assert(#started == 2)
bwMessages.BigWigs_CastTimer(nil, module, 1293792, 18, 18, "Flood", 0, 456, "Flood", true)
assert(#started == 3 and started[3].id == "Boss|text:Flood")
assert(started[3].data.key == 1293792 and started[3].data.nativeEventID == 81)
assert(started[3].data.precision == "exact")

-- BigWigs' Blizzard Timeline bridge is intentionally StartBar-based and has nil module/key.
bwMessages.BigWigs_StartBar(nil, nil, nil, "Timeline Cast", 9, 456, 3, 10, 79, nil)
assert(#started == 4)
assert(started[4].id == "blizzard-timeline|event:79")
assert(started[4].data.bridge == "Blizzard" and started[4].data.precision == "native")
assert(started[4].data.nativeEventID == 79)

-- Current bridge event callback can repeat the event ID in the final slot.
bwMessages.BigWigs_StartBar(nil, nil, nil, "Timeline Cast 2", 8, 456, 3, nil, 80, 80)
assert(#started == 5 and started[5].id == "blizzard-timeline|event:80")

bwMessages.BigWigs_Timer(nil, module, 123, SECRET, 10, "Secret", 0, 456, false, true)
assert(#started == 5, "secret BigWigs durations must fail closed")

bwMessages.BigWigs_PauseBar(nil, module, "Cast")
assert(#paused == 1 and paused[1].value == true)
bwMessages.BigWigs_StopBar(nil, module, "Cast")
assert(#stopped == 1 and stopped[1].id == "Boss|text:Cast")

bwMessages.BigWigs_OnBossEngageMidEncounter(nil, module)
assert(#hints == 1 and hints[1].provider == "BigWigs" and hints[1].encounterID == 3420)

-- RLA can load after BigWigs has already sent the mid-encounter event. Seed the
-- retained public IsEngaged/GetEncounterID state so recovery does not depend on event order.
hints = {}
assert(BigWigsProvider:SeedEncounterHint() == true)
assert(#hints == 1 and hints[1].provider == "BigWigs" and hints[1].encounterID == 3420)
module.IsEngaged = function() return false end
hints = {}
assert(BigWigsProvider:SeedEncounterHint() == false and #hints == 0)

started, stopped, paused, updated, faded = {}, {}, {}, {}, {}
local DBMProvider = ns:GetModule("Services.Providers.DBM")
assert(DBMProvider:Start(sink) == true)

-- DBM-Core 12.1.3/current upstream DBM_TimerBegin shape. The public mod ID is
-- resolved to the loaded boss module's real encounterId before RLA sees it.
dbmCallbacks.DBM_TimerBegin(nil, "dbm-1", "Cast", 10, 456, "cd", 123, nil, 2888, nil, false, "Cast", nil, nil, nil, nil, false, nil, true)
assert(#started == 1 and started[1].provider == "DBM" and started[1].id == "dbm-1")
assert(started[1].data.key == 123 and started[1].data.name == "Cast")
assert(started[1].data.encounterID == 3421)
assert(started[1].data.precision == "exact" and started[1].data.faded == false)

dbmCallbacks.DBM_TimerUpdate(nil, "dbm-1", 3, 12)
assert(#updated == 1 and updated[1].id == "dbm-1" and updated[1].elapsed == 3 and updated[1].total == 12)

dbmCallbacks.DBM_TimerBegin(nil, "dbm-variance", "Cast", 10, 456, "cd", 123, nil, 2888, nil, false, "Cast", nil, nil, nil, nil, true, nil, true)
assert(#started == 1, "variable DBM timers must be ignored")
dbmCallbacks.DBM_TimerBegin(nil, "dbm-disabled", "Cast", 10, 456, "cd", 123, nil, 2888, nil, false, "Cast", nil, nil, nil, nil, false, nil, false)
assert(#started == 1, "disabled DBM timers must be ignored")

-- A faded DBM bar still exists. Preserve it as non-actionable state so a later unfade
-- can restore the same timer occurrence instead of losing it permanently.
dbmCallbacks.DBM_TimerBegin(nil, "dbm-faded", "Faded", 10, 456, "cd", 124, nil, 2888, nil, true, "Faded", nil, nil, nil, nil, false, nil, true)
assert(#started == 2 and started[2].id == "dbm-faded" and started[2].data.faded == true)

dbmCallbacks.DBM_TimerPause(nil, "dbm-1")
assert(#paused == 1 and paused[1].value == true)
dbmCallbacks.DBM_TimerResume(nil, "dbm-1")
assert(#paused == 2 and paused[2].value == false)

-- Exact 12.1.3 fade update: id, spellId, modId, fade, spellName. Both fade and unfade
-- are state changes on the existing bar; neither is a TimerStop.
dbmCallbacks.DBM_TimerFadeUpdate(nil, "dbm-1", 123, 2888, true, "Cast")
assert(#faded == 1 and faded[1].id == "dbm-1" and faded[1].value == true)
assert(#stopped == 0)
dbmCallbacks.DBM_TimerFadeUpdate(nil, "dbm-1", 123, 2888, nil, "Cast")
assert(#faded == 2 and faded[2].id == "dbm-1" and faded[2].value == false)
assert(#stopped == 0)
dbmCallbacks.DBM_TimerFadeUpdate(nil, "dbm-1", 123, 2888, SECRET, "Cast")
assert(#faded == 2, "secret fade state must fail closed")

dbmCallbacks.DBM_TimerStop(nil, "dbm-1")
assert(#stopped == 1 and stopped[1].id == "dbm-1")

DBM.Options.IgnoreBlizzAPI = true
dbmCallbacks.DBM_IgnoreBlizzAPI()
assert(suppression[#suppression].provider == "DBM" and suppression[#suppression].value == true)
DBM.Options.IgnoreBlizzAPI = false
dbmCallbacks.DBM_ResumeBlizzAPI()
assert(suppression[#suppression].provider == "DBM" and suppression[#suppression].value == false)

dbmCallbacks.DBM_Pull(nil, { encounterId = 3421 })
assert(hints[#hints].provider == "DBM" and hints[#hints].encounterID == 3421)

-- DBM can also recover its combat state before RLA has registered DBM_Pull.
local dbmMod = {
    encounterId = 3421,
    IsInCombat = function() return true end,
}
DBM.Mods = { dbmMod }
hints = {}
assert(DBMProvider:SeedEncounterHint() == true)
assert(#hints == 1 and hints[1].provider == "DBM" and hints[1].encounterID == 3421)
dbmMod.IsInCombat = function() return false end
hints = {}
assert(DBMProvider:SeedEncounterHint() == false and #hints == 0)

print("ok - exact BigWigs/DBM contracts, boss encounter identity, event enrichment, cast timers, fade lifecycle, authority state, and late recovery")
