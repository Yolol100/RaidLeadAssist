local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local now = 100
local startOrder = {}
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
            BigWigs = "v419.2",
            BigWigs_TheVenomousAbyss = "v419.2",
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
    Get = function(_, key)
        if key == "bossA" then return { encounterID = 100 } end
        if key == "bossB" then return { encounterID = 200 } end
    end,
    MatchCall = function(_, encounterKey, key)
        if (encounterKey == "bossA" or encounterKey == "bossB") and key == 123 then return call end
    end,
})

local function provider(name)
    return {
        IsAvailable = function() return true end,
        Start = function()
            startOrder[#startOrder + 1] = name
            return true
        end,
        Stop = function() end,
    }
end
ns:RegisterModule("Services.Providers.DBM", provider("DBM"))
ns:RegisterModule("Services.Providers.BigWigs", provider("BigWigs"))
ns:RegisterModule("Services.Providers.Blizzard", provider("Blizzard"))

T.Load("Services/TimelineService.lua", ns)
local Timeline = ns:GetModule("Services.TimelineService")
Timeline:Initialize()
assert(table.concat(startOrder, ",") == "DBM,BigWigs,Blizzard",
    "provider startup must follow the declared DBM -> BigWigs -> Blizzard priority")

Timeline:SetEncounter("bossA")
Timeline:ProviderTimerStarted("BigWigs", "wrong-boss", {
    key = 123, duration = 10, encounterID = 200, precision = "exact",
})
assert(Timeline.timers["BigWigs|wrong-boss"] == nil,
    "an explicitly different BigWigs encounter must be rejected")

Timeline:ProviderTimerStarted("DBM", "invalid-boss", {
    key = 123, duration = 10, encounterID = "not-an-id", precision = "exact",
})
assert(Timeline.timers["DBM|invalid-boss"] == nil,
    "an invalid explicit bossmod encounter identity must fail closed")

Timeline:ProviderTimerStarted("BigWigs", "boss-a", {
    key = 123, duration = 10, encounterID = 100, precision = "exact",
})
local bigWigsA = Timeline.timers["BigWigs|boss-a"]
assert(bigWigsA and bigWigsA.encounterID == 100 and bigWigsA.call == call,
    "a matching BigWigs encounter timer must be accepted and retain its identity")

Timeline:ProviderTimerStarted("DBM", "dbm-a", {
    key = 123, duration = 10, encounterID = "100", precision = "exact",
})
local dbmA = Timeline.timers["DBM|dbm-a"]
assert(dbmA and dbmA.encounterID == 100 and dbmA.call == call,
    "a matching numeric-string DBM encounter identity must normalize safely")

Timeline:ProviderTimerStarted("Blizzard", "native", {
    key = 123, duration = 10, nativeEventID = 700, precision = "native",
})
assert(Timeline.timers["Blizzard|native"] ~= nil,
    "native Blizzard timing remains scoped by the independently verified selected encounter")

Timeline:SetEncounter("bossB", true)
assert(Timeline.timers["BigWigs|boss-a"] == nil and Timeline.timers["DBM|dbm-a"] == nil,
    "recent direct bossmod timers from the previous encounter must not survive a preserved remap")
local native = Timeline.timers["Blizzard|native"]
assert(native and native.call == call,
    "unscoped native Blizzard data may remap only through the newly selected verified encounter context")

Timeline:ProviderTimerStarted("BigWigs", "boss-b", {
    key = 123, duration = 8, encounterID = 200, precision = "exact",
})
assert(Timeline.timers["BigWigs|boss-b"] ~= nil,
    "the new encounter's explicit bossmod timer must be accepted after the switch")

print("ok - provider order is deterministic and explicit bossmod timers stay encounter-scoped")
