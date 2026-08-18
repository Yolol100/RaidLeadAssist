local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss12AssignmentOverride.lua", ns)

local Registry = ns:GetModule("Encounters.AssignmentRegistry")

for _, difficulty in ipairs({ "normal", "heroic", "mythic" }) do
    local layout = Registry:GetLayout("sentinels", difficulty)
    assert(type(layout.summary) == "string" and layout.summary ~= "")
    assert(#layout.sections == 0,
        difficulty .. " Sentinels should not expose editable fields for the fixed 1+2/3+4 split or fixed 1+3/2+2 toxin math")
    assert(#Registry:GetDefinitions("sentinels", difficulty) == 0,
        difficulty .. " Sentinels must not duplicate fixed strategy facts as settings")
end

print("ok - Sentinels settings stay empty because the split and toxin math are fixed raid-plan rules")
