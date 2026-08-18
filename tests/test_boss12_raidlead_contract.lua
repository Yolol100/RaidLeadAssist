local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
_G.issecretvalue = function() return false end
T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/VenomousAbyss/Nekzali.lua", ns)
T.Load("Encounters/VenomousAbyss/Sentinels.lua", ns)
local Registry = ns:GetModule("Encounters.Registry")
local function text(key, difficulty) return table.concat(Registry:GetProfile(key, difficulty).explanation, "\n") end
local function has(value, needle) return value:find(needle, 1, true) ~= nil end

for _, difficulty in ipairs({"normal","heroic","mythic"}) do
    local sent = Registry:GetProfile("sentinels", difficulty)
    assert(sent.callsByKey.coagulation.warning == "Green side: kill the slime.")
    assert(sent.callsByKey.miasma.warning == "Red side: stack on the target.")
    assert(sent.callsByKey.stasis.warning == "Stasis: pair toxin numbers to exactly 4 (1+3 or 2+2).")
    assert(sent.callsByKey.side_swap.warning == "After Stasis: hold your side while tanks swap the bosses.")
    assert(sent.callsByKey.side_swap.timing == false)
end

local sentNormal = text("sentinels", "normal")
assert(has(sentNormal, "assigned green or red group"))
assert(has(sentNormal, "40+ yards apart"))
assert(has(sentNormal, "1+3 or 2+2"))
assert(has(sentNormal, "stay put while tanks swap"))
local sentHeroic = text("sentinels", "heroic")
assert(has(sentHeroic, "Returning green poison") and has(sentHeroic, "Blood poison on you"))
assert(not has(sentHeroic, "40+ yards apart"), "Heroic briefing should contain only changes from Normal")
local sentMythic = text("sentinels", "mythic")
assert(has(sentMythic, "Protovenom on you"))
assert(not has(sentMythic, "Returning green poison"), "Mythic briefing should contain only changes from Heroic")
assert(Registry:GetProfile("sentinels","normal").callsByKey.protovenom == nil)
assert(Registry:GetProfile("sentinels","mythic").callsByKey.protovenom.warning == "Protovenom: marked players pair together.")

for _, difficulty in ipairs({"normal","heroic","mythic"}) do
    local nek = Registry:GetProfile("nekzali", difficulty)
    assert(nek.callsByKey.adds.warning == "Amani adds: kill them before they reach the Well.")
    assert(nek.callsByKey.phase2.warning == "Phase 2: Bloodlust and burn the boss.")
end
assert(Registry:GetProfile("nekzali", "heroic").callsByKey.flame == nil)
assert(Registry:GetProfile("nekzali", "mythic").callsByKey.flame == nil)
local nekNormal = text("nekzali", "normal")
assert(has(nekNormal, "melee stay in and soak together"))
assert(has(nekNormal, "Ranged stay outside and spread"))
local nekHeroic = text("nekzali", "heroic")
assert(has(nekHeroic, "assigned group instead of melee-only"))
assert(has(nekHeroic, "dead Amani corpse"))
assert(not has(nekHeroic, "Phase 2"), "Heroic briefing should not repeat the Normal plan")
local nekMythic = text("nekzali", "mythic")
assert(has(nekMythic, "well group is called"))
assert(has(nekMythic, "Soul Exhaustion"))
assert(not has(nekMythic, "dead Amani corpse"), "Mythic briefing should not repeat Heroic changes")

print("ok - boss 1/2 briefings and shared callouts use Normal base plus Heroic/Mythic deltas")
