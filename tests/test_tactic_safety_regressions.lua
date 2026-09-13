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
    assert(R:GetProfile("twinfangs",d).callsByKey.feast.warning == "Feast: assigned groups soak in order.")
end

-- Coiled Altar follows Blizzard's live Normal/Heroic 3-player Guillotine minimum,
-- while Mythic keeps the separate permanent-debuff fresh 5+ execution.
assert(text("altar","normal"):find("Green poison orbs spawn",1,true))
assert(text("altar","normal"):find("only collectors touch them",1,true))
assert(text("altar","normal"):find("at least 3 players soak",1,true))
assert(text("altar","heroic"):find("needs only 3 players",1,true))
assert(text("altar","heroic"):find("repeat-hit debuff",1,true))
assert(text("altar","mythic"):find("fresh 5+ players",1,true))
assert(R:GetProfile("altar","normal").callsByKey.guillotine.warning == "Guillotine: at least 3 soak; raid move 40+ yards.")
assert(R:GetProfile("altar","heroic").callsByKey.guillotine.action == "Assigned 3+ group soak; raid move")
assert(R:GetProfile("altar","mythic").callsByKey.guillotine.action == "Fresh 5+ group soak; raid move")
assert(R:GetProfile("altar","normal").callsByKey.intermission.warning:find("Bloodlust",1,true))
assert(not R:GetProfile("altar","normal").callsByKey.final.warning:find("Bloodlust",1,true))

for _,d in ipairs({"normal","heroic","mythic"}) do
    assert(R:GetProfile("sentinels",d).callsByKey.side_swap.warning == "After Stasis: hold assigned sides.")
    assert(R:GetProfile("sszorak",d).callsByKey.maelstrom.warning == "Maelstrom: assigned Poppers trigger Cysts.")
    assert(R:GetProfile("sszorak",d).callsByKey.dig_in.warning == "Dig In: use damage cooldowns.")
end
for _,d in ipairs({"heroic","mythic"}) do
    assert(R:GetProfile("vashnik",d).callsByKey.catalyst.warning == "Catalyst: soak every circle.")
end

-- Ula'tek enables only the reviewed exact-ID set; strategy/transition milestones remain manual.
for _,d in ipairs({"normal","heroic","mythic"}) do
    local p = R:GetProfile("ulatek",d)
    for _,key in ipairs({"waves","coils","heart","serpents","bite","circling"}) do
        assert(p.callsByKey[key] and p.callsByKey[key].timing ~= false)
    end
    for _,key in ipairs({"warden","eggs","phase3"}) do
        assert(p.callsByKey[key] and p.callsByKey[key].timing == false)
    end
end
assert(R:GetProfile("ulatek","normal").callsByKey.coils.warning == "Coils: stack 40%+ raid in the active soak.")
assert(R:GetProfile("ulatek","heroic").callsByKey.coils.warning == "Coils: stack 40%+ raid in the active soak.")
assert(R:GetProfile("ulatek","mythic").callsByKey.coils.warning == "Coils: assigned team soak the active Coil.")
assert(R:GetProfile("ulatek","mythic").callsByKey.incubation.timing ~= false)
assert(text("ulatek","normal"):find("swimming underneath no longer works",1,true))
assert(text("ulatek","heroic"):find("three players per side",1,true))
assert(text("ulatek","heroic"):find("Purge helpers move 7+ yards out",1,true))
assert(text("ulatek","mythic"):find("Soul Constrictor",1,true))
assert(R:GetProfile("ulatek","normal").callsByKey.circling.spellIDs[1] == 1301510)
assert(R:GetProfile("ulatek","normal").callsByKey.demolish == nil)

print("ok - strategy regressions cover current live hotfixes, difficulty assignments and bounded Ula'tek timing")
