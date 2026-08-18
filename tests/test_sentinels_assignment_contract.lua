local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss12AssignmentOverride.lua", ns)
T.Load("Services/AssignmentService.lua", ns)
local Registry = ns:GetModule("Encounters.AssignmentRegistry")
local Assignments = ns:GetModule("Services.AssignmentService")
Assignments:Initialize({ assignments = {} })
for _, difficulty in ipairs({"normal","heroic","mythic"}) do
    local defs = Registry:GetDefinitions("sentinels", difficulty)
    assert(#defs == 2)
    assert(defs[1].key == "team_a" and defs[1].label == "Team A · Green Side" and defs[1].required)
    assert(defs[2].key == "team_b" and defs[2].label == "Team B · Red Side" and defs[2].required)
    assert(defs[1].callKey == "side_swap" and defs[2].callKey == "side_swap")
end
local ok = Assignments:ApplyBossDraft("sentinels", "heroic", { team_a="Group 1", team_b="Group 2" })
assert(ok)
local warning = Assignments:BuildCallWarning(
    "After Stasis: hold your side while tanks swap the bosses.",
    "sentinels", "heroic", "side_swap"
)
assert(warning == "After Stasis: hold your side while tanks swap the bosses. Team A: Group 1. Team B: Group 2.")
local breath = Assignments:BuildCallWarning("Green side: kill the slime.", "sentinels", "heroic", "coagulation")
assert(breath == "Green side: kill the slime.")
print("ok - Sentinels assignments append readable team context to shared calls")
