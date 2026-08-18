local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local now = 100
local canSupply = true
local refreshCount = 0
local call = { key = "mechanic" }

_G.GetTime = function() return now end
_G.C_Timer = { After = function(_, callback) callback() end }
_G.CreateFrame = function() return T.Frame() end
_G.table.wipe = _G.table.wipe or function(tbl) for key in pairs(tbl) do tbl[key] = nil end end
_G.issecretvalue = function() return false end
_G.C_AddOns = {
    GetAddOnMetadata = function(name, field)
        if field ~= "Version" then return nil end
        local versions = {
            ["DBM-Core"] = "12.1.3",
            ["DBM-Raids-Midnight"] = "12.1.3",
        }
        return versions[name]
    end,
    IsAddOnLoaded = function() return true end,
}

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
ns:RegisterModule("Core.EventBus", { Emit = function() end })
ns:RegisterModule("Encounters.Registry", {
    Get = function() return { encounterID = 100 } end,
    MatchCall = function(_, _, key) if key == 123 then return call end end,
})

local dbm = {}
function dbm:IsAvailable() return true end
function dbm:Start(sink)
    self.sink = sink
    return true
end
function dbm:Stop() end
function dbm:CanSupplyBossTimers() return canSupply end
function dbm:RefreshAuthority()
    refreshCount = refreshCount + 1
    return self.sink:SetBlizzardSuppressedByProvider("DBM", canSupply)
end

local blizzard = {}
function blizzard:IsAvailable() return true end
function blizzard:Start(sink) self.sink = sink return true end
function blizzard:Stop() end
function blizzard:SeedExistingEvents() end

ns:RegisterModule("Services.Providers.DBM", dbm)
ns:RegisterModule("Services.Providers.BigWigs", { IsAvailable = function() return false end })
ns:RegisterModule("Services.Providers.Blizzard", blizzard)

T.Load("Services/TimelineService.lua", ns)
local Timeline = ns:GetModule("Services.TimelineService")
Timeline:Initialize()
Timeline:SetEncounter("boss")
assert(Timeline:IsBlizzardSuppressed() == true,
    "provider refresh after startup must reconstruct DBM authority")
assert(Timeline:GetProviderSummary() == "DBM",
    "usable provider summary must report DBM while its direct boss timer feed is authoritative")

local beforeNativeRefresh = refreshCount
canSupply = false
Timeline:ProviderTimerStarted("Blizzard", "native-1", {
    key = 123,
    duration = 10,
    nativeEventID = 700,
    precision = "native",
})
assert(refreshCount > beforeNativeRefresh,
    "native Blizzard timing must revalidate DBM authority at the execution boundary")
assert(Timeline:IsBlizzardSuppressed() == false,
    "DBM authority must yield immediately when the public boss timer feed is disabled")
assert(Timeline.timers["Blizzard|native-1"] ~= nil,
    "the same native event that discovers stale suppression must remain usable")
assert(Timeline:GetProviderSummary() == "Blizzard",
    "usable provider summary must distinguish native fallback from a loaded but unusable DBM core")

canSupply = true
Timeline:RefreshProviderAuthorities()
assert(Timeline:IsBlizzardSuppressed() == true,
    "restoring the direct DBM feed must restore DBM authority")
assert(Timeline.timers["Blizzard|native-1"] ~= nil,
    "global DBM authority must retain a required RLA fallback until a direct timer covers that call")
assert(Timeline:GetProviderSummary() == "DBM")

Timeline:ProviderTimerStarted("DBM", "dbm-1", {
    key = 123,
    duration = 10,
    precision = "exact",
})
local selected = Timeline:GetTimerForCall("mechanic")
assert(selected and selected.providerName == "DBM",
    "once DBM publishes the call directly, the direct timer must outrank the retained native fallback")

print("ok - DBM/Blizzard authority reconciles globally while preserving only call-scoped timing gaps")
