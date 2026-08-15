local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local callbacks = {}
local suppression = {}

_G.issecretvalue = function() return false end
_G.DBM = {
    Options = {
        IgnoreBlizzAPI = false,
        HideDBMBars = false,
        DontShowBossTimers = false,
    },
    Mods = {},
    RegisterCallback = function(_, name, callback) callbacks[name] = callback end,
    UnregisterCallback = function() end,
}

local sink = {
    SetBlizzardSuppressedByProvider = function(_, provider, value)
        suppression[#suppression + 1] = { provider = provider, value = value }
    end,
    ProviderReset = function() end,
}

T.Load("Core/Util.lua", ns)
T.Load("Services/Providers/DBMProvider.lua", ns)
local provider = ns:GetModule("Services.Providers.DBM")
assert(provider:Start(sink) == true)

callbacks.DBM_IgnoreBlizzAPI()
assert(suppression[#suppression].provider == "DBM" and suppression[#suppression].value == true,
    "DBM should suppress Blizzard-derived timers while its boss timer feed is usable")

DBM.Options.HideDBMBars = true
callbacks.DBM_IgnoreBlizzAPI()
assert(suppression[#suppression].value == false,
    "global HideDBMBars prevents DBM_TimerBegin, so Blizzard fallback must stay available")

DBM.Options.HideDBMBars = false
DBM.Options.DontShowBossTimers = true
callbacks.DBM_IgnoreBlizzAPI()
assert(suppression[#suppression].value == false,
    "global DontShowBossTimers prevents DBM_TimerBegin, so Blizzard fallback must stay available")

DBM.Options.DontShowBossTimers = false
callbacks.DBM_IgnoreBlizzAPI()
assert(suppression[#suppression].value == true,
    "restoring DBM boss timers must restore DBM authority")
callbacks.DBM_ResumeBlizzAPI()
assert(suppression[#suppression].value == false,
    "DBM_ResumeBlizzAPI must always restore Blizzard-derived timers")

provider:Stop()
DBM.Options.IgnoreBlizzAPI = true
DBM.Options.HideDBMBars = true
suppression = {}
assert(provider:Start(sink) == true)
assert(#suppression == 1 and suppression[1].value == false,
    "reload recovery must not reconstruct DBM suppression when DBM cannot emit boss timers")

provider:Stop()
DBM.Options.HideDBMBars = false
suppression = {}
assert(provider:Start(sink) == true)
assert(#suppression == 1 and suppression[1].value == true,
    "reload recovery must reconstruct DBM suppression when its boss timer feed is usable")

print("ok - DBM authority yields to Blizzard-derived fallback when global DBM boss bars cannot emit timers")
