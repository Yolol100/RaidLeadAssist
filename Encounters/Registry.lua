local _, ns = ...

local Util = ns:GetModule("Core.Util")

local Registry = {
    encounters = {},
    encountersByID = {},
    orderedKeys = {},
}

local function validateEncounter(definition)
    assert(type(definition.key) == "string", "Encounter requires key")
    assert(type(definition.name) == "string", "Encounter requires name")
    assert(type(definition.explanation) == "table" and #definition.explanation > 0, "Encounter requires explanation")
    assert(type(definition.calls) == "table", "Encounter requires calls")

    for index = 1, #definition.explanation do
        local line = definition.explanation[index]
        assert(type(line) == "string" and line ~= "", "Explanation lines must be non-empty strings")
        assert(#line <= 200, "Boss Explanation line is too long")
    end

    local seenCalls = {}
    for index = 1, #definition.calls do
        local call = definition.calls[index]
        assert(type(call.key) == "string", "Call requires key")
        assert(not seenCalls[call.key], "Duplicate call key: " .. call.key)
        assert(type(call.ability) == "string", "Call requires ability")
        assert(type(call.action) == "string", "Call requires action")
        assert(type(call.warning) == "string" and call.warning ~= "", "Call requires warning")
        assert(#call.warning <= 200, "Raid Warning is too long: " .. call.key)
        if call.timing ~= false then
            assert(call.spellIDs or call.timerNames, "Timed call requires a timer identity: " .. call.key)
        end
        seenCalls[call.key] = true
    end
end

local function addUniqueMapping(map, alias, callKey, label)
    local existing = map[alias]
    assert(not existing or existing == callKey, label .. " maps to multiple calls: " .. tostring(alias))
    map[alias] = callKey
end

function Registry:Register(definition)
    validateEncounter(definition)
    assert(not self.encounters[definition.key], "Duplicate encounter key: " .. definition.key)

    definition.callsByKey = {}
    definition.spellMap = {}
    definition.nameMap = {}

    for index = 1, #definition.calls do
        local call = definition.calls[index]
        definition.callsByKey[call.key] = call

        if call.timing ~= false then
            if call.spellIDs then
                for _, spellID in ipairs(call.spellIDs) do
                    local numericID = Util.ToNumericID(spellID)
                    assert(numericID, "Invalid spell ID for call: " .. call.key)
                    addUniqueMapping(definition.spellMap, numericID, call.key, "Spell ID")
                end
            end

            local names = call.timerNames or { call.ability }
            for _, name in ipairs(names) do
                local normalized = Util.NormalizeTimerName(name)
                if normalized then
                    addUniqueMapping(definition.nameMap, normalized, call.key, "Timer name")
                end
            end
        end
    end

    self.encounters[definition.key] = definition
    self.orderedKeys[#self.orderedKeys + 1] = definition.key

    if type(definition.encounterID) == "number" then
        assert(not self.encountersByID[definition.encounterID], "Duplicate encounter ID")
        self.encountersByID[definition.encounterID] = definition
    end
end

function Registry:Get(key)
    return self.encounters[key]
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

function Registry:MatchCall(encounterKey, spellID, timerName)
    local encounter = self.encounters[encounterKey]
    if not encounter then return nil end

    local numericID = Util.ToNumericID(spellID)
    if numericID then
        local callKey = encounter.spellMap[numericID]
        if callKey then return encounter.callsByKey[callKey] end
    end

    local normalized = Util.NormalizeTimerName(timerName)
    if normalized then
        local callKey = encounter.nameMap[normalized]
        if callKey then return encounter.callsByKey[callKey] end
    end
end

ns:RegisterModule("Encounters.Registry", Registry)
