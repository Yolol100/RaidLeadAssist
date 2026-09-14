local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss12AssignmentOverride.lua", ns)
T.Load("Encounters/Boss34AssignmentOverride.lua", ns)
T.Load("Encounters/SszorakAssignmentOverride.lua", ns)
T.Load("Encounters/TwinFangsAssignmentOverride.lua", ns)
T.Load("Encounters/Boss78AssignmentOverride.lua", ns)
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
local difficulties = { "heroic", "mythic" }
local encounters = Registry:GetOrdered()
local ulatekTimed = {
    waves = true,
    coils = true,
    heart = true,
    serpents = true,
    bite = true,
    circling = true,
}

assert(#encounters == 8, "readiness requires exactly eight supported Venomous Abyss encounters")

local profileCount = 0
for _, encounter in ipairs(encounters) do
    assert(type(encounter.key) == "string" and encounter.key ~= "", "encounter requires a stable key")
    assert(type(encounter.name) == "string" and encounter.name ~= "", encounter.key .. " requires a display name")
    assert(type(encounter.encounterID) == "number", encounter.key .. " requires a numeric encounter ID")
    assert(type(encounter.strategyStatus) == "string" and encounter.strategyStatus ~= "", encounter.key .. " requires strategy provenance/status")
    assert(Registry:GetProfile(encounter.key, "normal") == nil,
        encounter.key .. " Normal profile must remain retired")
    if encounter.key == "ulatek" then
        assert(encounter.strategyStatus:find("PASS-LIVE pending", 1, true),
            "Ula'tek selected source/CI timing must remain explicitly gated from PASS-LIVE")
    end

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
                local providerTimed = ulatekTimed[call.key] or (difficultyKey == "mythic" and call.key == "incubation")
                if providerTimed then
                    assert(call.timing ~= false,
                        "reviewed Ula'tek provider-timed call unexpectedly disabled: " .. difficultyKey .. "/" .. call.key)
                    assert(type(call.spellIDs) == "table" and #call.spellIDs > 0,
                        "provider-timed Ula'tek call requires a reviewed public spell identity: " .. call.key)
                else
                    assert(call.timing == false,
                        "unreviewed Ula'tek strategy milestone must remain manual: " .. difficultyKey .. "/" .. call.key)
                end
            end
        end

        local assignmentLayout = Assignments:GetLayout(encounter.key, difficultyKey)
        Assignments:ValidateLayout(encounter.key, difficultyKey, assignmentLayout)
        assert(type(assignmentLayout.summary) == "string" and assignmentLayout.summary ~= "",
            encounter.key .. "/" .. difficultyKey .. " assignment summary missing")
        assert(type(assignmentLayout.sections) == "table", encounter.key .. "/" .. difficultyKey .. " assignment sections missing")
        assert(not assignmentLayout.summary:find("Assignment override unavailable", 1, true),
            encounter.key .. "/" .. difficultyKey .. " must use the runtime encounter override, not the fail-closed base fallback")
    end
end

assert(profileCount == 16, "readiness requires all 16 supported boss/difficulty profiles")

print("ok - full readiness covers 8 encounters, 16 Heroic/Mythic profiles, bounded Ula'tek timing and runtime assignment overrides")
