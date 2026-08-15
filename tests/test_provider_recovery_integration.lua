local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local handlers = {}
local queued = {}
local frameScripts = {}
local active = true
local known = false
local seedOrder = {}
local dbmSucceeds = true
local bigWigsSucceeds = true

_G.C_Timer = {
    After = function(delay, callback)
        queued[#queued + 1] = { delay = delay, callback = callback }
    end,
}
_G.CreateFrame = function()
    return {
        RegisterEvent = function() end,
        SetScript = function(_, name, callback) frameScripts[name] = callback end,
    }
end

local function seed(name, succeeds)
    seedOrder[#seedOrder + 1] = name
    if succeeds then known = true return true end
    return false
end

ns:RegisterModule("Core.Constants", {
    PROVIDER_PRIORITY = { "DBM", "BigWigs", "Blizzard" },
})
ns:RegisterModule("Core.EventBus", {
    On = function(_, name, _, callback) handlers[name] = callback end,
})
ns:RegisterModule("Services.EncounterService", {
    IsActive = function() return active end,
    HasKnownEncounter = function() return known end,
})
ns:RegisterModule("Services.TimelineService", {
    activeProviders = {
        BigWigs = {
            SeedEncounterHint = function() return seed("BigWigs", bigWigsSucceeds) end,
        },
        DBM = {
            SeedEncounterHint = function() return seed("DBM", dbmSucceeds) end,
        },
    },
})

T.Load("Core/ProviderRecoveryIntegration.lua", ns)
local Integration = ns:GetModule("Core.ProviderRecoveryIntegration")

assert(frameScripts.OnEvent, "PLAYER_ENTERING_WORLD recovery frame must be registered")
frameScripts.OnEvent()
assert(#queued == 1 and queued[1].delay == 0)
local first = table.remove(queued, 1)
first.callback()
assert(known == true, "a retained bossmod encounter must be seeded after reload")
assert(table.concat(seedOrder, ",") == "DBM", "DBM must be consulted first and stop recovery after success")
assert(#queued == 0, "successful recovery must stop the bounded retry loop")

known = false
seedOrder = {}
dbmSucceeds = false
bigWigsSucceeds = true
handlers.TIMELINE_PROVIDER_CHANGED(Integration)
assert(#queued == 1)
local fallback = table.remove(queued, 1)
fallback.callback()
assert(known == true, "BigWigs must recover the encounter when DBM cannot")
assert(table.concat(seedOrder, ",") == "DBM,BigWigs", "BigWigs must only be consulted after DBM fails")
assert(#queued == 0)

known = false
seedOrder = {}
dbmSucceeds = false
bigWigsSucceeds = false
handlers.TIMELINE_PROVIDER_CHANGED(Integration)
assert(#queued == 1)
for expectedAttempt = 1, 3 do
    local item = table.remove(queued, 1)
    assert(item, "recovery probe should remain queued through the bounded retry window")
    item.callback()
    assert(#seedOrder == expectedAttempt * 2, "each failed attempt must try DBM then BigWigs")
end
assert(#queued == 0, "late recovery probing must stop after three attempts")

handlers.TIMELINE_PROVIDER_CHANGED(Integration)
assert(#queued == 1)
handlers.ENCOUNTER_STARTED(Integration)
local cancelled = table.remove(queued, 1)
cancelled.callback()
assert(#seedOrder == 6, "authoritative ENCOUNTER_START must cancel stale recovery probes")

active = false
handlers.TIMELINE_PROVIDER_CHANGED(Integration)
local inactive = table.remove(queued, 1)
inactive.callback()
assert(#seedOrder == 6, "provider changes outside encounters must not trigger recovery work")

print("ok - DBM-first late bossmod recovery is ordered, bounded, and safely falls back to BigWigs")
