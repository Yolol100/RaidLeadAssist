local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/VenomousAbyss/Nekzali.lua", ns)
T.Load("Encounters/VenomousAbyss/Sentinels.lua", ns)
T.Load("Encounters/VenomousAbyss/Explorers.lua", ns)
T.Load("Encounters/VenomousAbyss/Vashnik.lua", ns)
T.Load("Encounters/VenomousAbyss/Sszorak.lua", ns)
T.Load("Encounters/VenomousAbyss/TwinFangs.lua", ns)
T.Load("Encounters/VenomousAbyss/CoiledAltar.lua", ns)
T.Load("Encounters/VenomousAbyss/Ulatek.lua", ns)

local Registry = ns:GetModule("Encounters.Registry")
local Assignments = ns:GetModule("Encounters.AssignmentRegistry")
local difficulties = { "normal", "heroic", "mythic" }
local encounters = Registry:GetOrdered()

assert(#encounters == 8, "ten-of-ten readiness requires exactly eight supported Venomous Abyss encounters")

local profileCount = 0
for _, encounter in ipairs(encounters) do
    assert(type(encounter.key) == "string" and encounter.key ~= "", "encounter requires a stable key")
    assert(type(encounter.name) == "string" and encounter.name ~= "", encounter.key .. " requires a display name")
    assert(type(encounter.encounterID) == "number", encounter.key .. " requires a numeric encounter ID")
    assert(type(encounter.strategyStatus) == "string" and encounter.strategyStatus ~= "", encounter.key .. " requires strategy provenance/status")

    for _, difficultyKey in ipairs(difficulties) do
        local profile = Registry:GetProfile(encounter.key, difficultyKey)
        assert(profile, encounter.key .. "/" .. difficultyKey .. " profile missing")
        profileCount = profileCount + 1

        assert(type(profile.explanation) == "table" and #profile.explanation > 0,
            encounter.key .. "/" .. difficultyKey .. " needs a pre-pull explanation")
        assert(type(profile.calls) == "table" and #profile.calls > 0,
            encounter.key .. "/" .. difficultyKey .. " needs raid-leader calls")
        assert(type(profile.callsByKey) == "table", encounter.key .. "/" .. difficultyKey .. " needs callsByKey")

        local seen = {}
        for _, call in ipairs(profile.calls) do
            assert(type(call.key) == "string" and call.key ~= "", "call requires key")
            assert(not seen[call.key], encounter.key .. "/" .. difficultyKey .. " duplicate call key " .. call.key)
            seen[call.key] = true
            assert(profile.callsByKey[call.key] == call, encounter.key .. "/" .. difficultyKey .. " callsByKey drift")
            assert(type(call.ability) == "string" and call.ability ~= "", encounter.key .. "/" .. call.key .. " needs ability")
            assert(type(call.warning) == "string" and call.warning ~= "", encounter.key .. "/" .. call.key .. " needs warning copy")
            assert(type(call.voice) == "string" and call.voice ~= "", encounter.key .. "/" .. call.key .. " needs voice identity")

            if encounter.key == "ulatek" then
                assert(call.timing == false, "Ula'tek must remain manual-only until live/provider timing is proven")
            end
        end

        local assignmentLayout = Assignments:GetLayout(encounter.key, difficultyKey)
        assert(type(assignmentLayout) == "table", encounter.key .. "/" .. difficultyKey .. " assignment layout missing")
        assert(type(assignmentLayout.summary) == "string" and assignmentLayout.summary ~= "",
            encounter.key .. "/" .. difficultyKey .. " assignment summary missing")
        assert(type(assignmentLayout.sections) == "table", encounter.key .. "/" .. difficultyKey .. " assignment sections missing")
    end
end

assert(profileCount == 24, "ten-of-ten readiness requires all 24 boss/difficulty profiles")

print("ok - ten-of-ten readiness contract covers 8 encounters, 24 profiles, calls, assignments and Ula'tek fail-closed timing")
