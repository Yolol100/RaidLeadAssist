-- Phase 2 regression: settings must describe the same split and dynamic stack math as the raid tactic.
local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

T.Load("Encounters/AssignmentRegistry.lua", ns)

local Registry = ns:GetModule("Encounters.AssignmentRegistry")

for _, difficulty in ipairs({ "normal", "heroic", "mythic" }) do
    local layout = Registry:GetLayout("sentinels", difficulty)
    assert(#layout.sections == 3, difficulty .. " Sentinels should keep split, Stasis rules and healer jobs")
    assert(layout.sections[1].key == "split", difficulty .. " Sentinels must configure starting boss sides first")
    assert(layout.sections[2].key == "stasis", difficulty .. " Sentinels must configure Helical Toxin matching rules")

    local definitions = Registry:GetDefinitions("sentinels", difficulty)
    local breath, blood, oneThree, twoTwo
    for _, definition in ipairs(definitions) do
        if definition.key == "breath_side" then breath = definition end
        if definition.key == "blood_side" then blood = definition end
        if definition.key == "stasis_1_3" then oneThree = definition end
        if definition.key == "stasis_2_2" then twoTwo = definition end
        assert(definition.exactPlayers == nil or definition.key:find("^stasis_") == nil, "Helical Toxin settings must not pretend dynamic stack matching is a fixed four-player roster")
    end

    assert(breath and breath.label == "Groups 1+2 > Breath Start", difficulty .. " split settings must match Groups 1+2 on Breath")
    assert(blood and blood.label == "Groups 3+4 > Blood Start", difficulty .. " split settings must match Groups 3+4 on Blood")
    assert(oneThree and oneThree.kind == "rule", difficulty .. " must store the 1+3 Helical Toxin rule")
    assert(twoTwo and twoTwo.kind == "rule", difficulty .. " must store the 2+2 Helical Toxin rule")
end

print("ok - Sentinels settings match split and dynamic Helical Toxin tactics")
