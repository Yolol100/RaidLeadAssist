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
assert(string.find(text, "KEEP STACKS LOW", 1, true), "Heroic strategy must retain actionable Eternal Venom guidance")
assert(string.find(text, "3+ PLAYERS PER HIT", 1, true), "Heroic strategy must state the stable Ravenous Feast minimum")
assert(not string.find(text, "KILLS YOU AT 8 STACKS", 1, true), "volatile PTR death thresholds must not be hard-coded")

print("ok - Twin Fangs uses stable venom and Feast invariants")
