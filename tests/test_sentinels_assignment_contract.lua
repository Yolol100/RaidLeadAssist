local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss12AssignmentOverride.lua", ns)
T.Load("Services/AssignmentService.lua", ns)

local Registry = ns:GetModule("Encounters.AssignmentRegistry")
local Assignments = ns:GetModule("Services.AssignmentService")
local db = { assignments = {} }
Assignments:Initialize(db)

for _, difficulty in ipairs({ "normal", "heroic", "mythic" }) do
    local layout = Registry:GetLayout("sentinels", difficulty)
    local definitions = Registry:GetDefinitions("sentinels", difficulty)
    assert(type(layout.summary) == "string" and layout.summary ~= "")
    assert(#layout.sections == 1 and layout.sections[1].key == "split",
        difficulty .. " Sentinels should expose only the flex-safe starting split")
    assert(#definitions == 2, difficulty .. " Sentinels needs exactly Team A and Team B selectors")

    assert(definitions[1].key == "team_a" and definitions[1].label == "Team A · Breath Start")
    assert(definitions[1].kind == "rule" and definitions[1].required == true)
    assert(definitions[1].callKey == "side_swap" and definitions[1].callLabel == "TEAM A")
    assert(definitions[1].rotation == nil and definitions[1].exclusiveGroup == nil)

    assert(definitions[2].key == "team_b" and definitions[2].label == "Team B · Blood Start")
    assert(definitions[2].kind == "rule" and definitions[2].required == true)
    assert(definitions[2].callKey == "side_swap" and definitions[2].callLabel == "TEAM B")
    assert(definitions[2].rotation == nil and definitions[2].exclusiveGroup == nil)
end

local missing = Assignments:GetMissingRequired("sentinels", "heroic")
assert(#missing == 2, "Sentinels must require both starting team selectors before the pull")

local ok, result = Assignments:ApplyBossDraft("sentinels", "heroic", {
    team_a = "Group 1",
    team_b = "Group 2",
})
assert(ok, result and result.message)
assert(#Assignments:GetMissingRequired("sentinels", "heroic") == 0)

local swapWarning, swapComplete = Assignments:BuildCallWarning(
    "TEAMS > SWAP BOSS SIDES", "sentinels", "heroic", "side_swap"
)
assert(swapComplete and swapWarning:find("TEAM A: Group 1", 1, true),
    "side-swap call must remind the raid which roster is Team A")
assert(swapWarning:find("TEAM B: Group 2", 1, true),
    "side-swap call must remind the raid which roster is Team B")

local breathWarning = Assignments:BuildCallWarning(
    "BREATH SIDE > KILL ADD", "sentinels", "heroic", "coagulation"
)
assert(breathWarning == "BREATH SIDE > KILL ADD",
    "Breath mechanics must stay side-based because Team A/B swap bosses after Stasis")

local bloodWarning = Assignments:BuildCallWarning(
    "BLOOD SIDE > SOAK TARGET", "sentinels", "heroic", "miasma"
)
assert(bloodWarning == "BLOOD SIDE > SOAK TARGET",
    "Blood mechanics must stay side-based because Team A/B swap bosses after Stasis")

print("ok - Sentinels start teams are flex-safe while live boss mechanics remain correct after swaps")
