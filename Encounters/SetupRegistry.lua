local _, ns = ...

local SetupRegistry = {
    layouts = {},
}

local BOSS_KEYS = {
    "altar",
    "explorers",
    "nekzali",
    "sentinels",
    "sszorak",
    "twinfangs",
    "ulatek",
    "vashnik",
}

local VALID_BOSSES = {}
for index = 1, #BOSS_KEYS do VALID_BOSSES[BOSS_KEYS[index]] = true end

local VALID_DIFFICULTIES = { normal = true, heroic = true, mythic = true }
local VALID_KINDS = { world = true, target = true }
local MARKER_NAMES = {
    [1] = "Star",
    [2] = "Circle",
    [3] = "Diamond",
    [4] = "Triangle",
    [5] = "Moon",
    [6] = "Square",
    [7] = "Cross",
    [8] = "Skull",
}

local function fallbackLayout(bossKey, difficultyKey)
    return {
        summary = ("No fixed pre-pull marker setup for %s/%s."):format(tostring(bossKey), tostring(difficultyKey)),
        markers = {},
        checks = {},
    }
end

function SetupRegistry:ValidateLayout(bossKey, difficultyKey, profile)
    assert(VALID_BOSSES[bossKey], "Unknown setup boss: " .. tostring(bossKey))
    assert(VALID_DIFFICULTIES[difficultyKey], "Invalid setup difficulty: " .. tostring(difficultyKey))
    assert(type(profile) == "table", "Setup layout must be a table")
    assert(type(profile.summary) == "string" and profile.summary ~= "", "Setup layout requires summary")
    assert(#profile.summary <= 160, "Setup summary is too long")
    assert(type(profile.markers) == "table", "Setup layout requires markers")
    assert(type(profile.checks) == "table", "Setup layout requires checks")

    local seenKeys = {}
    local seenIcons = {}
    for index = 1, #profile.markers do
        local marker = profile.markers[index]
        assert(type(marker) == "table", "Setup marker must be a table")
        assert(type(marker.key) == "string" and marker.key ~= "", "Setup marker requires key")
        assert(not seenKeys[marker.key], "Duplicate setup marker key: " .. bossKey .. "/" .. difficultyKey .. "/" .. marker.key)
        assert(VALID_KINDS[marker.kind], "Invalid setup marker kind: " .. tostring(marker.kind))
        assert(type(marker.icon) == "number" and marker.icon >= 1 and marker.icon <= 8 and marker.icon == math.floor(marker.icon),
            "Setup marker icon must be an integer from 1 through 8")
        assert(not seenIcons[marker.kind .. ":" .. marker.icon],
            "Duplicate setup marker icon: " .. bossKey .. "/" .. difficultyKey .. "/" .. marker.kind .. "/" .. marker.icon)
        assert(type(marker.label) == "string" and marker.label ~= "", "Setup marker requires label")
        assert(#marker.label <= 32, "Setup marker label is too long")
        assert(type(marker.purpose) == "string" and marker.purpose ~= "", "Setup marker requires purpose")
        assert(#marker.purpose <= 160, "Setup marker purpose is too long")

        seenKeys[marker.key] = true
        seenIcons[marker.kind .. ":" .. marker.icon] = true
    end

    for index = 1, #profile.checks do
        local check = profile.checks[index]
        assert(type(check) == "string" and check ~= "", "Setup check must be a non-empty string")
        assert(#check <= 180, "Setup check is too long")
    end

    return profile
end

function SetupRegistry:Register(bossKey, difficultyKey, profile)
    self:ValidateLayout(bossKey, difficultyKey, profile)
    self.layouts[bossKey] = self.layouts[bossKey] or {}
    assert(self.layouts[bossKey][difficultyKey] == nil,
        "Duplicate setup layout: " .. bossKey .. "/" .. difficultyKey)
    self.layouts[bossKey][difficultyKey] = profile
end

function SetupRegistry:RegisterLayouts(bossKey, layouts)
    assert(type(layouts) == "table", "Setup layouts must be a table")
    for _, difficultyKey in ipairs({ "normal", "heroic", "mythic" }) do
        local profile = layouts[difficultyKey]
        if profile then self:Register(bossKey, difficultyKey, profile) end
    end
end

function SetupRegistry:GetLayout(bossKey, difficultyKey)
    local boss = self.layouts[bossKey]
    local profile = boss and boss[difficultyKey]
    return profile or fallbackLayout(bossKey, difficultyKey)
end

function SetupRegistry:HasSetup(bossKey, difficultyKey)
    local profile = self:GetLayout(bossKey, difficultyKey)
    return #profile.markers > 0 or #profile.checks > 0
end

function SetupRegistry:GetCounts(bossKey, difficultyKey)
    local profile = self:GetLayout(bossKey, difficultyKey)
    local world, target = 0, 0
    for index = 1, #profile.markers do
        if profile.markers[index].kind == "world" then world = world + 1 else target = target + 1 end
    end
    return world, target, #profile.checks
end

function SetupRegistry:GetMarkerName(icon)
    return MARKER_NAMES[icon]
end

function SetupRegistry:GetBossKeys()
    local result = {}
    for index = 1, #BOSS_KEYS do result[index] = BOSS_KEYS[index] end
    return result
end

ns:RegisterModule("Encounters.SetupRegistry", SetupRegistry)
