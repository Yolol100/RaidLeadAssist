local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/VenomousAbyss/TwinFangs.lua", ns)

local Registry = ns:GetModule("Encounters.Registry")
local heroic = Registry:GetProfile("twinfangs", "heroic")
assert(heroic)

local text = table.concat(heroic.explanation, "\n")
assert(string.find(text, "KEEP ETERNAL VENOM LOW", 1, true), "Heroic strategy must retain actionable Eternal Venom guidance")
assert(string.find(text, "EACH HIT NEEDS 3+ PLAYERS", 1, true), "Heroic strategy must state the stable Ravenous Feast minimum")
assert(string.find(text, "UNCOILED WRATH", 1, true), "Heroic strategy must explain the survivor-ramp finish condition")
assert(string.find(text, "FINISH TOGETHER", 1, true), "Heroic strategy must coordinate the joint finish")
assert(heroic.callsByKey.balance == nil, "Boss-health coordination must stay in the raidplan, not a duplicate button")
assert(heroic.callsByKey.stone == nil, "Stone Breaker must stay DBM-owned")
assert(not string.find(text, "KILLS YOU AT", 1, true), "volatile Eternal Venom death thresholds must not be hard-coded")

print("ok - Twin Fangs uses stable venom, Feast, DBM tank ownership and joint-finish invariants")
