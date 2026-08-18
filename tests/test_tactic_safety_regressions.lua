local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
_G.issecretvalue = function() return false end
T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
for _, file in ipairs({"Explorers.lua","Sszorak.lua","TwinFangs.lua","CoiledAltar.lua","Ulatek.lua","Sentinels.lua","Vashnik.lua"}) do T.Load("Encounters/VenomousAbyss/"..file,ns) end
local R=ns:GetModule("Encounters.Registry")
local function text(k,d) return table.concat(R:GetProfile(k,d).explanation,"\n") end

assert(R:GetProfile("twinfangs","normal").callsByKey.feast.warning == "Feast: fresh 3+ players soak each hit.")
assert(text("twinfangs","normal"):find("at least 3 fresh players",1,true))
for _,d in ipairs({"heroic","mythic"}) do
    assert(R:GetProfile("twinfangs",d).callsByKey.feast.warning == "Feast: Team A, then Team B, then Team C.")
end

assert(text("altar","normal"):find("Green poison orb on you",1,true))
assert(text("altar","heroic"):find("Guillotine gives a repeat-hit debuff",1,true))
assert(R:GetProfile("altar","normal").callsByKey.intermission.warning:find("Bloodlust",1,true))
assert(not R:GetProfile("altar","normal").callsByKey.final.warning:find("Bloodlust",1,true))

for _,d in ipairs({"normal","heroic","mythic"}) do
    assert(R:GetProfile("sentinels",d).callsByKey.side_swap.warning == "After Stasis: hold your side while tanks swap the bosses.")
    assert(R:GetProfile("sszorak",d).callsByKey.maelstrom.warning:find("Popper 1",1,true))
end
for _,d in ipairs({"heroic","mythic"}) do
    assert(R:GetProfile("vashnik",d).callsByKey.catalyst.warning == "Green circles: soak every one.")
end
for _,d in ipairs({"normal","heroic","mythic"}) do
    for _,call in ipairs(R:GetProfile("ulatek",d).calls) do assert(call.timing==false) end
end
assert(R:GetProfile("ulatek","heroic").callsByKey.coils.warning == "Spectral Coils: stack at Square.")
assert(R:GetProfile("ulatek","mythic").callsByKey.coils.warning == "Spectral Coils: called group stack at Square.")

print("ok - strategy regressions cover concise player-facing raid calls and conservative Ula'tek difficulty split")
