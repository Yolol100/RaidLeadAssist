local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local now = 100
local call = { key = "kick" }

_G.GetTime = function() return now end
_G.C_Timer = { After = function(_, cb) cb() end }
_G.CreateFrame = function() return T.Frame() end
_G.table.wipe = _G.table.wipe or function(t) for k in pairs(t) do t[k] = nil end end
_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
ns:RegisterModule("Core.EventBus", { Emit = function() end })
ns:RegisterModule("Encounters.Registry", {
    MatchCall = function(_, encounterKey, key)
        if encounterKey == "boss" and key == 123 then return call end
    end,
})
local function p()
    return { IsAvailable = function() return true end, Start = function() return true end, Stop = function() end }
end
ns:RegisterModule("Services.Providers.BigWigs", p())
ns:RegisterModule("Services.Providers.DBM", p())
ns:RegisterModule("Services.Providers.Blizzard", p())
T.Load("Core/Util.lua", ns)
T.Load("Services/TimelineService.lua", ns)
local Timeline = ns:GetModule("Services.TimelineService")
Timeline:Initialize()
Timeline:SetEncounter("boss")

Timeline:ProviderTimerStarted("Blizzard", "b1", { key = 123, duration = 10, nativeEventID = 77 })
now = 100.2
Timeline:ProviderTimerStarted("BigWigs", "w1", { key = 123, duration = 9.9 })
local best = Timeline:GetTimerForCall("kick")
assert(best and best.providerName == "BigWigs")
assert(Timeline:AcknowledgeCall("kick") == true)
assert(Timeline:GetTimerForCall("kick") == nil)

print("ok - timer selection and duplicate acknowledgement")
