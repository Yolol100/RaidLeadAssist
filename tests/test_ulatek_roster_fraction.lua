local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

local currentRoster = {}
local authoritativeRaid = true
ns:RegisterModule("Services.RosterService", {
    IsRaidRoster = function()
        return authoritativeRaid
    end,
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
    authoritativeRaid = true
    setRoster(scenario.size)
    local definition = heroicCoils[1]
    local valid = Assignments:ValidateDefinitionValue(definition, names(1, scenario.required))
    assert(valid, ("%d-player raid must accept exactly %d current Coil soakers"):format(scenario.size, scenario.required))

    local tooSmall, reason = Assignments:ValidateDefinitionValue(definition, names(1, scenario.required - 1))
    assert(not tooSmall, ("%d-player raid must reject %d Coil soakers"):format(scenario.size, scenario.required - 1))
    assert(reason:find(("requires at least %d current raid players"):format(scenario.required), 1, true),
        "failure must explain the current 40% minimum")
    assert(reason:find(("current %d-player raid"):format(scenario.size), 1, true),
        "failure must explain which live raid size drove the minimum")
end

setRoster(20)
local groupPass = Assignments:ValidateDefinitionValue(heroicCoils[1], "Groups 1+2")
assert(groupPass, "two full five-player subgroups must satisfy a 20-player Coil soak")
local groupFail, groupReason = Assignments:ValidateDefinitionValue(heroicCoils[1], "Group 1")
assert(not groupFail and groupReason:find("requires at least 8 current raid players", 1, true),
    "one five-player subgroup must fail the 20-player 40% floor")

local staleNames, staleReason = Assignments:ValidateDefinitionValue(heroicCoils[1],
    "Old01, Old02, Old03, Old04, Old05, Old06, Old07, Old08")
assert(not staleNames and staleReason:find("found 0", 1, true),
    "eight names outside the current raid must not satisfy the live 40% floor")

local mixedNames, mixedReason = Assignments:ValidateDefinitionValue(heroicCoils[1],
    "P01, P02, P03, P04, P05, P06, P07, Old08")
assert(not mixedNames and mixedReason:find("found 7", 1, true),
    "only actual current raid members may count toward the live 40% floor")

-- Fully-qualified names must exact-match the current realm; short fallback is only for unqualified names.
currentRoster = {
    { name = "Same-NewRealm", subgroup = 1, role = "DAMAGER" },
    { name = "P02", subgroup = 1, role = "DAMAGER" },
    { name = "P03", subgroup = 1, role = "DAMAGER" },
    { name = "P04", subgroup = 1, role = "DAMAGER" },
    { name = "P05", subgroup = 1, role = "DAMAGER" },
    { name = "P06", subgroup = 2, role = "DAMAGER" },
    { name = "P07", subgroup = 2, role = "DAMAGER" },
    { name = "P08", subgroup = 2, role = "DAMAGER" },
    { name = "P09", subgroup = 2, role = "DAMAGER" },
    { name = "P10", subgroup = 2, role = "DAMAGER" },
}
local wrongRealm, wrongRealmReason = Assignments:ValidateDefinitionValue(heroicCoils[1],
    "Same-OldRealm, P02, P03, P04")
assert(not wrongRealm and wrongRealmReason:find("found 3", 1, true),
    "a qualified stale realm name must not count as the current same-short-name player")
local exactRealm = Assignments:ValidateDefinitionValue(heroicCoils[1],
    "Same-NewRealm, P02, P03, P04")
assert(exactRealm, "the exact current qualified realm name must count")
local uniqueShort = Assignments:ValidateDefinitionValue(heroicCoils[1],
    "Same, P02, P03, P04")
assert(uniqueShort, "an unqualified unique short name may resolve to the current qualified roster name")

-- Outside an authoritative raid, percentage validation must not corrupt pre-planning.
authoritativeRaid = false
setRoster(1)
local preplan = Assignments:ValidateDefinitionValue(heroicCoils[1],
    "Future01, Future02, Future03, Future04")
assert(preplan, "future raid names must remain pre-plannable outside an authoritative raid roster")
local groupPreplan = Assignments:ValidateDefinitionValue(heroicCoils[1], "Groups 1+2")
assert(groupPreplan, "future raid subgroup plans must remain pre-plannable while solo or in a party")

authoritativeRaid = true
setRoster(20)
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

-- A setup that was valid for a smaller raid must fail closed if the raid grows.
setRoster(10)
Assignments:Initialize({ assignments = {} })
applied = Assignments:ApplyBossDraft("ulatek", "heroic", {
    coil_a = names(1, 4),
    coil_b = names(5, 8),
})
assert(applied, "four-player teams are valid for a 10-player raid")
local ready = Assignments:IsCallReady("ulatek", "heroic", "coils")
assert(ready, "10-player Coil teams should be ready at the 40% floor")

setRoster(20)
local stillReady, resizeReason = Assignments:IsCallReady("ulatek", "heroic", "coils")
assert(not stillReady, "saved Coil teams must fail closed after the raid grows beyond their 40% coverage")
assert(resizeReason:find("requires at least 8 current raid players", 1, true),
    "raid-growth failure must expose the new minimum")

-- Reload/initialization must not destroy a saved plan just because the current roster context changed.
local saved = {
    assignments = {
        ulatek = {
            heroic = {
                coil_a = names(1, 4),
                coil_b = names(5, 8),
            },
        },
    },
}
Assignments:Initialize(saved)
assert(Assignments:GetValue("ulatek", "heroic", "coil_a") == names(1, 4)
    and Assignments:GetValue("ulatek", "heroic", "coil_b") == names(5, 8),
    "normalization must preserve syntactically valid saved Coil teams across raid-size changes")
local reloadReady, reloadReason = Assignments:IsCallReady("ulatek", "heroic", "coils")
assert(not reloadReady and reloadReason:find("requires at least 8 current raid players", 1, true),
    "preserved saved teams must still fail live readiness against the current larger raid")

-- Relative subgroup plans are storage syntax, not something initialization may erase from partial context.
setRoster(1)
local savedGroups = {
    assignments = {
        ulatek = {
            heroic = {
                coil_a = "Groups 1+2",
                coil_b = "Groups 3+4",
            },
        },
    },
}
Assignments:Initialize(savedGroups)
assert(Assignments:GetValue("ulatek", "heroic", "coil_a") == "Groups 1+2"
    and Assignments:GetValue("ulatek", "heroic", "coil_b") == "Groups 3+4",
    "initialization must preserve subgroup expressions even when those raid groups are not currently populated")
local partialReady = Assignments:IsCallReady("ulatek", "heroic", "coils")
assert(not partialReady, "subgroup plans must still fail closed at use time when the authoritative raid cannot resolve them")

print("ok - Ula'tek Coil teams enforce an authoritative 40% raid floor, realm-safe membership, preplans and rotation reset")
