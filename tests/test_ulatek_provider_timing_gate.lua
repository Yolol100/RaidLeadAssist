local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local now = 100

_G.GetTime = function() return now end
_G.issecretvalue = function() return false end
table.wipe = table.wipe or function(value)
    for key in pairs(value) do value[key] = nil end
    return value
end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/VenomousAbyss/Ulatek.lua", ns)

ns:RegisterModule("Core.EventBus", { Emit = function() end })
ns:RegisterModule("Services.Providers.BigWigs", {})
ns:RegisterModule("Services.Providers.DBM", {})
ns:RegisterModule("Services.Providers.Blizzard", {})
T.Load("Services/TimelineService.lua", ns)

local Constants = ns:GetModule("Core.Constants")
local Registry = ns:GetModule("Encounters.Registry")
local Timeline = ns:GetModule("Services.TimelineService")

Timeline.activeProviders.BigWigs = {}
assert(Registry:SetActiveDifficulty("heroic") == true)
Timeline:SetEncounter("ulatek")

Timeline:ProviderTimerStarted("BigWigs", "bite-live", {
    key = 1295905,
    name = "Serpent's Bite",
    duration = 20,
    encounterID = 3492,
    precision = Constants.TimerPrecision.EXACT,
})
local bite, biteRemaining = Timeline:GetActionableTimerForCall("bite")
assert(bite and bite.call and bite.call.key == "bite")
assert(biteRemaining == 20)
assert(bite.precision == Constants.TimerPrecision.EXACT)

Timeline:ProviderTimerStarted("BigWigs", "coil-preview", {
    key = 1300530,
    name = "Spectral Coils",
    duration = 15,
    encounterID = 3492,
    precision = Constants.TimerPrecision.APPROXIMATE,
})
assert(Timeline:GetTimerForCall("coils"), "approximate Ula'tek Coils may remain visible as preview")
assert(Timeline:GetActionableTimerForCall("coils") == nil,
    "approximate Ula'tek Coils must never drive PREPARE/PRESS")

Timeline:ProviderTimerStarted("BigWigs", "wrong-encounter", {
    key = 1301510,
    name = "Circling Prey",
    duration = 12,
    encounterID = 3429,
    precision = Constants.TimerPrecision.EXACT,
})
assert(Timeline:GetTimerForCall("circling") == nil,
    "cross-encounter provider traffic must still fail closed")

local heroic = Registry:GetProfile("ulatek", "heroic")
assert(heroic.callsByKey.warden.timing == false)
assert(heroic.callsByKey.eggs.timing == false)
assert(heroic.callsByKey.fangs.timing == false)
assert(heroic.callsByKey.phase3.timing == false)

assert(Registry:SetActiveDifficulty("mythic") == true)
Timeline:SetEncounter("ulatek")
Timeline:ProviderTimerStarted("BigWigs", "incubation-live", {
    key = 1299757,
    name = "Toxic Incubation",
    duration = 18,
    encounterID = 3492,
    precision = Constants.TimerPrecision.EXACT,
})
local incubation = Timeline:GetActionableTimerForCall("incubation")
assert(incubation and incubation.call and incubation.call.key == "incubation",
    "reviewed Mythic Incubation provider identity must resolve to the RLA call")
assert(incubation.call.iconSpellID == 1299759,
    "provider identity must stay separate from the display spell identity")

print("ok - Ula'tek selected exact provider timers are actionable while approximation, cross-encounter traffic and manual milestones fail closed")
