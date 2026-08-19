local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local received = {}

_G.CreateFrame = function() return T.Frame() end
_G.C_Timer = { After = function(_, callback) callback() end }
_G.DBM = nil

ns:RegisterModule("Core.Constants", { PROVIDER_PRIORITY = {} })
ns:RegisterModule("Core.EventBus", { On = function() end })
ns:RegisterModule("Services.TimelineService", {
    activeProviders = {},
    ProviderTimerStarted = function(_, providerName, timerID, data)
        received[#received + 1] = {
            providerName = providerName,
            timerID = timerID,
            precision = data and data.precision,
        }
        return data
    end,
})
ns:RegisterModule("Services.EncounterService", {
    IsActive = function() return false end,
    HasKnownEncounter = function() return false end,
})

T.Load("Core/ProviderRecoveryIntegration.lua", ns)
local Integration = ns:GetModule("Core.ProviderRecoveryIntegration")
local Timeline = ns:GetModule("Services.TimelineService")

Timeline:ProviderTimerStarted("BigWigs", "bridge", {
    bridge = "Blizzard",
    precision = "native",
})
assert(received[#received].precision == "approximate",
    "BigWigs Blizzard bridge without isApproximate metadata must be preview-only")

Timeline:ProviderTimerStarted("BigWigs", "direct", {
    precision = "exact",
})
assert(received[#received].precision == "exact",
    "direct BigWigs timers must preserve explicit exact precision")

_G.DBM = { Options = { IgnoreBlizzAPI = false } }
Timeline:ProviderTimerStarted("DBM", "explorers-fallback", {
    encounterID = 3497,
    precision = "exact",
})
assert(received[#received].precision == "approximate",
    "Lost Explorers DBM fallback must not upgrade Blizzard-derived timing")

_G.DBM.Options.IgnoreBlizzAPI = true
Timeline:ProviderTimerStarted("DBM", "explorers-hardcoded", {
    encounterID = 3497,
    precision = "exact",
})
assert(received[#received].precision == "exact",
    "Lost Explorers may remain exact when DBM explicitly owns hardcoded timeline authority")

_G.DBM.Options.IgnoreBlizzAPI = false
Timeline:ProviderTimerStarted("DBM", "other-encounter", {
    encounterID = 3420,
    precision = "exact",
})
assert(received[#received].precision == "exact",
    "unreviewed encounters must not be downgraded by the Lost Explorers exception")

local malformed = { precision = "exact" }
assert(Integration:ApplyProviderPrecisionPolicy("Unknown", malformed) == malformed)
assert(malformed.precision == "exact")

print("ok - bossmod Blizzard fallback cannot launder approximate timing into exact RLA actions")
