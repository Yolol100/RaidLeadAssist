local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
_G.issecretvalue = function() return false end

local currentRoster = {
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
local authoritativeRaid = true

ns:RegisterModule("Services.RosterService", {
    IsRaidRoster = function() return authoritativeRaid end,
    GetRoster = function() return currentRoster end,
})

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss78AssignmentOverride.lua", ns)
T.Load("Encounters/VenomousAbyss/Ulatek.lua", ns)
T.Load("Services/AssignmentService.lua", ns)

ns:RegisterModule("Encounters.SetupRegistry", {
    HasSetup = function() return false end,
    GetCounts = function() return 0, 0, 0 end,
})
ns:RegisterModule("Services.MessageService", {
    GetCustomCurrentness = function() return "current" end,
})
ns:RegisterModule("Services.SetupService", {
    IsReady = function() return true end,
})
ns:RegisterModule("Services.TimelineService", {
    timers = {},
    GetProviderSummary = function() return "DBM" end,
})
ns:RegisterModule("Core.App", {
    activeBossKey = "ulatek",
    activeDifficultyKey = "normal",
    db = { automaticTimingEnabled = false },
    PrintDoctor = function() end,
})

local Assignments = ns:GetModule("Services.AssignmentService")
Assignments:Initialize({ assignments = {} })
T.Load("Core/ReadinessIntegration.lua", ns)
local Readiness = ns:GetModule("Core.ReadinessIntegration")

local function applyEgg(left)
    local ok, reason = Assignments:ApplyBossDraft("ulatek", "normal", {
        egg_left = left,
        egg_right = "P04",
        bite_melee = "P05",
        bite_ranged = "P06",
        bite_healer = "P07",
    })
    assert(ok, "test plan must save: " .. tostring(reason and reason.message))
end

applyEgg("Alex-OldRealm")
local state = Readiness:GetState()
assert(not state.ready and #state.invalidAssignments == 0 and #state.missingRequired == 0,
    "stale qualified identity should be a roster-currentness failure, not destructive assignment invalidation")
assert(#state.rosterMissing == 1 and state.rosterMissing[1] == "Alex-OldRealm",
    "qualified names must require an exact current-realm roster match")
assert(state.states[1] == "CHECK ROSTER", "stale qualified carrier must surface CHECK ROSTER")

applyEgg("Sam")
state = Readiness:GetState()
assert(#state.rosterMissing == 1 and state.rosterMissing[1] == "Sam",
    "ambiguous unqualified short names must not be accepted as roster-current")
assert(not state.ready and state.states[1] == "CHECK ROSTER")

applyEgg("Sam-RealmA")
state = Readiness:GetState()
assert(#state.rosterMissing == 0 and state.ready and state.states[1] == "READY MANUAL",
    "exact qualified current names must clear roster readiness")

currentRoster = {
    { name = "Alex-Realm", subgroup = 1, role = "DAMAGER" },
    { name = "Alex", subgroup = 1, role = "DAMAGER" },
    { name = "P04", subgroup = 1, role = "DAMAGER" },
    { name = "P05", subgroup = 1, role = "DAMAGER" },
    { name = "P06", subgroup = 2, role = "DAMAGER" },
    { name = "P07", subgroup = 2, role = "DAMAGER" },
}
applyEgg("Alex")
state = Readiness:GetState()
assert(#state.rosterMissing == 0,
    "an exact same-realm full name must remain valid even if its short alias is also used by a qualified player")

authoritativeRaid = false
applyEgg("Future-Realm")
state = Readiness:GetState()
assert(#state.rosterMissing == 0,
    "solo/party planning must not pretend its roster is authoritative for future raid assignments")

print("ok - readiness uses exact qualified names, unique short aliases and authoritative raid context")
