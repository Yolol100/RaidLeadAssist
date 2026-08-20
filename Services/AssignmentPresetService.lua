local _, ns = ...

local Constants = ns:GetModule("Core.Constants")
local Registry = ns:GetModule("Encounters.Registry")
local Assignments = ns:GetModule("Services.AssignmentService")

local AssignmentPresets = {
    database = nil,
    MAX_PRESETS_PER_PROFILE = 8,
    MAX_NAME_LENGTH = 32,
}

local function trim(value)
    if type(value) ~= "string" then return "" end
    return value:match("^%s*(.-)%s*$") or ""
end

local function containsControl(value)
    return value:find("[%z\1-\8\11\12\14-\31\127]") ~= nil
end

local function normalizeName(value)
    if type(value) ~= "string" then return false, "Preset name must be text." end
    if containsControl(value) then return false, "Preset name contains unsupported control characters." end
    local display = trim(value:gsub("[\r\n]+", " "):gsub("%s+", " "))
    if display == "" then return false, "Preset name cannot be empty." end
    if #display > AssignmentPresets.MAX_NAME_LENGTH then
        return false, ("Preset name must be %d characters or less."):format(AssignmentPresets.MAX_NAME_LENGTH)
    end
    return true, display, display:lower()
end

local function copyValues(values)
    local copy = {}
    for key, value in pairs(values or {}) do
        if type(key) == "string" and type(value) == "string" then copy[key] = value end
    end
    return copy
end

local function validContext(bossKey, difficultyKey)
    return type(bossKey) == "string"
        and Registry:Get(bossKey) ~= nil
        and Constants.DIFFICULTIES[difficultyKey] ~= nil
end

function AssignmentPresets:Initialize(database)
    self.database = database
    if type(database.assignmentPresets) ~= "table" then database.assignmentPresets = {} end
    self:NormalizeStored()
end

function AssignmentPresets:GetBucket(bossKey, difficultyKey, create)
    if not self.database or not validContext(bossKey, difficultyKey) then return nil end
    if type(self.database.assignmentPresets) ~= "table" then self.database.assignmentPresets = {} end

    local boss = self.database.assignmentPresets[bossKey]
    if boss ~= nil and type(boss) ~= "table" then
        self.database.assignmentPresets[bossKey] = nil
        boss = nil
    end
    if not boss and create then
        boss = {}
        self.database.assignmentPresets[bossKey] = boss
    end
    if not boss then return nil end

    local bucket = boss[difficultyKey]
    if bucket ~= nil and type(bucket) ~= "table" then
        boss[difficultyKey] = nil
        bucket = nil
    end
    if not bucket and create then
        bucket = {}
        boss[difficultyKey] = bucket
    end
    return bucket
end

function AssignmentPresets:CleanEmpty(bossKey, difficultyKey)
    if not self.database or type(self.database.assignmentPresets) ~= "table" then return end
    local boss = self.database.assignmentPresets[bossKey]
    if type(boss) ~= "table" then return end
    local bucket = boss[difficultyKey]
    if type(bucket) == "table" and next(bucket) == nil then boss[difficultyKey] = nil end
    if next(boss) == nil then self.database.assignmentPresets[bossKey] = nil end
end

function AssignmentPresets:NormalizeStored()
    if not self.database or type(self.database.assignmentPresets) ~= "table" then return end

    for bossKey, difficulties in pairs(self.database.assignmentPresets) do
        if type(difficulties) ~= "table" or not Registry:Get(bossKey) then
            self.database.assignmentPresets[bossKey] = nil
        else
            for difficultyKey, bucket in pairs(difficulties) do
                if not Constants.DIFFICULTIES[difficultyKey] or type(bucket) ~= "table" then
                    difficulties[difficultyKey] = nil
                else
                    local keys = {}
                    for presetKey in pairs(bucket) do
                        if type(presetKey) == "string" then keys[#keys + 1] = presetKey end
                    end
                    table.sort(keys)

                    local normalized = {}
                    local count = 0
                    for index = 1, #keys do
                        local entry = bucket[keys[index]]
                        if count < self.MAX_PRESETS_PER_PROFILE and type(entry) == "table" then
                            local okName, display, canonical = normalizeName(entry.name or keys[index])
                            local values = type(entry.values) == "table" and entry.values or nil
                            local okValues, clean = values and Assignments:ValidateBossDraft(bossKey, difficultyKey, values) or false, nil
                            if values then okValues, clean = Assignments:ValidateBossDraft(bossKey, difficultyKey, values) end
                            if okName and okValues and type(clean) == "table" and next(clean) ~= nil and not normalized[canonical] then
                                normalized[canonical] = { name = display, values = copyValues(clean) }
                                count = count + 1
                            end
                        end
                    end
                    difficulties[difficultyKey] = normalized
                    if next(normalized) == nil then difficulties[difficultyKey] = nil end
                end
            end
            if next(difficulties) == nil then self.database.assignmentPresets[bossKey] = nil end
        end
    end
end

function AssignmentPresets:SavePreset(bossKey, difficultyKey, name, values)
    if not validContext(bossKey, difficultyKey) then return false, "Unsupported boss or difficulty." end
    local okName, display, canonical = normalizeName(name)
    if not okName then return false, display end

    values = values or Assignments:GetValues(bossKey, difficultyKey)
    local okValues, clean = Assignments:ValidateBossDraft(bossKey, difficultyKey, values)
    if not okValues then return false, clean and clean.message or "Assignments are invalid." end
    if next(clean) == nil then return false, "Preset must contain at least one assignment." end

    local bucket = self:GetBucket(bossKey, difficultyKey, true)
    if not bucket[canonical] then
        local count = 0
        for _ in pairs(bucket) do count = count + 1 end
        if count >= self.MAX_PRESETS_PER_PROFILE then
            return false, ("A boss/difficulty can store at most %d presets."):format(self.MAX_PRESETS_PER_PROFILE)
        end
    end

    bucket[canonical] = { name = display, values = copyValues(clean) }
    return true, display
end

function AssignmentPresets:GetPreset(bossKey, difficultyKey, name)
    local okName, _, canonical = normalizeName(name)
    if not okName then return nil end
    local bucket = self:GetBucket(bossKey, difficultyKey, false)
    local entry = bucket and bucket[canonical]
    if type(entry) ~= "table" or type(entry.values) ~= "table" then return nil end
    return { name = entry.name, values = copyValues(entry.values) }
end

function AssignmentPresets:ApplyPreset(bossKey, difficultyKey, name)
    local preset = self:GetPreset(bossKey, difficultyKey, name)
    if not preset then return false, "Preset not found for this boss and difficulty." end

    local okValues, clean = Assignments:ValidateBossDraft(bossKey, difficultyKey, preset.values)
    if not okValues then
        return false, "Preset no longer matches the current assignment contract: " .. (clean and clean.message or "invalid assignments")
    end
    local applied, result = Assignments:ApplyBossDraft(bossKey, difficultyKey, clean)
    if not applied then return false, result and result.message or "Preset could not be applied." end
    return true, preset.name
end

function AssignmentPresets:DeletePreset(bossKey, difficultyKey, name)
    local okName, _, canonical = normalizeName(name)
    if not okName then return false, "Preset name is invalid." end
    local bucket = self:GetBucket(bossKey, difficultyKey, false)
    if not bucket or not bucket[canonical] then return false, "Preset not found for this boss and difficulty." end
    bucket[canonical] = nil
    self:CleanEmpty(bossKey, difficultyKey)
    return true
end

function AssignmentPresets:ListPresets(bossKey, difficultyKey)
    local bucket = self:GetBucket(bossKey, difficultyKey, false)
    local names = {}
    for _, entry in pairs(bucket or {}) do
        if type(entry) == "table" and type(entry.name) == "string" then names[#names + 1] = entry.name end
    end
    table.sort(names, function(a, b) return a:lower() < b:lower() end)
    return names
end

ns:RegisterModule("Services.AssignmentPresetService", AssignmentPresets)
