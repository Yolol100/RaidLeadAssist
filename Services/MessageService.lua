local _, ns = ...

local EventBus = ns:GetModule("Core.EventBus")
local Registry = ns:GetModule("Encounters.Registry")

local MessageService = {
    database = nil,
    MAX_WARNING_LENGTH = 200,
    MAX_EXPLANATION_LINES = 8,
}

local VALID_DIFFICULTIES = { normal = true, heroic = true, mythic = true }

local function trim(value)
    if type(value) ~= "string" then return "" end
    return value:match("^%s*(.-)%s*$") or ""
end

local function normalizeSingleLine(value)
    value = type(value) == "string" and value or ""
    value = value:gsub("[\r\n]+", " "):gsub("%s+", " ")
    return trim(value)
end

local function resolveDifficulty(service, difficultyKey)
    if VALID_DIFFICULTIES[difficultyKey] then return difficultyKey end
    return (service.database and service.database.selectedDifficultyKey) or Registry:GetActiveDifficulty() or "heroic"
end

local function getStoredProfile(database, bossKey, difficultyKey, create)
    if type(database.customMessages) ~= "table" then database.customMessages = {} end
    local bossProfiles = database.customMessages[bossKey]
    if bossProfiles ~= nil and type(bossProfiles) ~= "table" then
        database.customMessages[bossKey] = nil
        bossProfiles = nil
    end
    if not bossProfiles and create then
        bossProfiles = {}
        database.customMessages[bossKey] = bossProfiles
    end
    if not bossProfiles then return nil end

    local profile = bossProfiles[difficultyKey]
    if profile ~= nil and type(profile) ~= "table" then
        bossProfiles[difficultyKey] = nil
        profile = nil
    end
    if not profile and create then
        profile = { calls = {} }
        bossProfiles[difficultyKey] = profile
    end
    if profile and type(profile.calls) ~= "table" then profile.calls = {} end
    return profile
end

local function removeEmptyBoss(database, bossKey)
    local bossProfiles = database.customMessages and database.customMessages[bossKey]
    if type(bossProfiles) == "table" and next(bossProfiles) == nil then database.customMessages[bossKey] = nil end
end

function MessageService:Initialize(database)
    self.database = database
    if type(database.customMessages) ~= "table" then database.customMessages = {} end
    self:NormalizeStoredProfiles()
end

function MessageService:ValidateCallWarning(text)
    local normalized = normalizeSingleLine(text)
    if normalized == "" then return false, "Raid Warning text cannot be empty." end
    if #normalized > self.MAX_WARNING_LENGTH then
        return false, ("Raid Warning text must be %d characters or less."):format(self.MAX_WARNING_LENGTH)
    end
    return true, normalized
end

function MessageService:ParseExplanationText(text)
    if type(text) ~= "string" then return nil, "Boss Explanation must contain text." end
    local lines = {}
    text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
    for rawLine in (text .. "\n"):gmatch("(.-)\n") do
        local line = normalizeSingleLine(rawLine)
        if line ~= "" then
            if #line > self.MAX_WARNING_LENGTH then
                return nil, ("Each Boss Explanation line must be %d characters or less."):format(self.MAX_WARNING_LENGTH)
            end
            lines[#lines + 1] = line
            if #lines > self.MAX_EXPLANATION_LINES then
                return nil, ("Boss Explanation supports up to %d non-empty lines."):format(self.MAX_EXPLANATION_LINES)
            end
        end
    end
    if #lines == 0 then return nil, "Boss Explanation must contain at least one non-empty line." end
    return lines
end

function MessageService:NormalizeStoredProfiles()
    local stored = self.database.customMessages
    for bossKey, difficultyProfiles in pairs(stored) do
        if not Registry:Get(bossKey) or type(difficultyProfiles) ~= "table" then
            stored[bossKey] = nil
        else
            local cleanDifficulties = {}
            for difficultyKey, profile in pairs(difficultyProfiles) do
                local defaults = Registry:GetProfile(bossKey, difficultyKey)
                if defaults and type(profile) == "table" then
                    local cleanCalls = {}
                    if type(profile.calls) == "table" then
                        for callKey, text in pairs(profile.calls) do
                            local call = defaults.callsByKey[callKey]
                            if call then
                                local ok, normalized = self:ValidateCallWarning(text)
                                if ok and normalized ~= call.warning then cleanCalls[callKey] = normalized end
                            end
                        end
                    end

                    local cleanExplanation
                    if type(profile.explanation) == "table" then
                        local lines = self:ParseExplanationText(table.concat(profile.explanation, "\n"))
                        if lines and table.concat(lines, "\n") ~= table.concat(defaults.explanation, "\n") then
                            cleanExplanation = lines
                        end
                    end

                    if cleanExplanation or next(cleanCalls) then
                        cleanDifficulties[difficultyKey] = { explanation = cleanExplanation, calls = cleanCalls }
                    end
                end
            end
            stored[bossKey] = next(cleanDifficulties) and cleanDifficulties or nil
        end
    end
end

function MessageService:ValidateBossDraft(bossKey, difficultyKey, explanationText, callWarnings)
    if callWarnings == nil and type(explanationText) == "table" then
        callWarnings, explanationText, difficultyKey = explanationText, difficultyKey, nil
    end
    difficultyKey = resolveDifficulty(self, difficultyKey)
    local defaults = Registry:GetProfile(bossKey, difficultyKey)
    if not defaults then return false, { scope = "boss", message = "Unknown boss or difficulty." } end

    local lines, explanationError = self:ParseExplanationText(explanationText)
    if not lines then return false, { scope = "explanation", message = explanationError } end
    if type(callWarnings) ~= "table" then
        return false, { scope = "calls", message = "Combat Call Button text is missing." }
    end

    local normalizedCalls = {}
    for index = 1, #defaults.calls do
        local call = defaults.calls[index]
        local ok, value = self:ValidateCallWarning(callWarnings[call.key])
        if not ok then
            return false, { scope = "call", callKey = call.key, message = call.ability .. ": " .. value }
        end
        normalizedCalls[call.key] = value
    end
    return true, { difficultyKey = difficultyKey, explanation = lines, calls = normalizedCalls }
end

function MessageService:ApplyBossDraft(bossKey, difficultyKey, explanationText, callWarnings)
    if callWarnings == nil and type(explanationText) == "table" then
        callWarnings, explanationText, difficultyKey = explanationText, difficultyKey, nil
    end
    difficultyKey = resolveDifficulty(self, difficultyKey)
    local defaults = Registry:GetProfile(bossKey, difficultyKey)
    if not defaults then return false, { scope = "boss", message = "Unknown boss or difficulty." } end

    local ok, draft = self:ValidateBossDraft(bossKey, difficultyKey, explanationText, callWarnings)
    if not ok then return false, draft end

    local customCalls = {}
    for index = 1, #defaults.calls do
        local call = defaults.calls[index]
        if draft.calls[call.key] ~= call.warning then customCalls[call.key] = draft.calls[call.key] end
    end
    local customExplanation = table.concat(draft.explanation, "\n") ~= table.concat(defaults.explanation, "\n") and draft.explanation or nil

    if customExplanation or next(customCalls) then
        local profile = getStoredProfile(self.database, bossKey, difficultyKey, true)
        profile.explanation = customExplanation
        profile.calls = customCalls
    else
        local bossProfiles = self.database.customMessages[bossKey]
        if type(bossProfiles) == "table" then bossProfiles[difficultyKey] = nil end
        removeEmptyBoss(self.database, bossKey)
    end
    EventBus:Emit("MESSAGES_CHANGED", bossKey, difficultyKey)
    return true, draft
end

function MessageService:GetCallWarning(bossKey, difficultyKey, callKey)
    if callKey == nil then callKey, difficultyKey = difficultyKey, nil end
    difficultyKey = resolveDifficulty(self, difficultyKey)
    local defaults = Registry:GetProfile(bossKey, difficultyKey)
    local call = defaults and defaults.callsByKey[callKey]
    if not call then return nil end
    local profile = getStoredProfile(self.database, bossKey, difficultyKey, false)
    local custom = profile and profile.calls and profile.calls[callKey]
    return type(custom) == "string" and custom ~= "" and custom or call.warning
end

function MessageService:GetExplanation(bossKey, difficultyKey)
    difficultyKey = resolveDifficulty(self, difficultyKey)
    local defaults = Registry:GetProfile(bossKey, difficultyKey)
    if not defaults then return nil end
    local profile = getStoredProfile(self.database, bossKey, difficultyKey, false)
    return profile and type(profile.explanation) == "table" and #profile.explanation > 0 and profile.explanation or defaults.explanation
end

function MessageService:GetExplanationText(bossKey, difficultyKey)
    local lines = self:GetExplanation(bossKey, difficultyKey)
    return lines and table.concat(lines, "\n") or ""
end

function MessageService:SetCallWarning(bossKey, difficultyKey, callKey, text)
    if text == nil then text, callKey, difficultyKey = callKey, difficultyKey, nil end
    difficultyKey = resolveDifficulty(self, difficultyKey)
    local defaults = Registry:GetProfile(bossKey, difficultyKey)
    if not defaults or not defaults.callsByKey[callKey] then return false, "Unknown combat call." end
    local ok, normalized = self:ValidateCallWarning(text)
    if not ok then return false, normalized end
    local profile = getStoredProfile(self.database, bossKey, difficultyKey, true)
    profile.calls[callKey] = normalized ~= defaults.callsByKey[callKey].warning and normalized or nil
    EventBus:Emit("MESSAGES_CHANGED", bossKey, difficultyKey, callKey)
    return true
end

function MessageService:SetExplanationText(bossKey, difficultyKey, text)
    if text == nil then text, difficultyKey = difficultyKey, nil end
    difficultyKey = resolveDifficulty(self, difficultyKey)
    local defaults = Registry:GetProfile(bossKey, difficultyKey)
    if not defaults then return false, "Unknown boss or difficulty." end
    local lines, err = self:ParseExplanationText(text)
    if not lines then return false, err end
    local profile = getStoredProfile(self.database, bossKey, difficultyKey, true)
    profile.explanation = table.concat(lines, "\n") ~= table.concat(defaults.explanation, "\n") and lines or nil
    EventBus:Emit("MESSAGES_CHANGED", bossKey, difficultyKey, "explanation")
    return true
end

function MessageService:ResetCallWarning(bossKey, difficultyKey, callKey)
    if callKey == nil then callKey, difficultyKey = difficultyKey, nil end
    difficultyKey = resolveDifficulty(self, difficultyKey)
    local profile = getStoredProfile(self.database, bossKey, difficultyKey, false)
    if profile and profile.calls then profile.calls[callKey] = nil end
    EventBus:Emit("MESSAGES_CHANGED", bossKey, difficultyKey, callKey)
end

function MessageService:ResetExplanation(bossKey, difficultyKey)
    difficultyKey = resolveDifficulty(self, difficultyKey)
    local profile = getStoredProfile(self.database, bossKey, difficultyKey, false)
    if profile then profile.explanation = nil end
    EventBus:Emit("MESSAGES_CHANGED", bossKey, difficultyKey, "explanation")
end

function MessageService:ResetBoss(bossKey, difficultyKey)
    difficultyKey = resolveDifficulty(self, difficultyKey)
    local bossProfiles = self.database.customMessages and self.database.customMessages[bossKey]
    if type(bossProfiles) == "table" then bossProfiles[difficultyKey] = nil end
    removeEmptyBoss(self.database, bossKey)
    EventBus:Emit("MESSAGES_CHANGED", bossKey, difficultyKey)
end

function MessageService:ResetAll()
    if self.database then self.database.customMessages = {} end
    EventBus:Emit("MESSAGES_CHANGED")
end

ns:RegisterModule("Services.MessageService", MessageService)
