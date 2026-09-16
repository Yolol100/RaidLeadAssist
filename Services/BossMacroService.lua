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

local function registryCallForKey(encounterKey, callKey)
    if type(encounterKey) ~= "string" or type(callKey) ~= "string" then return nil end
    for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
        local profile = Registry:GetProfile(encounterKey, difficultyKey)
        local call = profile and profile.callsByKey and profile.callsByKey[callKey] or nil
        if call then return call end
    end
end

local function macroFromCall(service, encounter, difficultyKey, call)
    local warning = customWarning(service.database, encounter.key, difficultyKey, call.key) or call.warning or call.action or call.ability
    local prepare, press = Constants.GetCallTiming(call, service.database.timingLead)
    local spellIDs = copyArray(call.spellIDs)
    local iconSpellID = Util.ToNumericID(call.iconSpellID) or Util.ToNumericID(spellIDs[1])
    return {
        id = nextMacroId(service.database),
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

local function addCallsFromProfile(service, boss, encounter, difficultyKey, seen)
    local profile = Registry:GetProfile(encounter.key, difficultyKey)
    if not profile or type(profile.calls) ~= "table" then return end
    for index = 1, #profile.calls do
        local call = profile.calls[index]
        if call and type(call.key) == "string" and not seen[call.key] then
            seen[call.key] = true
            boss.macros[#boss.macros + 1] = macroFromCall(service, encounter, difficultyKey, call)
        end
    end
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
    for _, boss in pairs(self.database.bossProfiles or {}) do
        if type(boss) == "table" and type(boss.macros) == "table" then
            for _, macro in ipairs(boss.macros) do
                if type(macro) == "table" then
                    macro.spellIDs = type(macro.spellIDs) == "table" and macro.spellIDs or {}
                    macro.timerNames = type(macro.timerNames) == "table" and macro.timerNames or {}
                    if not macro.iconSpellID then
                        local call = registryCallForKey(boss.sourceEncounterKey, macro.sourceCallKey)
                        macro.iconSpellID = Util.ToNumericID(call and call.iconSpellID) or Util.ToNumericID(macro.spellIDs[1])
                    end
                    if macro.iconMode ~= "custom" then macro.iconMode = "ability" end
                    local prepare, press = Constants.GetCallTiming({
                        prepareSeconds = macro.prepareSeconds,
                        pressSeconds = macro.pressSeconds,
                    }, self.database.timingLead)
                    macro.prepareSeconds = prepare
                    macro.pressSeconds = press
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
                macros = {},
            }
            local seen = {}
            for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
                addCallsFromProfile(self, boss, encounter, difficultyKey, seen)
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
        macros = {},
    }
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

function BossMacroService:GetMacros(bossId)
    local boss = self:GetBoss(bossId)
    if not boss then return {} end
    if type(boss.macros) ~= "table" then boss.macros = {} end
    return boss.macros
end

function BossMacroService:GetAbilityOptions(bossId)
    local boss = self:GetBoss(bossId)
    if not boss or type(boss.sourceEncounterKey) ~= "string" then return {} end

    local difficultyOrder = {}
    local preferred = self.database and self.database.selectedDifficultyKey or nil
    if preferred and Constants.DIFFICULTIES[preferred] then
        difficultyOrder[#difficultyOrder + 1] = preferred
    end
    for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
        if difficultyKey ~= preferred then difficultyOrder[#difficultyOrder + 1] = difficultyKey end
    end

    local result, seen = {}, {}
    for _, difficultyKey in ipairs(difficultyOrder) do
        local profile = Registry:GetProfile(boss.sourceEncounterKey, difficultyKey)
        for _, call in ipairs(profile and profile.calls or {}) do
            if call and type(call.key) == "string" and not seen[call.key] then
                seen[call.key] = true
                local prepare, press = Constants.GetCallTiming(call, self.database.timingLead)
                local spellIDs = copyArray(call.spellIDs)
                result[#result + 1] = {
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
    end
    return result
end

function BossMacroService:FindMacroById(id)
    local numericID = tonumber(id)
    if not numericID then return nil, nil end
    for _, boss in pairs(self.database and self.database.bossProfiles or {}) do
        if type(boss) == "table" and type(boss.macros) == "table" then
            for index = 1, #boss.macros do
                if tonumber(boss.macros[index].id) == numericID then return boss.macros[index], boss end
            end
        end
    end
end

function BossMacroService:CreateMacro(bossId)
    local boss = self:GetBoss(bossId)
    if not boss then return nil, "Unknown boss." end
    if type(boss.macros) ~= "table" then boss.macros = {} end
    local macro = {
        id = nextMacroId(self.database),
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
    boss.macros[#boss.macros + 1] = macro
    return macro
end

function BossMacroService:DeleteMacro(bossId, macroId)
    local boss = self:GetBoss(bossId)
    if not boss or type(boss.macros) ~= "table" then return false, "Unknown boss." end
    for index = 1, #boss.macros do
        if tonumber(boss.macros[index].id) == tonumber(macroId) then
            local removed = table.remove(boss.macros, index)
            return true, removed
        end
    end
    return false, "Unknown macro."
end

function BossMacroService:UpdateMacro(bossId, macroId, draft)
    local boss = self:GetBoss(bossId)
    if not boss or type(boss.macros) ~= "table" then return false, "Unknown boss." end
    local macro
    for index = 1, #boss.macros do
        if tonumber(boss.macros[index].id) == tonumber(macroId) then macro = boss.macros[index] break end
    end
    if not macro then return false, "Unknown macro." end

    local name = trim(draft and draft.name)
    local body = type(draft and draft.body) == "string" and draft.body or ""
    if name == "" then return false, "Macro name cannot be empty." end
    if body == "" then return false, "Macro commands cannot be empty." end

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
    local timer, remaining = self:GetBestTimer(boss, macro, timeline)
    if not timer or type(remaining) ~= "number" then return nil end

    local defaultCall = self:GetRegistryCall(boss, macro, self.database.selectedDifficultyKey)
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
