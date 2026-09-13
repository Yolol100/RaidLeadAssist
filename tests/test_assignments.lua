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

-- Coiled Altar: Normal has no fixed Guillotine team; Heroic uses the live 3+ floor.
assert(#Registry:GetCallDefinitions("altar", "normal", "guillotine") == 0)
assert(#Registry:GetCallDefinitions("altar", "heroic", "guillotine") == 2)
ok = Assignments:ApplyBossDraft("altar", "heroic", {
    orb_collectors = "Collectorone, Collectortwo",
    guillotine_a = "A1, A2, A3",
    guillotine_b = "B1, B2, B3",
    wail_kick_a = "Kickerone",
    wail_kick_b = "Kickertwo",
})
assert(ok, "Heroic Coiled Altar must accept two distinct 3-player Guillotine groups")
local toxic = Assignments:BuildCallWarning("Orbs: collectors move them to Triangle.", "altar", "heroic", "toxic")
assert(toxic:find("Collectors: Collectorone, Collectortwo.", 1, true))
local oneCollector, collectorError = Assignments:ApplyBossDraft("altar", "heroic", {
    orb_collectors = "Collectorone",
    guillotine_a = "A1, A2, A3",
    guillotine_b = "B1, B2, B3",
    wail_kick_a = "Kickerone",
    wail_kick_b = "Kickertwo",
})
assert(not oneCollector and collectorError.assignmentKey == "orb_collectors")
local shortGuillotine, shortGuillotineError = Assignments:ApplyBossDraft("altar", "heroic", {
    orb_collectors = "Collectorone, Collectortwo",
    guillotine_a = "A1, A2",
    guillotine_b = "B1, B2, B3",
    wail_kick_a = "Kickerone",
    wail_kick_b = "Kickertwo",
})
assert(not shortGuillotine and shortGuillotineError.assignmentKey == "guillotine_a",
    "Heroic Coiled Altar must reject a Guillotine group below the live 3-player floor")

-- Ula'tek: Normal has no fixed Coil team, while Heroic/Mythic require alternating non-overlapping teams.
assert(#Registry:GetCallDefinitions("ulatek", "normal", "coils") == 0,
    "Normal Ula'tek may soak Coils as one raid group")
local heroicCoils = Registry:GetCallDefinitions("ulatek", "heroic", "coils")
assert(#heroicCoils == 2 and heroicCoils[1].required and heroicCoils[2].required,
    "Heroic Ula'tek must expose two required alternating Coil teams")
local ready, readyReason = Assignments:IsCallReady("ulatek", "heroic", "coils")
assert(not ready and readyReason:find("Missing:", 1, true),
    "Heroic Coil call must fail closed until both teams are assigned")

ok = Assignments:ApplyBossDraft("ulatek", "mythic", {
    coil_a = "Alpha, Bravo, Charlie, Delta, Echo",
    coil_b = "Foxtrot, Golf, Hotel, India, Juliet",
    egg_left = "Hunterone",
    egg_right = "Magetwo",
    bite_melee = "Meleeone, Meleetwo, Meleethree",
    bite_ranged = "Rangeone, Rangetwo, Rangethree",
    bite_healer = "Healone, Healtwo, Supportone",
    incubation_team = "Tankone, Tanktwo, Rogueone, Priestone",
})
assert(ok)
local incubation = Assignments:BuildCallWarning(
    "Incubation: assigned group take one hit each.",
    "ulatek", "mythic", "incubation"
)
assert(incubation:find("Incubation: Tankone, Tanktwo", 1, true))
local biteWarning = Assignments:BuildCallWarning(
    "Bite: assigned groups soak; Purge waves out.",
    "ulatek", "mythic", "bite"
)
assert(biteWarning:find("Melee: Meleeone, Meleetwo, Meleethree.", 1, true))
assert(biteWarning:find("Ranged: Rangeone, Rangetwo, Rangethree.", 1, true))
assert(biteWarning:find("Healer: Healone, Healtwo, Supportone.", 1, true))

local overlapCoils, overlapCoilsError = Assignments:ApplyBossDraft("ulatek", "heroic", {
    coil_a = "Alpha, Bravo, Charlie, Delta, Echo",
    coil_b = "Echo, Foxtrot, Golf, Hotel, India",
})
assert(not overlapCoils and overlapCoilsError.assignmentKey == "coil_b",
    "Ula'tek must reject a player assigned to both alternating Coil teams")

local overlapEggs, overlapEggsError = Assignments:ApplyBossDraft("ulatek", "normal", {
    egg_left = "Carrierone",
    egg_right = "Carrierone",
})
assert(not overlapEggs and overlapEggsError.assignmentKey == "egg_right",
    "Ula'tek must reject one player as both side egg carriers")

local overlapBite, overlapBiteError = Assignments:ApplyBossDraft("ulatek", "normal", {
    bite_melee = "Helperone, Helpertwo",
    bite_ranged = "Helperone, Helperthree",
    bite_healer = "Helperfour, Helperfive",
})
assert(not overlapBite and overlapBiteError.assignmentKey == "bite_ranged",
    "Ula'tek must reject overlap across Bite helper sectors")

local invalid, err = Assignments:ApplyBossDraft("sszorak", "heroic", { mutilate_group_1 = "Bad\1Name" })
assert(not invalid and err and err.assignmentKey == "mutilate_group_1")

print("ok - assignments stay minimal, valid, difficulty-specific and fail closed on final-boss overlap")
