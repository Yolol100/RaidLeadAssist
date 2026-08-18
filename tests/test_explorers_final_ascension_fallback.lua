local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local now = 100
local seedCount = 0

_G.GetTime = function() return now end
_G.issecretvalue = function() return false end
_G.table.wipe = _G.table.wipe or function(tbl) for key in pairs(tbl) do tbl[key] = nil end end
_G.C_AddOns = nil

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
ns:RegisterModule("Core.EventBus", { Emit = function() end })
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/VenomousAbyss/Explorers.lua", ns)

local Registry = ns:GetModule("Encounters.Registry")
assert(Registry:SetActiveDifficulty("heroic"))

local bigwigs = {}
local dbm = {}
local blizzard = {}
function blizzard:SeedExistingEvents()
    seedCount = seedCount + 1
    self.sink:ProviderTimerStarted("Blizzard", "final-ascension-native", {
        key = 1292779,
        name = "Final Ascension",
        duration = 60,
        nativeEventID = 501,
        precision = "native",
    })
    self.sink:ProviderTimerStarted("Blizzard", "fling-fish-native", {
        key = 1295817,
        name = "Fling Fish",
        duration = 28,
        nativeEventID = 502,
        precision = "native",
    })
end

ns:RegisterModule("Services.Providers.BigWigs", bigwigs)
ns:RegisterModule("Services.Providers.DBM", dbm)
ns:RegisterModule("Services.Providers.Blizzard", blizzard)

T.Load("Services/TimelineService.lua", ns)
local Timeline = ns:GetModule("Services.TimelineService")
Timeline.activeProviders.BigWigs = bigwigs
Timeline.activeProviders.DBM = dbm
Timeline.activeProviders.Blizzard = blizzard
blizzard.sink = Timeline

assert(Timeline:SetBlizzardSuppressedByProvider("DBM", true))
Timeline:SetEncounter("explorers")
assert(seedCount == 1,
    "encounter selection must reseed native events even while DBM globally suppresses Blizzard")

local native = Timeline.timers["Blizzard|final-ascension-native"]
assert(native and native.call and native.call.key == "fish",
    "DBM suppression must not hide the native Final Ascension timer when DBM has no direct representation")
assert(Timeline.timers["Blizzard|fling-fish-native"] == nil,
    "Fling Fish is a separate mechanic and must never alias the Final Ascension raidleader call")

Timeline:ProviderTimerStarted("BigWigs", "final-ascension-direct", {
    key = 1292779,
    name = "Final Ascension",
    duration = 60,
    nativeEventID = 501,
    precision = "exact",
})
local selected = Timeline:GetTimerForCall("fish")
assert(selected and selected.providerName == "BigWigs",
    "an exact direct BigWigs Final Ascension timer must outrank the retained native fallback")
assert(selected.occurrenceID == native.occurrenceID,
    "direct and native Final Ascension representations must deduplicate to one occurrence")

print("ok - Lost Explorers Final Ascension reseeds under DBM authority without aliasing Fling Fish")
