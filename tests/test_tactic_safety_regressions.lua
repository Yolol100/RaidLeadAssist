local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
_G.issecretvalue = function() return false end
T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
for _, file in ipairs({"Explorers.lua","Sszorak.lua","TwinFangs.lua","CoiledAltar.lua","Ulatek.lua","Sentinels.lua","Vashnik.lua"}) do T.Load("Encounters/VenomousAbyss/"..file,ns) end
local R=ns:GetModule("Encounters.Registry")

for _, bossKey in ipairs({"explorers","sszorak","twinfangs","altar","ulatek","sentinels","vashnik"}) do
    assert(R:GetProfile(bossKey,"normal") == nil,
        "Normal strategy must remain retired: " .. bossKey)
    assert(R:GetProfile(bossKey,"heroic"), "Heroic strategy missing: " .. bossKey)
    assert(R:GetProfile(bossKey,"mythic"), "Mythic strategy missing: " .. bossKey)
end

local explorers = R:GetProfile("explorers","heroic")
assert(table.concat(explorers.explanation,"\n") == "GEBBO → NAMA → IKU")
assert(explorers.callsByKey.fish_gebbo and explorers.callsByKey.fish_nama and explorers.callsByKey.fish_iku)
assert(explorers.callsByKey.fish_gebbo.sequenceKey == "fish")

local heroicFangs = R:GetProfile("twinfangs","heroic")
assert(heroicFangs.callsByKey.feast1 and heroicFangs.callsByKey.feast2 and heroicFangs.callsByKey.feast3,
    "Heroic Twin Fangs must keep three distinct fresh Feast hits")
assert(heroicFangs.callsByKey.feast1.sequenceKey == "feast")
assert(heroicFangs.callsByKey.feast2.timing == false and heroicFangs.callsByKey.feast3.timing == false,
    "later Heroic Feast sequence steps must remain manual sequence continuations")
assert(R:GetProfile("twinfangs","mythic").callsByKey.feast,
    "Mythic Twin Fangs retains its separate combined Feast assignment call")

local altarHeroic = R:GetProfile("altar","heroic")
local altarMythic = R:GetProfile("altar","mythic")
assert(altarHeroic.callsByKey.guillotine and altarMythic.callsByKey.guillotine)
assert(altarHeroic.callsByKey.intermission.warning:find("Bloodlust",1,true))
assert(altarHeroic.callsByKey.final.warning == "Final phase: keep health even; kill together.")

local sentHeroic = R:GetProfile("sentinels","heroic")
assert(table.concat(sentHeroic.explanation,"\n"):find("AFTER STASIS — RAID HOLDS SIDES; TANKS SWAP BOSSES",1,true),
    "Heroic Sentinels must retain post-Stasis side/tank execution in the dynamic briefing")
assert(sentHeroic.callsByKey.side_swap == nil,
    "Heroic Sentinels must not duplicate the dynamic side plan with an extra side-swap button")
assert(R:GetProfile("sentinels","mythic").callsByKey.side_swap,
    "Mythic Sentinels keeps the explicit assigned-side swap call")

local sszHeroic = R:GetProfile("sszorak","heroic")
assert(sszHeroic.callsByKey.venom and sszHeroic.callsByKey.crosswinds and sszHeroic.callsByKey.maelstrom)
assert(sszHeroic.callsByKey.apex == nil and sszHeroic.callsByKey.dig_in == nil,
    "Heroic Sszorak must not reintroduce low-value tank/cooldown raid calls")
local sszMythic = R:GetProfile("sszorak","mythic")
assert(sszMythic.callsByKey.apex and sszMythic.callsByKey.serpent,
    "Mythic Sszorak remains a separate execution profile")

local vashHeroic = R:GetProfile("vashnik","heroic")
assert(vashHeroic.callsByKey.catalyst)
assert(vashHeroic.callsByKey.siphon == nil and vashHeroic.callsByKey.fire_stagger == nil,
    "Heroic Vashnik must remain on the simple Purple+Orange strategy without Blood calls")
assert(R:GetProfile("vashnik","mythic").callsByKey.siphon,
    "Mythic Vashnik may retain its Mythic-specific Blood execution")

-- Ula'tek enables only the reviewed exact-ID set; strategy/transition milestones remain manual.
for _,d in ipairs({"heroic","mythic"}) do
    local p = R:GetProfile("ulatek",d)
    for _,key in ipairs({"waves","coils","heart","serpents","bite","circling"}) do
        assert(p.callsByKey[key] and p.callsByKey[key].timing ~= false,
            d .. " Ula'tek timing call missing: " .. key)
    end
    for _,key in ipairs({"warden","eggs","phase3"}) do
        assert(p.callsByKey[key] and p.callsByKey[key].timing == false,
            d .. " Ula'tek manual milestone changed: " .. key)
    end
    assert(p.callsByKey.fangs and p.callsByKey.fangs.timing == false)
end
local uh = R:GetProfile("ulatek","heroic")
local um = R:GetProfile("ulatek","mythic")
assert(uh.callsByKey.coils.warningTemplate:find("{{rotation:coils}}",1,true),
    "Heroic Coil call must render the alternating assigned team")
assert(um.callsByKey.coils.warningTemplate:find("{{rotation:coils}}",1,true),
    "Mythic Coil call must render the alternating assigned team")
assert(um.callsByKey.incubation.timing ~= false)
assert(uh.callsByKey.circling.spellIDs[1] == 1301510)
assert(uh.callsByKey.demolish == nil,
    "stale Ula'tek Demolish timer identity must not return")

print("ok - strategy regressions lock current Heroic/Mythic safety decisions and keep Normal retired")
