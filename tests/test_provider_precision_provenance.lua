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

local fallbackCapableDBMEncounters = {
    3420, -- Sszorak
    3421, -- The Twin Fangs
    3429, -- The Coiled Altar
    3445, -- Entombed Sentinels
    3455, -- Vashnik the Malignant
    3470, -- Nek'zali the Soulcoiler
    3492, -- Ula'tek
    3497, -- The Lost Explorers
}

_G.DBM = { Options = { IgnoreBlizzAPI = false } }
for _, encounterID in ipairs(fallbackCapableDBMEncounters) do
    Timeline:ProviderTimerStarted("DBM", "fallback-" .. tostring(encounterID), {
        encounterID = encounterID,
        precision = "exact",
    })
    assert(received[#received].precision == "approximate",
        "fallback-capable DBM encounter must not launder Blizzard timing into exact: "
            .. tostring(encounterID))
end

_G.DBM.Options.IgnoreBlizzAPI = true
for _, encounterID in ipairs(fallbackCapableDBMEncounters) do
    Timeline:ProviderTimerStarted("DBM", "hardcoded-" .. tostring(encounterID), {
        encounterID = encounterID,
        precision = "exact",
    })
    assert(received[#received].precision == "exact",
        "reviewed DBM hardcoded authority may remain exact: " .. tostring(encounterID))
end

_G.DBM.Options.IgnoreBlizzAPI = false
Timeline:ProviderTimerStarted("DBM", "outside-reviewed-raid", {
    encounterID = 999999,
    precision = "exact",
})
assert(received[#received].precision == "exact",
    "precision policy must remain scoped to the reviewed fallback-capable raid encounters")

local malformed = { precision = "exact" }
assert(Integration:ApplyProviderPrecisionPolicy("Unknown", malformed) == malformed)
assert(malformed.precision == "exact")

print("ok - bossmod Blizzard fallback cannot launder approximate timing into exact RLA actions")
