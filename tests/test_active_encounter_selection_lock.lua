local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

_G.CreateFrame = function() return T.Frame() end
_G.issecretvalue = function() return false end
_G.table.wipe = _G.table.wipe or function(tbl) for key in pairs(tbl) do tbl[key] = nil end end

T.Load("Core/Constants.lua", ns)

local encounterActive = true
local knownEncounter = true
local liveDifficulty = "heroic"
local selectedDifficulty
local timelineCalls = {}
local selectedUIBoss
local selectedUIDifficulty

ns:RegisterModule("Core.Database", {
    HasNewerSchema = function() return false end,
    ResetPosition = function() end,
})
ns:RegisterModule("Core.EventBus", { On = function() end })
ns:RegisterModule("Encounters.Registry", {
    Get = function(_, key)
        if key == "nekzali" or key == "sentinels" then return { key = key } end
    end,
    GetProfile = function(_, key, difficulty)
        if (key == "nekzali" or key == "sentinels") and difficulty then
            return { calls = {}, callsByKey = {} }
        end
    end,
    SetActiveDifficulty = function(_, key) selectedDifficulty = key return true end,
    GetOrdered = function() return {} end,
})
ns:RegisterModule("Services.RaidWarningService", { CancelBriefing = function() end })
ns:RegisterModule("Services.MessageService", {})
ns:RegisterModule("Services.AudioService", {})
ns:RegisterModule("Services.TimelineService", {
    SetEncounter = function(_, key, preserve)
        timelineCalls[#timelineCalls + 1] = { key = key, preserve = preserve }
    end,
})
ns:RegisterModule("Services.EncounterService", {
    IsActive = function() return encounterActive end,
    HasKnownEncounter = function() return knownEncounter end,
    GetDifficultyKey = function() return liveDifficulty end,
})
ns:RegisterModule("UI.MainFrame", {
    SetDifficulty = function(_, key) selectedUIDifficulty = key end,
    SetEncounter = function(_, key) selectedUIBoss = key end,
    ResetCallStates = function() end,
    Show = function() end,
})
ns:RegisterModule("UI.SettingsFrame", {
    frame = { IsShown = function() return false end },
})

T.Load("Core/App.lua", ns)
local App = ns:GetModule("Core.App")
App.activeBossKey = "nekzali"
App.activeDifficultyKey = "heroic"
App.db = { selectedBossKey = "nekzali", selectedDifficultyKey = "heroic" }

assert(App:SelectDifficulty("heroic", false) == false,
    "manual re-selection of the live difficulty must still be blocked in combat")
assert(App.activeDifficultyKey == "heroic" and App.db.selectedDifficultyKey == "heroic")
assert(#timelineCalls == 0, "blocked difficulty changes must not reset live timers")
assert(selectedUIDifficulty == "heroic")

assert(App:SelectDifficulty("normal", false) == false,
    "manual difficulty changes must be blocked during an active encounter")
assert(#timelineCalls == 0)

assert(App:SelectBoss("sentinels", false) == false,
    "manual boss changes must be blocked while the current encounter is known")
assert(App.activeBossKey == "nekzali" and App.db.selectedBossKey == "nekzali")
assert(selectedUIBoss == nil and #timelineCalls == 0,
    "blocked boss changes must not remap or reset live timers")

assert(App:SelectDifficulty("normal", true) == true,
    "automatic encounter difficulty selection must bypass the manual lock")
assert(selectedDifficulty == "normal" and App.activeDifficultyKey == "normal")
assert(#timelineCalls == 1 and timelineCalls[1].preserve == true)

assert(App:SelectBoss("sentinels", true) == true,
    "automatic encounter boss selection must bypass the manual lock")
assert(App.activeBossKey == "sentinels" and selectedUIBoss == "sentinels")
assert(#timelineCalls == 2 and timelineCalls[2].preserve == true)

encounterActive = false
assert(App:SelectBoss("nekzali", false) == true,
    "manual boss selection must remain available outside encounters")
assert(App.activeBossKey == "nekzali")

print("ok - active encounter profile selection locks")
