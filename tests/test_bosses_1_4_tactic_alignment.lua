local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss12AssignmentOverride.lua", ns)
T.Load("Encounters/Boss34AssignmentOverride.lua", ns)
T.Load("Encounters/VenomousAbyss/Nekzali.lua", ns)
T.Load("Encounters/VenomousAbyss/Sentinels.lua", ns)
T.Load("Encounters/VenomousAbyss/Explorers.lua", ns)
T.Load("Encounters/VenomousAbyss/Vashnik.lua", ns)
T.Load("Services/AssignmentService.lua", ns)

local Encounters = ns:GetModule("Encounters.Registry")
local AssignmentRegistry = ns:GetModule("Encounters.AssignmentRegistry")
local Assignments = ns:GetModule("Services.AssignmentService")
Assignments:Initialize({ assignments = {} })

local heroicNek = Encounters:GetProfile("nekzali", "heroic")
assert(heroicNek.callsByKey.pyre.warning == "Pyre: assigned group soak; everyone else out.")
assert(heroicNek.callsByKey.phase2.warning == "Phase 2: Bloodlust; burn before full energy.")
assert(#AssignmentRegistry:GetDefinitions("nekzali", "heroic") == 1)
assert(#AssignmentRegistry:GetDefinitions("nekzali", "mythic") == 3)

local ok = Assignments:ApplyBossDraft("sentinels", "heroic", { team_a = "Group 1", team_b = "Group 2" })
assert(ok)
local sentinelsCall = Encounters:GetProfile("sentinels", "heroic").callsByKey.side_swap
assert(Assignments:BuildCallWarning(sentinelsCall.warning, "sentinels", "heroic", "side_swap") ==
    "After Stasis: Group 1 green; Group 2 red; tanks swap bosses.")

local explorers = Encounters:GetProfile("explorers", "normal")
assert(explorers.callsByKey.crates.warning == "Crates: break until fish appears.")
assert(explorers.callsByKey.fish.warning == "Fish: feed Nama, then Iku, then Gebbo.")
assert(#AssignmentRegistry:GetDefinitions("explorers", "normal") == 0)
assert(#AssignmentRegistry:GetDefinitions("explorers", "heroic") == 0)
assert(#AssignmentRegistry:GetDefinitions("explorers", "mythic") == 3)

for _, difficulty in ipairs({ "normal", "heroic", "mythic" }) do
    local profile = Encounters:GetProfile("vashnik", difficulty)
    assert(profile.callsByKey.siphon.warning == "Blood circle: several teammates stack for healing.")
    assert(#AssignmentRegistry:GetDefinitions("vashnik", difficulty) == 0)
end

print("ok - bosses 1-4 raid warnings and assignment ownership match the tactic alignment pass")
