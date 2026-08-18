local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss12AssignmentOverride.lua", ns)

local Registry = ns:GetModule("Encounters.AssignmentRegistry")

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

print("ok - Sentinels exposes only two required flex-safe Green/Red team selectors")
