local _, ns = ...

local Constants = ns:GetModule("Core.Constants")
local Util = ns:GetModule("Core.Util")

local Registry = {
    encounters = {},
    encountersByID = {},
    orderedKeys = {},
    activeDifficultyKey = "heroic",
}

local function validTimingSeconds(value)
    return type(value) == "number" and value == value and value >= 0 and value < math.huge
end

local function validateProfile(encounterKey, difficultyKey, profile)
    local label = encounterKey .. "/" .. difficultyKey
    assert(type(profile) == "table", "Encounter profile requires table: " .. label)
    assert(type(profile.explanation) == "table" and #profile.explanation > 0, "Encounter profile requires explanation: " .. label)
    assert(type(profile.calls) == "table", "Encounter profile requires calls: " .. label)

    for index = 1, #profile.explanation do
        local line = profile.explanation[index]
        assert(type(line) == "string" and line ~= "", "Explanation lines must be non-empty strings: " .. label)
        assert(#line <= 200, "Boss Explanation line is too long: " .. label)
    end

    local seenCalls = {}
    for index = 1, #profile.calls do
        local call = profile.calls[index]
        assert(type(call.key) == "string", "Call requires key: " .. label)
        assert(not seenCalls[call.key], "Duplicate call key: " .. label .. "/" .. call.key)
        assert(type(call.ability) == "string", "Call requires ability: " .. label)
        assert(type(call.action) == "string", "Call requires action: " .. label)
        assert(type(call.warning) == "string" and call.warning ~= "", "Call requires warning: " .. label)
        assert(#call.warning <= 200, "Raid Warning is too long: " .. label .. "/" .. call.key)

        if call.timing ~= false then
            assert(call.spellIDs or call.timerNames, "Timed call requires a timer identity: " .. label .. "/" .. call.key)
            if call.prepareSeconds ~= nil then
                assert(validTimingSeconds(call.prepareSeconds), "Invalid prepareSeconds: " .. label .. "/" .. call.key)
            end
            if call.pressSeconds ~= nil then
                assert(validTimingSeconds(call.pressSeconds), "Invalid pressSeconds: " .. label .. "/" .. call.key)
            end
            local prepare, press = Constants.GetCallTiming(call)
            assert(prepare >= press, "prepareSeconds must be >= pressSeconds: " .. label .. "/" .. call.key)
        else
            assert(call.prepareSeconds == nil and call.pressSeconds == nil,
                "Manual call must not define automatic timing windows: " .. label .. "/" .. call.key)
        end

        seenCalls[call.key] = true
    end
end

local function addUniqueMapping(map, alias, callKey, label)
    local existing = map[alias]
    assert(not existing or existing == callKey, label .. " maps to multiple calls: " .. tostring(alias))
    map[alias] = callKey
end

local function buildProfile(profile)
    profile.callsByKey = {}
    profile.spellMap = {}
    profile.nameMap = {}

    for index = 1, #profile.calls do
        local call = profile.calls[index]
        profile.callsByKey[call.key] = call

        if call.timing ~= false then
            if call.spellIDs then
                for _, spellID in ipairs(call.spellIDs) do
                    local numericID = Util.ToNumericID(spellID)
                    assert(numericID, "Invalid spell ID for call: " .. call.key)
                    addUniqueMapping(profile.spellMap, numericID, call.key, "Spell ID")
                end
            end

            local names = call.timerNames or { call.ability }
            for _, name in ipairs(names) do
                local normalized = Util.NormalizeTimerName(name)
                if normalized then
                    addUniqueMapping(profile.nameMap, normalized, call.key, "Timer name")
                end
            end
        end
    end
end

local function applyProfileAlias(encounter, difficultyKey)
    local profile = encounter and encounter.profiles and encounter.profiles[difficultyKey]
    if not profile then return false end
    encounter.explanation = profile.explanation
    encounter.calls = profile.calls
    encounter.callsByKey = profile.callsByKey
    encounter.spellMap = profile.spellMap
    encounter.nameMap = profile.nameMap
    encounter.activeDifficultyKey = difficultyKey
    return true
end

local function validateEncounter(definition)
    assert(type(definition.key) == "string", "Encounter requires key")
    assert(type(definition.name) == "string", "Encounter requires name")
    assert(type(definition.profiles) == "table", "Encounter requires difficulty profiles")

    for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
        validateProfile(definition.key, difficultyKey, definition.profiles[difficultyKey])
    end
end

function Registry:Register(definition)
    validateEncounter(definition)
    assert(not self.encounters[definition.key], "Duplicate encounter key: " .. definition.key)

    for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
        buildProfile(definition.profiles[difficultyKey])
    end
    applyProfileAlias(definition, self.activeDifficultyKey)

    self.encounters[definition.key] = definition
    self.orderedKeys[#self.orderedKeys + 1] = definition.key

    if type(definition.encounterID) == "number" then
        assert(not self.encountersByID[definition.encounterID], "Duplicate encounter ID")
        self.encountersByID[definition.encounterID] = definition
    end
end

function Registry:SetActiveDifficulty(difficultyKey)
    if not Constants.DIFFICULTIES[difficultyKey] then return false end
    self.activeDifficultyKey = difficultyKey
    for _, key in ipairs(self.orderedKeys) do
        applyProfileAlias(self.encounters[key], difficultyKey)
    end
    return true
end

function Registry:GetActiveDifficulty()
    return self.activeDifficultyKey
end

function Registry:Get(key)
    return self.encounters[key]
end

function Registry:GetProfile(encounterKey, difficultyKey)
    local encounter = self.encounters[encounterKey]
    if not encounter or not Constants.DIFFICULTIES[difficultyKey] then return nil end
    return encounter.profiles[difficultyKey]
end

function Registry:GetOrdered()
    local result = {}
    for index = 1, #self.orderedKeys do
        result[#result + 1] = self.encounters[self.orderedKeys[index]]
    end
    return result
end

function Registry:FindByEncounterID(encounterID)
    return self.encountersByID[encounterID]
end

function Registry:FindByEncounterName(name)
    local normalized = Util.Normalize(name)
    if not normalized then return nil end

    for _, key in ipairs(self.orderedKeys) do
        local encounter = self.encounters[key]
        if Util.Normalize(encounter.name) == normalized then return encounter end

        if encounter.encounterAliases then
            for _, alias in ipairs(encounter.encounterAliases) do
                if Util.Normalize(alias) == normalized then return encounter end
            end
        end
    end
end

function Registry:MatchCall(encounterKey, difficultyKey, spellID, timerName)
    if not Constants.DIFFICULTIES[difficultyKey] then
        timerName = spellID
        spellID = difficultyKey
        difficultyKey = self.activeDifficultyKey
    end

    local profile = self:GetProfile(encounterKey, difficultyKey)
    if not profile then return nil end

    local numericID = Util.ToNumericID(spellID)
    if numericID then
        local callKey = profile.spellMap[numericID]
        if callKey then return profile.callsByKey[callKey] end
    end

    local normalized = Util.NormalizeTimerName(timerName)
    if normalized then
        local callKey = profile.nameMap[normalized]
        if callKey then return profile.callsByKey[callKey] end
    end
end

ns:RegisterModule("Encounters.Registry", Registry)
