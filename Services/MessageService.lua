local _, ns = ...

local EventBus = ns:GetModule("Core.EventBus")
local Registry = ns:GetModule("Encounters.Registry")

local MessageService = {
    database = nil,
    MAX_WARNING_LENGTH = 200,
    MAX_EXPLANATION_LINES = 8,
}

local function trim(value)
    if type(value) ~= "string" then return "" end
    return value:match("^%s*(.-)%s*$") or ""
end

local function normalizeSingleLine(value)
    value = type(value) == "string" and value or ""
    value = value:gsub("[\r\n]+", " ")
    value = value:gsub("%s+", " ")
    return trim(value)
end

local function getProfile(database, bossKey, create)
    if type(database.customMessages) ~= "table" then database.customMessages = {} end
    local profile = database.customMessages[bossKey]

    if profile ~= nil and type(profile) ~= "table" then
        database.customMessages[bossKey] = nil
        profile = nil
    end

    if not profile and create then
        profile = { calls = {} }
        database.customMessages[bossKey] = profile
    end

    if profile and type(profile.calls) ~= "table" then profile.calls = {} end
    return profile
end

function MessageService:Initialize(database)
    self.database = database
    if type(database.customMessages) ~= "table" then database.customMessages = {} end
    self:NormalizeStoredProfiles()
end

function MessageService:NormalizeStoredProfiles()
    local stored = self.database.customMessages
    if type(stored) ~= "table" then
        self.database.customMessages = {}
        return
    end

    for bossKey, profile in pairs(stored) do
        local encounter = Registry:Get(bossKey)
        if not encounter or type(profile) ~= "table" then
            stored[bossKey] = nil
        else
            local cleanCalls = {}
            if type(profile.calls) == "table" then
                for callKey, text in pairs(profile.calls) do
                    if encounter.callsByKey[callKey] then
                        local ok, normalized = self:ValidateCallWarning(text)
                        if ok and normalized ~= encounter.callsByKey[callKey].warning then
                            cleanCalls[callKey] = normalized
                        end
                    end
                end
            end

            local cleanExplanation
            if type(profile.explanation) == "table" then
                local rawLines = {}
                for index = 1, #profile.explanation do
                    if type(profile.explanation[index]) == "string" then
                        rawLines[#rawLines + 1] = profile.explanation[index]
                    end
                end
                if #rawLines > 0 then
                    local lines = self:ParseExplanationText(table.concat(rawLines, "\n"))
                    if lines and table.concat(lines, "\n") ~= table.concat(encounter.explanation, "\n") then
                        cleanExplanation = lines
                    end
                end
            end

            if cleanExplanation or next(cleanCalls) then
                stored[bossKey] = {
                    explanation = cleanExplanation,
                    calls = cleanCalls,
                }
            else
                stored[bossKey] = nil
            end
        end
    end
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

function MessageService:ValidateBossDraft(bossKey, explanationText, callWarnings)
    local encounter = Registry:Get(bossKey)
    if not encounter then
        return false, { scope = "boss", message = "Unknown boss." }
    end

    local lines, explanationError = self:ParseExplanationText(explanationText)
    if not lines then
        return false, { scope = "explanation", message = explanationError }
    end

    if type(callWarnings) ~= "table" then
        return false, { scope = "calls", message = "Combat Call Button text is missing." }
    end

    local normalizedCalls = {}
    for index = 1, #encounter.calls do
        local call = encounter.calls[index]
        local ok, value = self:ValidateCallWarning(callWarnings[call.key])
        if not ok then
            return false, {
                scope = "call",
                callKey = call.key,
                message = call.ability .. ": " .. value,
            }
        end
        normalizedCalls[call.key] = value
    end

    return true, {
        explanation = lines,
        calls = normalizedCalls,
    }
end

function MessageService:ApplyBossDraft(bossKey, explanationText, callWarnings)
    local encounter = Registry:Get(bossKey)
    if not encounter then
        return false, { scope = "boss", message = "Unknown boss." }
    end

    local ok, draft = self:ValidateBossDraft(bossKey, explanationText, callWarnings)
    if not ok then return false, draft end

    local customCalls = {}
    for index = 1, #encounter.calls do
        local call = encounter.calls[index]
        local value = draft.calls[call.key]
        if value ~= call.warning then customCalls[call.key] = value end
    end

    local defaultExplanation = table.concat(encounter.explanation, "\n")
    local normalizedExplanation = table.concat(draft.explanation, "\n")
    local customExplanation = normalizedExplanation ~= defaultExplanation and draft.explanation or nil

    if customExplanation or next(customCalls) then
        self.database.customMessages[bossKey] = {
            explanation = customExplanation,
            calls = customCalls,
        }
    else
        self.database.customMessages[bossKey] = nil
    end

    EventBus:Emit("MESSAGES_CHANGED", bossKey)
    return true, draft
end

function MessageService:GetCallWarning(bossKey, callKey)
    local encounter = Registry:Get(bossKey)
    local call = encounter and encounter.callsByKey[callKey]
    if not call then return nil end

    local profile = getProfile(self.database, bossKey, false)
    local custom = profile and profile.calls and profile.calls[callKey]
    if type(custom) == "string" and custom ~= "" then return custom end
    return call.warning
end

function MessageService:GetExplanation(bossKey)
    local encounter = Registry:Get(bossKey)
    if not encounter then return nil end

    local profile = getProfile(self.database, bossKey, false)
    if profile and type(profile.explanation) == "table" and #profile.explanation > 0 then
        return profile.explanation
    end
    return encounter.explanation
end

function MessageService:GetExplanationText(bossKey)
    local lines = self:GetExplanation(bossKey)
    return lines and table.concat(lines, "\n") or ""
end

function MessageService:SetCallWarning(bossKey, callKey, text)
    local encounter = Registry:Get(bossKey)
    if not encounter or not encounter.callsByKey[callKey] then return false, "Unknown combat call." end

    local ok, normalized = self:ValidateCallWarning(text)
    if not ok then return false, normalized end

    local profile = getProfile(self.database, bossKey, true)
    local defaultText = encounter.callsByKey[callKey].warning
    profile.calls[callKey] = normalized ~= defaultText and normalized or nil
    EventBus:Emit("MESSAGES_CHANGED", bossKey, callKey)
    return true
end

function MessageService:SetExplanationText(bossKey, text)
    local encounter = Registry:Get(bossKey)
    if not encounter then return false, "Unknown boss." end

    local lines, err = self:ParseExplanationText(text)
    if not lines then return false, err end

    local profile = getProfile(self.database, bossKey, true)
    local defaultText = table.concat(encounter.explanation, "\n")
    profile.explanation = table.concat(lines, "\n") ~= defaultText and lines or nil
    EventBus:Emit("MESSAGES_CHANGED", bossKey, "explanation")
    return true
end

function MessageService:ResetCallWarning(bossKey, callKey)
    local profile = getProfile(self.database, bossKey, false)
    if profile and profile.calls then profile.calls[callKey] = nil end
    EventBus:Emit("MESSAGES_CHANGED", bossKey, callKey)
end

function MessageService:ResetExplanation(bossKey)
    local profile = getProfile(self.database, bossKey, false)
    if profile then profile.explanation = nil end
    EventBus:Emit("MESSAGES_CHANGED", bossKey, "explanation")
end

function MessageService:ResetBoss(bossKey)
    if self.database and self.database.customMessages then self.database.customMessages[bossKey] = nil end
    EventBus:Emit("MESSAGES_CHANGED", bossKey)
end

function MessageService:ResetAll()
    if self.database then self.database.customMessages = {} end
    EventBus:Emit("MESSAGES_CHANGED")
end

ns:RegisterModule("Services.MessageService", MessageService)
