local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/SszorakAssignmentOverride.lua", ns)
T.Load("Services/AssignmentService.lua", ns)
local Registry = ns:GetModule("Encounters.AssignmentRegistry")
local Assignments = ns:GetModule("Services.AssignmentService")
Assignments:Initialize({ assignments = {} })
for _, difficulty in ipairs({"normal","heroic","mythic"}) do
    local defs = Registry:GetDefinitions("sszorak", difficulty)
    assert(#defs == 5, "Sszorak needs two Mutilate teams plus three Cyst Poppers")
    assert(defs[1].minPlayers == 5 and defs[2].minPlayers == 5)
    for i=3,5 do
        assert(defs[i].key == "cyst_popper_" .. tostring(i-2))
        assert(defs[i].kind == "assignee" and defs[i].callKey == "maelstrom" and defs[i].required)
        assert(defs[i].exclusiveGroup == "cyst_poppers")
    end
end
local ok = Assignments:ApplyBossDraft("sszorak","heroic",{
    mutilate_group_1="Alpha, Bravo, Charlie, Delta, Echo",
    mutilate_group_2="Foxtrot, Golf, Hotel, India, Juliet",
    cyst_popper_1="Kilo", cyst_popper_2="Lima", cyst_popper_3="Mike",
})
assert(ok)
local warning = Assignments:BuildCallWarning("MAELSTROM > POPPERS 1/2/3 > KNOCK AGAINST EACH WIND","sszorak","heroic","maelstrom")
assert(warning:find("POPPER 1: Kilo",1,true) and warning:find("POPPER 2: Lima",1,true) and warning:find("POPPER 3: Mike",1,true))
print("ok - Sszorak validates two 5+ Mutilate teams and three distinct Cyst Poppers")
