local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
local handlers = {}
local queued = {}
local frameScripts = {}
local active = true
local known = false
local seedCalls = 0
local seedSucceeds = true

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
            SeedEncounterHint = function()
                seedCalls = seedCalls + 1
                if seedSucceeds then known = true return true end
                return false
            end,
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
assert(seedCalls == 1 and known == true, "a retained bossmod encounter must be seeded after reload")
assert(#queued == 0, "successful recovery must stop the bounded retry loop")

known = false
seedSucceeds = false
seedCalls = 0
handlers.TIMELINE_PROVIDER_CHANGED(Integration)
assert(#queued == 1)
for expectedAttempt = 1, 3 do
    local item = table.remove(queued, 1)
    assert(item, "recovery probe should remain queued through the bounded retry window")
    item.callback()
    assert(seedCalls == expectedAttempt)
end
assert(#queued == 0, "late recovery probing must stop after three attempts")

handlers.TIMELINE_PROVIDER_CHANGED(Integration)
assert(#queued == 1)
handlers.ENCOUNTER_STARTED(Integration)
local cancelled = table.remove(queued, 1)
cancelled.callback()
assert(seedCalls == 3, "authoritative ENCOUNTER_START must cancel stale recovery probes")

active = false
handlers.TIMELINE_PROVIDER_CHANGED(Integration)
local inactive = table.remove(queued, 1)
inactive.callback()
assert(seedCalls == 3, "provider changes outside encounters must not trigger recovery work")

print("ok - late bossmod state recovery is bounded and cancelled by authoritative lifecycle events")
