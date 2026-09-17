local _, ns = ...

local Util = {}

local secretValuePredicate = _G.issecretvalue
local secretTablePredicate = _G.issecrettable
local tableAccessPredicate = _G.canaccesstable

local function predicateTrue(predicate, value)
    if type(predicate) ~= "function" then return false end
    local ok, result = pcall(predicate, value)
    return ok and result == true
end

function Util.IsSecret(value)
    return predicateTrue(secretValuePredicate, value)
end

function Util.IsSecretTable(value)
    return type(value) == "table" and predicateTrue(secretTablePredicate, value)
end

function Util.CanAccessTable(value)
    if type(value) ~= "table" then return false end
    if Util.IsSecret(value) or Util.IsSecretTable(value) then return false end
    if type(tableAccessPredicate) == "function" then
        local ok, canAccess = pcall(tableAccessPredicate, value)
        if not ok or canAccess ~= true then return false end
    end
    return true
end

function Util.Clamp(value, minimum, maximum)
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

function Util.Normalize(value)
    if type(value) ~= "string" or Util.IsSecret(value) then
        return nil
    end
    return value:lower():gsub("[^%w]", "")
end

function Util.NormalizeTimerName(value)
    if type(value) ~= "string" or Util.IsSecret(value) then
        return nil
    end

    local normalized = value
    normalized = normalized:gsub("|c%x%x%x%x%x%x%x%x", "")
    normalized = normalized:gsub("|r", "")
    normalized = normalized:gsub("|T.-|t", "")
    normalized = normalized:gsub("|A.-|a", "")
    normalized = normalized:gsub("^%s*%[B%]%s*", "")
    normalized = normalized:gsub("%s+%(%d+%)%s*$", "")
    normalized = normalized:gsub("%s+#%d+%s*$", "")
    return Util.Normalize(normalized)
end

function Util.ToNumericID(value)
    if Util.IsSecret(value) then return nil end
    if type(value) == "number" then return value end
    if type(value) == "string" then return tonumber(value) end
    return nil
end

function Util.IsRaidLeaderOrAssistant()
    return IsInRaid() and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player"))
end

function Util.NormalizeTexture(texture)
    if Util.IsSecret(texture) then return nil end
    if type(texture) == "number" then return texture end
    if type(texture) == "string" then
        return tonumber(texture) or texture
    end
    return nil
end

function Util.GetSpellIcon(spellID)
    if type(spellID) ~= "number" or Util.IsSecret(spellID) then
        return nil
    end
    return C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID) or nil
end

function Util.CopyDefaults(target, defaults)
    target = type(target) == "table" and target or {}
    for key, value in pairs(defaults) do
        if target[key] == nil then
            if type(value) == "table" then
                target[key] = Util.CopyDefaults({}, value)
            else
                target[key] = value
            end
        elseif type(value) == "table" and type(target[key]) == "table" then
            Util.CopyDefaults(target[key], value)
        end
    end
    return target
end

ns:RegisterModule("Core.Util", Util)
