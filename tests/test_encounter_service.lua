local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local emitted = {}

T.Load("Core/Constants.lua", ns)
ns:RegisterModule("Core.EventBus", {
    Emit = function(_, name, ...)
        emitted[#emitted + 1] = { name = name, args = { ... } }
    end,
})
ns:RegisterModule("Encounters.Registry", {
    FindByEncounterID = function(_, encounterID)
        if encounterID == 101 then return { key = "known" } end
    end,
    FindByEncounterName = function(_, encounterName)
        if encounterName == "Known Boss" then return { key = "known" } end
    end,
})

T.Load("Services/EncounterService.lua", ns)
local Encounter = ns:GetModule("Services.EncounterService")

Encounter:OnEvent("ENCOUNTER_START", 999, "Unknown Boss", 15)
assert(Encounter.currentEncounter == nil)
assert(Encounter.currentDifficultyID == 15)
assert(#emitted == 1 and emitted[1].name == "ENCOUNTER_STARTED",
    "unknown encounters must still notify the app so automatic timing can fail closed")
assert(emitted[1].args[1] == 999 and emitted[1].args[2] == 15)

emitted = {}
Encounter:OnEvent("ENCOUNTER_START", 101, "Known Boss", 16)
assert(Encounter.currentEncounter and Encounter.currentEncounter.key == "known")
assert(#emitted == 2)
assert(emitted[1].name == "ENCOUNTER_SELECTED" and emitted[1].args[1] == "known")
assert(emitted[2].name == "ENCOUNTER_STARTED" and emitted[2].args[2] == 16)

emitted = {}
Encounter:OnEvent("ENCOUNTER_END")
assert(Encounter.currentEncounter == nil and Encounter.currentDifficultyID == nil)
assert(#emitted == 1 and emitted[1].name == "ENCOUNTER_ENDED")

print("ok - encounter start fail-closed notification")
