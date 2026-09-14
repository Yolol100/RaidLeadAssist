local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
_G.issecretvalue = function() return false end
T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/VenomousAbyss/Vashnik.lua", ns)
local Registry = ns:GetModule("Encounters.Registry")

assert(Registry:GetProfile("vashnik", "normal") == nil)
local heroic = Registry:GetProfile("vashnik", "heroic")
assert(table.concat(heroic.explanation, "\n") == "PURPLE + ORANGE ONLY — BL ON PULL")
assert(#heroic.calls == 4)
assert(heroic.calls[1].warning == "KILL ADDS")
assert(heroic.calls[2].warning == "STAGGER DISPELS")
assert(heroic.calls[3].warning == "DODGE CROSS")
assert(heroic.calls[4].warning == "SOAK BILE")
assert(heroic.callsByKey.siphon == nil and heroic.callsByKey.fire_stagger == nil,
    "old Heroic Blood/Red route must not remain active")
assert(heroic.callsByKey.imbibe.spellIDs[1] == 1283164)
assert(heroic.callsByKey.froth.spellIDs[1] == 1281907)
assert(Registry:GetProfile("vashnik", "mythic").callsByKey.siphon,
    "Mythic remains separate and may retain Mythic-specific Blood execution")

print("ok - Vashnik Heroic is Purple+Orange only with four selected calls")
