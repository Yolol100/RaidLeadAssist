local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local now = 10
local sent = {}
local timers = {}
local leader = true
local encounterActive = false
local splitValue = "G1 = RED — G2 = GREEN"

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
ns:RegisterModule("Services.RaidGroupSplitService", {
    Describe = function() return splitValue end,
})
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
leader = true
now = now + 1
assert(Service:Send(string.rep("x", 200)) == true, "200-character Raid Warning must remain valid")
assert(#sent == 1)
assert(Service:Send(string.rep("x", 201)) == false, "201-character Raid Warning must fail closed before the chat API")
assert(#sent == 1, "oversized Raid Warning must never reach SendChatMessage")

leader = false
assert(Service:Send("manual") == false)
assert(#sent == 1)

leader = true
splitValue = nil
now = now + 1
local timerCount = #timers
assert(Service:SendBriefing({ "{{GROUP_SPLIT:RED:GREEN}}" }) == false,
    "dynamic briefing must fail closed when the current raid split cannot be verified")
assert(#timers == timerCount, "failed dynamic split must not schedule any Raid Warning")
assert(ns.messages[#ns.messages]:find("verified multi%-group raid roster"),
    "failed dynamic split must explain the missing verified roster")

splitValue = "G1 = RED — G2 = GREEN"
now = now + 1
assert(Service:SendBriefing({ "{{GROUP_SPLIT:RED:GREEN}}" }) == true,
    "verified dynamic split must remain sendable")
assert(#timers == timerCount + 1)

print("ok - raid warning lifecycle, length guards and dynamic split fail-closed behavior")
