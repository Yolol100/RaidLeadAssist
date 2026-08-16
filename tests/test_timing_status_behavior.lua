local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

local idleLabel = nil
local timerShown = false
local nextTimerCalls = 0
local automaticTimingEnabled = true
local activeProfile = {
    calls = {
        { key = "manual", timing = false },
    },
}
activeProfile.callsByKey = { manual = activeProfile.calls[1] }

local Constants = {
    CallState = { IDLE = "IDLE", CALLED = "CALLED", PREPARE = "PREPARE", PRESS = "PRESS" },
    MANUAL_CLICK_LOCK_SECONDS = 1,
    CALLED_FEEDBACK_SECONDS = 1,
}
function Constants.GetCallState() return Constants.CallState.IDLE end

local Registry = {}
function Registry:GetProfile(bossKey, difficultyKey)
    assert(bossKey == "ulatek", "unexpected boss key")
    assert(difficultyKey == "heroic", "unexpected difficulty key")
    return activeProfile
end
function Registry:Get() return { strategyStatus = "test" } end

local Timeline = { timers = {} }
function Timeline:GetActionableTimerForCall() return nil end
function Timeline:GetNextActionableTimer() return nil end
function Timeline:GetNextTimer()
    nextTimerCalls = nextTimerCalls + 1
    if activeProfile.calls[1].timing == false then
        return { call = activeProfile.calls[1], sourceID = "stale" }, 5
    end
    return { call = activeProfile.calls[1], sourceID = "automatic" }, 5
end
function Timeline:IsActionable() return true end
function Timeline:GetProviderSummary() return "test" end
function Timeline:GetProviderDiagnostics() return "test" end
function Timeline:AcknowledgeCall() end

local UI = { timeline = {} }
function UI:SetCallState() end
function UI.timeline:SetIdle(label)
    idleLabel = label
    timerShown = false
end
function UI.timeline:SetTimer()
    timerShown = true
    idleLabel = nil
end
function UI.timeline:SetState() end

local Audio = {}
function Audio:Prepare() end
function Audio:Press() end
function Audio:GetDiagnostics() return "ok" end
function Audio:IsEnabled() return false end

local Database = {}
local EventBus = {}
local RaidWarning = {}
local Messages = {}
local Encounter = {}
local SettingsUI = {}

ns:RegisterModule("Core.Constants", Constants)
ns:RegisterModule("Core.Database", Database)
ns:RegisterModule("Core.EventBus", EventBus)
ns:RegisterModule("Encounters.Registry", Registry)
ns:RegisterModule("Services.RaidWarningService", RaidWarning)
ns:RegisterModule("Services.MessageService", Messages)
ns:RegisterModule("Services.AudioService", Audio)
ns:RegisterModule("Services.TimelineService", Timeline)
ns:RegisterModule("Services.EncounterService", Encounter)
ns:RegisterModule("UI.MainFrame", UI)
ns:RegisterModule("UI.SettingsFrame", SettingsUI)

_G.CreateFrame = function()
    return {
        RegisterEvent = function() end,
        UnregisterEvent = function() end,
        SetScript = function() end,
    }
end
_G.GetTime = function() return 100 end
_G.SlashCmdList = {}

T.Load("Core/App.lua", ns)
local App = ns:GetModule("Core.App")
App.activeBossKey = "ulatek"
App.activeDifficultyKey = "heroic"
App.db = { automaticTimingEnabled = true }
App.timingAllowed = true
App.visualCalledUntil = {}
App.manualLockUntil = {}
App.audioStates = {}

-- A manual-only profile must advertise that state without consulting stale provider timers.
App:UpdateTiming()
assert(idleLabel == "MANUAL CALLS ONLY",
    "manual-only profile must override stale/provider timing presentation")
assert(nextTimerCalls == 0,
    "manual-only profile should not query a provider timer it cannot act on")

-- Profiles that do have automatic calls keep the normal timing path.
activeProfile = {
    calls = {
        { key = "automatic", timing = true },
    },
}
activeProfile.callsByKey = { automatic = activeProfile.calls[1] }
idleLabel = nil
timerShown = false
App:UpdateTiming()
assert(timerShown == true, "automatic profile must preserve normal timer presentation")
assert(nextTimerCalls == 1, "automatic profile must query the normal timer path")

-- Explicit user disablement takes precedence over profile capability.
App.db.automaticTimingEnabled = false
idleLabel = nil
timerShown = false
App:UpdateTiming()
assert(idleLabel == "AUTO TIMING OFF",
    "user-disabled automatic timing must remain explicit")
assert(timerShown == false, "user-disabled timing must not leave a timer visible")

print("ok - canonical App timing status enforces manual-only and user-disabled states")
