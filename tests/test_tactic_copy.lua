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
  for _,call in ipairs(p.calls) do assert(#call.action<=96 and #call.warning<=120) end
 end
end
assert(R:GetProfile("sentinels","heroic").callsByKey.side_swap.warning == "GROUPS HOLD SIDES > BOSSES SWAP")
assert(R:GetProfile("vashnik","heroic").callsByKey.catalyst.warning == "BILE > SOAK EVERY GREEN CIRCLE")
assert(R:GetProfile("sszorak","heroic").callsByKey.maelstrom.warning == "MAELSTROM > POPPERS 1/2/3 > KNOCK AGAINST EACH WIND")
assert(R:GetProfile("twinfangs","normal").callsByKey.feast.warning == "FEAST > FRESH 3+ SOAKERS EACH HIT")
assert(R:GetProfile("twinfangs","heroic").callsByKey.feast.warning == "FEAST > TEAM A > TEAM B > TEAM C")
assert(R:GetProfile("altar","heroic").callsByKey.intermission.warning:find("BLOODLUST",1,true))
assert(R:GetProfile("altar","heroic").callsByKey.final.warning == "PHASE 3 > KEEP BOTH EVEN > KILL TOGETHER")
for _,d in ipairs(C.DIFFICULTY_ORDER) do for _,call in ipairs(R:GetProfile("ulatek",d).calls) do assert(call.timing==false) end end
print("ok - all eight player briefings remain bounded, normally capitalized and free of policy boilerplate")
