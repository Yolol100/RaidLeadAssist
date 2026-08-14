local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local now = 100
local secret = {
    [995] = true,
    [996] = true,
    [997] = true,
    [998] = true,
    [999] = true,
}
local call = { key = "call" }

_G.GetTime = function() return now end
_G.C_Timer = { After = function(_, callback) callback() end }
_G.CreateFrame = function() return T.Frame() end
_G.table.wipe = _G.table.wipe or function(tbl) for key in pairs(tbl) do tbl[key] = nil end end
_G.issecretvalue = function(value) return secret[value] == true end

T.Load("Core/Constants.lua", ns)
ns:RegisterModule("Core.EventBus", { Emit = function() end })
ns:RegisterModule("Encounters.Registry", {
    MatchCall = function(_, encounterKey, key)
        if encounterKey == "boss" and key == 123 then return call end
    end,
})
local function provider()
    return {
        IsAvailable = function() return true end,
        Start = function() return true end,
        Stop = function() end,
    }
end
ns:RegisterModule("Services.Providers.BigWigs", provider())
ns:RegisterModule("Services.Providers.DBM", provider())
ns:RegisterModule("Services.Providers.Blizzard", provider())
T.Load("Core/Util.lua", ns)
T.Load("Services/TimelineService.lua", ns)

local Timeline = ns:GetModule("Services.TimelineService")
Timeline:Initialize()
Timeline:SetEncounter("boss")

Timeline:ProviderTimerStarted("BigWigs", "secret-duration", { key = 123, duration = 999 })
assert(Timeline.timers["BigWigs|secret-duration"] == nil,
    "secret duration must be rejected at the timeline service boundary")

Timeline:ProviderTimerStarted("BigWigs", "safe", {
    key = 123,
    name = 998,
    duration = 10,
    nativeEventID = 997,
    precision = "exact",
})
local timer = Timeline.timers["BigWigs|safe"]
assert(timer ~= nil and timer.call == call, "safe timer must still be accepted")
assert(timer.name == nil and timer.nativeEventID == nil,
    "secret metadata must not be retained by the timeline service")
local originalExpiration = timer.expiration

Timeline:ProviderTimerUpdated("BigWigs", "safe", 996, 20)
assert(timer.expiration == originalExpiration,
    "secret update values must not mutate an existing timer")

Timeline:ProviderTimerPaused("BigWigs", "safe", 995)
assert(timer.paused == false, "secret pause state must not mutate an existing timer")

print("ok - timer service rejects secret values before decisions or state changes")
