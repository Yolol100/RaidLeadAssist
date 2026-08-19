local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Core/EventBus.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss12AssignmentOverride.lua", ns)
T.Load("Encounters/Boss34AssignmentOverride.lua", ns)
T.Load("Encounters/SszorakAssignmentOverride.lua", ns)
T.Load("Encounters/TwinFangsAssignmentOverride.lua", ns)
T.Load("Encounters/Boss78AssignmentOverride.lua", ns)
for _, file in ipairs({
    "Nekzali.lua", "Sentinels.lua", "Explorers.lua", "Vashnik.lua",
    "Sszorak.lua", "TwinFangs.lua", "CoiledAltar.lua", "Ulatek.lua",
}) do
    T.Load("Encounters/VenomousAbyss/" .. file, ns)
end

local roster = {}
for group = 1, 4 do
    for index = 1, 5 do
        roster[#roster + 1] = { name = ("G%dP%d"):format(group, index), subgroup = group, role = "DAMAGER" }
    end
end
ns:RegisterModule("Services.RosterService", {
    GetRoster = function() return roster end,
})

T.Load("Services/AssignmentService.lua", ns)
local A = ns:GetModule("Services.AssignmentService")
local AR = ns:GetModule("Encounters.AssignmentRegistry")
local R = ns:GetModule("Encounters.Registry")
A:Initialize({ assignments = {} })

-- Fixed Normal mechanics must not create unnecessary assignment placeholders.
assert(#AR:GetDefinitions("nekzali", "normal") == 0)
assert(A:IsCallReady("nekzali", "normal", "pyre") == true)
local normalPyre = R:GetProfile("nekzali", "normal").callsByKey.pyre
local action = A:BuildCallAction(normalPyre.action, "nekzali", "normal", "pyre")
assert(action == "Melee soak together")

-- Heroic Nek'zali needs only the real Pyre soak assignment.
local nekDefs = AR:GetDefinitions("nekzali", "heroic")
assert(#nekDefs == 1 and nekDefs[1].key == "pyre_soakers" and nekDefs[1].compactGroups)
local ok = A:ApplyBossDraft("nekzali", "heroic", { pyre_soakers = "Group 1" })
assert(ok)
local nekPyre = R:GetProfile("nekzali", "heroic").callsByKey.pyre
local nekAction, ready = A:BuildCallAction(nekPyre.action, "nekzali", "heroic", "pyre")
assert(ready and nekAction == "Group 1 soak Pyre")
local nekWarning = A:BuildCallWarning(nekPyre.warning, "nekzali", "heroic", "pyre")
assert(nekWarning == "Pyre: Group 1 soak together.")

-- Group shorthand is validated against the actual current raid subgroups.
local invalid, err = A:ApplyBossDraft("nekzali", "heroic", { pyre_soakers = "Group 5" })
assert(not invalid and err.assignmentKey == "pyre_soakers")
assert(err.message:find("not present", 1, true))

-- Missing required dynamic assignments fail closed instead of sending generic calls.
A:ResetBoss("nekzali", "heroic")
local callReady, reason = A:IsCallReady("nekzali", "heroic", "pyre")
assert(not callReady and reason:find("Pyre Soak Group", 1, true))
local missingAction, complete = A:BuildCallAction(nekPyre.action, "nekzali", "heroic", "pyre")
assert(missingAction == nil and complete == false)

-- Lost Explorers uses a fixed fish order; no fish-runner roster placeholder remains.
for _, difficulty in ipairs({ "normal", "heroic", "mythic" }) do
    for _, definition in ipairs(AR:GetDefinitions("explorers", difficulty)) do
        assert(definition.callKey ~= "fish")
    end
    assert(R:GetProfile("explorers", difficulty).callsByKey.fish.warning == "Fish: Nama, then Iku, then Gebbo.")
end

-- Vashnik route is fixed strategy and therefore has no roster fields.
for _, difficulty in ipairs({ "normal", "heroic", "mythic" }) do
    assert(#AR:GetDefinitions("vashnik", difficulty) == 0)
end
assert(table.concat(R:GetProfile("vashnik", "normal").explanation, "\n"):find(
    "Flame+Shadow, Shadow+Blood, then Blood+Flame", 1, true
))

-- Heroic Feast shows the actual configured groups in order.
ok = A:ApplyBossDraft("twinfangs", "heroic", {
    feast_team_a = "Group 1",
    feast_team_b = "Group 2",
    feast_team_c = "Group 3",
})
assert(ok)
local feast = R:GetProfile("twinfangs", "heroic").callsByKey.feast
local feastWarning = A:BuildCallWarning(feast.warning, "twinfangs", "heroic", "feast")
assert(feastWarning == "Feast: Group 1, then Group 2, then Group 3.")

-- Normal Altar Guillotine is fixed 5+ execution; Heroic introduces assigned groups.
local altarNormal = AR:GetCallDefinitions("altar", "normal", "guillotine")
local altarHeroic = AR:GetCallDefinitions("altar", "heroic", "guillotine")
assert(#altarNormal == 0 and #altarHeroic == 2)
assert(R:GetProfile("altar", "normal").callsByKey.guillotine.warning == "Guillotine: 5+ soak; raid move 40+ yards.")

-- Mythic Ula'tek uses real configured groups/carriers in its shared calls.
ok = A:ApplyBossDraft("ulatek", "mythic", {
    coil_a = "Group 1",
    coil_b = "Group 2",
    egg_left = "G3P1",
    egg_right = "G3P2",
    incubation_team = "Group 4",
})
assert(ok)
local coils = R:GetProfile("ulatek", "mythic").callsByKey.coils
local coilsWarning = A:BuildCallWarning(coils.warning, "ulatek", "mythic", "coils")
assert(coilsWarning == "Coils: Group 1 stack at Square.")
A:AdvanceCall("ulatek", "mythic", "coils")
coilsWarning = A:BuildCallWarning(coils.warning, "ulatek", "mythic", "coils")
assert(coilsWarning == "Coils: Group 2 stack at Square.")

print("ok - difficulty-specific assignments are roster-aware and render into callouts")
