local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local now = 10
local sent = {}
local timers = {}
local leader = true
local encounterActive = false

_G.GetTime = function() return now end
_G.IsInRaid = function() return true end
_G.UnitIsGroupLeader = function() return leader end
_G.UnitIsGroupAssistant = function() return false end
_G.C_InstanceEncounter = { IsEncounterInProgress = function() return encounterActive end }
_G.C_ChatInfo = { SendChatMessage = function(text, channel) sent[#sent + 1] = channel .. ":" .. text end }
_G.C_Timer = { NewTimer = function(_, callback)
    local timer = { callback = callback, canceled = false }
    function timer:Cancel() self.canceled = true end
    timers[#timers + 1] = timer
    return timer
end }
_G.table.wipe = _G.table.wipe or function(tbl) for key in pairs(tbl) do tbl[key] = nil end end
_G.issecretvalue = function() return false end

ns:RegisterModule("Core.Constants", { BRIEFING_LINE_DELAY = 0.1, BRIEFING_CLICK_LOCK_SECONDS = 0.5 })
T.Load("Core/Util.lua", ns)
T.Load("Services/RaidWarningService.lua", ns)
local Service = ns:GetModule("Services.RaidWarningService")

assert(Service:SendBriefing({ "one", "two" }) == true)
assert(#timers == 2)
encounterActive = true
timers[1].callback()
assert(#sent == 0)
assert(timers[2].canceled == true)

encounterActive = false
leader = false
now = now + 1
assert(Service:Send("manual") == false)
assert(#sent == 0)

print("ok - raid warning lifecycle guards")
