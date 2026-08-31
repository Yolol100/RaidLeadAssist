local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local now = 100
local queries = 0
local idle = 0
local sent = 0
local acknowledged = 0
local audioPress = 0

_G.GetTime = function() return now end
_G.CreateFrame = function() return T.Frame() end
_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
local call = { key = "kick", ability = "Kick", voice = "Kick", warning = "KICK", spellIDs = { 123 } }
local profile = { calls = { call }, callsByKey = { kick = call } }

ns:RegisterModule("Core.Database", { HasNewerSchema = function() return false end, ResetPosition = function() end })
ns:RegisterModule("Core.EventBus", { On = function() end })
ns:RegisterModule("Encounters.Registry", {
    Get = function() return { key = "boss", strategyStatus = "test" } end,
    GetProfile = function() return profile end,
    GetOrdered = function() return {} end,
    SetActiveDifficulty = function() return true end,
})
ns:RegisterModule("Services.RaidWarningService", {
    Send = function() sent = sent + 1 return true end,
    CancelBriefing = function() end,
    CanSend = function() return true end,
})
ns:RegisterModule("Services.MessageService", { GetCallWarning = function() return "KICK" end })
ns:RegisterModule("Services.AudioService", {
    Press = function() audioPress = audioPress + 1 end,
    Prepare = function() end,
    GetDiagnostics = function() return "off" end,
    IsEnabled = function() return false end,
})
local timer = { call = call, occurrenceID = 1, sourceID = "x" }
ns:RegisterModule("Services.TimelineService", {
    GetActionableTimerForCall = function()
        queries = queries + 1
        return timer, 2
    end,
    GetNextActionableTimer = function() return timer, 2 end,
    GetNextTimer = function() return nil end,
    IsActionable = function() return true end,
    AcknowledgeCall = function() acknowledged = acknowledged + 1 return true end,
    GetProviderSummary = function() return "DBM" end,
    GetProviderDiagnostics = function() return "DBM" end,
})
ns:RegisterModule("Services.EncounterService", {
    IsActive = function() return false end,
    IsInRaidInstance = function() return true end,
    HasKnownEncounter = function() return true end,
    GetDifficultyKey = function() return "heroic" end,
    GetDifficultyID = function() return 15 end,
})
ns:RegisterModule("UI.MainFrame", {
    timeline = {
        SetIdle = function() idle = idle + 1 end,
        SetTimer = function() end,
        SetState = function() end,
    },
    SetCallState = function() end,
    ResetCallStates = function() end,
})
ns:RegisterModule("UI.SettingsFrame", { frame = { IsShown = function() return false end } })

T.Load("Core/App.lua", ns)
local App = ns:GetModule("Core.App")
App.db = { automaticTimingEnabled = false, schemaVersion = 5 }
App.activeBossKey = "boss"
App.activeDifficultyKey = "heroic"
App.timingAllowed = true

App:UpdateTiming()
assert(queries == 0 and idle == 1, "user timing master must stop timer-driven UI/TTS queries")

App:SendCall("kick")
assert(sent == 1 and acknowledged == 1, "manual calls must remain usable when automatic timing is off")

App.db.automaticTimingEnabled = true
App.manualLockUntil = {}
App:UpdateTiming()
assert(queries > 0 and audioPress == 1, "automatic timing must resume when the user master is enabled")

App.timingAllowed = false
queries = 0
App:UpdateTiming()
assert(queries == 0, "user timing setting must never override runtime encounter safety")

App.timingAllowed = true
App:PrintDoctor()
assert(ns.messages[#ns.messages - 6]:find("Doctor: READY", 1, true), "doctor should report a ready pre-pull test context")
assert(ns.messages[#ns.messages - 1]:find("Tested bossmod contracts:", 1, true),
    "doctor should expose the callback-contract baseline")

print("ok - automatic timing master, diagnostics, manual calls, and runtime safety")
