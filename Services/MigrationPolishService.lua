local _, ns = ...

local Registry = ns:GetModule("Encounters.Registry")
local BossMacros = ns:GetModule("Services.BossMacroService")

local originalNormalizeStoredProfiles = BossMacros.NormalizeStoredProfiles

local function looksLikeLegacyCapsWarning(body)
    if type(body) ~= "string" then return false end
    local warning = body:match("^/rw%s+(.+)$")
    if not warning or #warning < 6 then return false end
    local letters = warning:gsub("[^A-Za-z]", "")
    if #letters < 5 then return false end
    return letters == letters:upper()
end

local function migrateLinkedDefaultMacros(service)
    for _, boss in pairs(service.database and service.database.bossProfiles or {}) do
        if type(boss) == "table" and boss.defaultProfile == true and type(boss.sourceEncounterKey) == "string" then
            for difficultyKey, difficulty in pairs(boss.difficulties or {}) do
                local profile = Registry:GetProfile(boss.sourceEncounterKey, difficultyKey)
                local callsByKey = profile and profile.callsByKey or nil
                for _, macro in ipairs(type(difficulty) == "table" and difficulty.macros or {}) do
                    local call = callsByKey and type(macro) == "table" and callsByKey[macro.sourceCallKey] or nil
                    if call then
                        if looksLikeLegacyCapsWarning(macro.body) then
                            macro.body = "/rw " .. tostring(call.warning or call.action or call.ability or "")
                        end
                        if macro.iconMode == "custom" and tonumber(macro.customIcon) == 134400 then
                            macro.iconMode = "ability"
                            macro.customIcon = nil
                            macro.iconSpellID = call.iconSpellID or (call.spellIDs and call.spellIDs[1]) or macro.iconSpellID
                        end
                    end
                end
            end
        end
    end
end

function BossMacros:NormalizeStoredProfiles(...)
    local result = originalNormalizeStoredProfiles(self, ...)
    migrateLinkedDefaultMacros(self)
    return result
end

ns:RegisterModule("Services.MigrationPolishService", BossMacros)
