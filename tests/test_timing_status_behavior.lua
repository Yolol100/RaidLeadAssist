local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

local idleLabel = nil
local originalCalls = 0
local automaticTimingEnabled = true
local activeProfile = {
    calls = {
        { key = "manual", timing = false },
    },
}

local App = {
    activeBossKey = "ulatek",
    activeDifficultyKey = "heroic",
}

function App:UpdateTiming()
    originalCalls = originalCalls + 1
    idleLabel = "ORIGINAL TIMING STATE"
end

function App:IsAutomaticTimingEnabled()
    return automaticTimingEnabled
end

local Registry = {}
function Registry:GetProfile(bossKey, difficultyKey)
    assert(bossKey == "ulatek", "unexpected boss key")
    assert(difficultyKey == "heroic", "unexpected difficulty key")
    return activeProfile
end

local UI = {
    timeline = {},
}
function UI.timeline:SetIdle(label)
    idleLabel = label
end

ns:RegisterModule("Core.App", App)
ns:RegisterModule("Encounters.Registry", Registry)
ns:RegisterModule("UI.MainFrame", UI)

T.Load("Core/TimingStatusIntegration.lua", ns)

-- A manual-only profile must advertise that state even if the wrapped timing update
-- left behind some other provider/timer presentation.
App:UpdateTiming()
assert(originalCalls == 1, "wrapped timing update must still run")
assert(idleLabel == "MANUAL CALLS ONLY",
    "manual-only profile must override stale/provider timing presentation")

-- Profiles that do have automatic calls keep the state produced by the normal timing path.
activeProfile = {
    calls = {
        { key = "automatic", timing = true },
    },
}
idleLabel = nil
App:UpdateTiming()
assert(originalCalls == 2, "wrapped timing update must run for automatic profiles")
assert(idleLabel == "ORIGINAL TIMING STATE",
    "automatic profile must not be replaced with a manual-only label")

-- Explicit user disablement takes precedence over profile capability.
automaticTimingEnabled = false
idleLabel = nil
App:UpdateTiming()
assert(originalCalls == 3, "wrapped timing update must run when automatic timing is disabled")
assert(idleLabel == "AUTO TIMING OFF",
    "user-disabled automatic timing must remain explicit")

print("ok - timing status behavior enforces manual-only and user-disabled states")
