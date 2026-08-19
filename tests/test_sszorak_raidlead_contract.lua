local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
_G.issecretvalue = function() return false end
T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/VenomousAbyss/Sszorak.lua", ns)
local Registry = ns:GetModule("Encounters.Registry")
local function plan(d) return table.concat(Registry:GetProfile("sszorak",d).explanation,"\n") end
local function has(text, needle) return text:find(needle,1,true) ~= nil end

for _, d in ipairs({"normal","heroic","mythic"}) do
    local p = Registry:GetProfile("sszorak",d)
    assert(p.callsByKey.maelstrom.warning == "Maelstrom: Poppers 1-2-3 trigger Cysts on each wind.")
    assert(p.callsByKey.apex.warning == "Mutilate: called team soak green frontal.")
end
local normal = plan("normal")
assert(has(normal, "assigned outer marker"))
assert(has(normal, "opposite direction"))
assert(has(normal, "only assigned Cyst Poppers"))
assert(has(normal, "assigned soak team"))
assert(has(normal, "major damage cooldowns"))
local heroic = plan("heroic")
assert(has(heroic, "poison pools at the arena edge"))
assert(has(heroic, "other Mutilate soak team"))
assert(not has(heroic, "opposite direction"), "Heroic should contain only changes from Normal")
local mythic = plan("mythic")
assert(has(mythic, "14+ players stack"))
assert(has(mythic, "Virulence players spread"))
assert(not has(mythic, "poison pools at the arena edge"), "Mythic should contain only changes from Heroic")
assert(Registry:GetProfile("sszorak","mythic").callsByKey.serpent.warning == "Serpent's Fury: 14+ stack on marked player.")
print("ok - Sszorak player plan keeps combat cues while concise popper/team calls stay raidleader-owned")
