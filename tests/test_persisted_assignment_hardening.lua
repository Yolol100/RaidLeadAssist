local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Services/AssignmentService.lua", ns)

local Assignments = ns:GetModule("Services.AssignmentService")
local db = {
    assignments = {
        sszorak = {
            heroic = {
                mutilate_a = "Alpha, Bravo, Charlie, Delta, alpha",
                mutilate_b = "Foxtrot, Golf, Hotel, India, Juliet",
            },
        },
        sentinels = {
            heroic = {
                breath_side = "Valid Breath",
                blood_side = "Valid Blood",
                stasis_a = "One, Two, Three",
                stasis_b = "Four, Five, Six, Seven",
            },
        },
        twinfangs = {
            heroic = {
                feast_a = "One, Two, Three",
                feast_b = "Three, Four, Five",
                feast_c = "Six, Seven, Eight",
                stone_a = "Stone One",
                stone_b = "Stone Two",
            },
        },
    },
}

Assignments:Initialize(db)

assert(Assignments:GetValue("sszorak", "heroic", "mutilate_a") == "",
    "persisted duplicate players must be removed during initialization")
assert(Assignments:GetValue("sszorak", "heroic", "mutilate_b") == "Foxtrot, Golf, Hotel, India, Juliet",
    "valid persisted assignments must survive neighboring corruption")

assert(Assignments:GetValue("sentinels", "heroic", "stasis_a") == "",
    "persisted exact-size violations must be removed during initialization")
assert(Assignments:GetValue("sentinels", "heroic", "stasis_b") == "Four, Five, Six, Seven",
    "valid exact-size assignments must survive neighboring corruption")
assert(Assignments:GetValue("sentinels", "heroic", "breath_side") == "Valid Breath",
    "unrelated valid assignments must be preserved")

assert(Assignments:GetValue("twinfangs", "heroic", "feast_a") == "One, Two, Three",
    "the first valid exclusive assignment should be preserved")
assert(Assignments:GetValue("twinfangs", "heroic", "feast_b") == "",
    "persisted exclusive-group overlap must fail closed")
assert(Assignments:GetValue("twinfangs", "heroic", "feast_c") == "Six, Seven, Eight",
    "non-overlapping exclusive assignments should be preserved")
assert(Assignments:GetValue("twinfangs", "heroic", "stone_a") == "Stone One",
    "valid unrelated values must remain available after overlap cleanup")

print("ok - persisted assignments are semantically revalidated and unsafe fields fail closed")
