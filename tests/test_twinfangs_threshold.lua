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
assert(string.find(text, "HEROIC: ETERNAL VENOM KILLS YOU AT 8 STACKS.", 1, true))

print("ok - Twin Fangs Heroic venom threshold")
