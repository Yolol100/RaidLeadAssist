local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
_G.issecretvalue = function() return false end

-- Exercise the real roster adapter before the readiness test swaps in its controlled roster stub.
do
    local rosterNs = T.NewNamespace()
    local raidRows = {
        { "Zulu", 2, "DAMAGER" },
        { "Tank", 1, "TANK" },
        { "Heal", 1, "HEALER" },
        { "Alpha", 1, "DAMAGER" },
        { "", 1, "DAMAGER" },
    }
    _G.IsInRaid = function() return true end
    _G.GetNumGroupMembers = function() return #raidRows end
    _G.GetRaidRosterInfo = function(index)
        local row = raidRows[index]
        return row[1], nil, row[2], nil, "Class", "CLASS", nil, nil, nil, row[3]
    end
    T.Load("Services/RosterService.lua", rosterNs)
    local realRoster = rosterNs:GetModule("Services.RosterService")
    local roster = realRoster:GetRoster()
    assert(#roster == 4, "real raid roster adapter must drop empty names")
    assert(roster[1].name == "Tank" and roster[2].name == "Heal" and roster[3].name == "Alpha" and roster[4].name == "Zulu",
        "real raid roster adapter must sort by subgroup, role and name")
    assert(roster[4].subgroup == 2 and roster[4].raidIndex == 1,
        "real raid roster adapter must preserve subgroup and source raid index")

    _G.IsInRaid = function() return false end
    _G.GetNumGroupMembers = function() return 3 end
    local unitNames = { player = "Player-Realm", party1 = "Healer-Realm", party2 = "Dps-Realm" }
    local unitRoles = { player = "TANK", party1 = "HEALER", party2 = "DAMAGER" }
    _G.UnitName = function(unit) return unitNames[unit] end
    _G.UnitGroupRolesAssigned = function(unit) return unitRoles[unit] end
    _G.UnitClass = function() return "Class", "CLASS" end
    roster = realRoster:GetRoster()
    assert(#roster == 3 and roster[1].name == "Player-Realm" and roster[2].name == "Healer-Realm" and roster[3].name == "Dps-Realm",
        "real party roster adapter must include player plus party units in role order")
end

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
    activeDifficultyKey = "heroic",
    db = { automaticTimingEnabled = false },
    PrintDoctor = function() end,
})

local Assignments = ns:GetModule("Services.AssignmentService")
Assignments:Initialize({ assignments = {} })
T.Load("Core/ReadinessIntegration.lua", ns)
local Readiness = ns:GetModule("Core.ReadinessIntegration")

local function applyEgg(left)
    local ok, reason = Assignments:ApplyBossDraft("ulatek", "heroic", {
        coil_a = "Group 1",
        coil_b = "Group 2",
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
    { name = "P08", subgroup = 2, role = "DAMAGER" },
    { name = "P09", subgroup = 2, role = "DAMAGER" },
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

print("ok - Heroic readiness uses exact qualified names, unique short aliases and authoritative raid context")
