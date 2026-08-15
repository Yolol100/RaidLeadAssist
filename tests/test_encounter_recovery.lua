local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local emitted = {}
local active = false
local difficultyID = 15
local instanceID = 3004

_G.C_InstanceEncounter = {
    IsEncounterInProgress = function() return active end,
}
_G.GetInstanceInfo = function()
    return "The Venomous Abyss", "raid", difficultyID, nil, nil, nil, nil, instanceID
end

T.Load("Core/Constants.lua", ns)
ns:RegisterModule("Core.EventBus", {
    On = function() end,
    Emit = function(_, name, ...)
        emitted[#emitted + 1] = { name = name, args = { ... } }
    end,
})
ns:RegisterModule("Encounters.Registry", {
    FindByEncounterID = function(_, encounterID)
        if encounterID == 3421 then return { key = "twinfangs" } end
    end,
    FindByEncounterName = function() end,
})

T.Load("Services/EncounterService.lua", ns)
local Encounter = ns:GetModule("Services.EncounterService")

assert(Encounter:TryRecoverFromProvider("DBM", 3421) == false,
    "bossmod hints outside a native encounter must not select a boss")

active = true
instanceID = 9999
assert(Encounter:TryRecoverFromProvider("DBM", 3421) == false,
    "bossmod hints in another instance must be ignored")

instanceID = 3004
assert(Encounter:TryRecoverFromProvider("DBM", 9999) == false,
    "unknown encounter IDs must stay fail closed")

difficultyID = 17
assert(Encounter:TryRecoverFromProvider("DBM", 3421) == false,
    "unsupported active difficulties must not recover an N/H/M profile")

difficultyID = 15
emitted = {}
assert(Encounter:TryRecoverFromProvider("BigWigs", 3421) == true)
assert(Encounter.currentEncounter and Encounter.currentEncounter.key == "twinfangs")
assert(Encounter.currentDifficultyID == 15)
assert(#emitted == 2)
assert(emitted[1].name == "ENCOUNTER_SELECTED" and emitted[1].args[1] == "twinfangs")
assert(emitted[2].name == "ENCOUNTER_RECOVERED")
assert(emitted[2].args[1] == 3421 and emitted[2].args[2] == 15 and emitted[2].args[3] == "BigWigs")

assert(Encounter:TryRecoverFromProvider("DBM", 3421) == false,
    "a second provider hint must not replace an already verified encounter")

print("ok - mid-pull bossmod recovery requires independent WoW encounter verification")
