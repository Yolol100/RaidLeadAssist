local _, ns = ...

local Util = ns:GetModule("Core.Util")

local Database = {
    SCHEMA_VERSION = 6,
    newerSchemaDetected = false,
}

local VALID_POINTS = {
    TOPLEFT = true, TOP = true, TOPRIGHT = true,
    LEFT = true, CENTER = true, RIGHT = true,
    BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}

local VALID_DIFFICULTIES = {
    normal = true,
    heroic = true,
    mythic = true,
}

local function cloneValue(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return nil end

    local copy = {}
    seen[value] = copy
    for key, child in pairs(value) do
        local keyType = type(key)
        if keyType == "string" or keyType == "number" then
            copy[key] = cloneValue(child, seen)
        end
    end
    return copy
end

local DEFAULTS = {
    schemaVersion = 6,
    selectedBossKey = "nekzali",
    selectedDifficultyKey = "heroic",
    audioEnabled = true,
    automaticTimingEnabled = true,
    forceShown = false,
    customMessages = {},
    assignments = {},
    assignmentPresets = {},
    position = {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 40,
    },
}

function Database:Initialize()
    local stored = type(RaidLeadAssistDB) == "table" and RaidLeadAssistDB or {}
    local storedVersion = tonumber(stored.schemaVersion) or 0

    if storedVersion > self.SCHEMA_VERSION then
        self.newerSchemaDetected = true
        self.data = Util.CopyDefaults(cloneValue(stored) or {}, DEFAULTS)
        self:Migrate()
        return
    end

    RaidLeadAssistDB = Util.CopyDefaults(stored, DEFAULTS)
    self.data = RaidLeadAssistDB
    self:Migrate()
end

function Database:Migrate()
    local version = tonumber(self.data.schemaVersion) or 0
    self.newerSchemaDetected = version > self.SCHEMA_VERSION

    if type(self.data.position) ~= "table" then
        self.data.position = Util.CopyDefaults({}, DEFAULTS.position)
    else
        self.data.position = Util.CopyDefaults(self.data.position, DEFAULTS.position)
    end

    local position = self.data.position
    local function isFiniteNumber(value)
        return type(value) == "number" and value == value and value > -math.huge and value < math.huge
    end
    if not VALID_POINTS[position.point] or not VALID_POINTS[position.relativePoint]
        or not isFiniteNumber(position.x) or not isFiniteNumber(position.y) then
        self.data.position = Util.CopyDefaults({}, DEFAULTS.position)
    end

    if type(self.data.audioEnabled) ~= "boolean" then self.data.audioEnabled = DEFAULTS.audioEnabled end
    if type(self.data.automaticTimingEnabled) ~= "boolean" then
        self.data.automaticTimingEnabled = DEFAULTS.automaticTimingEnabled
    end
    if type(self.data.forceShown) ~= "boolean" then self.data.forceShown = DEFAULTS.forceShown end
    if type(self.data.selectedBossKey) ~= "string" then self.data.selectedBossKey = DEFAULTS.selectedBossKey end
    if not VALID_DIFFICULTIES[self.data.selectedDifficultyKey] then
        self.data.selectedDifficultyKey = DEFAULTS.selectedDifficultyKey
    end
    if type(self.data.customMessages) ~= "table" then self.data.customMessages = {} end
    if type(self.data.assignments) ~= "table" then self.data.assignments = {} end
    if type(self.data.assignmentPresets) ~= "table" then self.data.assignmentPresets = {} end

    if version < 2 then
        self.data.customMessages = type(self.data.customMessages) == "table" and self.data.customMessages or {}
    end

    if version < 3 then
        local migrated = {}
        for bossKey, profile in pairs(self.data.customMessages) do
            if type(profile) == "table" then
                if profile.explanation ~= nil or profile.calls ~= nil then
                    migrated[bossKey] = { heroic = profile }
                else
                    migrated[bossKey] = profile
                end
            end
        end
        self.data.customMessages = migrated
    end

    if version < 4 then
        self.data.assignments = type(self.data.assignments) == "table" and self.data.assignments or {}
    end

    if version < 6 then
        self.data.assignmentPresets = type(self.data.assignmentPresets) == "table" and self.data.assignmentPresets or {}
    end

    if not self.newerSchemaDetected then
        self.data.schemaVersion = self.SCHEMA_VERSION
    end
end

function Database:Get()
    return self.data
end

function Database:HasNewerSchema()
    return self.newerSchemaDetected == true
end

function Database:ResetPosition()
    self.data.position = Util.CopyDefaults({}, DEFAULTS.position)
end

ns:RegisterModule("Core.Database", Database)
