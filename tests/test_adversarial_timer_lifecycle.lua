local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local now = 2000
local call = { key = "mechanic" }

_G.GetTime = function() return now end
_G.C_Timer = { After = function(_, cb) cb() end }
_G.CreateFrame = function() return T.Frame() end
_G.table.wipe = _G.table.wipe or function(tbl) for key in pairs(tbl) do tbl[key] = nil end end
_G.issecretvalue = function() return false end
_G.C_AddOns = {
    GetAddOnMetadata = function(addon, field)
        if field ~= "Version" then return nil end
        local versions = {
            ["DBM-Core"] = "12.1.3",
            ["DBM-Raids-Midnight"] = "12.1.3",
            BigWigs = "v419.2",
            BigWigs_TheVenomousAbyss = "v419.2",
        }
        return versions[addon]
    end,
    IsAddOnLoaded = function() return true end,
}

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
ns:RegisterModule("Core.EventBus", { Emit = function() end })
ns:RegisterModule("Encounters.Registry", {
    Get = function() return { encounterID = 1001 } end,
    MatchCall = function(_, encounterKey, key, name)
        if encounterKey == "boss" and (key == 123 or name == "Mechanic") then return call end
    end,
})

local function provider()
    return {
        IsAvailable = function() return true end,
        Start = function() return true end,
        Stop = function() end,
        CanSupplyBossTimers = function() return true end,
    }
end
ns:RegisterModule("Services.Providers.DBM", provider())
ns:RegisterModule("Services.Providers.BigWigs", provider())
ns:RegisterModule("Services.Providers.Blizzard", provider())
T.Load("Services/TimelineService.lua", ns)
local Timeline = ns:GetModule("Services.TimelineService")
Timeline:Initialize()
Timeline:SetEncounter("boss")

local function startDBM(duration, count)
    Timeline:ProviderTimerStarted("DBM", "shared-id", {
        key = 123,
        name = "Mechanic",
        duration = duration,
        encounterID = 1001,
        precision = "exact",
        count = count,
    })
    return Timeline.timers["DBM|shared-id"]
end

-- A normal live refresh for the same provider bar stays the same occurrence.
local first = startDBM(10, 1)
assert(first and first.occurrenceID)
local firstOccurrence = first.occurrenceID
assert(Timeline:AcknowledgeCall("mechanic") == true)
assert(first.acknowledged == true)
now = now + 2
local refreshed = startDBM(12, 1)
assert(refreshed.occurrenceID == firstOccurrence, "live restart should preserve occurrence identity")
assert(refreshed.acknowledged == true, "live restart should preserve acknowledgement")

-- Explicit count change is a hard occurrence boundary even if the source ID is reused.
local counted = startDBM(12, 2)
assert(counted.occurrenceID ~= firstOccurrence, "count change must create a new occurrence")
assert(counted.acknowledged ~= true, "count change must re-arm the mechanic")

-- Rebuild an acknowledged short-lived timer, then deliver a stale pause after it expired.
Timeline:Reset()
now = 2100
local expired = startDBM(1, 1)
local expiredOccurrence = expired.occurrenceID
assert(Timeline:AcknowledgeCall("mechanic") == true)
now = now + 3
Timeline:ProviderTimerPaused("DBM", "shared-id", true)
assert(Timeline.timers["DBM|shared-id"] == nil,
    "late pause after expiry must discard the stale timer instead of freezing it")

-- A fresh Begin/Start after the old deadline must not inherit the expired occurrence.
local fresh = startDBM(10, 1)
assert(fresh.occurrenceID ~= expiredOccurrence,
    "restart after an expired late-pause timer must create a new occurrence")
assert(fresh.acknowledged ~= true,
    "restart after an expired late-pause timer must not inherit stale acknowledgement")

print("ok - adversarial timer lifecycle ordering keeps expired callbacks from suppressing a new occurrence")
