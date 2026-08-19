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
 for _,d in ipairs(C.DIFFICULTY_ORDER) do
  local p=R:GetProfile(enc.key,d)
  assert(p and #p.explanation>0 and #p.calls>0)
  local text=txt(enc.key,d)
  assert(not text:find("CALL PRIORITY",1,true), "generic bossmod ownership boilerplate must stay out of player plans")
  assert(not text:find("FOLLOW DBM OR BIGWIGS",1,true), "player plans must contain actions, not addon-policy prose")
  for _,line in ipairs(p.explanation) do
   assert(#line<=200)
   assert(line ~= string.upper(line) or not line:find("[A-Z][A-Z][A-Z]"), "briefing lines should use normal capitalization")
  end
  for _,call in ipairs(p.calls) do
   assert(#call.action<=64 and #call.warning<=96)
   assert(call.warning:find(":",1,true), "raid call should use cue: action wording")
   assert(not call.warning:find(" > ",1,true), "raid call should use natural language rather than arrow chains")
  end
 end
end
assert(R:GetProfile("sentinels","heroic").callsByKey.side_swap.warning == "After Stasis: hold sides; tanks swap bosses.")
assert(R:GetProfile("vashnik","heroic").callsByKey.catalyst.warning == "Green circles: soak every one.")
assert(R:GetProfile("sszorak","heroic").callsByKey.maelstrom.warning == "Maelstrom: Poppers 1-2-3 trigger Cysts on each wind.")
assert(R:GetProfile("twinfangs","normal").callsByKey.feast.warning == "Feast: fresh 3+ players soak each hit.")
assert(R:GetProfile("twinfangs","heroic").callsByKey.feast.warning == "Feast: Team A, then B, then C.")
assert(R:GetProfile("altar","heroic").callsByKey.intermission.warning:find("Bloodlust",1,true))
assert(R:GetProfile("altar","heroic").callsByKey.final.warning == "Final phase: keep health even; kill together.")
for _,d in ipairs(C.DIFFICULTY_ORDER) do for _,call in ipairs(R:GetProfile("ulatek",d).calls) do assert(call.timing==false) end end
print("ok - all eight player briefings and raid calls remain bounded, normally capitalized and action-first")
