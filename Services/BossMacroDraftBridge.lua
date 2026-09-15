local _, ns = ...

local BossMacros = ns:GetModule("Services.BossMacroService")
local originalUpdateMacro = BossMacros.UpdateMacro

local function copyArray(source)
    local result = {}
    if type(source) ~= "table" then return result end
    for index = 1, #source do result[index] = source[index] end
    return result
end

function BossMacros:UpdateMacro(bossId, macroId, draft)
    local ok, macroOrError = originalUpdateMacro(self, bossId, macroId, draft)
    if not ok then return false, macroOrError end

    local macro = macroOrError
    if type(draft) == "table" then
        macro.sourceCallKey = type(draft.sourceCallKey) == "string" and draft.sourceCallKey or nil
        if type(draft.spellIDs) == "table" then macro.spellIDs = copyArray(draft.spellIDs) end
        if type(draft.timerNames) == "table" then macro.timerNames = copyArray(draft.timerNames) end
    end
    return true, macro
end

ns:RegisterModule("Services.BossMacroDraftBridge", {})
