local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss12AssignmentOverride.lua", ns)
T.Load("Encounters/Boss34AssignmentOverride.lua", ns)
T.Load("Encounters/SszorakAssignmentOverride.lua", ns)
T.Load("Encounters/TwinFangsAssignmentOverride.lua", ns)
T.Load("Encounters/Boss78AssignmentOverride.lua", ns)
T.Load("Services/AssignmentService.lua", ns)

local Registry = ns:GetModule("Encounters.AssignmentRegistry")
local Assignments = ns:GetModule("Services.AssignmentService")
Assignments:Initialize({ assignments = {} })

local difficulties = { "normal", "heroic", "mythic" }
for _, bossKey in ipairs(Registry:GetBossKeys()) do
    for _, difficultyKey in ipairs(difficulties) do
        local layout = Registry:GetLayout(bossKey, difficultyKey)
        assert(type(layout) == "table" and type(layout.summary) == "string" and type(layout.sections) == "table")
        local seen = {}
        for _, definition in ipairs(Registry:GetDefinitions(bossKey, difficultyKey)) do
            assert(type(definition.key) == "string" and definition.key ~= "")
            assert(not seen[definition.key], "duplicate assignment key: " .. bossKey .. "/" .. difficultyKey .. "/" .. definition.key)
            seen[definition.key] = true
            assert(definition.kind == "assignee" or definition.kind == "rotation" or definition.kind == "rule" or definition.kind == "sequence")
        end
    end
end

-- Sentinels: two real non-overlapping physical-side assignments.
local sentinels = Registry:GetDefinitions("sentinels", "heroic")
assert(#sentinels == 2 and sentinels[1].key == "team_a" and sentinels[2].key == "team_b")
assert(sentinels[1].compactGroups and sentinels[2].compactGroups)
local ok = Assignments:ApplyBossDraft("sentinels", "heroic", { team_a = "Group 1", team_b = "Group 2" })
assert(ok)
local sentWarning = Assignments:BuildCallWarning(
    "After Stasis: hold assigned sides.",
    "sentinels", "heroic", "side_swap"
)
assert(sentWarning == "After Stasis: hold assigned sides. Green: Group 1. Red: Group 2.")

-- Lost Explorers has no fixed roster on Normal/Heroic; Mythic controls crate breaks.
assert(#Registry:GetDefinitions("explorers", "normal") == 0)
assert(#Registry:GetDefinitions("explorers", "heroic") == 0)
assert(#Registry:GetDefinitions("explorers", "mythic") == 3)
for _, difficulty in ipairs(difficulties) do
    for _, definition in ipairs(Registry:GetDefinitions("explorers", difficulty)) do
        assert(definition.callKey ~= "fish")
    end
end

-- Vashnik: fixed fountain route, no roster fields.
for _, difficulty in ipairs(difficulties) do
    assert(#Registry:GetDefinitions("vashnik", difficulty) == 0)
end

-- Sszorak: two distinct 5+ Mutilate groups and three distinct Cyst Poppers.
ok = Assignments:ApplyBossDraft("sszorak", "heroic", {
    mutilate_group_1 = "Alpha, Bravo, Charlie, Delta, Echo",
    mutilate_group_2 = "Foxtrot, Golf, Hotel, India, Juliet",
    cyst_popper_1 = "Kilo",
    cyst_popper_2 = "Lima",
    cyst_popper_3 = "Mike",
})
assert(ok)
local maelstrom = Assignments:BuildCallWarning(
    "Maelstrom: assigned Poppers trigger Cysts.",
    "sszorak", "heroic", "maelstrom"
)
assert(maelstrom:find("Popper 1: Kilo.", 1, true) and maelstrom:find("Popper 2: Lima.", 1, true) and maelstrom:find("Popper 3: Mike.", 1, true))
local shortTeam, shortError = Assignments:ApplyBossDraft("sszorak", "heroic", {
    mutilate_group_1 = "Alpha, Bravo, Charlie, Delta",
    mutilate_group_2 = "Foxtrot, Golf, Hotel, India, Juliet",
    cyst_popper_1 = "Kilo", cyst_popper_2 = "Lima", cyst_popper_3 = "Mike",
})
assert(not shortTeam and shortError.assignmentKey == "mutilate_group_1")
local duplicatePopper, popperError = Assignments:ApplyBossDraft("sszorak", "heroic", {
    mutilate_group_1 = "Alpha, Bravo, Charlie, Delta, Echo",
    mutilate_group_2 = "Foxtrot, Golf, Hotel, India, Juliet",
    cyst_popper_1 = "Kilo", cyst_popper_2 = "Kilo", cyst_popper_3 = "Mike",
})
assert(not duplicatePopper and popperError.assignmentKey == "cyst_popper_2")

-- Twin Fangs: Normal is dynamic; Heroic/Mythic have three fixed fresh groups.
assert(#Registry:GetDefinitions("twinfangs", "normal") == 0)
ok = Assignments:ApplyBossDraft("twinfangs", "heroic", {
    feast_team_a = "One, Two, Three",
    feast_team_b = "Four, Five, Six",
    feast_team_c = "Seven, Eight, Nine",
})
assert(ok)
local feast = Assignments:BuildCallWarning(
    "Feast: assigned groups soak in order.",
    "twinfangs", "heroic", "feast"
)
assert(feast:find("Hit 1: One, Two, Three.", 1, true))
assert(feast:find("Hit 2: Four, Five, Six.", 1, true))
assert(feast:find("Hit 3: Seven, Eight, Nine.", 1, true))
local overlapFeast, overlapFeastError = Assignments:ApplyBossDraft("twinfangs", "heroic", {
    feast_team_a = "One, Two, Three",
    feast_team_b = "Three, Five, Six",
    feast_team_c = "Seven, Eight, Nine",
})
assert(not overlapFeast and overlapFeastError.assignmentKey == "feast_team_b")
for _, definition in ipairs(Registry:GetDefinitions("twinfangs", "mythic")) do
    assert(not definition.key:find("tainted", 1, true), "Tainted Blood needs no fixed roster assignment")
end

-- Coiled Altar: Normal has no fixed Guillotine team; Heroic adds two 5+ groups.
assert(#Registry:GetCallDefinitions("altar", "normal", "guillotine") == 0)
assert(#Registry:GetCallDefinitions("altar", "heroic", "guillotine") == 2)
ok = Assignments:ApplyBossDraft("altar", "heroic", {
    orb_collectors = "Collectorone, Collectortwo",
    guillotine_a = "A1, A2, A3, A4, A5",
    guillotine_b = "B1, B2, B3, B4, B5",
    wail_kick_a = "Kickerone",
    wail_kick_b = "Kickertwo",
})
assert(ok)
local toxic = Assignments:BuildCallWarning("Orbs: collectors move them to Triangle.", "altar", "heroic", "toxic")
assert(toxic:find("Collectors: Collectorone, Collectortwo.", 1, true))
local oneCollector, collectorError = Assignments:ApplyBossDraft("altar", "heroic", {
    orb_collectors = "Collectorone",
    guillotine_a = "A1, A2, A3, A4, A5",
    guillotine_b = "B1, B2, B3, B4, B5",
    wail_kick_a = "Kickerone",
    wail_kick_b = "Kickertwo",
})
assert(not oneCollector and collectorError.assignmentKey == "orb_collectors")

-- Ula'tek: Mythic adds Coil, egg-carrier and 4+ Incubation assignments.
ok = Assignments:ApplyBossDraft("ulatek", "mythic", {
    coil_a = "Alpha, Bravo, Charlie, Delta, Echo",
    coil_b = "Foxtrot, Golf, Hotel, India, Juliet",
    egg_left = "Hunterone",
    egg_right = "Magetwo",
    incubation_team = "Tankone, Tanktwo, Rogueone, Priestone",
})
assert(ok)
local incubation = Assignments:BuildCallWarning(
    "Incubation: assigned group take one hit each.",
    "ulatek", "mythic", "incubation"
)
assert(incubation:find("Incubation: Tankone, Tanktwo", 1, true))

local invalid, err = Assignments:ApplyBossDraft("sszorak", "heroic", { mutilate_group_1 = "Bad\1Name" })
assert(not invalid and err and err.assignmentKey == "mutilate_group_1")

print("ok - assignments stay minimal, valid and difficulty-specific")
