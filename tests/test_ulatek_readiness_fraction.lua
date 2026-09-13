local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
_G.issecretvalue = function() return false end

local currentRoster = {}
local authoritativeRaid = true
local function setRoster(size)
    currentRoster = {}
    for index = 1, size do
        currentRoster[index] = {
            name = ("P%02d"):format(index),
            subgroup = math.floor((index - 1) / 5) + 1,
            role = "DAMAGER",
        }
    end
end

ns:RegisterModule("Services.RosterService", {
    IsRaidRoster = function() return authoritativeRaid end,
    GetRoster = function() return currentRoster end,
})

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss78AssignmentOverride.lua", ns)
T.Load("Encounters/VenomousAbyss/Ulatek.lua", ns)
T.Load("Services/AssignmentService.lua", ns)

ns:RegisterModule("Encounters.SetupRegistry", {
    HasSetup = function() return false end,
    GetCounts = function() return 0, 0, 0 end,
})
ns:RegisterModule("Services.MessageService", {
    GetCustomCurrentness = function() return "current" end,
})
ns:RegisterModule("Services.SetupService", {
    IsReady = function() return true end,
})
ns:RegisterModule("Services.TimelineService", {
    timers = {},
    GetProviderSummary = function() return "DBM" end,
})
ns:RegisterModule("Core.App", {
    activeBossKey = "ulatek",
    activeDifficultyKey = "heroic",
    db = { automaticTimingEnabled = false },
    PrintDoctor = function() end,
})

local Assignments = ns:GetModule("Services.AssignmentService")
setRoster(20)
Assignments:Initialize({
    assignments = {
        ulatek = {
            heroic = {
                coil_a = "P01, P02, P03, P04",
                coil_b = "P05, P06, P07, P08",
                egg_left = "P09",
                egg_right = "P10",
                bite_melee = "P11",
                bite_ranged = "P12",
                bite_healer = "P13",
            },
        },
    },
})

T.Load("Core/ReadinessIntegration.lua", ns)
local Readiness = ns:GetModule("Core.ReadinessIntegration")

local state = Readiness:GetState()
assert(not state.ready and state.label == "CHECK", "undersized Coil teams must block global readiness")
assert(#state.missingRequired == 0, "all required fields are present in this scenario")
assert(#state.invalidAssignments == 2, "both undersized Coil teams must be reported as live-invalid")
assert(#state.rosterMissing == 0, "all configured names are current raid members")
assert(state.states[1] == "CHECK ASSIGNMENTS", "live-invalid Coil teams must surface as CHECK ASSIGNMENTS")
assert(state.invalidAssignments[1].message:find("40%", 1, true), "readiness must expose the live 40% reason")

-- Pre-planning outside an actual raid must not be falsely blocked by the solo/party roster.
authoritativeRaid = false
setRoster(1)
state = Readiness:GetState()
assert(state.ready and state.states[1] == "READY MANUAL",
    "saved future raid assignments must remain pre-plannable outside an authoritative raid")
assert(#state.invalidAssignments == 0 and #state.rosterMissing == 0,
    "solo/party context must not masquerade as the raid for assignment readiness")

-- Once the actual raid forms, valid 40%+ teams restore readiness.
authoritativeRaid = true
setRoster(20)
local ok = Assignments:ApplyBossDraft("ulatek", "heroic", {
    coil_a = "P01, P02, P03, P04, P05, P06, P07, P08",
    coil_b = "P09, P10, P11, P12, P13, P14, P15, P16",
    egg_left = "P17",
    egg_right = "P18",
    bite_melee = "P01",
    bite_ranged = "P02",
    bite_healer = "P03",
})
assert(ok, "valid 20-player Ula'tek plan must save")
state = Readiness:GetState()
assert(state.ready and state.states[1] == "READY MANUAL", "valid live plan must restore READY")
assert(#state.invalidAssignments == 0 and #state.rosterMissing == 0)

-- If the live raid grows, the global readiness indicator must fail closed too, not only the call button.
setRoster(30)
state = Readiness:GetState()
assert(not state.ready and state.states[1] == "CHECK ASSIGNMENTS",
    "20-player teams must stop being globally ready after the raid grows to 30")
assert(#state.invalidAssignments == 2, "both eight-player teams must fail the new 12-player minimum")
assert(state.invalidAssignments[1].message:find("requires at least 12 current raid players", 1, true),
    "readiness must show the resized live minimum")

print("ok - Ula'tek global readiness shares the authoritative live 40% Coil contract")
