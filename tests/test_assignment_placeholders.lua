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
    IsRaidRoster = function() return true end,
    GetRoster = function() return roster end,
})

T.Load("Services/AssignmentService.lua", ns)
local A = ns:GetModule("Services.AssignmentService")
local AR = ns:GetModule("Encounters.AssignmentRegistry")
local R = ns:GetModule("Encounters.Registry")
A:Initialize({ assignments = {} })

-- Normal is retired throughout the runtime and may not expose placeholder assignment behavior.
for _, bossKey in ipairs({ "nekzali", "sentinels", "explorers", "vashnik", "sszorak", "twinfangs", "altar", "ulatek" }) do
    assert(R:GetProfile(bossKey, "normal") == nil, bossKey .. " Normal profile must stay retired")
    assert(#AR:GetDefinitions(bossKey, "normal") == 0, bossKey .. " Normal assignments must stay empty")
end
local normalReady, normalReason = A:IsCallReady("nekzali", "normal", "pyre")
assert(not normalReady and normalReason == "Unknown boss or difficulty.",
    "retired Normal call readiness must fail closed")

-- Heroic Nek'zali is role-based: no fixed Pyre roster placeholder is required.
assert(#AR:GetDefinitions("nekzali", "heroic") == 0)
local nekPyre = R:GetProfile("nekzali", "heroic").callsByKey.pyre
assert(nekPyre.warning == "MELEE + TANK — SOAK")
local nekAction, ready = A:BuildCallAction(nekPyre.action, "nekzali", "heroic", "pyre")
assert(ready and nekAction == nekPyre.action)
assert(A:IsCallReady("nekzali", "heroic", "pyre") == true)

-- Mythic Nek'zali keeps only the actual Pyre and rotating well assignments.
local mythicNekDefs = AR:GetDefinitions("nekzali", "mythic")
assert(#mythicNekDefs == 3)
local ok = A:ApplyBossDraft("nekzali", "mythic", {
    pyre_soakers = "Group 1",
    well_a = "Group 2",
    well_b = "Group 3",
})
assert(ok)
local mythicPyre = R:GetProfile("nekzali", "mythic").callsByKey.pyre
local mythicWarning = A:BuildCallWarning(mythicPyre.warning, "nekzali", "mythic", "pyre")
assert(mythicWarning:find("Group 1", 1, true), "Mythic Pyre warning must render the configured group")

-- Group shorthand is validated against the actual current raid subgroups.
local invalid, err = A:ApplyBossDraft("nekzali", "mythic", {
    pyre_soakers = "Group 5",
    well_a = "Group 2",
    well_b = "Group 3",
})
assert(not invalid and err.assignmentKey == "pyre_soakers")
assert(err.message:find("not present", 1, true))

-- Lost Explorers Heroic uses fixed sequential fish calls; neither difficulty has a fish-owner placeholder.
for _, difficulty in ipairs({ "heroic", "mythic" }) do
    for _, definition in ipairs(AR:GetDefinitions("explorers", difficulty)) do
        assert(definition.callKey ~= "fish" and not definition.callKey:find("^fish_"))
    end
end
local explorersHeroic = R:GetProfile("explorers", "heroic")
assert(explorersHeroic.callsByKey.fish_gebbo.warning == "FISH NOW → GEBBO")
assert(explorersHeroic.callsByKey.fish_nama.warning == "FISH NOW → NAMA")
assert(explorersHeroic.callsByKey.fish_iku.warning == "FISH NOW → IKU")
assert(table.concat(explorersHeroic.callsByKey.fish_gebbo.sequenceKeys, ",") == "fish_gebbo,fish_nama,fish_iku")
assert(R:GetProfile("explorers", "mythic").callsByKey.fish.warning == "Fish: use the planned Mythic target.")

-- Vashnik Heroic and Mythic do not require fixed player roster fields.
for _, difficulty in ipairs({ "heroic", "mythic" }) do
    assert(#AR:GetDefinitions("vashnik", difficulty) == 0)
end
assert(table.concat(R:GetProfile("vashnik", "heroic").explanation, "\n"):find(
    "PURPLE + ORANGE ONLY", 1, true
))

-- Heroic Twin Fangs requires three fresh non-overlapping Feast groups. In a 20-player raid
-- the 30% floor means 6+ players per team, so exercise a realistic 7/7/6 partition.
local feastTeamA = "G1P1, G1P2, G1P3, G1P4, G1P5, G2P1, G2P2"
local feastTeamB = "G2P3, G2P4, G2P5, G3P1, G3P2, G3P3, G3P4"
local feastTeamC = "G3P5, G4P1, G4P2, G4P3, G4P4, G4P5"
ok = A:ApplyBossDraft("twinfangs", "heroic", {
    feast_heroic_a = feastTeamA,
    feast_heroic_b = feastTeamB,
    feast_heroic_c = feastTeamC,
})
assert(ok)
for index, expected in ipairs({ feastTeamA, feastTeamB, feastTeamC }) do
    local callKey = "feast" .. tostring(index)
    local feast = R:GetProfile("twinfangs", "heroic").callsByKey[callKey]
    local warning, complete = A:BuildCallWarning(feast.warning, "twinfangs", "heroic", callKey)
    assert(complete and warning:find(expected, 1, true), callKey .. " must render its configured fresh team")
end

-- Heroic Altar has real assignment fields; retired Normal has none.
assert(#AR:GetCallDefinitions("altar", "normal", "guillotine") == 0)
local altarHeroic = AR:GetCallDefinitions("altar", "heroic", "guillotine")
assert(#altarHeroic == 2)
for _, definition in ipairs(altarHeroic) do
    assert(definition.minPlayers == 3)
end

-- Mythic Ula'tek renders valid 40%+ Coils rotation, side carriers, three Bite sectors and Incubation.
ok = A:ApplyBossDraft("ulatek", "mythic", {
    coil_a = "Groups 1+2",
    coil_b = "Groups 3+4",
    egg_left = "G3P1",
    egg_right = "G3P2",
    bite_melee = "G3P3",
    bite_ranged = "G3P4",
    bite_healer = "G3P5",
    incubation_team = "Group 4",
})
assert(ok)
local coils = R:GetProfile("ulatek", "mythic").callsByKey.coils
local coilsWarning = A:BuildCallWarning(coils.warning, "ulatek", "mythic", "coils")
assert(coilsWarning == "Coils: Groups 1+2 soak the active Coil.")
A:AdvanceCall("ulatek", "mythic", "coils")
coilsWarning = A:BuildCallWarning(coils.warning, "ulatek", "mythic", "coils")
assert(coilsWarning == "Coils: Groups 3+4 soak the active Coil.")

local eggs = R:GetProfile("ulatek", "mythic").callsByKey.eggs
local eggAction, eggReady = A:BuildCallAction(eggs.action, "ulatek", "mythic", "eggs")
assert(eggReady and eggAction == "Triangle G3P1; Cross G3P2")

local bite = R:GetProfile("ulatek", "mythic").callsByKey.bite
local biteWarning, biteReady = A:BuildCallWarning(bite.warning, "ulatek", "mythic", "bite")
assert(biteReady and biteWarning == "Bite: G3P3; G3P4; G3P5 soak. Purge waves out.")

print("ok - Heroic/Mythic assignments are roster-aware, Normal is retired, and calls render only real assignments")
