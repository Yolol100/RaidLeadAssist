local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss12AssignmentOverride.lua", ns)
T.Load("Encounters/Boss34AssignmentOverride.lua", ns)
T.Load("Encounters/SszorakAssignmentOverride.lua", ns)
T.Load("Encounters/TwinFangsAssignmentOverride.lua", ns)
T.Load("Encounters/Boss78AssignmentOverride.lua", ns)
T.Load("Services/AssignmentService.lua", ns)

local Assignments = ns:GetModule("Services.AssignmentService")
local db = {
    assignments = {
        legacyboss = {
            heroic = {
                obsolete = "Should disappear",
            },
        },
        sszorak = {
            mythic = {
                mutilate_group_1 = "Alpha, Bravo, Charlie, Delta, alpha",
                mutilate_group_2 = "Foxtrot, Golf, Hotel, India, Juliet",
                cyst_popper_1 = "Kilo",
                cyst_popper_2 = "Lima",
                cyst_popper_3 = "Mike",
            },
        },
        sentinels = {
            mythic = {
                team_a = "Group 1",
                team_b = "Group 2",
            },
        },
        twinfangs = {
            heroic = {
                feast_team_a = "One, Two, Three",
                feast_team_b = "Three, Four, Five",
                feast_team_c = "Six, Seven, Eight",
            },
        },
        vashnik = {
            heroic = {
                bile_team = "Old stale roster",
            },
        },
    },
}

Assignments:Initialize(db)

assert(db.assignments.legacyboss == nil,
    "unknown persisted bosses must fail closed instead of reaching the assignment registry")
assert(Assignments:GetValue("sszorak", "mythic", "mutilate_group_1") == "",
    "persisted duplicate players must be removed during initialization")
assert(Assignments:GetValue("sszorak", "mythic", "mutilate_group_2") == "Foxtrot, Golf, Hotel, India, Juliet",
    "valid persisted Mythic Mutilate assignments must survive neighboring corruption")
assert(Assignments:GetValue("sszorak", "mythic", "cyst_popper_1") == "Kilo")
assert(Assignments:GetValue("sszorak", "mythic", "cyst_popper_2") == "Lima")
assert(Assignments:GetValue("sszorak", "mythic", "cyst_popper_3") == "Mike")

assert(Assignments:GetValue("sentinels", "mythic", "team_a") == "Group 1",
    "current Mythic fixed-side Team A must survive initialization")
assert(Assignments:GetValue("sentinels", "mythic", "team_b") == "Group 2",
    "current Mythic fixed-side Team B must survive initialization")

assert(Assignments:GetValue("twinfangs", "heroic", "feast_team_a") == "One, Two, Three",
    "the first valid exclusive Feast assignment should be preserved")
assert(Assignments:GetValue("twinfangs", "heroic", "feast_team_b") == "",
    "persisted exclusive-group overlap must fail closed")
assert(Assignments:GetValue("twinfangs", "heroic", "feast_team_c") == "Six, Seven, Eight",
    "non-overlapping exclusive Feast assignments should be preserved")

assert(Assignments:GetValue("vashnik", "heroic", "bile_team") == "",
    "retired Vashnik fixed-roster fields must be removed from persisted data")

print("ok - persisted Heroic/Mythic assignments keep valid fields while unknown, stale and unsafe fields fail closed")
