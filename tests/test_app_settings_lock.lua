local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

_G.CreateFrame = function() return T.Frame() end
_G.issecretvalue = function() return false end
_G.table.wipe = _G.table.wipe or function(tbl) for key in pairs(tbl) do tbl[key] = nil end end

T.Load("Core/Constants.lua", ns)
local selectedDifficulty
local timelineEncounter
local uiDifficulty
local resetCount = 0

ns:RegisterModule("Core.Database", {
    HasNewerSchema = function() return false end,
    ResetPosition = function() end,
})
ns:RegisterModule("Core.EventBus", { On = function() end })
ns:RegisterModule("Encounters.Registry", {
    SetActiveDifficulty = function(_, key) selectedDifficulty = key return true end,
    Get = function() return {} end,
    GetProfile = function() return { calls = {}, callsByKey = {} } end,
    GetOrdered = function() return {} end,
})
ns:RegisterModule("Services.RaidWarningService", { CancelBriefing = function() end })
ns:RegisterModule("Services.MessageService", {})
ns:RegisterModule("Services.AudioService", {})
ns:RegisterModule("Services.TimelineService", {
    SetEncounter = function(_, key) timelineEncounter = key end,
})
ns:RegisterModule("Services.EncounterService", {
    IsActive = function() return false end,
    GetDifficultyKey = function() return nil end,
})
ns:RegisterModule("UI.MainFrame", {
    SetDifficulty = function(_, key) uiDifficulty = key end,
    ResetCallStates = function() resetCount = resetCount + 1 end,
})
local settingsShown = true
ns:RegisterModule("UI.SettingsFrame", {
    frame = { IsShown = function() return settingsShown end },
})

T.Load("Core/App.lua", ns)
local App = ns:GetModule("Core.App")
App.activeBossKey = "nekzali"
App.activeDifficultyKey = "heroic"
App.db = { selectedDifficultyKey = "heroic" }

assert(App:SelectDifficulty("normal", false) == false,
    "manual difficulty changes must be blocked while Settings is open")
assert(App.activeDifficultyKey == "heroic" and App.db.selectedDifficultyKey == "heroic",
    "blocked difficulty changes must leave active and persisted context unchanged")
assert(selectedDifficulty == nil and timelineEncounter == nil and resetCount == 0,
    "blocked difficulty changes must have no downstream side effects")
assert(uiDifficulty == "heroic", "UI must be restored to the active difficulty after a blocked change")

settingsShown = false
assert(App:SelectDifficulty("normal", false) == true)
assert(App.activeDifficultyKey == "normal" and App.db.selectedDifficultyKey == "normal")
assert(selectedDifficulty == "normal" and timelineEncounter == "nekzali" and resetCount == 1)

settingsShown = true
assert(App:SelectDifficulty("mythic", true) == true,
    "automatic encounter difficulty selection must bypass the editor lock")
assert(App.activeDifficultyKey == "mythic" and App.db.selectedDifficultyKey == "mythic")

print("ok - settings lock prevents cross-difficulty draft drift")
