local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

local currentRoster = {}
local authoritativeRaid = true
ns:RegisterModule("Services.RosterService", {
    IsRaidRoster = function() return authoritativeRaid end,
    GetRoster = function() return currentRoster end,
})

T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss78AssignmentOverride.lua", ns)
T.Load("Services/AssignmentService.lua", ns)

local Registry = ns:GetModule("Encounters.AssignmentRegistry")
local Assignments = ns:GetModule("Services.AssignmentService")
Assignments:Initialize({ assignments = {} })

local function setStandardRoster(size)
    currentRoster = {}
    for index = 1, size do
        currentRoster[index] = {
            name = ("P%02d"):format(index),
            subgroup = math.floor((index - 1) / 5) + 1,
            role = "DAMAGER",
        }
    end
end

local heroicCoils = Registry:GetCallDefinitions("ulatek", "heroic", "coils")
assert(#heroicCoils == 2, "Heroic Ula'tek must expose two Coil teams")

-- Exact full-name lookup must stay deterministic even when its key is also an ambiguous short-name alias.
local function assertExactSameRealmSurvivesOrder(first, second)
    currentRoster = {
        { name = first, subgroup = 1, role = "DAMAGER" },
        { name = second, subgroup = 1, role = "DAMAGER" },
        { name = "P03", subgroup = 1, role = "DAMAGER" },
        { name = "P04", subgroup = 1, role = "DAMAGER" },
        { name = "P05", subgroup = 1, role = "DAMAGER" },
        { name = "P06", subgroup = 2, role = "DAMAGER" },
        { name = "P07", subgroup = 2, role = "DAMAGER" },
        { name = "P08", subgroup = 2, role = "DAMAGER" },
        { name = "P09", subgroup = 2, role = "DAMAGER" },
        { name = "P10", subgroup = 2, role = "DAMAGER" },
    }
    local ok, reason = Assignments:ValidateDefinitionValue(heroicCoils[1], "Alex, P03, P04, P05")
    assert(ok, "exact same-realm Alex must count regardless of roster order: " .. tostring(reason))
end

assertExactSameRealmSurvivesOrder("Alex", "Alex-Realm")
assertExactSameRealmSurvivesOrder("Alex-Realm", "Alex")

currentRoster = {
    { name = "Sam-RealmA", subgroup = 1, role = "DAMAGER" },
    { name = "Sam-RealmB", subgroup = 1, role = "DAMAGER" },
    { name = "P03", subgroup = 1, role = "DAMAGER" },
    { name = "P04", subgroup = 1, role = "DAMAGER" },
    { name = "P05", subgroup = 1, role = "DAMAGER" },
    { name = "P06", subgroup = 2, role = "DAMAGER" },
    { name = "P07", subgroup = 2, role = "DAMAGER" },
    { name = "P08", subgroup = 2, role = "DAMAGER" },
    { name = "P09", subgroup = 2, role = "DAMAGER" },
    { name = "P10", subgroup = 2, role = "DAMAGER" },
}
local ambiguous, ambiguousReason = Assignments:ValidateDefinitionValue(heroicCoils[1], "Sam, P03, P04, P05")
assert(not ambiguous and ambiguousReason:find("found 3", 1, true),
    "an ambiguous unqualified short name must not count toward the live 40% floor")
local qualified = Assignments:ValidateDefinitionValue(heroicCoils[1], "Sam-RealmA, P03, P04, P05")
assert(qualified, "an exact qualified name must still resolve when the short name is ambiguous")

-- A subgroup preplan may be saved outside a raid, but live overlap must be re-evaluated once the raid forms.
authoritativeRaid = false
currentRoster = {}
Assignments:Initialize({ assignments = {} })
local applied = Assignments:ApplyBossDraft("ulatek", "heroic", {
    coil_a = "Groups 1+2",
    coil_b = "P01, P02, P03, P04, P05, P06, P07, P08",
})
assert(applied, "future subgroup and explicit-name Coil teams must remain pre-plannable outside a raid")
assert(#Assignments:GetInvalidConfigured("ulatek", "heroic") == 0,
    "preplanning outside an authoritative raid must not invent a live overlap")
local preplanReady = Assignments:IsCallReady("ulatek", "heroic", "coils")
assert(preplanReady, "configured Coil preplan must remain callable in non-authoritative preview context")

authoritativeRaid = true
setStandardRoster(20)
local invalid = Assignments:GetInvalidConfigured("ulatek", "heroic")
assert(#invalid == 1 and invalid[1].message:find("overlaps", 1, true),
    "global live validation must catch subgroup-to-explicit Coil overlap after the raid forms")
local liveReady, liveReason = Assignments:IsCallReady("ulatek", "heroic", "coils")
assert(not liveReady and liveReason:find("overlaps", 1, true),
    "Coil call gating must fail closed on a live-only exclusivity conflict")

applied = Assignments:ApplyBossDraft("ulatek", "heroic", {
    coil_a = "Groups 1+2",
    coil_b = "Groups 3+4",
})
assert(applied, "non-overlapping live Coil subgroup teams must save")
assert(#Assignments:GetInvalidConfigured("ulatek", "heroic") == 0,
    "non-overlapping live Coil teams must clear configured validation")
local repairedReady = Assignments:IsCallReady("ulatek", "heroic", "coils")
assert(repairedReady, "non-overlapping live Coil teams must restore call readiness")

-- Call-specific assignees without a percentage floor must still resolve uniquely to the live raid.
currentRoster = {
    { name = "Alex-NewRealm", subgroup = 1, role = "DAMAGER" },
    { name = "Sam-RealmA", subgroup = 1, role = "DAMAGER" },
    { name = "Sam-RealmB", subgroup = 1, role = "DAMAGER" },
    { name = "P04", subgroup = 1, role = "DAMAGER" },
    { name = "P05", subgroup = 1, role = "DAMAGER" },
    { name = "P06", subgroup = 2, role = "DAMAGER" },
    { name = "P07", subgroup = 2, role = "DAMAGER" },
    { name = "P08", subgroup = 2, role = "DAMAGER" },
    { name = "P09", subgroup = 2, role = "DAMAGER" },
    { name = "P10", subgroup = 2, role = "DAMAGER" },
}
Assignments:Initialize({ assignments = {} })
applied = Assignments:ApplyBossDraft("ulatek", "normal", {
    egg_left = "Alex-OldRealm",
    egg_right = "P04",
})
assert(applied, "stale qualified names must remain storable plans rather than being destructively erased")
local staleEggReady, staleEggReason = Assignments:IsCallReady("ulatek", "normal", "eggs")
assert(not staleEggReady and staleEggReason:find("uniquely present in the current raid", 1, true),
    "egg call must fail closed when a qualified assignee belongs to a stale realm")

applied = Assignments:ApplyBossDraft("ulatek", "normal", {
    egg_left = "Sam",
    egg_right = "P04",
})
assert(applied, "an ambiguous short name may remain in a saved plan for later repair")
local ambiguousEggReady, ambiguousEggReason = Assignments:IsCallReady("ulatek", "normal", "eggs")
assert(not ambiguousEggReady and ambiguousEggReason:find("uniquely present in the current raid", 1, true),
    "egg call must fail closed when an unqualified short name is ambiguous across realms")

applied = Assignments:ApplyBossDraft("ulatek", "normal", {
    egg_left = "Sam-RealmA",
    egg_right = "P04",
})
assert(applied, "an exact qualified live egg carrier must save")
local exactEggReady, exactEggReason = Assignments:IsCallReady("ulatek", "normal", "eggs")
assert(exactEggReady, "exact live egg carriers must restore call readiness: " .. tostring(exactEggReason))

print("ok - live assignment context revalidates exclusivity, identity and current-roster call safety")
