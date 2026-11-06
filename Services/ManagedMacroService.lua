local _, ns = ...

local BossMacros = ns:GetModule("Services.BossMacroService")

local ManagedMacroService = {
    database = nil,
    acknowledgeCallback = nil,
    frame = nil,
    reconciling = false,
    migrating = false,
    migrationWarningShown = false,
}

local function accountMacroMax()
    local globalConstants = _G.Constants
    local macroConstants = globalConstants and globalConstants.MacroConsts
    return (macroConstants and tonumber(macroConstants.MAX_ACCOUNT_MACROS))
        or tonumber(_G.MAX_ACCOUNT_MACROS)
        or 120
end

local function macroBodyMax()
    local globalConstants = _G.Constants
    local macroConstants = globalConstants and globalConstants.MacroConsts
    return (macroConstants and tonumber(macroConstants.MAX_MACRO_LENGTH)) or 255
end

local function trim(value)
    if type(value) ~= "string" then return "" end
    return value:match("^%s*(.-)%s*$") or ""
end

local function markerLine(macroId)
    return ("/run RLA_P(%d)"):format(tonumber(macroId) or 0)
end

local function managedBody(macro)
    local body = type(macro and macro.body) == "string" and macro.body or ""
    body = body:gsub("%s+$", "")
    local marker = markerLine(macro and macro.id)
    if body == "" then return marker end
    return body .. "\n" .. marker
end

local function parseManagedId(body)
    if type(body) ~= "string" then return nil end
    local value = body:match("/run%s+RLA_P%((%d+)%)")
    return value and tonumber(value) or nil
end

local function macroInfo(index)
    if type(index) ~= "number" then return nil end
    local name, icon, body = GetMacroInfo(index)
    if not name then return nil end
    return { index = index, name = name, icon = icon, body = body or "" }
end

local function generalMacroRange()
    local accountCount = select(1, GetNumMacros())
    return 1, tonumber(accountCount) or 0
end

local function characterMacroRange()
    local _, characterCount = GetNumMacros()
    local base = accountMacroMax()
    local first = base + 1
    local last = base + (tonumber(characterCount) or 0)
    return first, last
end

local function findInRangeByMarker(macroId, first, last)
    local numericId = tonumber(macroId)
    if not numericId then return nil end
    for index = first, last do
        local info = macroInfo(index)
        if info and parseManagedId(info.body) == numericId then return info end
    end
end

local function findGeneralByMarker(macroId)
    local first, last = generalMacroRange()
    return findInRangeByMarker(macroId, first, last)
end

local function findCharacterByMarker(macroId)
    local first, last = characterMacroRange()
    return findInRangeByMarker(macroId, first, last)
end

local function findByMarker(macroId)
    return findGeneralByMarker(macroId)
end

local function safeName(macro)
    local name = trim(macro and macro.name)
    if name == "" then name = "RLA Macro" end
    return name:sub(1, 16)
end

local function inCombat()
    return type(InCombatLockdown) == "function" and InCombatLockdown() == true
end

local function deleteMacroAt(index)
    if not index then return true end
    local ok, result = pcall(DeleteMacro, index)
    return ok and result ~= false
end

function ManagedMacroService:GetManagedOverhead(macroId)
    return 1 + #markerLine(macroId)
end

function ManagedMacroService:GetMacroBodyMax()
    return macroBodyMax()
end

function ManagedMacroService:ValidateMacro(macro)
    if type(macro) ~= "table" or not tonumber(macro.id) then return false, "Invalid Raid Lead Assist macro." end
    local body = managedBody(macro)
    local maxLength = macroBodyMax()
    if #body > maxLength then
        return false, ("Macro is %d characters; World of Warcraft allows %d including the Raid Lead Assist timer marker."):format(#body, maxLength)
    end
    return true, body
end

function ManagedMacroService:Queue(macroId, operation)
    if not self.database then return end
    if type(self.database.pendingMacroSync) ~= "table" then self.database.pendingMacroSync = {} end
    self.database.pendingMacroSync[tostring(macroId)] = operation or "sync"
end

function ManagedMacroService:ClearQueue(macroId)
    if self.database and type(self.database.pendingMacroSync) == "table" then
        self.database.pendingMacroSync[tostring(macroId)] = nil
    end
end

function ManagedMacroService:SyncMacro(macro, silent)
    if type(macro) ~= "table" then return false, "Unknown macro." end
    if inCombat() then
        self:Queue(macro.id, "sync")
        if not silent then ns:Print("Macro update queued until combat ends.") end
        return false, "combat"
    end

    local valid, bodyOrError = self:ValidateMacro(macro)
    if not valid then
        if not silent then ns:Print(bodyOrError) end
        return false, bodyOrError
    end

    local body = bodyOrError
    local name = safeName(macro)
    local icon = BossMacros:GetIcon(macro)
    local existing = findGeneralByMarker(macro.id)
    local legacyCharacter = findCharacterByMarker(macro.id)
    local index

    if existing then
        local ok, result = pcall(EditMacro, existing.index, name, icon, body)
        if not ok or not result then
            local message = "Could not update the managed General Macro."
            if not silent then ns:Print(message) end
            return false, message
        end
        index = tonumber(result) or existing.index
    else
        -- false means account-wide: the macro is stored under WoW's General Macros,
        -- not under the current character's character-specific macro tab.
        local ok, result = pcall(CreateMacro, name, icon, body, false)
        if not ok or not result then
            local message = "Could not create a General Macro. Check whether your General Macro slots are full."
            if not silent then ns:Print(message) end
            return false, message
        end
        index = tonumber(result)
    end

    -- Older RaidLeadAssist builds created character-specific macros. Once the
    -- General Macro exists successfully, remove that legacy copy so there is only
    -- one managed WoW macro for this RLA macro id.
    if legacyCharacter then
        deleteMacroAt(legacyCharacter.index)
    end

    macro.managedMacroIndex = index
    self:ClearQueue(macro.id)
    return true, index
end

function ManagedMacroService:DeleteManaged(macroOrId, silent)
    local macroId = type(macroOrId) == "table" and macroOrId.id or macroOrId
    macroId = tonumber(macroId)
    if not macroId then return false, "Invalid macro id." end

    if inCombat() then
        self:Queue(macroId, "delete")
        if not silent then ns:Print("Macro deletion queued until combat ends.") end
        return false, "combat"
    end

    local general = findGeneralByMarker(macroId)
    if general and not deleteMacroAt(general.index) then
        local message = "Could not delete the managed General Macro."
        if not silent then ns:Print(message) end
        return false, message
    end

    -- Also clean up a legacy character-specific copy left by older versions.
    local character = findCharacterByMarker(macroId)
    if character and not deleteMacroAt(character.index) then
        local message = "Could not delete the legacy character macro."
        if not silent then ns:Print(message) end
        return false, message
    end

    self:ClearQueue(macroId)
    return true
end

function ManagedMacroService:Pickup(macro)
    if type(macro) ~= "table" then return false, "Unknown macro." end
    if inCombat() then
        ns:Print("Action-bar placement is unavailable during combat. Try again when combat ends.")
        return false, "combat"
    end

    local ok, indexOrError = self:SyncMacro(macro, true)
    if not ok then
        if indexOrError ~= "combat" then ns:Print(indexOrError or "Could not prepare macro.") end
        return false, indexOrError
    end

    local pickupOk = pcall(PickupMacro, indexOrError)
    if not pickupOk then
        ns:Print("Could not pick up the managed macro.")
        return false, "pickup"
    end
    return true
end

function ManagedMacroService:GetManagedIdByMacroIndex(index)
    local info = macroInfo(tonumber(index))
    return info and parseManagedId(info.body) or nil
end

function ManagedMacroService:GetMacroIndex(macroId)
    local existing = findByMarker(macroId)
    return existing and existing.index or nil
end

function ManagedMacroService:FlushQueue()
    if inCombat() or not self.database or type(self.database.pendingMacroSync) ~= "table" then return end
    local operations = {}
    for key, operation in pairs(self.database.pendingMacroSync) do
        operations[#operations + 1] = { id = tonumber(key), operation = operation }
    end
    table.sort(operations, function(a, b) return (a.id or 0) < (b.id or 0) end)

    for _, item in ipairs(operations) do
        if item.id then
            if item.operation == "delete" then
                self:DeleteManaged(item.id, true)
            else
                local macro = BossMacros:FindMacroById(item.id)
                if macro then
                    self:SyncMacro(macro, true)
                else
                    self:DeleteManaged(item.id, true)
                end
            end
        end
    end
end

function ManagedMacroService:MigrateCharacterMacros()
    if self.migrating or inCombat() then return end
    self.migrating = true

    local failed = 0
    for _, boss in ipairs(BossMacros:GetBossesOrdered()) do
        for _, macro in ipairs(BossMacros:GetAllMacros(boss.id)) do
            if findCharacterByMarker(macro.id) then
                local ok = self:SyncMacro(macro, true)
                if not ok then failed = failed + 1 end
            end
        end
    end

    self.migrating = false
    if failed > 0 and not self.migrationWarningShown then
        self.migrationWarningShown = true
        ns:Print(("Could not move %d RaidLeadAssist macro(s) to General Macros. Check whether your General Macro slots are full."):format(failed))
    elseif failed == 0 then
        self.migrationWarningShown = false
    end
end

function ManagedMacroService:ReconcileIndices()
    if self.reconciling then return end
    self.reconciling = true
    for _, boss in ipairs(BossMacros:GetBossesOrdered()) do
        for _, macro in ipairs(BossMacros:GetAllMacros(boss.id)) do
            macro.managedMacroIndex = self:GetMacroIndex(macro.id)
        end
    end
    self.reconciling = false
end

function ManagedMacroService:Acknowledge(macroId)
    macroId = tonumber(macroId)
    if not macroId then return end
    if self.acknowledgeCallback then
        pcall(self.acknowledgeCallback, macroId)
    end
end

function ManagedMacroService:Initialize(database, acknowledgeCallback)
    self.database = database
    self.acknowledgeCallback = acknowledgeCallback
    if type(database.pendingMacroSync) ~= "table" then database.pendingMacroSync = {} end

    _G.RLA_P = function(macroId)
        ManagedMacroService:Acknowledge(macroId)
    end

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("UPDATE_MACROS")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:SetScript("OnEvent", function(_, eventName)
        if inCombat() then return end
        if eventName == "PLAYER_REGEN_ENABLED" then
            self:FlushQueue()
        end
        self:MigrateCharacterMacros()
        self:ReconcileIndices()
    end)
    self.frame = frame

    if not inCombat() then
        C_Timer.After(0, function()
            if inCombat() then return end
            self:MigrateCharacterMacros()
            self:ReconcileIndices()
            self:FlushQueue()
        end)
    end
end

ns:RegisterModule("Services.ManagedMacroService", ManagedMacroService)
