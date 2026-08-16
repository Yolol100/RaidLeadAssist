local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local metadata = {
    BigWigs = { Version = "v419.2" },
    BigWigs_TheVenomousAbyss = { Version = "v419.2" },
    ["DBM-Core"] = { Version = "12.1.3" },
    ["DBM-Raids-Midnight"] = { Version = "12.1.3" },
}
local loaded = {
    BigWigs_TheVenomousAbyss = true,
    ["DBM-Raids-Midnight"] = false,
}
local dbmFeedEnabled = true

_G.issecretvalue = function() return false end
_G.table.wipe = _G.table.wipe or function(tbl) for key in pairs(tbl) do tbl[key] = nil end end
_G.C_AddOns = {
    GetAddOnMetadata = function(name, field)
        return metadata[name] and metadata[name][field]
    end,
    IsAddOnLoaded = function(name)
        return loaded[name] == true
    end,
}

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
ns:RegisterModule("Core.EventBus", { Emit = function() end })
ns:RegisterModule("Encounters.Registry", { MatchCall = function() end })
ns:RegisterModule("Services.Providers.BigWigs", {})
ns:RegisterModule("Services.Providers.DBM", {
    CanSupplyBossTimers = function() return dbmFeedEnabled end,
})
ns:RegisterModule("Services.Providers.Blizzard", {})

T.Load("Services/TimelineService.lua", ns)
local Timeline = ns:GetModule("Services.TimelineService")
Timeline.activeProviders.BigWigs = ns:GetModule("Services.Providers.BigWigs")
Timeline.activeProviders.DBM = ns:GetModule("Services.Providers.DBM")
Timeline.activeProviders.Blizzard = ns:GetModule("Services.Providers.Blizzard")

local diagnostics = Timeline:GetProviderDiagnostics()
assert(diagnostics:find("BigWigs v419.2", 1, true))
assert(diagnostics:find("Venomous pack loaded", 1, true))
assert(diagnostics:find("DBM 12.1.3", 1, true))
assert(diagnostics:find("Midnight raid pack installed/not loaded", 1, true))
assert(diagnostics:find("Blizzard native", 1, true))
assert(Timeline:GetProviderSummary() == "DBM, BigWigs, Blizzard",
    "usable summary must retain configured priority across all usable sources")

Timeline.blizzardSuppressionSources.DBM = true
diagnostics = Timeline:GetProviderDiagnostics()
assert(diagnostics:find("Blizzard timers suppressed by DBM", 1, true))
assert(Timeline:GetProviderSummary() == "DBM, BigWigs",
    "a suppressed native source must not be advertised as usable")

dbmFeedEnabled = false
diagnostics = Timeline:GetProviderDiagnostics()
assert(diagnostics:find("boss timer feed disabled", 1, true),
    "diagnostics must distinguish a loaded DBM core from a usable direct boss timer feed")
assert(Timeline:GetProviderSummary() == "BigWigs",
    "a disabled DBM timer feed must not be advertised as usable")

dbmFeedEnabled = true
metadata["DBM-Raids-Midnight"] = nil
diagnostics = Timeline:GetProviderDiagnostics()
assert(diagnostics:find("Midnight raid pack missing", 1, true))
assert(Timeline:GetProviderSummary() == "BigWigs",
    "DBM core without its target raid pack must not satisfy timing readiness")

metadata.BigWigs_TheVenomousAbyss = nil
assert(Timeline:GetProviderSummary() == "",
    "no direct target pack plus suppressed native timing must fail readiness closed")

print("ok - provider diagnostics distinguish loaded components from actually usable timing sources")
