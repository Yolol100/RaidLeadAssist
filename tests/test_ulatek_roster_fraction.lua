local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

local currentRoster = {}
ns:RegisterModule("Services.RosterService", {
    GetRoster = function()
        return currentRoster
    end,
})

T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss78AssignmentOverride.lua", ns)
T.Load("Services/AssignmentService.lua", ns)

local Registry = ns:GetModule("Encounters.AssignmentRegistry")
local Assignments = ns:GetModule("Services.AssignmentService")
Assignments:Initialize({ assignments = {} })

local function setRoster(size)
    currentRoster = {}
    for index = 1, size do
        currentRoster[index] = {
            name = ("P%02d"):format(index),
            subgroup = math.floor((index - 1) / 5) + 1,
            role = "DAMAGER",
        }
    end
end

local function names(first, last)
    local result = {}
    for index = first, last do result[#result + 1] = ("P%02d"):format(index) end
    return table.concat(result, ", ")
end

local heroicCoils = Registry:GetCallDefinitions("ulatek", "heroic", "coils")
assert(#heroicCoils == 2, "Heroic Ula'tek must expose two Coil teams")
assert(heroicCoils[1].minRaidFraction == 0.4 and heroicCoils[2].minRaidFraction == 0.4,
    "both Heroic Coil teams must enforce Blizzard's 40% roster floor")

local mythicCoils = Registry:GetCallDefinitions("ulatek", "mythic", "coils")
assert(#mythicCoils == 2 and mythicCoils[1].minRaidFraction == 0.4 and mythicCoils[2].minRaidFraction == 0.4,
    "both Mythic Coil teams must enforce the same 40% roster floor")

for _, scenario in ipairs({
    { size = 10, required = 4 },
    { size = 15, required = 6 },
    { size = 20, required = 8 },
    { size = 30, required = 12 },
}) do
    setRoster(scenario.size)
    local definition = heroicCoils[1]
    local valid = Assignments:ValidateDefinitionValue(definition, names(1, scenario.required))
    assert(valid, ("%d-player raid must accept exactly %d Coil soakers"):format(scenario.size, scenario.required))

    local tooSmall, reason = Assignments:ValidateDefinitionValue(definition, names(1, scenario.required - 1))
    assert(not tooSmall, ("%d-player raid must reject %d Coil soakers"):format(scenario.size, scenario.required - 1))
    assert(reason:find(("requires at least %d unique players"):format(scenario.required), 1, true),
        "failure must explain the current 40% minimum")
    assert(reason:find(("current %d-player group"):format(scenario.size), 1, true),
        "failure must explain which live roster size drove the minimum")
end

setRoster(20)
local groupPass = Assignments:ValidateDefinitionValue(heroicCoils[1], "Groups 1+2")
assert(groupPass, "two full five-player subgroups must satisfy a 20-player Coil soak")
local groupFail, groupReason = Assignments:ValidateDefinitionValue(heroicCoils[1], "Group 1")
assert(not groupFail and groupReason:find("requires at least 8 unique players", 1, true),
    "one five-player subgroup must fail the 20-player 40% floor")

-- Rotations must advance A -> B and reset to A on pull/reset state cleanup.
local applied = Assignments:ApplyBossDraft("ulatek", "heroic", {
    coil_a = names(1, 8),
    coil_b = names(9, 16),
})
assert(applied, "valid 20-player Coil teams must save")
local value = Assignments:GetRotationValue("ulatek", "heroic", "coils", "coils")
assert(value == names(1, 8), "first Coil occurrence must use Team 1")
Assignments:AdvanceCall("ulatek", "heroic", "coils")
value = Assignments:GetRotationValue("ulatek", "heroic", "coils", "coils")
assert(value == names(9, 16), "second Coil occurrence must use Team 2")
Assignments:ResetRuntime()
value = Assignments:GetRotationValue("ulatek", "heroic", "coils", "coils")
assert(value == names(1, 8), "runtime reset must restart the Coil rotation at Team 1")

-- A setup that was valid for a smaller roster must fail closed if the raid grows.
setRoster(10)
Assignments:Initialize({ assignments = {} })
applied = Assignments:ApplyBossDraft("ulatek", "heroic", {
    coil_a = names(1, 4),
    coil_b = names(5, 8),
})
assert(applied, "four-player teams are valid for a 10-player roster")
local ready = Assignments:IsCallReady("ulatek", "heroic", "coils")
assert(ready, "10-player Coil teams should be ready at the 40% floor")

setRoster(20)
local stillReady, resizeReason = Assignments:IsCallReady("ulatek", "heroic", "coils")
assert(not stillReady, "saved Coil teams must fail closed after the raid grows beyond their 40% coverage")
assert(resizeReason:find("requires at least 8 unique players", 1, true),
    "roster-growth failure must expose the new minimum")

print("ok - Ula'tek Coil teams enforce a dynamic 40% roster floor and reset rotation safely")
