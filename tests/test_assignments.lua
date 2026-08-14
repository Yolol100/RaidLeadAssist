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
    end
end

assert(#Registry:GetDefinitions("sszorak", "heroic") == 3, "Sszorak should be a focused Mutilate rotation")
assert(#Registry:GetDefinitions("ulatek", "normal") == 0, "Normal Ula'tek should not invent fixed assignments")
assert(#Registry:GetDefinitions("ulatek", "mythic") > #Registry:GetDefinitions("ulatek", "heroic"), "Mythic Ula'tek needs extra intercept planning")
assert(#Registry:GetLayout("twinfangs", "mythic").sections == 4, "Mythic Twin Fangs should have four tactic-specific assignment blocks")
assert(#Registry:GetLayout("vashnik", "normal").sections == 1, "Normal Vashnik should stay lightweight")

local ok, values = Assignments:ApplyBossDraft("sszorak", "heroic", {
    mutilate_a = "Alpha, Bravo, Charlie, Delta, Echo",
    mutilate_b = "Foxtrot, Golf, Hotel, India, Juliet",
})
assert(ok, values and values.message)
assert(Assignments:GetValue("sszorak", "heroic", "mutilate_a") == "Alpha, Bravo, Charlie, Delta, Echo")
assert(Assignments:GetValue("sszorak", "normal", "mutilate_a") == "", "difficulty assignments must stay isolated")

local first = Assignments:BuildCallWarning("APEX PREDATOR", "sszorak", "heroic", "apex")
assert(first:find("TEAM A: Alpha", 1, true), "first Mutilate call should use Team A")
Assignments:AdvanceCall("sszorak", "heroic", "apex")
local second = Assignments:BuildCallWarning("APEX PREDATOR", "sszorak", "heroic", "apex")
assert(second:find("TEAM B: Foxtrot", 1, true), "second Mutilate call should use Team B")
Assignments:ResetRuntime()
local reset = Assignments:BuildCallWarning("APEX PREDATOR", "sszorak", "heroic", "apex")
assert(reset:find("TEAM A: Alpha", 1, true), "rotation should reset between pulls")

local missing = Assignments:GetMissingRequired("sszorak", "heroic")
assert(#missing == 0, "filled required Sszorak slots should be complete")

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

local invalid, err = Assignments:ApplyBossDraft("sszorak", "heroic", { mutilate_a = "Bad\1Name" })
assert(not invalid and err and err.assignmentKey == "mutilate_a", "control characters must be rejected")

print("ok - boss-specific assignment layouts, persistence, validation, and rotations")
