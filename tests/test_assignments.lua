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

for _, bossKey in ipairs(Registry:GetBossKeys()) do
    local normal = Registry:GetLayout(bossKey, "normal")
    assert(#normal.sections == 0 and #Registry:GetDefinitions(bossKey, "normal") == 0,
        bossKey .. " Normal assignments must remain retired")
    for _, difficultyKey in ipairs({ "heroic", "mythic" }) do
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

-- Heroic bosses with dynamic/role-based execution do not expose fake roster fields.
for _, bossKey in ipairs({ "nekzali", "sentinels", "explorers", "vashnik", "sszorak" }) do
    assert(#Registry:GetDefinitions(bossKey, "heroic") == 0,
        bossKey .. " Heroic must not expose fixed assignments that the strategy does not require")
end
assert(#Registry:GetDefinitions("explorers", "mythic") == 3)
assert(#Registry:GetDefinitions("vashnik", "mythic") == 0)

-- Mythic Sentinels still require two non-overlapping physical sides.
local sentinels = Registry:GetDefinitions("sentinels", "mythic")
assert(#sentinels == 2 and sentinels[1].key == "team_a" and sentinels[2].key == "team_b")
local ok = Assignments:ApplyBossDraft("sentinels", "mythic", { team_a = "Group 1", team_b = "Group 2" })
assert(ok)
local overlap, overlapError = Assignments:ApplyBossDraft("sentinels", "mythic", { team_a = "Group 1", team_b = "Group 1" })
assert(not overlap and overlapError.assignmentKey == "team_b")

-- Mythic Sszorak keeps two 5+ Mutilate teams and three unique Cyst Poppers.
local ssz = Registry:GetDefinitions("sszorak", "mythic")
assert(#ssz == 5)
ok = Assignments:ApplyBossDraft("sszorak", "mythic", {
    mutilate_group_1 = "Alpha, Bravo, Charlie, Delta, Echo",
    mutilate_group_2 = "Foxtrot, Golf, Hotel, India, Juliet",
    cyst_popper_1 = "Kilo", cyst_popper_2 = "Lima", cyst_popper_3 = "Mike",
})
assert(ok)
local shortTeam, shortError = Assignments:ApplyBossDraft("sszorak", "mythic", {
    mutilate_group_1 = "Alpha, Bravo, Charlie, Delta",
    mutilate_group_2 = "Foxtrot, Golf, Hotel, India, Juliet",
    cyst_popper_1 = "Kilo", cyst_popper_2 = "Lima", cyst_popper_3 = "Mike",
})
assert(not shortTeam and shortError.assignmentKey == "mutilate_group_1")
local duplicatePopper, popperError = Assignments:ApplyBossDraft("sszorak", "mythic", {
    mutilate_group_1 = "Alpha, Bravo, Charlie, Delta, Echo",
    mutilate_group_2 = "Foxtrot, Golf, Hotel, India, Juliet",
    cyst_popper_1 = "Kilo", cyst_popper_2 = "Kilo", cyst_popper_3 = "Mike",
})
assert(not duplicatePopper and popperError.assignmentKey == "cyst_popper_2")

-- Heroic Twin Fangs requires three fresh, non-overlapping Feast teams.
local twinHeroic = Registry:GetDefinitions("twinfangs", "heroic")
assert(#twinHeroic == 3)
for index = 1, 3 do
    local definition = twinHeroic[index]
    assert(definition.required and definition.minPlayers == 3 and definition.minRaidFraction == 0.30)
    assert(definition.exclusiveGroup == "heroic_feast")
end
ok = Assignments:ApplyBossDraft("twinfangs", "heroic", {
    feast_heroic_a = "One, Two, Three",
    feast_heroic_b = "Four, Five, Six",
    feast_heroic_c = "Seven, Eight, Nine",
})
assert(ok)
local overlapFeast, overlapFeastError = Assignments:ApplyBossDraft("twinfangs", "heroic", {
    feast_heroic_a = "One, Two, Three",
    feast_heroic_b = "Three, Five, Six",
    feast_heroic_c = "Seven, Eight, Nine",
})
assert(not overlapFeast and overlapFeastError.assignmentKey == "feast_heroic_b")
assert(#Registry:GetDefinitions("twinfangs", "mythic") == 6,
    "Mythic Twin Fangs must remain a separate six-field assignment contract")

-- Coiled Altar Heroic uses Orb Collectors, two 3+ Guillotine teams and Wail kicks.
assert(#Registry:GetDefinitions("altar", "heroic") == 6)
ok = Assignments:ApplyBossDraft("altar", "heroic", {
    orb_collectors = "Collectorone, Collectortwo",
    guillotine_a = "A1, A2, A3",
    guillotine_b = "B1, B2, B3",
    wail_kick_a = "Kickerone",
    wail_kick_b = "Kickertwo",
})
assert(ok)
local shortGuillotine, shortGuillotineError = Assignments:ApplyBossDraft("altar", "heroic", {
    orb_collectors = "Collectorone, Collectortwo",
    guillotine_a = "A1, A2",
    guillotine_b = "B1, B2, B3",
    wail_kick_a = "Kickerone",
    wail_kick_b = "Kickertwo",
})
assert(not shortGuillotine and shortGuillotineError.assignmentKey == "guillotine_a")

-- Ula'tek Heroic/Mythic keep alternating Coils, exact egg carriers and disjoint Bite sectors.
local heroicCoils = Registry:GetCallDefinitions("ulatek", "heroic", "coils")
assert(#heroicCoils == 2 and heroicCoils[1].required and heroicCoils[2].required)
local ready, readyReason = Assignments:IsCallReady("ulatek", "heroic", "coils")
assert(not ready and readyReason:find("Missing:", 1, true))
local overlapCoils, overlapCoilsError = Assignments:ApplyBossDraft("ulatek", "heroic", {
    coil_a = "Alpha, Bravo, Charlie, Delta, Echo",
    coil_b = "Echo, Foxtrot, Golf, Hotel, India",
})
assert(not overlapCoils and overlapCoilsError.assignmentKey == "coil_b")
local tooManyEggs, tooManyEggsError = Assignments:ApplyBossDraft("ulatek", "heroic", {
    egg_left = "Carrierone, Carriertwo",
    egg_right = "Carrierthree",
})
assert(not tooManyEggs and tooManyEggsError.assignmentKey == "egg_left")
local overlapBite, overlapBiteError = Assignments:ApplyBossDraft("ulatek", "heroic", {
    bite_melee = "Helperone, Helpertwo",
    bite_ranged = "Helperone, Helperthree",
    bite_healer = "Helperfour, Helperfive",
})
assert(not overlapBite and overlapBiteError.assignmentKey == "bite_ranged")
assert(#Registry:GetDefinitions("ulatek", "mythic") == 8)

local invalid, err = Assignments:ApplyBossDraft("sszorak", "mythic", { mutilate_group_1 = "Bad\1Name" })
assert(not invalid and err and err.assignmentKey == "mutilate_group_1")

print("ok - assignments are Heroic/Mythic-scoped, minimal and fail closed on size/overlap errors")
