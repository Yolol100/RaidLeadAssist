local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

local definitions = {
    { key = "tank", label = "Tank" },
    { key = "healer", label = "Healer" },
}

ns:RegisterModule("Services.AssignmentService", {
    MAX_WARNING_LENGTH = 200,
    MAX_PLAN_LINES = 12,
    ValidateBossDraft = function(_, _, _, values)
        if values.invalid then return false, { message = "Invalid draft." } end
        local clean = {}
        for key, value in pairs(values) do
            if type(value) == "string" then clean[key] = value:match("^%s*(.-)%s*$") end
        end
        return true, clean
    end,
    GetMissingRequired = function(_, _, _, values)
        return values.tank == "" or values.tank == nil and { "Tank" } or {}
    end,
    GetDefinitions = function() return definitions end,
})

T.Load("Services/AssignmentPreviewService.lua", ns)
local Preview = ns:GetModule("Services.AssignmentPreviewService")

local lines, reason = Preview:BuildLines("boss", "heroic", { tank = " MainTank ", healer = " HealerOne " })
assert(reason == nil and #lines == 2, "valid preview should render every filled assignment")
assert(lines[1] == "Tank: MainTank." and lines[2] == "Healer: HealerOne.", "preview should use normalized validated values")

local missing, missingReason = Preview:BuildLines("boss", "heroic", { healer = "HealerOne" })
assert(missing == nil and missingReason == "Missing required: Tank", "required assignments must block preview")

local invalid, invalidReason = Preview:BuildLines("boss", "heroic", { invalid = true, tank = "MainTank" })
assert(invalid == nil and invalidReason == "Invalid draft.", "assignment validation must remain authoritative")

local tooLong, lengthReason = Preview:BuildLines("boss", "heroic", { tank = string.rep("x", 200) })
assert(tooLong == nil and lengthReason:find("Raid Warning length limit", 1, true), "overlong preview lines must fail closed")

definitions = {}
local manyValues = {}
for index = 1, 20 do
    definitions[index] = { key = "slot" .. index, label = "Slot " .. index }
    manyValues["slot" .. index] = "Player" .. index
end
manyValues.tank = "MainTank"
local bounded = assert(Preview:BuildLines("boss", "heroic", manyValues))
assert(#bounded == 12, "preview output must respect the assignment plan line budget")

print("ok - assignment preview is validated, normalized, bounded and fail closed")
