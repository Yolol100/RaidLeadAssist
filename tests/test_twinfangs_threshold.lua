local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/VenomousAbyss/TwinFangs.lua", ns)

local Registry = ns:GetModule("Encounters.Registry")
local normal = Registry:GetProfile("twinfangs", "normal")
local heroic = Registry:GetProfile("twinfangs", "heroic")
assert(normal and heroic)

local normalText = table.concat(normal.explanation, "\n")
local heroicText = table.concat(heroic.explanation, "\n")
assert(string.find(normalText, "similar health", 1, true), "Normal base plan must keep both bosses balanced")
assert(string.find(normalText, "kill them together", 1, true), "Normal base plan must coordinate the joint finish")
assert(string.find(normalText, "at least 3 fresh players", 1, true), "Normal Feast must state fresh 3+ soakers per hit")
assert(string.find(heroicText, "Team A, B or C", 1, true), "Heroic delta must tell players to follow the assigned Feast team")
assert(heroic.callsByKey.balance == nil, "Boss-health coordination must stay in the plan, not a duplicate button")
assert(heroic.callsByKey.stone == nil, "Stone Breaker tank execution must stay bossmod/role-owned")
assert(not string.find(normalText .. heroicText, "KILLS YOU AT", 1, true), "volatile Eternal Venom death thresholds must not be hard-coded")

print("ok - Twin Fangs keeps stable fresh-Feast and joint-finish guidance without volatile thresholds")
