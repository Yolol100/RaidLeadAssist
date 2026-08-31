local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local callbacks = {}
local started = {}
local SECRET = {}

_G.issecretvalue = function(value) return value == SECRET end
_G.DBM = {
    Options = { IgnoreBlizzAPI = false },
    Mods = { { id = "2888", encounterId = 3421 } },
    GetModByName = function(_, id)
        if tostring(id) == "2888" then return _G.DBM.Mods[1] end
    end,
    RegisterCallback = function(_, name, callback) callbacks[name] = callback end,
    UnregisterCallback = function() end,
}

local sink = {}
function sink:ProviderTimerStarted(provider, id, data)
    started[#started + 1] = { provider = provider, id = id, data = data }
end
function sink:SetBlizzardSuppressedByProvider() return true end
function sink:ProviderTimerStopped() end
function sink:ProviderTimerUpdated() end
function sink:ProviderTimerPaused() end
function sink:ProviderTimerFaded() end
function sink:ProviderEncounterHint() end
function sink:ProviderReset() end

T.Load("Core/Util.lua", ns)
T.Load("Services/Providers/DBMProvider.lua", ns)
local provider = ns:GetModule("Services.Providers.DBM")
assert(provider:Start(sink) == true)

local function begin(id, simpleType, fullType)
    callbacks.DBM_TimerBegin(nil, id, "Timer", 10, 456, simpleType, 123, nil, 2888,
        nil, false, "Timer", nil, nil, nil, fullType, false, nil, true)
    return started[#started]
end

local approximate = begin("dbm-cd", "cd", "cd")
assert(approximate and approximate.data.precision == "approximate",
    "DBM cooldown full types must not be promoted to exact timing")

local exactCount = begin("dbm-next-count", "cd", "nextcount")
assert(exactCount and exactCount.data.precision == "exact",
    "DBM next-count full types must remain exact")

local exactNext = begin("dbm-next", "next", "next")
assert(exactNext and exactNext.data.precision == "exact",
    "DBM NewNextTimer simple type must be accepted as exact")

local legacy = begin("dbm-legacy", "cd", nil)
assert(legacy and legacy.data.precision == "exact",
    "legacy DBM callbacks without fullType must preserve existing compatibility")

local secret = begin("dbm-secret-fulltype", "cd", SECRET)
assert(secret and secret.data.precision == "approximate",
    "secret DBM fullType values must fail closed to approximate")

local secretNext = begin("dbm-secret-next-fulltype", "next", SECRET)
assert(secretNext and secretNext.data.precision == "approximate",
    "secret fullType must fail closed even when the simple type is next")

local nonStringStage = begin("dbm-nonstring-stage-fulltype", "stage", 12345)
assert(nonStringStage and nonStringStage.data.precision == "approximate",
    "non-string fullType must fail closed even when the simple type is stage")

print("ok - DBM full timer type preserves exact next timers without laundering cooldowns")
