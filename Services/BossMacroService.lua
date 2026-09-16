local _, ns = ...

local Constants = ns:GetModule("Core.Constants")
local Registry = ns:GetModule("Encounters.Registry")
local Util = ns:GetModule("Core.Util")

local BossMacroService = {
    database = nil,
}

local function trim(value)
    if type(value) ~= "string" then return "" end
    return value:match("^%s*(.-)%s*$") or ""
end

local function copyArray(source)
    local result = {}
    if type(source) ~= "table" then return result end
    for index = 1, #source do result[index] = source[index] end
    return result
end

local function cloneTable(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return nil end
    local copy = {}
    seen[value] = copy
    for key, child in pairs(value) do
        local keyType = type(key)
        if keyType == "string" or keyType == "number" then
            copy[key] = cloneTable(child, seen)
        end
    end
    return copy
end

local function spellIcon(spellID)
    local numericID = Util.ToNumericID(spellID)
    if not numericID then return nil end
    if C_Spell and type(C_Spell.GetSpellTexture) == "function" then
        local ok, texture = pcall(C_Spell.GetSpellTexture, numericID)
        if ok and not Util.IsSecret(texture) and texture then return texture end
    end
    if type(GetSpellTexture) == "function" then
        local ok, texture = pcall(GetSpellTexture, numericID)
        if ok and not Util.IsSecret(texture) and texture then return texture end
    end
    return nil
end

local function customWarning(database, bossKey, difficultyKey, callKey)
    local byBoss = type(database.customMessages) == "table" and database.customMessages[bossKey] or nil
    local profile = type(byBoss) == "table" and byBoss[difficultyKey] or nil
    local calls = type(profile) == "table" and profile.calls or nil
    local value = type(calls) == "table" and calls[callKey] or nil
    return type(value) == "string" and value ~= "" and value or nil
end

local function nextMacroId(database)
    local id = tonumber(database.nextMacroId) or 1
    database.nextMacroId = id + 1
    return id
end

local function nextBossId(database)
    local id = tonumber(database.nextBossId) or 1
    database.nextBossId = id + 1
    return id
end

local function maxBossOrder(database)
    local highest = 0
    for _, boss in pairs(database.bossProfiles or {}) do
        local value = type(boss) == "table" and tonumber(boss.order) or nil
        if value and value > highest then highest = value end
    end
    return highest
end

local function validDifficulty(difficultyKey)
    return Constants.DIFFICULTIES[difficultyKey] ~= nil
end

local function selectedDifficulty(service, difficultyKey)
    if validDifficulty(difficultyKey) then return difficultyKey end
    local selected = service.database and service.database.selectedDifficultyKey or nil
    if validDifficulty(selected) then return selected end
    return Constants.DIFFICULTY_ORDER[1]
end

local function registryCallForKey(encounterKey, callKey, preferredDifficulty)
    if type(encounterKey) ~= "string" or type(callKey) ~= "string" then return nil end
    if validDifficulty(preferredDifficulty) then
        local profile = Registry:GetProfile(encounterKey, preferredDifficulty)
        local call = profile and profile.callsByKey and profile.callsByKey[callKey] or nil
        if call then return call end
    end
    for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
        if difficultyKey ~= preferredDifficulty then
            local profile = Registry:GetProfile(encounterKey, difficultyKey)
            local call = profile and profile.callsByKey and profile.callsByKey[callKey] or nil
            if call then return call end
        end
    end
end

local function defaultTacticsText(encounterKey, difficultyKey)
    local profile = type(encounterKey) == "string" and Registry:GetProfile(encounterKey, difficultyKey) or nil
    local lines = profile and profile.explanation or nil
    if type(lines) ~= "table" then return "" end
    local result = {}
    for index = 1, #lines do
        if type(lines[index]) == "string" and lines[index] ~= "" then
            result[#result + 1] = lines[index]
        end
    end
    return table.concat(result, "\n")
end

local function ensureDifficultyProfile(boss, difficultyKey)
    if type(boss.difficulties) ~= "table" then boss.difficulties = {} end
    local profile = boss.difficulties[difficultyKey]
    if type(profile) ~= "table" then
        profile = {}
        boss.difficulties[difficultyKey] = profile
    end
    if type(profile.macros) ~= "table" then profile.macros = {} end
    if type(profile.tactics) ~= "string" then profile.tactics = nil end
    return profile
end

local function macroFromCall(service, encounter, difficultyKey, call)
    local warning = customWarning(service.database, encounter.key, difficultyKey, call.key) or call.warning or call.action or call.ability
    local prepare, press = Constants.GetCallTiming(call, service.database.timingLead)
    local spellIDs = copyArray(call.spellIDs)
    local iconSpellID = Util.ToNumericID(call.iconSpellID) or Util.ToNumericID(spellIDs[1])
    return {
        id = nextMacroId(service.database),
        difficultyKey = difficultyKey,
        name = call.ability or call.action or call.key,
        body = "/rw " .. tostring(warning or ""),
        sourceCallKey = call.key,
        spellIDs = spellIDs,
        timerNames = copyArray(call.timerNames),
        iconSpellID = iconSpellID,
        iconMode = "ability",
        customIcon = nil,
        timingEnabled = call.timing ~= false,
        prepareSeconds = prepare,
        pressSeconds = press,
        managedMacroIndex = nil,
    }
end

local function addCallsFromProfile(service, boss, encounter, difficultyKey)
    local target = ensureDifficultyProfile(boss, difficultyKey)
    local profile = Registry:GetProfile(encounter.key, difficultyKey)
    if not profile or type(profile.calls) ~= "table" then return end

    local seen = {}
    for _, macro in ipairs(target.macros) do
        if type(macro) == "table" and type(macro.sourceCallKey) == "string" then
            seen[macro.sourceCallKey] = true
        end
    end

    for index = 1, #profile.calls do
        local call = profile.calls[index]
        if call and type(call.key) == "string" and not seen[call.key] then
            seen[call.key] = true
            target.macros[#target.macros + 1] = macroFromCall(service, encounter, difficultyKey, call)
        end
    end
end

local function reconcileCallsFromProfile(service, boss, encounter, difficultyKey)
    local target = ensureDifficultyProfile(boss, difficultyKey)
    local profile = Registry:GetProfile(encounter.key, difficultyKey)
    if not profile or type(profile.calls) ~= "table" then return end

    local callsByKey = type(profile.callsByKey) == "table" and profile.callsByKey or {}
    local reconciled = {}
    for _, macro in ipairs(target.macros) do
        if type(macro) == "table" then
            local sourceKey = type(macro.sourceCallKey) == "string" and macro.sourceCallKey or nil
            if not sourceKey then
                reconciled[#reconciled + 1] = macro
            else
                local call = callsByKey[sourceKey]
                if call then
                    macro.spellIDs = copyArray(call.spellIDs)
                    macro.timerNames = copyArray(call.timerNames)
                    local iconSpellID = Util.ToNumericID(call.iconSpellID) or Util.ToNumericID(macro.spellIDs[1])
                    if macro.iconMode ~= "custom" then
                        macro.iconSpellID = iconSpellID
                        macro.iconMode = "ability"
                        macro.customIcon = nil
                    end
                    macro.timingEnabled = call.timing ~= false
                    local prepare, press = Constants.GetCallTiming(call, service.database.timingLead)
                    macro.prepareSeconds = prepare
                    macro.pressSeconds = press
                    reconciled[#reconciled + 1] = macro
                elseif tonumber(macro.id) then
                    service.database.pendingMacroSync[tostring(macro.id)] = "delete"
                end
            end
        end
    end
    target.macros = reconciled
    addCallsFromProfile(service, boss, encounter, difficultyKey)
end

local function macroBelongsToDifficulty(encounterKey, macro, difficultyKey)
    if type(encounterKey) ~= "string" or type(macro) ~= "table" or type(macro.sourceCallKey) ~= "string" then
        return false
    end
    local profile = Registry:GetProfile(encounterKey, difficultyKey)
    return profile and profile.callsByKey and profile.callsByKey[macro.sourceCallKey] ~= nil or false
end

local function normalizeMacro(service, boss, difficultyKey, macro)
    if type(macro) ~= "table" then return nil end
    if not tonumber(macro.id) then macro.id = nextMacroId(service.database) end
    macro.difficultyKey = difficultyKey
    macro.name = type(macro.name) == "string" and macro.name:sub(1, 16) or "Macro"
    macro.body = type(macro.body) == "string" and macro.body or "/rw "
    macro.spellIDs = type(macro.spellIDs) == "table" and macro.spellIDs or {}
    macro.timerNames = type(macro.timerNames) == "table" and macro.timerNames or {}
    if not macro.iconSpellID then
        local call = registryCallForKey(boss.sourceEncounterKey, macro.sourceCallKey, difficultyKey)
        macro.iconSpellID = Util.ToNumericID(call and call.iconSpellID) or Util.ToNumericID(macro.spellIDs[1])
    end
    if macro.iconMode ~= "custom" then macro.iconMode = "ability" end
    local prepare, press = Constants.GetCallTiming({
        prepareSeconds = macro.prepareSeconds,
        pressSeconds = macro.pressSeconds,
    }, service.database.timingLead)
    macro.prepareSeconds = prepare
    macro.pressSeconds = press
    return macro
end

local function appendIfMissingById(macros, macro)
    local id = tonumber(macro and macro.id)
    for _, current in ipairs(macros or {}) do
        if id and tonumber(current and current.id) == id then return false end
    end
    macros[#macros + 1] = macro
    return true
end

function BossMacroService:Initialize(database)
    self.database = database
    if type(database.bossProfiles) ~= "table" then database.bossProfiles = {} end
    if type(database.deletedDefaultBosses) ~= "table" then database.deletedDefaultBosses = {} end
    if type(database.pendingMacroSync) ~= "table" then database.pendingMacroSync = {} end
    database.nextBossId = tonumber(database.nextBossId) or 1
    database.nextMacroId = tonumber(database.nextMacroId) or 1

    self:SeedDefaultBosses()
    self:NormalizeStoredProfiles()

    if not database.selectedBossId or not database.bossProfiles[database.selectedBossId] then
        local preferred = type(database.selectedBossKey) == "string" and ("encounter:" .. database.selectedBossKey) or nil
        if preferred and database.bossProfiles[preferred] then
            database.selectedBossId = preferred
        else
            local ordered = self:GetBossesOrdered()
            database.selectedBossId = ordered[1] and ordered[1].id or nil
        end
    end
end

function BossMacroService:NormalizeStoredProfiles()
    local migrationDifficulty = selectedDifficulty(self)

    for _, boss in pairs(self.database.bossProfiles or {}) do
        if type(boss) == "table" then
            for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
                ensureDifficultyProfile(boss, difficultyKey)
            end

            -- Schema <= 8 stored one flat macro list per boss. Preserve those IDs
            -- in the most appropriate difficulty and clone only when the same
            -- encounter call exists in both modes. Manual macros remain in the
            -- user's currently selected mode so action-bar markers are not split.
            if type(boss.macros) == "table" and #boss.macros > 0 then
                for _, legacyMacro in ipairs(boss.macros) do
                    if type(legacyMacro) == "table" then
                        local targets = {}
                        if type(boss.sourceEncounterKey) == "string" and type(legacyMacro.sourceCallKey) == "string" then
                            for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
                                if macroBelongsToDifficulty(boss.sourceEncounterKey, legacyMacro, difficultyKey) then
                                    targets[#targets + 1] = difficultyKey
                                end
                            end
                        end
                        if #targets == 0 then targets[1] = migrationDifficulty end

                        local primary = targets[1]
                        for _, difficultyKey in ipairs(targets) do
                            if difficultyKey == migrationDifficulty then primary = difficultyKey break end
                        end

                        local primaryMacro = normalizeMacro(self, boss, primary, legacyMacro)
                        appendIfMissingById(ensureDifficultyProfile(boss, primary).macros, primaryMacro)

                        for _, difficultyKey in ipairs(targets) do
                            if difficultyKey ~= primary then
                                local cloned = cloneTable(legacyMacro) or {}
                                cloned.id = nextMacroId(self.database)
                                cloned.managedMacroIndex = nil
                                normalizeMacro(self, boss, difficultyKey, cloned)
                                appendIfMissingById(ensureDifficultyProfile(boss, difficultyKey).macros, cloned)
                            end
                        end
                    end
                end
                boss.macros = nil
            end

            for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
                local profile = ensureDifficultyProfile(boss, difficultyKey)
                local normalized = {}
                for _, macro in ipairs(profile.macros) do
                    local value = normalizeMacro(self, boss, difficultyKey, macro)
                    if value then normalized[#normalized + 1] = value end
                end
                profile.macros = normalized
                if profile.tactics == nil then
                    profile.tactics = defaultTacticsText(boss.sourceEncounterKey, difficultyKey)
                end
            end

            if boss.defaultProfile and type(boss.sourceEncounterKey) == "string" then
                local encounter = Registry:Get(boss.sourceEncounterKey)
                if encounter then
                    for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
                        reconcileCallsFromProfile(self, boss, encounter, difficultyKey)
                    end
                end
            end
        end
    end
end

function BossMacroService:SeedDefaultBosses()
    local order = maxBossOrder(self.database)
    local encounters = Registry:GetOrdered()
    for index = 1, #encounters do
        local encounter = encounters[index]
        local bossId = "encounter:" .. encounter.key
        if not self.database.deletedDefaultBosses[bossId] and not self.database.bossProfiles[bossId] then
            order = order + 1
            local boss = {
                id = bossId,
                name = encounter.name,
                encounterID = encounter.encounterID,
                sourceEncounterKey = encounter.key,
                defaultProfile = true,
                order = order,
                difficulties = {},
            }
            for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
                local profile = ensureDifficultyProfile(boss, difficultyKey)
                profile.tactics = defaultTacticsText(encounter.key, difficultyKey)
                addCallsFromProfile(self, boss, encounter, difficultyKey)
            end
            self.database.bossProfiles[bossId] = boss
        end
    end
end

function BossMacroService:GetBoss(id)
    return type(id) == "string" and self.database and self.database.bossProfiles[id] or nil
end

function BossMacroService:GetBossesOrdered()
    local result = {}
    for _, boss in pairs(self.database and self.database.bossProfiles or {}) do
        if type(boss) == "table" and type(boss.id) == "string" then result[#result + 1] = boss end
    end
    table.sort(result, function(a, b)
        local ao, bo = tonumber(a.order) or math.huge, tonumber(b.order) or math.huge
        if ao ~= bo then return ao < bo end
        return tostring(a.name or "") < tostring(b.name or "")
    end)
    return result
end

function BossMacroService:FindByEncounterID(encounterID)
    local numericID = tonumber(encounterID)
    if not numericID then return nil end
    for _, boss in pairs(self.database and self.database.bossProfiles or {}) do
        if type(boss) == "table" and tonumber(boss.encounterID) == numericID then return boss end
    end
end

function BossMacroService:CreateBoss(name, encounterID)
    name = trim(name)
    if name == "" then return nil, "Boss name cannot be empty." end
    local serial = nextBossId(self.database)
    local id = "custom:" .. tostring(serial)
    local boss = {
        id = id,
        name = name,
        encounterID = tonumber(encounterID),
        sourceEncounterKey = nil,
        defaultProfile = false,
        order = maxBossOrder(self.database) + 1,
        difficulties = {},
    }
    for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
        local profile = ensureDifficultyProfile(boss, difficultyKey)
        profile.tactics = ""
    end
    self.database.bossProfiles[id] = boss
    self.database.selectedBossId = id
    return boss
end

function BossMacroService:RenameBoss(id, name)
    local boss = self:GetBoss(id)
    name = trim(name)
    if not boss then return false, "Unknown boss." end
    if name == "" then return false, "Boss name cannot be empty." end
    boss.name = name
    return true
end

function BossMacroService:DeleteBoss(id)
    local boss = self:GetBoss(id)
    if not boss then return false, "Unknown boss." end
    if boss.defaultProfile then self.database.deletedDefaultBosses[id] = true end
    self.database.bossProfiles[id] = nil
    if self.database.selectedBossId == id then
        local ordered = self:GetBossesOrdered()
        self.database.selectedBossId = ordered[1] and ordered[1].id or nil
    end
    return true
end

function BossMacroService:GetDifficultyProfile(bossId, difficultyKey)
    local boss = self:GetBoss(bossId)
    if not boss then return nil end
    difficultyKey = selectedDifficulty(self, difficultyKey)
    return ensureDifficultyProfile(boss, difficultyKey), difficultyKey
end

function BossMacroService:GetMacros(bossId, difficultyKey)
    local profile = self:GetDifficultyProfile(bossId, difficultyKey)
    return profile and profile.macros or {}
end

function BossMacroService:GetAllMacros(bossId)
    local boss = self:GetBoss(bossId)
    if not boss then return {} end
    local result = {}
    for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
        local profile = ensureDifficultyProfile(boss, difficultyKey)
        for _, macro in ipairs(profile.macros) do result[#result + 1] = macro end
    end
    return result
end

function BossMacroService:GetTactics(bossId, difficultyKey)
    local boss = self:GetBoss(bossId)
    if not boss then return "" end
    difficultyKey = selectedDifficulty(self, difficultyKey)
    local profile = ensureDifficultyProfile(boss, difficultyKey)
    if profile.tactics == nil then profile.tactics = defaultTacticsText(boss.sourceEncounterKey, difficultyKey) end
    return profile.tactics or ""
end

function BossMacroService:SetTactics(bossId, difficultyKey, text)
    local boss = self:GetBoss(bossId)
    if not boss then return false, "Unknown boss." end
    difficultyKey = selectedDifficulty(self, difficultyKey)
    local profile = ensureDifficultyProfile(boss, difficultyKey)
    profile.tactics = type(text) == "string" and text or ""
    return true, profile.tactics
end

function BossMacroService:ResetTactics(bossId, difficultyKey)
    local boss = self:GetBoss(bossId)
    if not boss then return false, "Unknown boss." end
    difficultyKey = selectedDifficulty(self, difficultyKey)
    local profile = ensureDifficultyProfile(boss, difficultyKey)
    profile.tactics = defaultTacticsText(boss.sourceEncounterKey, difficultyKey)
    return true, profile.tactics
end

function BossMacroService:GetAbilityOptions(bossId, difficultyKey)
    local boss = self:GetBoss(bossId)
    if not boss or type(boss.sourceEncounterKey) ~= "string" then return {} end
    difficultyKey = selectedDifficulty(self, difficultyKey)
    local profile = Registry:GetProfile(boss.sourceEncounterKey, difficultyKey)
    local result = {}
    for _, call in ipairs(profile and profile.calls or {}) do
        if call and type(call.key) == "string" then
            local prepare, press = Constants.GetCallTiming(call, self.database.timingLead)
            local spellIDs = copyArray(call.spellIDs)
            result[#result + 1] = {
                difficultyKey = difficultyKey,
                sourceCallKey = call.key,
                name = call.ability or call.action or call.key,
                spellIDs = spellIDs,
                timerNames = copyArray(call.timerNames),
                iconSpellID = Util.ToNumericID(call.iconSpellID) or Util.ToNumericID(spellIDs[1]),
                timingEnabled = call.timing ~= false,
                prepareSeconds = prepare,
                pressSeconds = press,
            }
        end
    end
    return result
end

function BossMacroService:FindMacroById(id)
    local numericID = tonumber(id)
    if not numericID then return nil, nil, nil end
    for _, boss in pairs(self.database and self.database.bossProfiles or {}) do
        if type(boss) == "table" then
            for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
                local profile = ensureDifficultyProfile(boss, difficultyKey)
                for index = 1, #profile.macros do
                    if tonumber(profile.macros[index].id) == numericID then
                        profile.macros[index].difficultyKey = difficultyKey
                        return profile.macros[index], boss, difficultyKey
                    end
                end
            end
        end
    end
end

function BossMacroService:CreateMacro(bossId, difficultyKey)
    local boss = self:GetBoss(bossId)
    if not boss then return nil, "Unknown boss." end
    difficultyKey = selectedDifficulty(self, difficultyKey)
    local macros = ensureDifficultyProfile(boss, difficultyKey).macros
    local macro = {
        id = nextMacroId(self.database),
        difficultyKey = difficultyKey,
        name = "New Macro",
        body = "/rw ",
        sourceCallKey = nil,
        spellIDs = {},
        timerNames = {},
        iconSpellID = nil,
        iconMode = "custom",
        customIcon = 134400,
        timingEnabled = false,
        prepareSeconds = Constants.PREPARE_SECONDS,
        pressSeconds = Constants.PRESS_SECONDS,
        managedMacroIndex = nil,
    }
    macros[#macros + 1] = macro
    return macro
end

function BossMacroService:DeleteMacro(bossId, macroId, difficultyKey)
    local boss = self:GetBoss(bossId)
    if not boss then return false, "Unknown boss." end
    difficultyKey = selectedDifficulty(self, difficultyKey)
    local macros = ensureDifficultyProfile(boss, difficultyKey).macros
    for index = 1, #macros do
        if tonumber(macros[index].id) == tonumber(macroId) then
            local removed = table.remove(macros, index)
            return true, removed
        end
    end
    return false, "Unknown macro."
end

function BossMacroService:MoveMacro(bossId, macroId, targetMacroId, difficultyKey)
    local boss = self:GetBoss(bossId)
    if not boss then return false, "Unknown boss." end
    difficultyKey = selectedDifficulty(self, difficultyKey)
    local macros = ensureDifficultyProfile(boss, difficultyKey).macros
    local sourceIndex, targetIndex
    for index = 1, #macros do
        local id = tonumber(macros[index].id)
        if id == tonumber(macroId) then sourceIndex = index end
        if id == tonumber(targetMacroId) then targetIndex = index end
    end
    if not sourceIndex or not targetIndex then return false, "Unknown macro." end
    if sourceIndex == targetIndex then return true end
    local moving = table.remove(macros, sourceIndex)
    -- Drop onto a slot means the dragged macro takes that slot's original
    -- position. Keep the original target index after removal.
    table.insert(macros, math.max(1, math.min(targetIndex, #macros + 1)), moving)
    return true
end

function BossMacroService:MoveMacroByOffset(bossId, macroId, delta, difficultyKey)
    local boss = self:GetBoss(bossId)
    if not boss then return false, "Unknown boss." end
    difficultyKey = selectedDifficulty(self, difficultyKey)
    local macros = ensureDifficultyProfile(boss, difficultyKey).macros
    local sourceIndex
    for index = 1, #macros do
        if tonumber(macros[index].id) == tonumber(macroId) then sourceIndex = index break end
    end
    if not sourceIndex then return false, "Unknown macro." end
    local targetIndex = math.max(1, math.min(#macros, sourceIndex + (tonumber(delta) or 0)))
    if targetIndex == sourceIndex then return true end
    local moving = table.remove(macros, sourceIndex)
    table.insert(macros, targetIndex, moving)
    return true
end

function BossMacroService:UpdateMacro(bossId, macroId, draft)
    local boss = self:GetBoss(bossId)
    if not boss then return false, "Unknown boss." end
    local macro, macroBoss, difficultyKey = self:FindMacroById(macroId)
    if not macro or not macroBoss or macroBoss.id ~= boss.id then return false, "Unknown macro." end

    local name = trim(draft and draft.name)
    local body = type(draft and draft.body) == "string" and draft.body or ""
    if name == "" then return false, "Macro name cannot be empty." end
    if body == "" then return false, "Macro commands cannot be empty." end

    macro.difficultyKey = difficultyKey
    macro.name = name:sub(1, 16)
    macro.body = body
    macro.sourceCallKey = type(draft.sourceCallKey) == "string" and draft.sourceCallKey or nil
    macro.iconMode = draft.iconMode == "ability" and "ability" or "custom"
    local normalizedIcon = Util.NormalizeTexture(draft.customIcon)
    if normalizedIcon then macro.customIcon = normalizedIcon end
    macro.iconSpellID = Util.ToNumericID(draft.iconSpellID) or macro.iconSpellID
    macro.timingEnabled = draft.timingEnabled == true

    local prepare, press = Constants.GetCallTiming({
        prepareSeconds = tonumber(draft.prepareSeconds),
        pressSeconds = tonumber(draft.pressSeconds),
    }, self.database.timingLead)
    macro.prepareSeconds = prepare
    macro.pressSeconds = press

    if type(draft.spellIDs) == "table" then
        macro.spellIDs = copyArray(draft.spellIDs)
    elseif draft.spellID ~= nil then
        local spellID = Util.ToNumericID(draft.spellID)
        macro.spellIDs = spellID and { spellID } or {}
    end

    if type(draft.timerNames) == "table" then
        macro.timerNames = copyArray(draft.timerNames)
    elseif type(draft.timerName) == "string" then
        local timerName = trim(draft.timerName)
        macro.timerNames = timerName ~= "" and { timerName } or {}
    end

    if macro.iconMode == "ability" and not macro.iconSpellID then
        macro.iconSpellID = Util.ToNumericID(macro.spellIDs[1])
    end
    return true, macro
end

function BossMacroService:GetRegistryCall(boss, macro, difficultyKey)
    if not boss or not macro or not boss.sourceEncounterKey or not macro.sourceCallKey then return nil end
    difficultyKey = selectedDifficulty(self, difficultyKey or macro.difficultyKey)
    local profile = Registry:GetProfile(boss.sourceEncounterKey, difficultyKey)
    return profile and profile.callsByKey and profile.callsByKey[macro.sourceCallKey] or nil
end

function BossMacroService:GetIcon(macro)
    if not macro then return 134400 end
    if macro.iconMode == "custom" and macro.customIcon then return macro.customIcon end
    local texture = spellIcon(macro.iconSpellID)
    if texture then return texture end
    for index = 1, #(macro.spellIDs or {}) do
        texture = spellIcon(macro.spellIDs[index])
        if texture then return texture end
    end
    return macro.customIcon or 134400
end

local function timerRemaining(timer)
    if not timer then return nil end
    if timer.paused == true then return tonumber(timer.pausedRemaining) end
    if type(timer.expiration) ~= "number" then return nil end
    return timer.expiration - GetTime()
end

local function numericContains(values, candidate)
    local numeric = Util.ToNumericID(candidate)
    if not numeric then return false end
    for index = 1, #(values or {}) do
        if Util.ToNumericID(values[index]) == numeric then return true end
    end
    return false
end

local function normalizedContains(values, candidate)
    local normalized = Util.NormalizeTimerName(candidate)
    if not normalized then return false end
    for index = 1, #(values or {}) do
        if Util.NormalizeTimerName(values[index]) == normalized then return true end
    end
    return false
end

function BossMacroService:TimerMatchesMacro(boss, macro, timer)
    if not boss or not macro or not timer then return false end
    if macro.sourceCallKey and timer.call and timer.call.key == macro.sourceCallKey then return true end
    if numericContains(macro.spellIDs, timer.key) then return true end
    if normalizedContains(macro.timerNames, timer.name) then return true end
    return false
end

function BossMacroService:GetBestTimer(boss, macro, timeline)
    if not macro or macro.timingEnabled ~= true or not timeline then return nil end
    if macro.difficultyKey and macro.difficultyKey ~= self.database.selectedDifficultyKey then return nil end

    if macro.sourceCallKey and type(timeline.GetActionableTimerForCall) == "function" then
        local timer, remaining = timeline:GetActionableTimerForCall(macro.sourceCallKey)
        if timer and type(remaining) == "number" and self:TimerMatchesMacro(boss, macro, timer) then
            return timer, remaining
        end
    end

    local best, bestRemaining
    for _, timer in pairs(timeline.timers or {}) do
        if timer.acknowledged ~= true and timeline:IsActionable(timer) and self:TimerMatchesMacro(boss, macro, timer) then
            local remaining = timerRemaining(timer)
            if type(remaining) == "number" and remaining >= -Constants.TIMER_EXPIRY_GRACE_SECONDS then
                if not best or remaining < bestRemaining then
                    best, bestRemaining = timer, remaining
                end
            end
        end
    end
    return best, bestRemaining
end

function BossMacroService:GetTimingState(boss, macro, timeline)
    if macro and macro.difficultyKey and macro.difficultyKey ~= self.database.selectedDifficultyKey then return nil end
    local timer, remaining = self:GetBestTimer(boss, macro, timeline)
    if not timer or type(remaining) ~= "number" then return nil end

    local difficultyKey = macro and macro.difficultyKey or self.database.selectedDifficultyKey
    local defaultCall = self:GetRegistryCall(boss, macro, difficultyKey)
    local timingCall = {
        prepareSeconds = tonumber(macro.prepareSeconds) or (defaultCall and defaultCall.prepareSeconds),
        pressSeconds = tonumber(macro.pressSeconds) or (defaultCall and defaultCall.pressSeconds),
    }
    local state = Constants.GetGuidanceState(timingCall, remaining, true, self.database.timingLead)
    return {
        timer = timer,
        remaining = remaining,
        state = state,
        startedAt = timer.startedAt,
        duration = timer.duration,
        expiration = timer.expiration,
    }
end

function BossMacroService:AcknowledgeMacro(macroId, timeline)
    local macro, boss = self:FindMacroById(macroId)
    if not macro or not boss or not timeline then return false end
    if macro.difficultyKey and macro.difficultyKey ~= self.database.selectedDifficultyKey then return false end

    if macro.sourceCallKey and type(timeline.AcknowledgeCall) == "function"
        and timeline:AcknowledgeCall(macro.sourceCallKey) then
        return true
    end

    local changed = false
    for _, timer in pairs(timeline.timers or {}) do
        if timer.acknowledged ~= true and self:TimerMatchesMacro(boss, macro, timer) then
            timer.acknowledged = true
            changed = true
        end
    end
    return changed
end

ns:RegisterModule("Services.BossMacroService", BossMacroService)
