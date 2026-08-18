local _, ns = ...

local AssignmentRegistry = {}

local VALID_KINDS = {
    assignee = true,
    rotation = true,
    rule = true,
    sequence = true,
}

local function slot(key, label, options)
    options = options or {}
    return {
        key = key,
        label = label,
        kind = options.kind or (options.rotation and "rotation" or "assignee"),
        callKey = options.callKey,
        callLabel = options.callLabel,
        rotation = options.rotation,
        required = options.required == true,
        exactPlayers = options.exactPlayers,
        minPlayers = options.minPlayers,
        exclusiveGroup = options.exclusiveGroup,
        helper = options.helper,
    }
end

local function section(key, title, description, columns, slots)
    return {
        key = key,
        title = title,
        description = description,
        columns = columns or 1,
        slots = slots or {},
    }
end

local function layout(summary, sections)
    return { summary = summary, sections = sections or {} }
end

local PYRE = section("pyre", "Mythic Hungering Pyre", "Mythic strategy: configure the players represented by Groups 1+2 for the fixed Pyre soak team.", 1, {
    slot("pyre_soak", "Groups 1+2 Soak Team", { callKey = "pyre", callLabel = "SOAK", required = true }),
})

local CREMATION = section("cremation", "Cremation Rules", "Heroic+: Slithering Flame chooses its target dynamically. Store the movement rule instead of pretending a player can be preselected.", 2, {
    slot("cremation_left", "Left-side Rule", { kind = "rule", helper = "Example: left target burns the left corpse zone." }),
    slot("cremation_right", "Right-side Rule", { kind = "rule", helper = "Example: right target burns the right corpse zone." }),
})

local WELL = section("well", "Grasping Depths", "Mythic: alternate fresh teams into the Soulcoil Well because leaving applies Soul Exhaustion.", 2, {
    slot("well_a", "Well Team A", { callKey = "grasping", callLabel = "WELL A", rotation = "well", required = true, exclusiveGroup = "well" }),
    slot("well_b", "Well Team B", { callKey = "grasping", callLabel = "WELL B", rotation = "well", required = true, exclusiveGroup = "well" }),
})

local SENTINEL_SPLIT = section("split", "Raid Split", "Build two stable sides before the pull so marks and boss mechanics stay separated.", 2, {
    slot("breath_side", "Breath Side", { required = true, exclusiveGroup = "sentinel_side" }),
    slot("blood_side", "Blood Side", { required = true, exclusiveGroup = "sentinel_side" }),
})

local SENTINEL_STASIS = section("stasis", "Helical Toxin Groups", "Players clear Helical Toxins at exactly four applications. Put exactly four unique names in each configured group.", 2, {
    slot("stasis_a", "Group A", { callKey = "stasis", callLabel = "GROUP A", required = true, exactPlayers = 4, exclusiveGroup = "stasis" }),
    slot("stasis_b", "Group B", { callKey = "stasis", callLabel = "GROUP B", required = true, exactPlayers = 4, exclusiveGroup = "stasis" }),
    slot("stasis_c", "Group C", { callKey = "stasis", callLabel = "GROUP C", exactPlayers = 4, exclusiveGroup = "stasis" }),
    slot("stasis_d", "Group D", { callKey = "stasis", callLabel = "GROUP D", exactPlayers = 4, exclusiveGroup = "stasis" }),
    slot("stasis_e", "Group E", { callKey = "stasis", callLabel = "GROUP E", exactPlayers = 4, exclusiveGroup = "stasis" }),
})

local SENTINEL_HEAL = section("healers", "Blood-side Healer Jobs", "Optional names for predictable dispel ownership; actual debuff targets remain dynamic.", 2, {
    slot("blood_dispel_a", "Dispel A"),
    slot("blood_dispel_b", "Dispel B"),
})

local EXPLORER_CRATES_NORMAL = section("crates", "Crates & Fish", "Assign who opens crates and who gets the fish to an unused controlled tortollan.", 2, {
    slot("crate_a", "Crate Breaker", { callKey = "crates", callLabel = "BREAKER", required = true }),
    slot("fish_a", "Fish Runner", { callKey = "fish", callLabel = "RUNNER", required = true }),
})

local EXPLORER_CRATES_ROTATION = section("crates", "Crate Rotation", "Rotate distinct crate breakers so Splinters are controlled; Mythic crate breaks also damage the raid.", 3, {
    slot("crate_a", "Breaker 1", { callKey = "crates", callLabel = "BREAKER 1", rotation = "crates", required = true, exclusiveGroup = "crates" }),
    slot("crate_b", "Breaker 2", { callKey = "crates", callLabel = "BREAKER 2", rotation = "crates", required = true, exclusiveGroup = "crates" }),
    slot("crate_c", "Breaker 3", { callKey = "crates", callLabel = "BREAKER 3", rotation = "crates", exclusiveGroup = "crates" }),
})

local EXPLORER_FISH = section("fish", "Fish Runners", "Choose one or two reliable players who make sure Final Ascension is stopped with the fish.", 2, {
    slot("fish_a", "Runner 1", { callKey = "fish", callLabel = "RUNNER 1", rotation = "fish", required = true }),
    slot("fish_b", "Runner 2", { callKey = "fish", callLabel = "RUNNER 2", rotation = "fish" }),
})

local EXPLORER_THUD = section("thud", "Mighty Thud Soak Points", "The three targets are random. These are distinct groups waiting at soak points A, B and C; they are not preselected targets.", 3, {
    slot("thud_a", "Soak Point A", { callKey = "thud", callLabel = "POINT A", required = true, exclusiveGroup = "thud" }),
    slot("thud_b", "Soak Point B", { callKey = "thud", callLabel = "POINT B", required = true, exclusiveGroup = "thud" }),
    slot("thud_c", "Soak Point C", { callKey = "thud", callLabel = "POINT C", required = true, exclusiveGroup = "thud" }),
})

local VASHNIK_BILE = section("bile", "Catalytic Bile Coverage", "Heroic+: choose a mobile soak team. Members claim an unsoaked impact; RLA does not choose a live target.", 1, {
    slot("bile_team", "Bile Soak Team", { callKey = "catalyst", callLabel = "SOAK TEAM", required = true }),
})

local VASHNIK_FOUNTAINS = section("fountains", "Fountain Sequence", "Store the planned raid route. Each Imbibe still activates the two nearest fountains; this is tactic text, not a roster assignment.", 1, {
    slot("fountain_order", "Fountain Order", { kind = "sequence", helper = "FLAME > SHADOW > SHADOW > BLOOD > BLOOD > FLAME" }),
})

local VASHNIK_TUMOR = section("tumors", "Mythic Tumor Rules", "Plague Froth targets are random. Save lane rules so selected players know where to aim their waves.", 2, {
    slot("tumor_left", "Left Lane Rule", { kind = "rule", helper = "Example: left Froth aims through left Tumor lane." }),
    slot("tumor_right", "Right Lane Rule", { kind = "rule", helper = "Example: right Froth aims through right Tumor lane." }),
})

local SSZORAK_MUTILATE = section("mutilate", "Mutilate Rotation", "Every Mutilate needs at least five players. Use distinct teams because repeat Mutilate damage is heavily increased.", 3, {
    slot("mutilate_a", "Team A", { callKey = "apex", callLabel = "TEAM A", rotation = "mutilate", required = true, minPlayers = 5, exclusiveGroup = "mutilate" }),
    slot("mutilate_b", "Team B", { callKey = "apex", callLabel = "TEAM B", rotation = "mutilate", required = true, minPlayers = 5, exclusiveGroup = "mutilate" }),
    slot("mutilate_c", "Team C", { callKey = "apex", callLabel = "TEAM C", rotation = "mutilate", minPlayers = 5, exclusiveGroup = "mutilate" }),
})

local TWIN_FEAST = section("feast", "Ravenous Feast", "Three hits happen in quick succession. Every hit needs 3+ players and Feasted makes repeating a player unsafe.", 3, {
    slot("feast_a", "Hit 1 · Group A", { callKey = "feast", callLabel = "HIT 1 A", required = true, minPlayers = 3, exclusiveGroup = "feast" }),
    slot("feast_b", "Hit 2 · Group B", { callKey = "feast", callLabel = "HIT 2 B", required = true, minPlayers = 3, exclusiveGroup = "feast" }),
    slot("feast_c", "Hit 3 · Group C", { callKey = "feast", callLabel = "HIT 3 C", required = true, minPlayers = 3, exclusiveGroup = "feast" }),
})

local TWIN_STONE = section("stone", "Stone Breaker Rotation", "Never leave an impact empty. Use distinct soakers because Fractured increases later Stone Breaker damage.", 3, {
    slot("stone_a", "Breaker A", { callKey = "stone", callLabel = "A", rotation = "stone", required = true, exclusiveGroup = "stone" }),
    slot("stone_b", "Breaker B", { callKey = "stone", callLabel = "B", rotation = "stone", required = true, exclusiveGroup = "stone" }),
    slot("stone_c", "Breaker C", { callKey = "stone", callLabel = "C", rotation = "stone", exclusiveGroup = "stone" }),
})

local TWIN_BROOD = section("brood", "Broodling Interrupt Coverage", "Mythic: Broodlings can need coverage at the same time. Assign separate kick owners instead of one rotating interrupter.", 3, {
    slot("brood_kick_a", "Broodling 1 Kick", { callKey = "brood", callLabel = "KICK 1", required = true, exclusiveGroup = "brood" }),
    slot("brood_kick_b", "Broodling 2 Kick", { callKey = "brood", callLabel = "KICK 2", required = true, exclusiveGroup = "brood" }),
    slot("brood_kick_c", "Broodling 3 Kick", { callKey = "brood", callLabel = "KICK 3", exclusiveGroup = "brood" }),
})

local TWIN_BLOOD = section("tainted", "Tainted Blood", "Mythic: optional distinct coverage for blood founts created during Feast.", 2, {
    slot("tainted_a", "Fount Team A", { callKey = "tainted", callLabel = "FOUNT A", exclusiveGroup = "tainted" }),
    slot("tainted_b", "Fount Team B", { callKey = "tainted", callLabel = "FOUNT B", exclusiveGroup = "tainted" }),
})

local ALTAR_GUILLOTINE_NORMAL = section("guillotine", "Guillotine Soak Coverage", "Normal: every axe needs at least five players. Team B is an optional second coverage team; repeats are not forced.", 2, {
    slot("guillotine_a", "Team A", { callKey = "guillotine", callLabel = "TEAM A", rotation = "guillotine", required = true, minPlayers = 5 }),
    slot("guillotine_b", "Team B", { callKey = "guillotine", callLabel = "TEAM B", rotation = "guillotine", minPlayers = 5 }),
})

local ALTAR_GUILLOTINE_HEROIC = section("guillotine", "Guillotine Soak Rotation", "Heroic: each axe needs at least five fresh players because Guillotined increases repeat damage by 500%.", 2, {
    slot("guillotine_a", "Team A", { callKey = "guillotine", callLabel = "TEAM A", rotation = "guillotine", required = true, minPlayers = 5, exclusiveGroup = "guillotine" }),
    slot("guillotine_b", "Team B", { callKey = "guillotine", callLabel = "TEAM B", rotation = "guillotine", required = true, minPlayers = 5, exclusiveGroup = "guillotine" }),
})

local ALTAR_GUILLOTINE_MYTHIC = section("guillotine", "Guillotine Soak Rotation", "Mythic Guillotined is permanent, so plan fresh 5+ player teams for later axes.", 4, {
    slot("guillotine_a", "Team A", { callKey = "guillotine", callLabel = "TEAM A", rotation = "guillotine", required = true, minPlayers = 5, exclusiveGroup = "guillotine" }),
    slot("guillotine_b", "Team B", { callKey = "guillotine", callLabel = "TEAM B", rotation = "guillotine", required = true, minPlayers = 5, exclusiveGroup = "guillotine" }),
    slot("guillotine_c", "Team C", { callKey = "guillotine", callLabel = "TEAM C", rotation = "guillotine", required = true, minPlayers = 5, exclusiveGroup = "guillotine" }),
    slot("guillotine_d", "Team D", { callKey = "guillotine", callLabel = "TEAM D", rotation = "guillotine", minPlayers = 5, exclusiveGroup = "guillotine" }),
})

local ALTAR_KICKS = section("kicks", "Soulcoiler Interrupts", "Preassign Wail coverage. On Mythic the interrupt also briefly reveals hidden Manifestations of Dread.", 3, {
    slot("wail_kick_a", "Wail Kick A", { callKey = "spiritcackle", callLabel = "WAIL A", rotation = "wail", required = true }),
    slot("wail_kick_b", "Wail Kick B", { callKey = "spiritcackle", callLabel = "WAIL B", rotation = "wail" }),
    slot("wail_kick_c", "Wail Kick C", { callKey = "spiritcackle", callLabel = "WAIL C", rotation = "wail" }),
})

local ULATEK_EGG_NORMAL = section("eggs", "Doomscale Egg Handler", "Normal already has egg handling. Optionally name who owns that interaction before the pull.", 1, {
    slot("egg_handler", "Egg Handler"),
})

local ULATEK_COILS = section("coils", "Spectral Coil Rotation", "Mythic: alternate distinct groups because Soul Constrictor blocks the next soak for affected players.", 2, {
    slot("coil_a", "Coil Group A", { callKey = "coils", callLabel = "GROUP A", rotation = "coils", required = true, exclusiveGroup = "coils" }),
    slot("coil_b", "Coil Group B", { callKey = "coils", callLabel = "GROUP B", rotation = "coils", required = true, exclusiveGroup = "coils" }),
})

local ULATEK_EGGS_HEROIC = section("eggs", "Doomscale Eggs", "Heroic: Doomscale Eggs still need controlled handling. Assign one owner to each side before the pull.", 2, {
    slot("egg_left", "Left Egg Owner", { required = true }),
    slot("egg_right", "Right Egg Owner", { required = true }),
})

local ULATEK_EGGS_MYTHIC = section("eggs", "Doomscale Eggs", "Mythic: assign each side before the pull and keep carriers separated while handling Noxious Shell.", 2, {
    slot("egg_left", "Left Egg Carrier", { callKey = "eggs", callLabel = "LEFT", required = true }),
    slot("egg_right", "Right Egg Carrier", { callKey = "eggs", callLabel = "RIGHT", required = true }),
})

local ULATEK_INCUBATION = section("incubation", "Toxic Incubation Intercepts", "Mythic: rotate distinct players because Toxic Burn increases repeat Incubation damage by 200%.", 3, {
    slot("incubation_a", "Intercept A", { callKey = "incubation", callLabel = "A", rotation = "incubation", required = true, exclusiveGroup = "incubation" }),
    slot("incubation_b", "Intercept B", { callKey = "incubation", callLabel = "B", rotation = "incubation", required = true, exclusiveGroup = "incubation" }),
    slot("incubation_c", "Intercept C", { callKey = "incubation", callLabel = "C", rotation = "incubation", required = true, exclusiveGroup = "incubation" }),
})

local LAYOUTS = {
    nekzali = {
        normal = layout("Role-based plan: melee soak and ranged spread need no fixed player assignment.", {}),
        heroic = layout("Role-based Pyre/Cremation plan; only static corpse-burn movement rules need configuration.", { CREMATION }),
        mythic = layout("Fixed Groups 1+2 Pyre soak, alternating Well teams and static Cremation movement rules.", { PYRE, WELL, CREMATION }),
    },
    sentinels = {
        normal = layout("Split the raid first, then build exact four-player Stasis groups.", { SENTINEL_SPLIT, SENTINEL_STASIS, SENTINEL_HEAL }),
        heroic = layout("Stable boss sides, Stasis fours and optional Blood dispel ownership.", { SENTINEL_SPLIT, SENTINEL_STASIS, SENTINEL_HEAL }),
        mythic = layout("Stable sides and complete four-player Stasis planning; Protovenom remains a dynamic matching rule.", { SENTINEL_SPLIT, SENTINEL_STASIS, SENTINEL_HEAL }),
    },
    explorers = {
        normal = layout("One clear crate/fish owner plus three soak-point groups for random Thud targets.", { EXPLORER_CRATES_NORMAL, EXPLORER_THUD }),
        heroic = layout("Rotate crate breakers, keep fish responsibility explicit and define three Thud soak points.", { EXPLORER_CRATES_ROTATION, EXPLORER_FISH, EXPLORER_THUD }),
        mythic = layout("Strict crate rotation because Mythic breaks hit the raid, plus fish and Thud planning.", { EXPLORER_CRATES_ROTATION, EXPLORER_FISH, EXPLORER_THUD }),
    },
    vashnik = {
        normal = layout("No mandatory named assignment; save only the planned fountain sequence.", { VASHNIK_FOUNTAINS }),
        heroic = layout("Mobile Catalytic Bile coverage plus the planned fountain sequence.", { VASHNIK_BILE, VASHNIK_FOUNTAINS }),
        mythic = layout("Bile coverage, fountain sequence and Tumor lane rules; Froth targets themselves stay dynamic.", { VASHNIK_BILE, VASHNIK_FOUNTAINS, VASHNIK_TUMOR }),
    },
    sszorak = {
        normal = layout("The assignment screen is almost entirely the Mutilate rotation.", { SSZORAK_MUTILATE }),
        heroic = layout("The assignment screen is almost entirely the Mutilate rotation.", { SSZORAK_MUTILATE }),
        mythic = layout("Mutilate rotation remains the fixed assignment; Serpent's Fury targets are dynamic.", { SSZORAK_MUTILATE }),
    },
    twinfangs = {
        normal = layout("Three distinct 3+ Feast groups and a separate Stone Breaker rotation.", { TWIN_FEAST, TWIN_STONE }),
        heroic = layout("Three distinct 3+ Feast groups are critical because Feasted punishes repeats; keep Stone Breaker separate.", { TWIN_FEAST, TWIN_STONE }),
        mythic = layout("Feast, Stone Breaker, simultaneous Broodling kick coverage and optional Tainted Blood coverage each get their own block.", { TWIN_FEAST, TWIN_STONE, TWIN_BROOD, TWIN_BLOOD }),
    },
    altar = {
        normal = layout("One required 5+ Guillotine team plus optional second coverage; interrupts stay lightweight.", { ALTAR_GUILLOTINE_NORMAL, ALTAR_KICKS }),
        heroic = layout("Rotate distinct Guillotine teams and preassign Wail interrupts.", { ALTAR_GUILLOTINE_HEROIC, ALTAR_KICKS }),
        mythic = layout("Fresh Guillotine teams are the dominant assignment, with a dedicated Wail interrupt rotation.", { ALTAR_GUILLOTINE_MYTHIC, ALTAR_KICKS }),
    },
    ulatek = {
        normal = layout("Only optional egg ownership is useful as a fixed pre-pull responsibility on Normal.", { ULATEK_EGG_NORMAL }),
        heroic = layout("Assign one owner to each Doomscale Egg side; Heroic Coil and Fangs targets stay live and dynamic.", { ULATEK_EGGS_HEROIC }),
        mythic = layout("Coil rotation, egg-side carriers and a dedicated Toxic Incubation intercept rotation.", { ULATEK_COILS, ULATEK_EGGS_MYTHIC, ULATEK_INCUBATION }),
    },
}

local VALID_DIFFICULTIES = { normal = true, heroic = true, mythic = true }

local function validateLayouts()
    for bossKey, difficulties in pairs(LAYOUTS) do
        assert(type(bossKey) == "string" and type(difficulties) == "table", "Invalid assignment boss")
        for difficultyKey, profile in pairs(difficulties) do
            assert(VALID_DIFFICULTIES[difficultyKey], "Invalid assignment difficulty: " .. tostring(difficultyKey))
            assert(type(profile.summary) == "string", "Assignment layout requires summary")
            assert(type(profile.sections) == "table", "Assignment layout requires sections")
            local seen = {}
            for sectionIndex = 1, #profile.sections do
                local item = profile.sections[sectionIndex]
                assert(type(item.key) == "string" and type(item.title) == "string", "Assignment section requires identity")
                assert(type(item.columns) == "number" and item.columns >= 1 and item.columns <= 4, "Invalid assignment columns")
                for slotIndex = 1, #item.slots do
                    local definition = item.slots[slotIndex]
                    assert(type(definition.key) == "string" and definition.key ~= "", "Assignment requires key")
                    assert(type(definition.label) == "string" and definition.label ~= "", "Assignment requires label")
                    assert(VALID_KINDS[definition.kind], "Invalid assignment kind: " .. tostring(definition.kind))
                    assert(not seen[definition.key], "Duplicate assignment key: " .. bossKey .. "/" .. difficultyKey .. "/" .. definition.key)
                    if definition.rotation ~= nil then
                        assert(definition.kind == "rotation", "Rotating assignment must use rotation kind")
                        assert(type(definition.rotation) == "string" and definition.rotation ~= "", "Invalid rotation")
                    end
                    if definition.exactPlayers ~= nil then assert(definition.exactPlayers >= 1, "Invalid exactPlayers") end
                    if definition.minPlayers ~= nil then assert(definition.minPlayers >= 1, "Invalid minPlayers") end
                    assert(not (definition.exactPlayers and definition.minPlayers), "Assignment cannot require both exactPlayers and minPlayers")
                    if definition.exclusiveGroup ~= nil then
                        assert(definition.kind == "assignee" or definition.kind == "rotation", "exclusiveGroup requires a roster-like field")
                        assert(type(definition.exclusiveGroup) == "string" and definition.exclusiveGroup ~= "", "Invalid exclusiveGroup")
                    end
                    seen[definition.key] = true
                end
            end
        end
    end
end

validateLayouts()

function AssignmentRegistry:GetLayout(bossKey, difficultyKey)
    local boss = LAYOUTS[bossKey]
    return boss and boss[difficultyKey] or layout("No assignment template for this encounter.", {})
end

function AssignmentRegistry:GetDefinitions(bossKey, difficultyKey)
    local result = {}
    local profile = self:GetLayout(bossKey, difficultyKey)
    for sectionIndex = 1, #profile.sections do
        local item = profile.sections[sectionIndex]
        for slotIndex = 1, #item.slots do result[#result + 1] = item.slots[slotIndex] end
    end
    return result
end

function AssignmentRegistry:GetCallDefinitions(bossKey, difficultyKey, callKey)
    local result = {}
    local definitions = self:GetDefinitions(bossKey, difficultyKey)
    for index = 1, #definitions do
        if definitions[index].callKey == callKey then result[#result + 1] = definitions[index] end
    end
    return result
end

function AssignmentRegistry:GetBossKeys()
    local result = {}
    for bossKey in pairs(LAYOUTS) do result[#result + 1] = bossKey end
    table.sort(result)
    return result
end

ns:RegisterModule("Encounters.AssignmentRegistry", AssignmentRegistry)
