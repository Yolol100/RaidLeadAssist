local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/TwinFangsAssignmentOverride.lua", ns)
ns:RegisterModule("Encounters.Registry", {
    Get = function(_, key) return key == "twinfangs" and { key = key } or nil end,
})
T.Load("Services/AssignmentService.lua", ns)
T.Load("Services/AssignmentPresetService.lua", ns)

local Assignments = ns:GetModule("Services.AssignmentService")
local Presets = ns:GetModule("Services.AssignmentPresetService")
local db = { assignments = {}, assignmentPresets = {} }
Assignments:Initialize(db)
Presets:Initialize(db)

local original = {
    feast_heroic_a = "Group 1",
    feast_heroic_b = "Group 2",
    feast_heroic_c = "Groups 3+4",
}
local alternate = {
    feast_heroic_a = "Group 4",
    feast_heroic_b = "Group 3",
    feast_heroic_c = "Groups 1+2",
}

local ok = Assignments:ApplyBossDraft("twinfangs", "heroic", original)
assert(ok)
local saved, name = Presets:Save("Progression", "twinfangs", "heroic")
assert(saved and name == "Progression")
assert(#Presets:List("twinfangs", "heroic") == 1)

ok = Assignments:ApplyBossDraft("twinfangs", "heroic", alternate)
assert(ok)
local loaded, loadedName = Presets:Load("progression", "twinfangs", "heroic")
assert(loaded and loadedName == "Progression")
local values = Assignments:GetValues("twinfangs", "heroic")
assert(values.feast_heroic_a == "Group 1"
    and values.feast_heroic_b == "Group 2"
    and values.feast_heroic_c == "Groups 3+4",
    "loading a preset must restore a validated copy of the saved Heroic plan")

local overwritten = Presets:Save("PROGRESSION", "twinfangs", "heroic")
assert(overwritten and #Presets:List("twinfangs", "heroic") == 1,
    "preset names are case-insensitive and overwrite deterministically")

local badName = Presets:Save("Bad\1Name", "twinfangs", "heroic")
assert(not badName, "control characters must not enter SavedVariables preset keys")
local missing = Presets:Load("does-not-exist", "twinfangs", "heroic")
assert(not missing)
local wrongProfile = Presets:Save("Other", "unknown", "heroic")
assert(not wrongProfile)
local retiredNormal = Presets:Save("Old Normal", "twinfangs", "normal")
assert(not retiredNormal, "retired Normal presets must fail closed")

for index = 1, Presets.MAX_PRESETS_PER_PROFILE - 1 do
    local added, err = Presets:Save("Plan " .. index, "twinfangs", "heroic")
    assert(added, tostring(err))
end
local tooMany = Presets:Save("Overflow", "twinfangs", "heroic")
assert(not tooMany, "preset storage must remain bounded per boss/difficulty")

local deleted = Presets:Delete("progression", "twinfangs", "heroic")
assert(deleted)
assert(not Presets:Load("progression", "twinfangs", "heroic"))

-- Corrupt/untrusted persisted presets are normalized away at initialization.
local corrupt = {
    assignments = {},
    assignmentPresets = {
        twinfangs = {
            heroic = {
                good = { name = "Good", values = original },
                bad = { name = "Bad\1Name", values = original },
            },
            normal = {
                old = { name = "Old", values = original },
            },
        },
        unknown = { heroic = { x = { name = "X", values = {} } } },
    },
}
Assignments:Initialize(corrupt)
Presets:Initialize(corrupt)
assert(Presets:List("twinfangs", "heroic")[1] == "Good")
assert(corrupt.assignmentPresets.twinfangs.normal == nil)
assert(corrupt.assignmentPresets.unknown == nil)

_G.issecretvalue = nil
print("ok - assignment presets are Heroic/Mythic-only, local, validated, bounded and fail closed")
