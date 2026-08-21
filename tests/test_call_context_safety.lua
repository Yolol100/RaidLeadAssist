local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local now = 100
local active = true
local known = false
local difficulty = "heroic"
local warnings = {}
local briefings = 0
local prints = {}
local handlers = {}
local explanationEnabled = true
local callEnabled = true
local encounterModule

_G.GetTime = function() return now end
_G.InCombatLockdown = function() return false end
_G.SlashCmdList = {}
_G.issecretvalue = function() return false end

ns.Print = function(_, text) prints[#prints + 1] = text end
ns:RegisterModule("Core.Constants", {
    MANUAL_CLICK_LOCK_SECONDS = 1.25,
    CALLED_FEEDBACK_SECONDS = 0.8,
    CallState = { CALLED = "CALLED" },
})
ns:RegisterModule("Core.Database", { HasNewerSchema = function() return false end })
ns:RegisterModule("Core.EventBus", {
    On = function(_, name, _, callback) handlers[name] = callback end,
})
ns:RegisterModule("Encounters.Registry", {
    GetProfile = function(_, bossKey, difficultyKey)
        if bossKey == "boss" and difficultyKey == "heroic" then
            return { callsByKey = { kick = { key = "kick" } } }
        end
    end,
})
ns:RegisterModule("Encounters.SetupRegistry", {})
ns:RegisterModule("Services.RaidWarningService", {
    Send = function(_, text) warnings[#warnings + 1] = text return true end,
    SendBriefing = function() briefings = briefings + 1 return true end,
})
ns:RegisterModule("Services.MessageService", {
    GetCallWarning = function() return "BASE WARNING" end,
})
ns:RegisterModule("Services.AssignmentService", {
    Initialize = function() end,
    ResetRuntime = function() end,
    GetValues = function() return { tank = "MainTank" } end,
    IsCallReady = function() return true end,
    BuildCallAction = function(_, action) return action, true end,
    BuildCallWarning = function(_, warning) return warning, true end,
    AdvanceCall = function() end,
})
ns:RegisterModule("Services.AssignmentPlanService", {
    BuildLines = function() return { "PLAN" } end,
})
ns:RegisterModule("Services.SetupService", { Initialize = function() end })
ns:RegisterModule("Services.TimelineService", { AcknowledgeCall = function() end })
encounterModule = {
    currentEncounter = nil,
    IsActive = function() return active end,
    HasKnownEncounter = function() return known end,
    GetDifficultyKey = function() return difficulty end,
}
ns:RegisterModule("Services.EncounterService", encounterModule)
ns:RegisterModule("UI.MainFrame", {
    explanationButton = { frame = { SetEnabled = function(_, value) explanationEnabled = value end } },
    callButtons = { { frame = { SetEnabled = function(_, value) callEnabled = value end } } },
    SetCallState = function() end,
})
ns:RegisterModule("UI.SettingsFrame", {})
ns:RegisterModule("UI.AssignmentFrame", {
    Initialize = function() end,
    Open = function() end,
    CloseForEncounter = function() end,
})
ns:RegisterModule("UI.AssignmentPreview", { Attach = function() end })
ns:RegisterModule("UI.AssignmentLaunchers", { Attach = function() end })
ns:RegisterModule("UI.SetupCard", {})

local App = {
    activeBossKey = "boss",
    activeDifficultyKey = "heroic",
    manualLockUntil = {},
    visualCalledUntil = {},
    db = {},
    Initialize = function() end,
    SelectBoss = function() return true end,
    SelectDifficulty = function() return true end,
    SendExplanation = function()
        briefings = briefings + 1
        return true
    end,
}
ns:RegisterModule("Core.App", App)

T.Load("Core/AssignmentIntegration.lua", ns)

assert(App:SendCall("kick") == false, "unknown active encounter must block manual Raid Warnings")
assert(App:SendExplanation() == false, "all active encounters must block the pre-pull raid plan")
assert(#warnings == 0 and briefings == 0)

assert(handlers.ENCOUNTER_STARTED, "encounter start guard must be registered")
assert(handlers.ENCOUNTER_RECOVERED, "encounter recovery guard must be registered")
handlers.ENCOUNTER_STARTED()
assert(explanationEnabled == false and callEnabled == false,
    "unsafe active encounter must disable visible plan/call controls")

known = true
encounterModule.currentEncounter = { key = "boss" }
difficulty = "heroic"
handlers.ENCOUNTER_RECOVERED()
assert(explanationEnabled == false and callEnabled == true,
    "verified recovery must re-enable combat calls while keeping the pre-pull plan disabled")

known = true
encounterModule.currentEncounter = { key = "boss" }
difficulty = nil
assert(App:SendCall("kick") == false, "unsupported difficulty must block manual Raid Warnings")
assert(#warnings == 0)

difficulty = "heroic"
encounterModule.currentEncounter = { key = "other" }
assert(App:SendCall("kick") == false, "stale selected boss must not send a call for another live encounter")
assert(#warnings == 0)

active = false
handlers.ENCOUNTER_ENDED()
assert(explanationEnabled == true and callEnabled == true,
    "leaving the encounter must restore pre-pull plan and manual call controls")
assert(App:SendExplanation() == true and briefings == 1,
    "raid plan must remain usable outside encounters")

active = true
known = true
difficulty = "heroic"
encounterModule.currentEncounter = { key = "boss" }
handlers.ENCOUNTER_STARTED()
assert(explanationEnabled == false and callEnabled == true,
    "verified active encounters should keep combat calls enabled but disable the pre-pull plan")
assert(App:SendExplanation() == false and briefings == 1,
    "raid plan must not send after the pull has begun")
assert(App:SendCall("kick") == true, "verified supported encounter must allow the configured combat call")
assert(#warnings == 1 and warnings[1] == "BASE WARNING")

print("ok - active encounter Raid Warning context, recovery and pre-pull lifecycle")
