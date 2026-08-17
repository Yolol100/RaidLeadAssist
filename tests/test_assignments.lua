local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Services/AssignmentService.lua", ns)

local Registry = ns:GetModule("Encounters.AssignmentRegistry")
local Assignments = ns:GetModule("Services.AssignmentService")
local db = { assignments = {} }
Assignments:Initialize(db)

local bosses = { "nekzali", "sentinels", "explorers", "vashnik", "sszorak", "twinfangs", "altar", "ulatek" }
for _, bossKey in ipairs(bosses) do
    for _, difficultyKey in ipairs({ "normal", "heroic", "mythic" }) do
        local layout = Registry:GetLayout(bossKey, difficultyKey)
        assert(type(layout.summary) == "string", "layout summary missing: " .. bossKey .. "/" .. difficultyKey)
        assert(type(layout.sections) == "table", "layout sections missing: " .. bossKey .. "/" .. difficultyKey)
        local seen = {}
        for _, definition in ipairs(Registry:GetDefinitions(bossKey, difficultyKey)) do
            assert(not seen[definition.key], "assignment keys must be unique per boss/difficulty")
            seen[definition.key] = true
            assert(definition.kind == "assignee" or definition.kind == "rotation" or definition.kind == "rule" or definition.kind == "sequence",
                "every assignment must expose a supported field kind")
        end
    end
end

assert(#Registry:GetDefinitions("sszorak", "heroic") == 3, "Sszorak should stay a focused Mutilate rotation")
assert(#Registry:GetDefinitions("ulatek", "normal") == 1, "Normal Ula'tek should expose optional egg ownership")
assert(#Registry:GetDefinitions("ulatek", "mythic") > #Registry:GetDefinitions("ulatek", "heroic"), "Mythic Ula'tek needs extra intercept planning")
assert(#Registry:GetLayout("twinfangs", "mythic").sections == 4, "Mythic Twin Fangs should have four tactic-specific assignment blocks")
assert(#Registry:GetLayout("vashnik", "normal").sections == 1, "Normal Vashnik should stay lightweight")

local vashnikNormal = Registry:GetDefinitions("vashnik", "normal")
assert(vashnikNormal[1].key == "fountain_order" and vashnikNormal[1].kind == "sequence", "Vashnik Normal must use one sequence field")
assert(vashnikNormal[1].helper == "FLAME > SHADOW > SHADOW > BLOOD > BLOOD > FLAME", "Vashnik assignment helper must match the active raid route exactly")

local nekHeroic = Registry:GetDefinitions("nekzali", "heroic")
local cremationRules = 0
for _, definition in ipairs(nekHeroic) do
    if definition.key:find("cremation_", 1, true) then
        assert(definition.kind == "rule", "Cremation must be a movement rule, not a roster assignment")
        cremationRules = cremationRules + 1
    end
end
assert(cremationRules == 2, "Heroic Nek'zali should expose two Cremation rules")

local sentinels = Registry:GetDefinitions("sentinels", "heroic")
for _, definition in ipairs(sentinels) do
    if definition.key:find("stasis_", 1, true) then
        assert(definition.exactPlayers == 4, "Helical Toxin groups must encode exact four-player validation")
        assert(definition.exclusiveGroup == "stasis", "Helical Toxin groups must reject cross-group overlap")
    end
end

local twinMythic = Registry:GetDefinitions("twinfangs", "mythic")
for _, definition in ipairs(twinMythic) do
    if definition.key:find("brood_kick_", 1, true) then
        assert(definition.rotation == nil and definition.kind == "assignee", "Broodling kicks are simultaneous coverage, not a rotating cast assignment")
        assert(definition.exclusiveGroup == "brood", "simultaneous Broodling kick owners must be distinct")
    elseif definition.key:find("feast_", 1, true) then
        assert(definition.minPlayers == 3, "every Ravenous Feast hit must require at least three configured players")
        assert(definition.exclusiveGroup == "feast", "Feast groups must reject repeated Feasted players")
    end
end

local altarNormal = Registry:GetDefinitions("altar", "normal")
assert(altarNormal[1].key == "guillotine_a" and altarNormal[1].required, "Normal Altar needs one required Guillotine team")
assert(altarNormal[2].key == "guillotine_b" and not altarNormal[2].required, "Normal Altar second Guillotine team should be optional")

local ok, values = Assignments:ApplyBossDraft("sszorak", "heroic", {
    mutilate_a = "Alpha, Bravo, Charlie, Delta, Echo",
    mutilate_b = "Foxtrot, Golf, Hotel, India, Juliet",
})
assert(ok, values and values.message)
assert(Assignments:GetValue("sszorak", "heroic", "mutilate_a") == "Alpha, Bravo, Charlie, Delta, Echo")
assert(Assignments:GetValue("sszorak", "normal", "mutilate_a") == "", "difficulty assignments must stay isolated")

local invalidGroup, groupError = Assignments:ApplyBossDraft("sszorak", "heroic", {
    mutilate_a = "Alpha, Bravo, Charlie, Delta",
    mutilate_b = "Foxtrot, Golf, Hotel, India, Juliet",
})
assert(not invalidGroup and groupError.assignmentKey == "mutilate_a", "Mutilate must reject fewer than five configured players")
assert(groupError.message:find("at least 5 unique players", 1, true), "Mutilate validation should explain the five-player minimum")

local duplicateGroup, duplicateError = Assignments:ApplyBossDraft("sszorak", "heroic", {
    mutilate_a = "Alpha, Bravo, Charlie, Delta, alpha",
    mutilate_b = "Foxtrot, Golf, Hotel, India, Juliet",
})
assert(not duplicateGroup and duplicateError.assignmentKey == "mutilate_a", "one assignment must reject duplicate player names case-insensitively")
assert(duplicateError.message:find("duplicate player", 1, true), "duplicate-player validation must explain the error")

local overlapGroup, overlapError = Assignments:ApplyBossDraft("sszorak", "heroic", {
    mutilate_a = "Alpha, Bravo, Charlie, Delta, Echo",
    mutilate_b = "Echo, Foxtrot, Golf, Hotel, India",
})
assert(not overlapGroup and overlapError.assignmentKey == "mutilate_b", "distinct Mutilate teams must reject overlap")
assert(overlapError.message:find("assigned to both", 1, true), "overlap validation must name the conflict")

local invalidStasis, stasisError = Assignments:ApplyBossDraft("sentinels", "heroic", {
    breath_side = "Alpha",
    blood_side = "Bravo",
    stasis_a = "One, Two, Three",
    stasis_b = "Four, Five, Six, Seven",
})
assert(not invalidStasis and stasisError.assignmentKey == "stasis_a", "Stasis must reject non-four-player groups")
assert(stasisError.message:find("exactly 4 unique players", 1, true), "Stasis validation should explain the exact group size")

local invalidFeast, feastError = Assignments:ApplyBossDraft("twinfangs", "heroic", {
    feast_a = "One, Two",
    feast_b = "Three, Four, Five",
    feast_c = "Six, Seven, Eight",
    stone_a = "Nine",
    stone_b = "Ten",
})
assert(not invalidFeast and feastError.assignmentKey == "feast_a", "Ravenous Feast must reject fewer than three configured players per hit")
assert(feastError.message:find("at least 3 unique players", 1, true), "Feast validation should explain the three-player minimum")

local overlapFeast, overlapFeastError = Assignments:ApplyBossDraft("twinfangs", "heroic", {
    feast_a = "One, Two, Three",
    feast_b = "Three, Four, Five",
    feast_c = "Six, Seven, Eight",
    stone_a = "Nine",
    stone_b = "Ten",
})
assert(not overlapFeast and overlapFeastError.assignmentKey == "feast_b", "Feasted players must not appear in consecutive Feast groups")

ok = Assignments:ApplyBossDraft("sszorak", "heroic", {
    mutilate_a = "Alpha, Bravo, Charlie, Delta, Echo",
    mutilate_b = "Foxtrot, Golf, Hotel, India, Juliet",
})
assert(ok)
local first, firstComplete = Assignments:BuildCallWarning("APEX PREDATOR", "sszorak", "heroic", "apex")
assert(firstComplete and first:find("TEAM A: Alpha", 1, true), "first Mutilate call should use Team A")
Assignments:AdvanceCall("sszorak", "heroic", "apex")
local second = Assignments:BuildCallWarning("APEX PREDATOR", "sszorak", "heroic", "apex")
assert(second:find("TEAM B: Foxtrot", 1, true), "second Mutilate call should use Team B")
Assignments:ResetRuntime()
local reset = Assignments:BuildCallWarning("APEX PREDATOR", "sszorak", "heroic", "apex")
assert(reset:find("TEAM A: Alpha", 1, true), "rotation should reset between pulls")

local missing = Assignments:GetMissingRequired("sszorak", "heroic")
assert(#missing == 0, "filled required Sszorak slots should be complete")

ok = Assignments:ApplyBossDraft("vashnik", "mythic", {
    bile_team = "Alpha, Bravo",
    fountain_order = "FLAME > SHADOW > SHADOW > BLOOD > BLOOD > FLAME",
    tumor_left = "Left Froth -> left lane",
    tumor_right = "Right Froth -> right lane",
})
assert(ok, "rule and sequence fields should accept tactic text without roster-count validation")

ok = Assignments:ApplyBossDraft("ulatek", "mythic", {
    coil_a = "Group One",
    coil_b = "Group Two",
    egg_left = "Hunterone",
    egg_right = "Magetwo",
    incubation_a = "Tankone",
    incubation_b = "Tanktwo",
    incubation_c = "Rogueone",
})
assert(ok)
local coil = Assignments:BuildCallWarning("SPECTRAL COILS", "ulatek", "mythic", "coils")
assert(coil:find("GROUP A: Group One", 1, true), "Ula'tek Coil call should start with Group A")
Assignments:AdvanceCall("ulatek", "mythic", "coils")
coil = Assignments:BuildCallWarning("SPECTRAL COILS", "ulatek", "mythic", "coils")
assert(coil:find("GROUP B: Group Two", 1, true), "Ula'tek Coil call should rotate to Group B")

local plan = Assignments:GetPlanLines("ulatek", "mythic")
assert(#plan >= 7, "Ula'tek Mythic plan should announce configured jobs")
for index = 1, #plan do assert(#plan[index] <= Assignments.MAX_WARNING_LENGTH, "assignment plan line too long") end

local overflowOk = Assignments:ApplyBossDraft("twinfangs", "normal", {
    feast_a = "AlphaLongPlayerNameOne, AlphaLongPlayerNameTwo, AlphaLongPlayerNameThree",
    feast_b = "BravoLongPlayerNameOne, BravoLongPlayerNameTwo, BravoLongPlayerNameThree",
    feast_c = "CharlieLongPlayerOne, CharlieLongPlayerTwo, CharlieLongPlayerThree",
    stone_a = "StoneOne",
    stone_b = "StoneTwo",
})
assert(overflowOk, "long but valid assignments should save")
local feastBase = "RAVENOUS FEAST > 3 HITS > 3+ PER HIT > GROUPS A > B > C"
local overflowWarning, overflowComplete = Assignments:BuildCallWarning(feastBase, "twinfangs", "normal", "feast")
assert(overflowComplete == false, "oversized assignment detail must be reported as incomplete")
assert(overflowWarning == feastBase, "overflow must fall back to the complete base call rather than a misleading partial assignment")

local invalid, err = Assignments:ApplyBossDraft("sszorak", "heroic", { mutilate_a = "Bad\1Name" })
assert(not invalid and err and err.assignmentKey == "mutilate_a", "control characters must be rejected")

print("ok - typed assignments, uniqueness, overlap safety, group sizes, overflow fallback, persistence, and rotations")
