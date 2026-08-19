local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local now = 100
local timerQueries = 0
local audioPrepare = 0
local audioPress = 0
local lastIdle = nil

_G.GetTime = function() return now end
_G.CreateFrame = function() return T.Frame() end
_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/VenomousAbyss/Ulatek.lua", ns)

local Registry = ns:GetModule("Encounters.Registry")
local exactProviderTimer = {
    call = { key = "provider-fixture" },
    occurrenceID = 1,
    sourceID = "bigwigs-ulatek-live",
    providerName = "BigWigs",
    precision = "exact",
    expiration = now + 20,
}

ns:RegisterModule("Core.Database", {
    HasNewerSchema = function() return false end,
    ResetPosition = function() end,
})
ns:RegisterModule("Core.EventBus", { On = function() end })
ns:RegisterModule("Services.RaidWarningService", {
    Send = function() return true end,
    CancelBriefing = function() end,
    CanSend = function() return true end,
})
ns:RegisterModule("Services.MessageService", { GetCallWarning = function() return "CALL" end })
ns:RegisterModule("Services.AudioService", {
    Press = function() audioPress = audioPress + 1 end,
    Prepare = function() audioPrepare = audioPrepare + 1 end,
    GetDiagnostics = function() return "off" end,
    IsEnabled = function() return false end,
})
ns:RegisterModule("Services.TimelineService", {
    timers = { ["BigWigs|ulatek-live"] = exactProviderTimer },
    GetActionableTimerForCall = function()
        timerQueries = timerQueries + 1
        return exactProviderTimer, 20
    end,
    GetNextActionableTimer = function()
        timerQueries = timerQueries + 1
        return exactProviderTimer, 20
    end,
    GetNextTimer = function()
        timerQueries = timerQueries + 1
        return exactProviderTimer, 20
    end,
    IsActionable = function() return true end,
    AcknowledgeCall = function() return true end,
    GetProviderSummary = function() return "BigWigs" end,
    GetProviderDiagnostics = function() return "BigWigs live Ula'tek bars" end,
})
ns:RegisterModule("Services.EncounterService", {
    IsActive = function() return true end,
    IsInRaidInstance = function() return true end,
    HasKnownEncounter = function() return true end,
    GetDifficultyKey = function() return "heroic" end,
    GetDifficultyID = function() return 15 end,
})
ns:RegisterModule("UI.MainFrame", {
    timeline = {
        SetIdle = function(_self, text) lastIdle = text end,
        SetTimer = function() error("manual-only Ula'tek must not publish an automatic timer") end,
        SetState = function() error("manual-only Ula'tek must not publish an automatic timing state") end,
    },
    SetCallState = function() end,
    ResetCallStates = function() end,
})
ns:RegisterModule("UI.SettingsFrame", { frame = { IsShown = function() return false end } })

T.Load("Core/App.lua", ns)
local App = ns:GetModule("Core.App")
App.db = { automaticTimingEnabled = true, schemaVersion = 5 }
App.activeBossKey = "ulatek"
App.timingAllowed = true

for _, difficulty in ipairs({ "normal", "heroic", "mythic" }) do
    local profile = Registry:GetProfile("ulatek", difficulty)
    assert(profile and #profile.calls > 0, "Ula'tek profile must exist for " .. difficulty)
    for _, call in ipairs(profile.calls) do
        assert(call.timing == false, "every Ula'tek call must stay manual-only on " .. difficulty)
    end

    assert(Registry:SetActiveDifficulty(difficulty) == true)
    App.activeDifficultyKey = difficulty
    timerQueries = 0
    audioPrepare = 0
    audioPress = 0
    lastIdle = nil

    App:UpdateTiming()

    assert(timerQueries == 0,
        "exact BigWigs/Blizzard provider traffic must not be queried for manual-only Ula'tek on " .. difficulty)
    assert(audioPrepare == 0 and audioPress == 0,
        "manual-only Ula'tek must not emit PREPARE/PRESS audio on " .. difficulty)
    assert(lastIdle == "MANUAL CALLS ONLY",
        "Ula'tek timeline must remain explicitly manual-only on " .. difficulty)
end

print("ok - Ula'tek remains manual-only across all difficulties even when exact provider traffic is available")
