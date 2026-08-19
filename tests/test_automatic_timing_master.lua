local source = debug.getinfo(1, "S").source:sub(2)
local root = source:match("^(.*[/\\])tests[/\\]") or "./"

local modules = {}
local ns = {
    version = "test",
    messages = {},
    GetModule = function(_, name)
        return assert(modules[name], "missing module " .. tostring(name))
    end,
    RegisterModule = function(_, name, module)
        modules[name] = module
    end,
    Print = function(self, message)
        self.messages[#self.messages + 1] = message
    end,
}

local sent = 0
local acknowledged = 0
local queries = 0
local audioPress = 0

modules["Core.Constants"] = {
    DIFFICULTIES = { heroic = { name = "Heroic" } },
    DIFFICULTY_KEY_BY_ID = { [15] = "heroic" },
    MANUAL_CLICK_LOCK_SECONDS = 1,
    CALLED_FEEDBACK_SECONDS = 1,
    CallState = { IDLE = "idle", CALLED = "called", PREPARE = "prepare", PRESS = "press" },
    GetCallState = function() return "press" end,
}
modules["Core.Database"] = {
    HasNewerSchema = function() return false end,
}
modules["Core.EventBus"] = { On = function() end }
modules["Encounters.Registry"] = {
    Get = function() return { strategyStatus = "test" } end,
    GetProfile = function()
        return { calls = { { key = "call", timing = true } }, callsByKey = { call = { key = "call" } } }
    end,
    GetOrdered = function() return {} end,
    SetActiveDifficulty = function() end,
}
modules["Services.RaidWarningService"] = {
    CanSend = function() return true end,
    Send = function() sent = sent + 1 return true end,
    CancelBriefing = function() end,
}
modules["Services.MessageService"] = { GetCallWarning = function() return "warning" end, Initialize = function() end }
modules["Services.AudioService"] = {
    GetDiagnostics = function() return "ready" end,
    IsEnabled = function() return true end,
    Press = function() audioPress = audioPress + 1 end,
    Prepare = function() end,
    Initialize = function() end,
}
modules["Services.TimelineService"] = {
    timers = {},
    GetProviderDiagnostics = function() return "DBM direct" end,
    GetProviderSummary = function() return "DBM" end,
    GetActionableTimerForCall = function()
        queries = queries + 1
        return { call = { key = "call" }, occurrenceID = 1 }, 1
    end,
    GetNextActionableTimer = function() return nil end,
    GetNextTimer = function() return nil end,
    IsActionable = function() return true end,
    AcknowledgeCall = function() acknowledged = acknowledged + 1 end,
    SetEncounter = function() end,
    Initialize = function() end,
    RefreshProviders = function() end,
    Reset = function() end,
}
modules["Services.EncounterService"] = {
    IsInRaidInstance = function() return true end,
    IsActive = function() return false end,
    HasKnownEncounter = function() return true end,
    GetDifficultyKey = function() return "heroic" end,
    GetDifficultyID = function() return 15 end,
    Initialize = function() end,
}
modules["UI.MainFrame"] = {
    SetCallState = function() end,
    timeline = { SetIdle = function() end, SetTimer = function() end, SetState = function() end },
}
modules["UI.SettingsFrame"] = {}

_G.GetTime = function() return 100 end
_G.CreateFrame = function()
    return { RegisterEvent = function() end, SetScript = function() end, UnregisterEvent = function() end }
end
_G.C_Timer = { After = function() end }

local chunk = assert(loadfile(root .. "Core/App.lua"))
chunk("RaidLeadAssist", ns)
local App = assert(modules["Core.App"])

App.db = { automaticTimingEnabled = false, schemaVersion = 1 }
App.activeBossKey = "nekzali"
App.activeDifficultyKey = "heroic"

App:UpdateTiming()
assert(queries == 0, "automatic timing must not query providers when the user master is disabled")
App:SendCall("call")
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
assert(ns.messages[#ns.messages - 1]:find("Tested bossmod contracts: DBM 12.1.4; BigWigs v419.2", 1, true),
    "doctor should expose the callback-contract baseline")

print("ok - automatic timing master, diagnostics, manual calls, and runtime safety")
