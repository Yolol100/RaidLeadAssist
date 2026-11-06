local _, ns = ...

local BossMacros = ns:GetModule("Services.BossMacroService")

local originalNormalizeStoredProfiles = BossMacros.NormalizeStoredProfiles
local originalSetTactics = BossMacros.SetTactics
local originalResetTactics = BossMacros.ResetTactics

local ROLE = "tactics-prepull"
local BODY_LIMIT = 228

local function trim(value)
    if type(value) ~= "string" then return "" end
    return value:match("^%s*(.-)%s*$") or ""
end

local function nextMacroId(service)
    local id = tonumber(service.database and service.database.nextMacroId) or 1
    service.database.nextMacroId = id + 1
    return id
end

local function buildBody(text)
    local lines = {}
    for line in tostring(text or ""):gmatch("[^\r\n]+") do
        line = trim(line)
        if line ~= "" then
            local candidate = "/rw " .. line
            local joined = #lines > 0 and (table.concat(lines, "\n") .. "\n" .. candidate) or candidate
            if #joined <= BODY_LIMIT then
                lines[#lines + 1] = candidate
            else
                local used = #lines > 0 and (#table.concat(lines, "\n") + 1) or 0
                local remaining = BODY_LIMIT - used - 4
                if remaining > 12 then
                    lines[#lines + 1] = "/rw " .. line:sub(1, remaining - 3) .. "..."
                end
                break
            end
        end
    end
    return table.concat(lines, "\n")
end

local function findMacro(profile)
    for _, macro in ipairs(type(profile) == "table" and profile.macros or {}) do
        if type(macro) == "table" and macro.systemRole == ROLE then return macro end
    end
end

local function syncForProfile(service, boss, difficultyKey)
    local profile = boss and boss.difficulties and boss.difficulties[difficultyKey] or nil
    if type(profile) ~= "table" or type(profile.macros) ~= "table" then return nil, nil end
    local body = buildBody(profile.tactics)
    local macro = findMacro(profile)

    if body == "" then
        if not macro then return nil, nil end
        for index = #profile.macros, 1, -1 do
            if profile.macros[index] == macro then
                table.remove(profile.macros, index)
                break
            end
        end
        return nil, macro
    end

    if not macro then
        macro = {
            id = nextMacroId(service),
            difficultyKey = difficultyKey,
            name = "Pull Tactics",
            body = body,
            sourceCallKey = nil,
            spellIDs = {},
            timerNames = {},
            iconSpellID = nil,
            iconMode = "custom",
            customIcon = "Interface\\Icons\\INV_Misc_Note_01",
            timingEnabled = false,
            prepareSeconds = 0,
            pressSeconds = 0,
            managedMacroIndex = nil,
            systemRole = ROLE,
        }
        table.insert(profile.macros, 1, macro)
    else
        macro.name = "Pull Tactics"
        macro.body = body
        macro.difficultyKey = difficultyKey
        macro.iconMode = "custom"
        macro.customIcon = "Interface\\Icons\\INV_Misc_Note_01"
        macro.timingEnabled = false
    end
    return macro
end

local function getManagedMacroService()
    local ok, managed = pcall(ns.GetModule, ns, "Services.ManagedMacroService")
    if not ok or type(managed) ~= "table" then return nil end
    return managed
end

local function syncManagedMacro(macro)
    local managed = getManagedMacroService()
    if type(macro) ~= "table" or not managed or type(managed.SyncMacro) ~= "function" then return end
    managed:SyncMacro(macro, false)
end

local function deleteManagedMacro(macro)
    local managed = getManagedMacroService()
    if type(macro) ~= "table" or not managed or type(managed.DeleteManaged) ~= "function" then return end
    managed:DeleteManaged(macro, false)
end

local function syncAll(service)
    for _, boss in pairs(service.database and service.database.bossProfiles or {}) do
        if type(boss) == "table" then
            for difficultyKey, profile in pairs(boss.difficulties or {}) do
                if type(profile) == "table" then syncForProfile(service, boss, difficultyKey) end
            end
        end
    end
end

function BossMacros:NormalizeStoredProfiles(...)
    local result = originalNormalizeStoredProfiles(self, ...)
    syncAll(self)
    return result
end

function BossMacros:SetTactics(bossId, difficultyKey, text)
    local ok, result = originalSetTactics(self, bossId, difficultyKey, text)
    local macro, removed
    if ok then
        local boss = self:GetBoss(bossId)
        macro, removed = syncForProfile(self, boss, difficultyKey)
        if removed then deleteManagedMacro(removed) else syncManagedMacro(macro) end
    end
    return ok, result, macro
end

function BossMacros:ResetTactics(bossId, difficultyKey)
    local ok, result = originalResetTactics(self, bossId, difficultyKey)
    local macro, removed
    if ok then
        local boss = self:GetBoss(bossId)
        macro, removed = syncForProfile(self, boss, difficultyKey)
        if removed then deleteManagedMacro(removed) else syncManagedMacro(macro) end
    end
    return ok, result, macro
end

function BossMacros:GetTacticsMacro(bossId, difficultyKey)
    local boss = self:GetBoss(bossId)
    local profile = boss and boss.difficulties and boss.difficulties[difficultyKey] or nil
    return findMacro(profile)
end

ns:RegisterModule("Services.TacticsMacroService", BossMacros)
