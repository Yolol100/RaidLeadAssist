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
        difficulty .. " Sentinels should expose only the flex-safe raid split")
    assert(#definitions == 2, difficulty .. " Sentinels needs exactly Green and Red team selectors")

    assert(definitions[1].key == "green_team" and definitions[1].label == "Green Team Selector")
    assert(definitions[1].kind == "rule" and definitions[1].required == true)
    assert(definitions[1].callKey == "coagulation" and definitions[1].callLabel == "GREEN")
    assert(definitions[1].rotation == nil and definitions[1].exclusiveGroup == nil)

    assert(definitions[2].key == "red_team" and definitions[2].label == "Red Team Selector")
    assert(definitions[2].kind == "rule" and definitions[2].required == true)
    assert(definitions[2].callKey == "miasma" and definitions[2].callLabel == "RED")
    assert(definitions[2].rotation == nil and definitions[2].exclusiveGroup == nil)
end

local missing = Assignments:GetMissingRequired("sentinels", "heroic")
assert(#missing == 2, "Sentinels must require both split selectors before the pull")

local ok, result = Assignments:ApplyBossDraft("sentinels", "heroic", {
    green_team = "Group 1",
    red_team = "Group 2",
})
assert(ok, result and result.message)
assert(#Assignments:GetMissingRequired("sentinels", "heroic") == 0)

local greenWarning, greenComplete = Assignments:BuildCallWarning(
    "GREEN TEAM > KILL ADD", "sentinels", "heroic", "coagulation"
)
assert(greenComplete and greenWarning:find("GREEN: Group 1", 1, true),
    "Green team selector must be appended to the live add-priority call")

local redWarning, redComplete = Assignments:BuildCallWarning(
    "RED TEAM > SOAK TARGET", "sentinels", "heroic", "miasma"
)
assert(redComplete and redWarning:find("RED: Group 2", 1, true),
    "Red team selector must be appended to the live Miasma soak call")

print("ok - Sentinels has two required flex selectors and injects them into live raidleader calls")
