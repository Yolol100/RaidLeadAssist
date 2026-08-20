local _, ns = ...

local Constants = ns:GetModule("Core.Constants")
local Util = ns:GetModule("Core.Util")
local Registry = ns:GetModule("Encounters.Registry")
local Assignments = ns:GetModule("Services.AssignmentService")

local AssignmentPresets = {
    database = nil,
    MAX_PRESETS_PER_PROFILE = 8,
    MAX_NAME_LENGTH = 32,
}

local function trim(value)
    if type(value) ~= "string" or Util.IsSecret(value) then return nil end
    return value:match("^%s*(.-)%s*$")
end

local function normalizeName(value)
    local name = trim(value)
    if not name or name == "" or #name > AssignmentPresets.MAX_NAME_LENGTH then return nil end
    if name:find("[%z\1-\31\127]") then return nil end
    return name
end

local function profileBucket(database, bossKey, difficultyKey, create)
    if type(database.assignmentPresets) ~= "table" then database.assignmentPresets = {} end
    local boss = database.assignmentPresets[bossKey]
    if type(boss) ~= "table" then
        if not create then return nil end
        boss = {}
        database.assignmentPresets[bossKey] = boss
    end
    local profile = boss[difficultyKey]
    if type(profile) ~= "table" then
        if not create then return nil end
        profile = {}
        boss[difficultyKey] = profile
    end
    return profile
end

local function copyValues(values)
    local copy = {}
    for key, value in pairs(values or {}) do
        if type(key) == "string" and type(value) == "string" then copy[key] = value end
    end
    return copy
end

local function countPresets(profile)
    local count = 0
    for _ in pairs(profile or {}) do count = count + 1 end
    return count
end

local function validProfile(bossKey, difficultyKey)
    return type(bossKey) == "string"
        and Registry:Get(bossKey) ~= nil
        and Constants.DIFFICULTIES[difficultyKey] ~= nil
end

function AssignmentPresets:Initialize(database)
    self.database = database
    if type(database.assignmentPresets) ~= "table" then database.assignmentPresets = {} end
    self:NormalizeStored()
end

function AssignmentPresets:NormalizeStored()
    if not self.database then return end
    local root = self.database.assignmentPresets
    for bossKey, difficulties in pairs(root) do
        if type(difficulties) ~= "table" or not Registry:Get(bossKey) then
            root[bossKey] = nil
        else
            for difficultyKey, profile in pairs(difficulties) do
                if not Constants.DIFFICULTIES[difficultyKey] or type(profile) ~= "table" then
                    difficulties[difficultyKey] = nil
                else
                    local cleanProfile = {}
                    local accepted = 0
                    local ordered = {}
                    for key, preset in pairs(profile) do
                        ordered[#ordered + 1] = { key = key, preset = preset }
                    end
                    table.sort(ordered, function(a, b) return tostring(a.key) < tostring(b.key) end)
                    for index = 1, #ordered do
                        if accepted >= self.MAX_PRESETS_PER_PROFILE then break end
                        local entry = ordered[index]
                        local preset = entry.preset
                        local name = type(preset) == "table" and normalizeName(preset.name) or nil
                        local values = type(preset) == "table" and preset.values or nil
                        if name and type(values) == "table" then
                            local ok, validated = Assignments:ValidateBossDraft(bossKey, difficultyKey, values)
                            if ok then
                                cleanProfile[name:lower()] = { name = name, values = copyValues(validated) }
                                accepted = accepted + 1
                            end
                        end
                    end
                    difficulties[difficultyKey] = next(cleanProfile) and cleanProfile or nil
                end
            end
            if next(difficulties) == nil then root[bossKey] = nil end
        end
    end
end

function AssignmentPresets:Save(name, bossKey, difficultyKey)
    if not self.database or not validProfile(bossKey, difficultyKey) then return false, "Unknown boss or difficulty." end
    name = normalizeName(name)
    if not name then return false, ("Preset name must be 1-%d printable characters."):format(self.MAX_NAME_LENGTH) end

    local values = Assignments:GetValues(bossKey, difficultyKey)
    local any = false
    for _, value in pairs(values) do if type(value) == "string" and value ~= "" then any = true break end end
    if not any then return false, "Fill at least one assignment before saving a preset." end

    local ok, validated = Assignments:ValidateBossDraft(bossKey, difficultyKey, values)
    if not ok then return false, validated and validated.message or "Current assignments are invalid." end

    local profile = profileBucket(self.database, bossKey, difficultyKey, true)
    local key = name:lower()
    if profile[key] == nil and countPresets(profile) >= self.MAX_PRESETS_PER_PROFILE then
        return false, ("A profile can store at most %d presets."):format(self.MAX_PRESETS_PER_PROFILE)
    end
    profile[key] = { name = name, values = copyValues(validated) }
    return true, name
end

function AssignmentPresets:Load(name, bossKey, difficultyKey)
    if not self.database or not validProfile(bossKey, difficultyKey) then return false, "Unknown boss or difficulty." end
    name = normalizeName(name)
    if not name then return false, "Preset name is missing or invalid." end
    local profile = profileBucket(self.database, bossKey, difficultyKey, false)
    local preset = profile and profile[name:lower()] or nil
    if type(preset) ~= "table" or type(preset.values) ~= "table" then return false, "Preset not found." end

    local ok, result = Assignments:ApplyBossDraft(bossKey, difficultyKey, copyValues(preset.values))
    if not ok then return false, result and result.message or "Preset is no longer valid for this profile." end
    return true, preset.name
end

function AssignmentPresets:Delete(name, bossKey, difficultyKey)
    if not self.database or not validProfile(bossKey, difficultyKey) then return false, "Unknown boss or difficulty." end
    name = normalizeName(name)
    if not name then return false, "Preset name is missing or invalid." end
    local profile = profileBucket(self.database, bossKey, difficultyKey, false)
    local key = name:lower()
    if not profile or not profile[key] then return false, "Preset not found." end
    profile[key] = nil
    local boss = self.database.assignmentPresets[bossKey]
    if next(profile) == nil then boss[difficultyKey] = nil end
    if next(boss) == nil then self.database.assignmentPresets[bossKey] = nil end
    return true, name
end

function AssignmentPresets:List(bossKey, difficultyKey)
    if not self.database or not validProfile(bossKey, difficultyKey) then return {} end
    local profile = profileBucket(self.database, bossKey, difficultyKey, false)
    local names = {}
    for _, preset in pairs(profile or {}) do
        if type(preset) == "table" and type(preset.name) == "string" then names[#names + 1] = preset.name end
    end
    table.sort(names, function(a, b) return a:lower() < b:lower() end)
    return names
end

ns:RegisterModule("Services.AssignmentPresetService", AssignmentPresets)
