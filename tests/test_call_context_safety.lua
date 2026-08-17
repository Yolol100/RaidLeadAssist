local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local now = 100
local active = true
local known = false
local difficulty = "heroic"
local warnings = {}
local briefings = 0
local encounterModule

_G.GetTime = function() return now end
_G.SlashCmdList = {}
_G.issecretvalue = function() return false end
_G.CreateFrame = function()
    return { RegisterEvent=function() end, UnregisterEvent=function() end, SetScript=function() end }
end

ns.Print = function() end
ns:RegisterModule("Core.Constants", { MANUAL_CLICK_LOCK_SECONDS=1.25, CALLED_FEEDBACK_SECONDS=0.8, CallState={CALLED="CALLED"} })
ns:RegisterModule("Core.Database", { HasNewerSchema=function() return false end })
ns:RegisterModule("Core.EventBus", { On=function() end })
ns:RegisterModule("Encounters.Registry", {
    GetProfile=function(_, bossKey, difficultyKey)
        if bossKey == "boss" and difficultyKey == "heroic" then return { callsByKey={kick={key="kick"}} } end
    end,
})
ns:RegisterModule("Services.RaidWarningService", {
    Send=function(_, text) warnings[#warnings+1]=text return true end,
    SendBriefing=function() briefings=briefings+1 return true end,
})
ns:RegisterModule("Services.MessageService", { GetCallWarning=function() return "BASE WARNING" end, GetExplanation=function() return {"PLAN"} end })
ns:RegisterModule("Services.AssignmentService", { BuildCallWarning=function(_, warning) return warning, true end, AdvanceCall=function() end })
ns:RegisterModule("Services.AudioService", {})
ns:RegisterModule("Services.TimelineService", { AcknowledgeCall=function() end })
encounterModule = {
    currentEncounter=nil,
    IsActive=function() return active end,
    HasKnownEncounter=function() return known end,
    GetDifficultyKey=function() return difficulty end,
}
ns:RegisterModule("Services.EncounterService", encounterModule)
ns:RegisterModule("UI.MainFrame", { SetCallState=function() end })
ns:RegisterModule("UI.SettingsFrame", {})
ns:RegisterModule("UI.AssignmentFrame", {})
ns:RegisterModule("UI.AssignmentLaunchers", {})

T.Load("Core/App.lua", ns)
local App = ns:GetModule("Core.App")
App.activeBossKey="boss"; App.activeDifficultyKey="heroic"; App.manualLockUntil={}; App.visualCalledUntil={}; App.db={}

assert(App:SendCall("kick") == false, "unknown active encounter must block manual Raid Warnings")
assert(App:SendExplanation() == false, "all active encounters must block the pre-pull raid plan")
assert(#warnings == 0 and briefings == 0)

known=true; encounterModule.currentEncounter={key="boss"}; difficulty=nil
assert(App:SendCall("kick") == false, "unsupported difficulty must block manual Raid Warnings")

difficulty="heroic"; encounterModule.currentEncounter={key="other"}
assert(App:SendCall("kick") == false, "stale selected boss must not send a call for another live encounter")

active=false
assert(App:SendExplanation() == true and briefings == 1, "raid plan must remain usable outside encounters")

active=true; known=true; difficulty="heroic"; encounterModule.currentEncounter={key="boss"}
assert(App:SendExplanation() == false and briefings == 1, "raid plan must not send after the pull has begun")
assert(App:SendCall("kick") == true, "verified supported encounter must allow the configured combat call")
assert(#warnings == 1 and warnings[1] == "BASE WARNING")

print("ok - canonical App enforces active encounter Raid Warning context and pre-pull lifecycle")
