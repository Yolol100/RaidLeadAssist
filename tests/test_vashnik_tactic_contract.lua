local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
_G.issecretvalue = function() return false end
T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/VenomousAbyss/Vashnik.lua", ns)
local Registry = ns:GetModule("Encounters.Registry")
local function plan(d) return table.concat(Registry:GetProfile("vashnik", d).explanation, "\n") end
local function has(text, needle) return text:find(needle,1,true) ~= nil end

for _, d in ipairs({"normal","heroic","mythic"}) do
    assert(Registry:GetProfile("vashnik",d).callsByKey.imbibe.warning == "Fountain adds: kill them before center.")
end
local normal = plan("normal")
assert(has(normal, "Fountain adds spawn"))
assert(has(normal, "Fire debuff on you"))
assert(has(normal, "Blood debuff on you"))
assert(has(normal, "Shadow debuff on you"))
assert(has(normal, "Froth circle on you"))
assert(not has(normal, "Flame > Shadow"), "fountain route belongs in raidleader prep")

assert(Registry:GetProfile("vashnik","normal").callsByKey.catalyst == nil)
local heroic = plan("heroic")
assert(has(heroic, "Skull, wait, then kill Cross"))
assert(has(heroic, "Green circles appear"))
assert(not has(heroic, "Fountain adds spawn"), "Heroic should contain only changes from Normal")
for _, d in ipairs({"heroic","mythic"}) do
    local catalyst = Registry:GetProfile("vashnik",d).callsByKey.catalyst
    assert(catalyst.warning == "Green circles: soak every one.")
end

local mythic = plan("mythic")
assert(has(mythic, "aim one wave through the Tumor"))
assert(has(mythic, "switch and kill it immediately"))
assert(not has(mythic, "Skull"), "Mythic should contain only changes from Heroic")
assert(Registry:GetProfile("vashnik","mythic").callsByKey.froth.warning == "Froth: aim one wave through a Tumor.")

print("ok - Vashnik uses cue/action Normal plan plus concise Heroic/Mythic callouts")
