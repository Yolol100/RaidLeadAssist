local _, ns = ...

local Util = ns:GetModule("Core.Util")

local Database = {
    SCHEMA_VERSION = 8,
    newerSchemaDetected = false,
}

local VALID_POINTS = {
    TOPLEFT = true, TOP = true, TOPRIGHT = true,
    LEFT = true, CENTER = true, RIGHT = true,
    BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}

local VALID_DIFFICULTIES = {
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
    schemaVersion = 8,
    selectedBossKey = "nekzali",
    selectedDifficultyKey = "heroic",
    selectedBossId = nil,
    audioEnabled = true,
    automaticTimingEnabled = true,
    uiScale = 1,
    timingLead = {
        prepare = 5,
        press = 3,
    },
    forceShown = false,
    customMessages = {},
    assignments = {},
    assignmentPresets = {},
    bossProfiles = {},
    deletedDefaultBosses = {},
    nextBossId = 1,
    nextMacroId = 1,
    pendingMacroSync = {},
    position = {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 40,
    },
}

local function isFiniteNumber(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function numeric(value)
    if Util.IsSecret(value) then return nil end
    if type(value) == "number" then return value end
    if type(value) == "string" then return tonumber(value) end
    return nil
end

local function normalizeTimingLead(value)
    if type(value) ~= "table" then return Util.CopyDefaults({}, DEFAULTS.timingLead) end
    local prepare = numeric(value.prepare)
    local press = numeric(value.press)
    if not isFiniteNumber(prepare) or not isFiniteNumber(press)
        or prepare < 2 or prepare > 30
        or press < 1 or press > 10
        or prepare <= press then
        return Util.CopyDefaults({}, DEFAULTS.timingLead)
    end
    return { prepare = prepare, press = press }
end

local function normalizeUIScale(value)
    local scale = numeric(value)
    if not isFiniteNumber(scale) then return DEFAULTS.uiScale end
    return math.max(0.70, math.min(1.10, scale))
end

local function dropUnsupportedDifficulties(root)
    if type(root) ~= "table" then return end
    for _, difficulties in pairs(root) do
        if type(difficulties) == "table" then
            for difficultyKey in pairs(difficulties) do
                if not VALID_DIFFICULTIES[difficultyKey] then difficulties[difficultyKey] = nil end
            end
        end
    end
end

local function normalizeBossMacroStorage(data)
    if type(data.bossProfiles) ~= "table" then data.bossProfiles = {} end
    if type(data.deletedDefaultBosses) ~= "table" then data.deletedDefaultBosses = {} end
    if type(data.pendingMacroSync) ~= "table" then data.pendingMacroSync = {} end

    local nextBossId = tonumber(data.nextBossId)
    if not nextBossId or nextBossId < 1 or nextBossId ~= math.floor(nextBossId) then nextBossId = 1 end

    local nextMacroId = tonumber(data.nextMacroId)
    if not nextMacroId or nextMacroId < 1 or nextMacroId ~= math.floor(nextMacroId) then nextMacroId = 1 end

    -- Saved counters are hints, not authority. A partial restore, downgrade or
    -- hand-edited SavedVariables file can leave them behind existing records.
    -- Reconcile them with durable IDs before anything allocates a new boss/macro.
    local highestBossSerial = 0
    local highestMacroId = 0
    for bossKey, boss in pairs(data.bossProfiles) do
        local id = type(boss) == "table" and boss.id or bossKey
        if type(id) == "string" then
            local serial = tonumber(id:match("^custom:(%d+)$"))
            if serial and serial > highestBossSerial then highestBossSerial = serial end
        end

        if type(boss) == "table" and type(boss.macros) == "table" then
            for _, macro in ipairs(boss.macros) do
                local macroId = type(macro) == "table" and tonumber(macro.id) or nil
                if macroId and macroId > highestMacroId and macroId == math.floor(macroId) then
                    highestMacroId = macroId
                end
            end
        end
    end

    data.nextBossId = math.max(nextBossId, highestBossSerial + 1)
    data.nextMacroId = math.max(nextMacroId, highestMacroId + 1)

    if data.selectedBossId ~= nil and type(data.selectedBossId) ~= "string" then
        data.selectedBossId = nil
    end
end

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
    if not VALID_POINTS[position.point] or not VALID_POINTS[position.relativePoint]
        or not isFiniteNumber(position.x) or not isFiniteNumber(position.y) then
        self.data.position = Util.CopyDefaults({}, DEFAULTS.position)
    end

    if type(self.data.audioEnabled) ~= "boolean" then self.data.audioEnabled = DEFAULTS.audioEnabled end
    if type(self.data.automaticTimingEnabled) ~= "boolean" then
        self.data.automaticTimingEnabled = DEFAULTS.automaticTimingEnabled
    end
    self.data.uiScale = normalizeUIScale(self.data.uiScale)
    self.data.timingLead = normalizeTimingLead(self.data.timingLead)
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
        self.data.timingLead = normalizeTimingLead(self.data.timingLead)
        self.data.assignmentPresets = type(self.data.assignmentPresets) == "table" and self.data.assignmentPresets or {}
    end

    if version < 7 then
        self.data.uiScale = normalizeUIScale(self.data.uiScale)
    end

    if version < 8 then
        normalizeBossMacroStorage(self.data)
        if not self.data.selectedBossId and type(self.data.selectedBossKey) == "string" then
            self.data.selectedBossId = "encounter:" .. self.data.selectedBossKey
        end
    end

    dropUnsupportedDifficulties(self.data.customMessages)
    dropUnsupportedDifficulties(self.data.assignments)
    dropUnsupportedDifficulties(self.data.assignmentPresets)
    normalizeBossMacroStorage(self.data)

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
