local _, ns = ...

local AssignmentRegistry = {}

local DEFINITIONS = {
    nekzali = {
        normal = {
            { key = "pyre_soak", label = "Pyre Soak Team", callKey = "pyre", callLabel = "SOAK", required = true },
        },
        heroic = {
            { key = "pyre_soak", label = "Pyre Soak Team", callKey = "pyre", callLabel = "SOAK", required = true },
            { key = "cremation_left", label = "Cremation Left", helper = "Player or small team responsible for the left-side remains." },
            { key = "cremation_right", label = "Cremation Right", helper = "Player or small team responsible for the right-side remains." },
        },
        mythic = {
            { key = "pyre_soak", label = "Pyre Soak Team", callKey = "pyre", callLabel = "SOAK", required = true },
            { key = "well_a", label = "Well Team A", callKey = "grasping", callLabel = "WELL A", rotation = "well", required = true },
            { key = "well_b", label = "Well Team B", callKey = "grasping", callLabel = "WELL B", rotation = "well", required = true },
            { key = "cremation_left", label = "Cremation Left", helper = "Player or small team responsible for the left-side remains." },
            { key = "cremation_right", label = "Cremation Right", helper = "Player or small team responsible for the right-side remains." },
        },
    },
    sentinels = {
        normal = {
            { key = "breath_side", label = "Breath Side", helper = "Players assigned to the breath-side boss." },
            { key = "blood_side", label = "Blood Side", helper = "Players assigned to the blood-side boss." },
            { key = "stasis_a", label = "Stasis Group A", callKey = "stasis", callLabel = "A", required = true },
            { key = "stasis_b", label = "Stasis Group B", callKey = "stasis", callLabel = "B", required = true },
            { key = "stasis_c", label = "Stasis Group C", callKey = "stasis", callLabel = "C" },
            { key = "stasis_d", label = "Stasis Group D", callKey = "stasis", callLabel = "D" },
            { key = "stasis_e", label = "Stasis Group E", callKey = "stasis", callLabel = "E" },
        },
        heroic = {
            { key = "breath_side", label = "Breath Side", helper = "Players assigned to the breath-side boss." },
            { key = "blood_side", label = "Blood Side", helper = "Players assigned to the blood-side boss." },
            { key = "stasis_a", label = "Stasis Group A", callKey = "stasis", callLabel = "A", required = true },
            { key = "stasis_b", label = "Stasis Group B", callKey = "stasis", callLabel = "B", required = true },
            { key = "stasis_c", label = "Stasis Group C", callKey = "stasis", callLabel = "C" },
            { key = "stasis_d", label = "Stasis Group D", callKey = "stasis", callLabel = "D" },
            { key = "stasis_e", label = "Stasis Group E", callKey = "stasis", callLabel = "E" },
        },
        mythic = {
            { key = "breath_side", label = "Breath Side", helper = "Players assigned to the breath-side boss." },
            { key = "blood_side", label = "Blood Side", helper = "Players assigned to the blood-side boss." },
            { key = "stasis_a", label = "Stasis Group A", callKey = "stasis", callLabel = "A", required = true },
            { key = "stasis_b", label = "Stasis Group B", callKey = "stasis", callLabel = "B", required = true },
            { key = "stasis_c", label = "Stasis Group C", callKey = "stasis", callLabel = "C", required = true },
            { key = "stasis_d", label = "Stasis Group D", callKey = "stasis", callLabel = "D", required = true },
            { key = "stasis_e", label = "Stasis Group E", callKey = "stasis", callLabel = "E", required = true },
        },
    },
    explorers = {
        normal = {
            { key = "crate_a", label = "Crate Breaker A", callKey = "crates", callLabel = "BREAKER A", rotation = "crates", required = true },
            { key = "crate_b", label = "Crate Breaker B", callKey = "crates", callLabel = "BREAKER B", rotation = "crates", required = true },
            { key = "fish_a", label = "Fish Runner A", callKey = "fish", callLabel = "RUNNER A", rotation = "fish", required = true },
            { key = "fish_b", label = "Fish Runner B", callKey = "fish", callLabel = "RUNNER B", rotation = "fish" },
            { key = "thud_a", label = "Thud Group A", callKey = "thud", callLabel = "A", required = true },
            { key = "thud_b", label = "Thud Group B", callKey = "thud", callLabel = "B", required = true },
            { key = "thud_c", label = "Thud Group C", callKey = "thud", callLabel = "C", required = true },
        },
        heroic = {
            { key = "crate_a", label = "Crate Breaker A", callKey = "crates", callLabel = "BREAKER A", rotation = "crates", required = true },
            { key = "crate_b", label = "Crate Breaker B", callKey = "crates", callLabel = "BREAKER B", rotation = "crates", required = true },
            { key = "crate_c", label = "Crate Breaker C", callKey = "crates", callLabel = "BREAKER C", rotation = "crates" },
            { key = "fish_a", label = "Fish Runner A", callKey = "fish", callLabel = "RUNNER A", rotation = "fish", required = true },
            { key = "fish_b", label = "Fish Runner B", callKey = "fish", callLabel = "RUNNER B", rotation = "fish" },
            { key = "thud_a", label = "Thud Group A", callKey = "thud", callLabel = "A", required = true },
            { key = "thud_b", label = "Thud Group B", callKey = "thud", callLabel = "B", required = true },
            { key = "thud_c", label = "Thud Group C", callKey = "thud", callLabel = "C", required = true },
        },
        mythic = {
            { key = "crate_a", label = "Crate Breaker A", callKey = "crates", callLabel = "BREAKER A", rotation = "crates", required = true },
            { key = "crate_b", label = "Crate Breaker B", callKey = "crates", callLabel = "BREAKER B", rotation = "crates", required = true },
            { key = "crate_c", label = "Crate Breaker C", callKey = "crates", callLabel = "BREAKER C", rotation = "crates", required = true },
            { key = "fish_a", label = "Fish Runner A", callKey = "fish", callLabel = "RUNNER A", rotation = "fish", required = true },
            { key = "fish_b", label = "Fish Runner B", callKey = "fish", callLabel = "RUNNER B", rotation = "fish" },
            { key = "thud_a", label = "Thud Group A", callKey = "thud", callLabel = "A", required = true },
            { key = "thud_b", label = "Thud Group B", callKey = "thud", callLabel = "B", required = true },
            { key = "thud_c", label = "Thud Group C", callKey = "thud", callLabel = "C", required = true },
        },
    },
    vashnik = {
        normal = {},
        heroic = {
            { key = "bile_left", label = "Bile Left", callKey = "catalyst", callLabel = "LEFT", required = true },
            { key = "bile_middle", label = "Bile Middle", callKey = "catalyst", callLabel = "MID", required = true },
            { key = "bile_right", label = "Bile Right", callKey = "catalyst", callLabel = "RIGHT", required = true },
        },
        mythic = {
            { key = "bile_left", label = "Bile Left", callKey = "catalyst", callLabel = "LEFT", required = true },
            { key = "bile_middle", label = "Bile Middle", callKey = "catalyst", callLabel = "MID", required = true },
            { key = "bile_right", label = "Bile Right", callKey = "catalyst", callLabel = "RIGHT", required = true },
        },
    },
    sszorak = {
        normal = {
            { key = "mutilate_a", label = "Mutilate Team A", callKey = "apex", callLabel = "TEAM A", rotation = "mutilate", required = true },
            { key = "mutilate_b", label = "Mutilate Team B", callKey = "apex", callLabel = "TEAM B", rotation = "mutilate", required = true },
            { key = "mutilate_c", label = "Mutilate Team C", callKey = "apex", callLabel = "TEAM C", rotation = "mutilate" },
        },
        heroic = {
            { key = "mutilate_a", label = "Mutilate Team A", callKey = "apex", callLabel = "TEAM A", rotation = "mutilate", required = true },
            { key = "mutilate_b", label = "Mutilate Team B", callKey = "apex", callLabel = "TEAM B", rotation = "mutilate", required = true },
            { key = "mutilate_c", label = "Mutilate Team C", callKey = "apex", callLabel = "TEAM C", rotation = "mutilate" },
        },
        mythic = {
            { key = "mutilate_a", label = "Mutilate Team A", callKey = "apex", callLabel = "TEAM A", rotation = "mutilate", required = true },
            { key = "mutilate_b", label = "Mutilate Team B", callKey = "apex", callLabel = "TEAM B", rotation = "mutilate", required = true },
            { key = "mutilate_c", label = "Mutilate Team C", callKey = "apex", callLabel = "TEAM C", rotation = "mutilate", required = true },
        },
    },
    twinfangs = {
        normal = {
            { key = "feast_a", label = "Feast Group A", callKey = "feast", callLabel = "A", required = true },
            { key = "feast_b", label = "Feast Group B", callKey = "feast", callLabel = "B", required = true },
            { key = "feast_c", label = "Feast Group C", callKey = "feast", callLabel = "C", required = true },
            { key = "stone_a", label = "Stone Breaker A", callKey = "stone", callLabel = "A", rotation = "stone", required = true },
            { key = "stone_b", label = "Stone Breaker B", callKey = "stone", callLabel = "B", rotation = "stone", required = true },
            { key = "stone_c", label = "Stone Breaker C", callKey = "stone", callLabel = "C", rotation = "stone" },
        },
        heroic = {
            { key = "feast_a", label = "Feast Group A", callKey = "feast", callLabel = "A", required = true },
            { key = "feast_b", label = "Feast Group B", callKey = "feast", callLabel = "B", required = true },
            { key = "feast_c", label = "Feast Group C", callKey = "feast", callLabel = "C", required = true },
            { key = "stone_a", label = "Stone Breaker A", callKey = "stone", callLabel = "A", rotation = "stone", required = true },
            { key = "stone_b", label = "Stone Breaker B", callKey = "stone", callLabel = "B", rotation = "stone", required = true },
            { key = "stone_c", label = "Stone Breaker C", callKey = "stone", callLabel = "C", rotation = "stone" },
        },
        mythic = {
            { key = "feast_a", label = "Feast Group A", callKey = "feast", callLabel = "A", required = true },
            { key = "feast_b", label = "Feast Group B", callKey = "feast", callLabel = "B", required = true },
            { key = "feast_c", label = "Feast Group C", callKey = "feast", callLabel = "C", required = true },
            { key = "stone_a", label = "Stone Breaker A", callKey = "stone", callLabel = "A", rotation = "stone", required = true },
            { key = "stone_b", label = "Stone Breaker B", callKey = "stone", callLabel = "B", rotation = "stone", required = true },
            { key = "stone_c", label = "Stone Breaker C", callKey = "stone", callLabel = "C", rotation = "stone", required = true },
            { key = "brood_kick_a", label = "Brood Kick A", callKey = "brood", callLabel = "KICK A", required = true },
            { key = "brood_kick_b", label = "Brood Kick B", callKey = "brood", callLabel = "KICK B", required = true },
            { key = "brood_kick_c", label = "Brood Kick C", callKey = "brood", callLabel = "KICK C" },
        },
    },
    altar = {
        normal = {
            { key = "guillotine_a", label = "Guillotine Team A", callKey = "guillotine", callLabel = "TEAM A", rotation = "guillotine", required = true },
            { key = "guillotine_b", label = "Guillotine Team B", callKey = "guillotine", callLabel = "TEAM B", rotation = "guillotine", required = true },
            { key = "night_kick_a", label = "Nightfall Kick A", callKey = "nightfall", callLabel = "KICK A", rotation = "nightfall", required = true },
            { key = "night_kick_b", label = "Nightfall Kick B", callKey = "nightfall", callLabel = "KICK B", rotation = "nightfall" },
        },
        heroic = {
            { key = "guillotine_a", label = "Guillotine Team A", callKey = "guillotine", callLabel = "TEAM A", rotation = "guillotine", required = true },
            { key = "guillotine_b", label = "Guillotine Team B", callKey = "guillotine", callLabel = "TEAM B", rotation = "guillotine", required = true },
            { key = "night_kick_a", label = "Nightfall Kick A", callKey = "nightfall", callLabel = "KICK A", rotation = "nightfall", required = true },
            { key = "night_kick_b", label = "Nightfall Kick B", callKey = "nightfall", callLabel = "KICK B", rotation = "nightfall" },
            { key = "wail_kick_a", label = "Wail Kick A", callKey = "spiritcackle", callLabel = "WAIL A", rotation = "wail", required = true },
            { key = "wail_kick_b", label = "Wail Kick B", callKey = "spiritcackle", callLabel = "WAIL B", rotation = "wail" },
        },
        mythic = {
            { key = "guillotine_a", label = "Guillotine Team A", callKey = "guillotine", callLabel = "TEAM A", rotation = "guillotine", required = true },
            { key = "guillotine_b", label = "Guillotine Team B", callKey = "guillotine", callLabel = "TEAM B", rotation = "guillotine", required = true },
            { key = "guillotine_c", label = "Guillotine Team C", callKey = "guillotine", callLabel = "TEAM C", rotation = "guillotine", required = true },
            { key = "guillotine_d", label = "Guillotine Team D", callKey = "guillotine", callLabel = "TEAM D", rotation = "guillotine" },
            { key = "night_kick_a", label = "Nightfall Kick A", callKey = "nightfall", callLabel = "KICK A", rotation = "nightfall", required = true },
            { key = "night_kick_b", label = "Nightfall Kick B", callKey = "nightfall", callLabel = "KICK B", rotation = "nightfall" },
            { key = "wail_kick_a", label = "Wail Kick A", callKey = "spiritcackle", callLabel = "WAIL A", rotation = "wail", required = true },
            { key = "wail_kick_b", label = "Wail Kick B", callKey = "spiritcackle", callLabel = "WAIL B", rotation = "wail", required = true },
            { key = "wail_kick_c", label = "Wail Kick C", callKey = "spiritcackle", callLabel = "WAIL C", rotation = "wail" },
        },
    },
    ulatek = {
        normal = {},
        heroic = {
            { key = "coil_a", label = "Coil Group A", callKey = "coils", callLabel = "GROUP A", rotation = "coils", required = true },
            { key = "coil_b", label = "Coil Group B", callKey = "coils", callLabel = "GROUP B", rotation = "coils", required = true },
        },
        mythic = {
            { key = "coil_a", label = "Coil Group A", callKey = "coils", callLabel = "GROUP A", rotation = "coils", required = true },
            { key = "coil_b", label = "Coil Group B", callKey = "coils", callLabel = "GROUP B", rotation = "coils", required = true },
            { key = "egg_left", label = "Egg Carrier Left", callKey = "eggs", callLabel = "LEFT", required = true },
            { key = "egg_right", label = "Egg Carrier Right", callKey = "eggs", callLabel = "RIGHT", required = true },
            { key = "incubation_a", label = "Incubation A", callKey = "incubation", callLabel = "A", rotation = "incubation", required = true },
            { key = "incubation_b", label = "Incubation B", callKey = "incubation", callLabel = "B", rotation = "incubation", required = true },
            { key = "incubation_c", label = "Incubation C", callKey = "incubation", callLabel = "C", rotation = "incubation", required = true },
        },
    },
}

local VALID_DIFFICULTIES = { normal = true, heroic = true, mythic = true }

local function validateDefinitions()
    for bossKey, profiles in pairs(DEFINITIONS) do
        assert(type(bossKey) == "string" and type(profiles) == "table", "Invalid assignment boss definition")
        for difficultyKey, definitions in pairs(profiles) do
            assert(VALID_DIFFICULTIES[difficultyKey], "Invalid assignment difficulty: " .. tostring(difficultyKey))
            assert(type(definitions) == "table", "Assignment definitions require a list")
            local seen = {}
            for index = 1, #definitions do
                local definition = definitions[index]
                assert(type(definition.key) == "string" and definition.key ~= "", "Assignment requires key")
                assert(type(definition.label) == "string" and definition.label ~= "", "Assignment requires label")
                assert(not seen[definition.key], "Duplicate assignment key: " .. bossKey .. "/" .. difficultyKey .. "/" .. definition.key)
                if definition.callKey ~= nil then assert(type(definition.callKey) == "string" and definition.callKey ~= "", "Invalid assignment callKey") end
                if definition.rotation ~= nil then assert(type(definition.rotation) == "string" and definition.rotation ~= "", "Invalid assignment rotation") end
                seen[definition.key] = true
            end
        end
    end
end

validateDefinitions()

function AssignmentRegistry:GetDefinitions(bossKey, difficultyKey)
    local boss = DEFINITIONS[bossKey]
    return (boss and boss[difficultyKey]) or {}
end

function AssignmentRegistry:GetCallDefinitions(bossKey, difficultyKey, callKey)
    local result = {}
    local definitions = self:GetDefinitions(bossKey, difficultyKey)
    for index = 1, #definitions do
        local definition = definitions[index]
        if definition.callKey == callKey then result[#result + 1] = definition end
    end
    return result
end

function AssignmentRegistry:GetBossKeys()
    local result = {}
    for bossKey in pairs(DEFINITIONS) do result[#result + 1] = bossKey end
    table.sort(result)
    return result
end

ns:RegisterModule("Encounters.AssignmentRegistry", AssignmentRegistry)
