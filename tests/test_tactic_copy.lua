local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
_G.issecretvalue = function() return false end
T.Load("Core/Constants.lua",ns)
T.Load("Core/Util.lua",ns)
T.Load("Encounters/Registry.lua",ns)
for _,file in ipairs({"CoiledAltar.lua","Explorers.lua","Nekzali.lua","Sentinels.lua","Sszorak.lua","TwinFangs.lua","Ulatek.lua","Vashnik.lua"}) do T.Load("Encounters/VenomousAbyss/"..file,ns) end
local R=ns:GetModule("Encounters.Registry")
local C=ns:GetModule("Core.Constants")
local function txt(k,d) return table.concat(R:GetProfile(k,d).explanation,"\n") end

for _,enc in ipairs(R:GetOrdered()) do
 assert(R:GetProfile(enc.key,"normal") == nil, "Normal profile must stay retired: " .. enc.key)
 for _,d in ipairs(C.DIFFICULTY_ORDER) do
  local p=R:GetProfile(enc.key,d)
  assert(p and #p.explanation>0 and #p.calls>0)
  local text=txt(enc.key,d)
  assert(not text:find("CALL PRIORITY",1,true), "generic bossmod ownership boilerplate must stay out of player plans")
  assert(not text:find("FOLLOW DBM OR BIGWIGS",1,true), "player plans must contain actions, not addon-policy prose")
  for _,line in ipairs(p.explanation) do
   assert(type(line) == "string" and line ~= "" and #line<=250)
  end
  for _,call in ipairs(p.calls) do
   assert(type(call.action) == "string" and call.action ~= "")
   assert(type(call.warning) == "string" and call.warning ~= "")
   assert(#call.action<=96 and #call.warning<=160)
   assert(not call.warning:find(" > ",1,true), "raid call should use natural language rather than ASCII arrow chains")
  end
 end
end

local sentinels = R:GetProfile("sentinels","heroic")
assert(sentinels.callsByKey.side_swap,
    "Heroic Sentinels must retain the post-Stasis physical-side/tank-swap call")

local vashnik = R:GetProfile("vashnik","heroic")
assert(vashnik.callsByKey.catalyst and vashnik.callsByKey.siphon == nil and vashnik.callsByKey.fire_stagger == nil,
    "Heroic Vashnik must remain Purple+Orange only without the retired Blood route")

local sszorak = R:GetProfile("sszorak","heroic")
assert(sszorak.callsByKey.venom and sszorak.callsByKey.crosswinds and sszorak.callsByKey.maelstrom)
assert(sszorak.callsByKey.apex == nil and sszorak.callsByKey.dig_in == nil,
    "Heroic Sszorak must stay focused on raid-lead cyst/crosswind/wind calls")

local fangs = R:GetProfile("twinfangs","heroic")
assert(fangs.callsByKey.feast1 and fangs.callsByKey.feast2 and fangs.callsByKey.feast3)
assert(fangs.callsByKey.feast == nil,
    "Heroic Twin Fangs must keep the three fresh Feast hits as a sequence rather than the Mythic combined call")

assert(R:GetProfile("altar","heroic").callsByKey.intermission.warning:find("Bloodlust",1,true))
assert(R:GetProfile("altar","heroic").callsByKey.final.warning == "Final phase: keep health even; kill together.")
for _,d in ipairs(C.DIFFICULTY_ORDER) do
 local p=R:GetProfile("ulatek",d)
 for _,key in ipairs({"waves","coils","heart","serpents","bite","circling"}) do
  assert(p.callsByKey[key] and p.callsByKey[key].timing ~= false, d .. " selected Ula'tek timing call must remain provider-eligible")
 end
 for _,key in ipairs({"warden","eggs","phase3"}) do
  assert(p.callsByKey[key] and p.callsByKey[key].timing == false, d .. " Ula'tek strategy milestone must remain manual")
 end
 assert(p.callsByKey.fangs and p.callsByKey.fangs.timing == false)
end
assert(R:GetProfile("ulatek","mythic").callsByKey.incubation.timing ~= false)
print("ok - all eight Heroic/Mythic briefings and raid calls remain bounded, scoped and action-first")
