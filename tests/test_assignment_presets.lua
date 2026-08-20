local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss12AssignmentOverride.lua", ns)
T.Load("Encounters/Boss34AssignmentOverride.lua", ns)
T.Load("Encounters/SszorakAssignmentOverride.lua", ns)
T.Load("Encounters/TwinFangsAssignmentOverride.lua", ns)
T.Load("Encounters/Boss78AssignmentOverride.lua", ns)
ns:RegisterModule("Encounters.Registry", {
    Get = function(_, key) return key == "sentinels" and { key = key } or nil end,
})
T.Load("Services/AssignmentService.lua", ns)
T.Load("Services/AssignmentPresetService.lua", ns)

local Assignments = ns:GetModule("Services.AssignmentService")
local Presets = ns:GetModule("Services.AssignmentPresetService")
local db = { assignments = {}, assignmentPresets = {} }
Assignments:Initialize(db)
Presets:Initialize(db)

local ok = Assignments:ApplyBossDraft("sentinels", "heroic", { team_a = "Group 1", team_b = "Group 2" })
assert(ok)
local saved, name = Presets:Save("Progression", "sentinels", "heroic")
assert(saved and name == "Progression")
assert(#Presets:List("sentinels", "heroic") == 1)

ok = Assignments:ApplyBossDraft("sentinels", "heroic", { team_a = "Group 3", team_b = "Group 4" })
assert(ok)
local loaded, loadedName = Presets:Load("progression", "sentinels", "heroic")
assert(loaded and loadedName == "Progression")
local values = Assignments:GetValues("sentinels", "heroic")
assert(values.team_a == "Group 1" and values.team_b == "Group 2",
    "loading a preset must restore a validated copy of the saved plan")

local overwritten = Presets:Save("PROGRESSION", "sentinels", "heroic")
assert(overwritten and #Presets:List("sentinels", "heroic") == 1,
    "preset names are case-insensitive and overwrite deterministically")

local badName = Presets:Save("Bad\1Name", "sentinels", "heroic")
assert(not badName, "control characters must not enter SavedVariables preset keys")
local missing = Presets:Load("does-not-exist", "sentinels", "heroic")
assert(not missing)
local wrongProfile = Presets:Save("Other", "unknown", "heroic")
assert(not wrongProfile)

for index = 1, Presets.MAX_PRESETS_PER_PROFILE - 1 do
    local added, err = Presets:Save("Plan " .. index, "sentinels", "heroic")
    assert(added, tostring(err))
end
local tooMany = Presets:Save("Overflow", "sentinels", "heroic")
assert(not tooMany, "preset storage must remain bounded per boss/difficulty")

local deleted = Presets:Delete("progression", "sentinels", "heroic")
assert(deleted)
assert(not Presets:Load("progression", "sentinels", "heroic"))

-- Corrupt/untrusted persisted presets are normalized away at initialization.
local corrupt = {
    assignments = {},
    assignmentPresets = {
        sentinels = {
            heroic = {
                good = { name = "Good", values = { team_a = "Group 1", team_b = "Group 2" } },
                bad = { name = "Bad\1Name", values = { team_a = "Group 1", team_b = "Group 2" } },
            },
        },
        unknown = { heroic = { x = { name = "X", values = {} } } },
    },
}
Assignments:Initialize(corrupt)
Presets:Initialize(corrupt)
assert(Presets:List("sentinels", "heroic")[1] == "Good")
assert(corrupt.assignmentPresets.unknown == nil)

_G.issecretvalue = nil
print("ok - assignment presets are local, validated, bounded and fail closed")
