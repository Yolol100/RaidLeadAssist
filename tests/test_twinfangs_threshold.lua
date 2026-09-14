local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/VenomousAbyss/TwinFangs.lua", ns)

local Registry = ns:GetModule("Encounters.Registry")
assert(Registry:GetProfile("twinfangs", "normal") == nil,
    "Normal Twin Fangs profile must remain retired")
local heroic = assert(Registry:GetProfile("twinfangs", "heroic"))
local mythic = assert(Registry:GetProfile("twinfangs", "mythic"))

local heroicText = table.concat(heroic.explanation, "\n")
local mythicText = table.concat(mythic.explanation, "\n")
assert(string.find(heroicText, "3 FRESH GROUPS", 1, true),
    "Heroic Feast must explicitly use three fresh groups")
assert(string.find(heroicText, "NO ONE SOAKS TWO FEAST HITS", 1, true),
    "Heroic Feast must forbid repeat soaking while Feasted is active")
assert(heroic.callsByKey.feast1 and heroic.callsByKey.feast2 and heroic.callsByKey.feast3,
    "Heroic Feast must remain a three-step sequence")
assert(heroic.callsByKey.balance == nil, "Boss-health coordination must stay in the plan/bossmod layer, not a duplicate button")
assert(heroic.callsByKey.stone == nil, "Stone Breaker tank execution must stay bossmod/role-owned")
assert(not string.find(heroicText .. mythicText, "KILLS YOU AT", 1, true),
    "volatile Eternal Venom death thresholds must not be hard-coded")
assert(mythic.callsByKey.feast and mythic.callsByKey.feast1 == nil,
    "Mythic must retain its separate Feast execution instead of inheriting the Heroic sequence blindly")

print("ok - Twin Fangs keeps three fresh Heroic Feast groups without volatile hard-coded venom thresholds")
