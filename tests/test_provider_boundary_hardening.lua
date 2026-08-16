local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local SECRET = {}
local NAN = 0 / 0
local INF = math.huge

local dbmCallbacks = {}
local bwMessages = {}
local dbmBossModule = { id = "2888", encounterId = 3421 }

_G.issecretvalue = function(value) return value == SECRET end
_G.table.wipe = _G.table.wipe or function(tbl) for key in pairs(tbl) do tbl[key] = nil end end
_G.Enum = { EncounterTimelineEventState = { Active = 0, Paused = 1, Finished = 2, Canceled = 3 } }
_G.CreateFrame = function() return T.Frame() end
_G.GetTime = function() return 100 end
_G.BigWigsLoader = {
    RegisterMessage = function(_, name, callback) bwMessages[name] = callback end,
    UnregisterMessage = function() end,
}
_G.DBM = {
    Options = { IgnoreBlizzAPI = false },
    Mods = { dbmBossModule },
    GetModByName = function(_, id)
        if tostring(id) == dbmBossModule.id then return dbmBossModule end
    end,
    RegisterCallback = function(_, name, callback) dbmCallbacks[name] = callback end,
    UnregisterCallback = function() end,
}

local timelineAPICalls = 0
_G.C_EncounterTimeline = {
    GetEventState = function() timelineAPICalls = timelineAPICalls + 1; return 0 end,
    GetEventInfo = function() timelineAPICalls = timelineAPICalls + 1; return nil end,
    GetEventTimeRemaining = function() timelineAPICalls = timelineAPICalls + 1; return 5 end,
    GetEventTimeElapsed = function() timelineAPICalls = timelineAPICalls + 1; return 1 end,
}

local started, stopped, paused, updated, faded, hints = {}, {}, {}, {}, {}, {}
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
function sink:SetBlizzardSuppressedByProvider() return false end
function sink:ProviderEncounterHint(provider, encounterID)
    hints[#hints + 1] = { provider = provider, encounterID = encounterID }
end

T.Load("Core/Util.lua", ns)
T.Load("Services/Providers/DBMProvider.lua", ns)
T.Load("Services/Providers/BigWigsProvider.lua", ns)
T.Load("Services/Providers/BlizzardProvider.lua", ns)

local DBMProvider = ns:GetModule("Services.Providers.DBM")
assert(DBMProvider:Start(sink) == true)

-- Valid control case.
dbmCallbacks.DBM_TimerBegin(nil, "valid", "Cast", 10, 456, "cd", 123, nil, 2888, nil, false, "Cast", nil, nil, nil, nil, false, nil, true)
assert(#started == 1 and started[1].provider == "DBM")

-- Adapter-level identity normalization must not turn malformed values into valid strings.
for _, badID in ipairs({ "", "   ", NAN, INF }) do
    dbmCallbacks.DBM_TimerBegin(nil, badID, "Cast", 10, 456, "cd", 123, nil, 2888, nil, false, "Cast", nil, nil, nil, nil, false, nil, true)
    dbmCallbacks.DBM_TimerStop(nil, badID)
    dbmCallbacks.DBM_TimerPause(nil, badID)
    dbmCallbacks.DBM_TimerUpdate(nil, badID, 1, 10)
end
assert(#started == 1, "malformed DBM IDs must be rejected before string conversion")
assert(#stopped == 0 and #paused == 0 and #updated == 0, "malformed DBM IDs must not reach lifecycle callbacks")

-- Unknown boolean-shaped metadata is uncertainty, not false.
dbmCallbacks.DBM_TimerBegin(nil, "bad-fade", "Cast", 10, 456, "cd", 123, nil, 2888, nil, "false", "Cast", nil, nil, nil, nil, false, nil, true)
dbmCallbacks.DBM_TimerBegin(nil, "bad-variance", "Cast", 10, 456, "cd", 123, nil, 2888, nil, false, "Cast", nil, nil, nil, nil, "false", nil, true)
assert(#started == 1, "malformed DBM fade/variance metadata must fail closed")
dbmCallbacks.DBM_TimerFadeUpdate(nil, "valid", 123, 2888, "false", "Cast")
assert(#faded == 0, "malformed DBM fade updates must be ignored")

local BigWigsProvider = ns:GetModule("Services.Providers.BigWigs")
assert(BigWigsProvider:Start(sink) == true)
local module = {
    moduleName = "Boss",
    GetEncounterID = function() return 3420 end,
    IsEngaged = function() return true end,
}
_G.BigWigs = {
    IterateBossModules = function() return next, { Boss = module }, nil end,
}

local beforeBigWigs = #started
bwMessages.BigWigs_Timer(nil, module, 123, 10, 10, "Cast", 0, 456, false, true)
assert(#started == beforeBigWigs + 1 and started[#started].provider == "BigWigs")

bwMessages.BigWigs_Timer(nil, module, 123, 10, 10, "Malformed Approx", 0, 456, "false", true)
assert(#started == beforeBigWigs + 1, "malformed BigWigs approximate metadata must not be upgraded to exact")

-- Invalid native event IDs may not survive by being stringified into a plausible timer identity.
for _, badEventID in ipairs({ NAN, INF, 0, -1, 1.5, "", "abc" }) do
    local before = #started
    bwMessages.BigWigs_StartBar(nil, nil, nil, "Timeline", 9, 456, 3, 10, badEventID, badEventID)
    assert(#started == before, "malformed BigWigs Blizzard-bridge event IDs must be rejected")
end

bwMessages.BigWigs_StartBar(nil, module, 123, "No Event Enrichment", 10, 456, false, 10, nil, NAN)
bwMessages.BigWigs_Timer(nil, module, 123, 10, 10, "No Event Enrichment", 0, 456, false, true)
assert(started[#started].data.nativeEventID == nil, "invalid BigWigs event metadata must not attach to a direct timer")

module.GetEncounterID = function() return NAN end
local beforeInvalidEncounter = #started
local beforeHints = #hints
bwMessages.BigWigs_Timer(nil, module, 123, 10, 10, "Bad Encounter", 0, 456, false, true)
bwMessages.BigWigs_OnBossEngage(nil, module)
assert(#started == beforeInvalidEncounter and #hints == beforeHints, "non-finite BigWigs encounter IDs must fail closed")

local BlizzardProvider = ns:GetModule("Services.Providers.Blizzard")
assert(BlizzardProvider:Start(sink) == true)
local beforeBlizzard = #started
BlizzardProvider:AddEvent({ id = 7, source = 0, duration = 10, spellID = 123, spellName = "Valid" }, 7)
assert(#started == beforeBlizzard + 1 and started[#started].provider == "Blizzard")

for _, badEventID in ipairs({ NAN, INF, 0, -1, 1.5, "", "abc" }) do
    local before = #started
    BlizzardProvider:AddEvent({ id = badEventID, source = 0, duration = 10, spellID = 123, spellName = "Bad ID" }, badEventID)
    assert(#started == before, "malformed Blizzard event IDs must be rejected")
end

local beforeBadInfo = #started
assert(pcall(function() BlizzardProvider:AddEvent("not-a-table", 7) end), "malformed Blizzard event info must not throw")
BlizzardProvider:AddEvent({ id = 8, source = 0, duration = INF, spellID = 123, spellName = "Infinite" }, 8)
BlizzardProvider:AddEvent({ id = 9, source = 0, duration = NAN, spellID = 123, spellName = "NaN" }, 9)
assert(#started == beforeBadInfo, "non-finite Blizzard durations must fail closed")

local callsBeforeInvalidIDs = timelineAPICalls
for _, badEventID in ipairs({ NAN, INF, 0, -1, 1.5, "", "abc", {} }) do
    assert(BlizzardProvider:GetSafeRemaining(badEventID) == nil)
end
assert(timelineAPICalls == callsBeforeInvalidIDs, "invalid Blizzard event IDs must never reach timeline APIs")

print("ok - provider adapters fail closed before malformed identities, booleans, encounter IDs, and timeline event IDs can be normalized into trusted data")
