local _, ns = ...

local Util = ns:GetModule("Core.Util")

local DBMProvider = {}
DBMProvider.__index = DBMProvider

local ALLOWED_TYPES = {
    cd = true,
    stage = true,
    cast = true,
}

local function normalizeTimerID(id)
    if Util.IsSecret(id) then return nil end
    if type(id) ~= "string" and type(id) ~= "number" then return nil end
    return tostring(id)
end

local function normalizeTimerCount(value)
    if Util.IsSecret(value) or type(value) ~= "number" then return nil end
    if value ~= value or value <= 0 or value == math.huge or value == -math.huge then return nil end
    if value ~= math.floor(value) then return nil end
    return value
end

local function normalizeEncounterID(value)
    if Util.IsSecret(value) then return nil end
    if type(value) == "string" then value = tonumber(value) end
    if type(value) ~= "number" or value ~= value or value <= 0 or value == math.huge or value == -math.huge then return nil end
    if value ~= math.floor(value) then return nil end
    return value
end

local function encounterIDForMod(mod)
    if type(mod) ~= "table" then return nil end
    return normalizeEncounterID(mod.encounterId)
end

local function encounterIDForModID(modID)
    if Util.IsSecret(modID) then return nil end
    if type(modID) ~= "string" and type(modID) ~= "number" then return nil end
    if not _G.DBM then return nil end

    local mod
    if type(DBM.GetModByName) == "function" then
        local ok, result = pcall(DBM.GetModByName, DBM, modID)
        if ok and type(result) == "table" then mod = result end
    end

    if not mod and type(DBM.Mods) == "table" then
        local wanted = tostring(modID)
        for index = 1, #DBM.Mods do
            local candidate = DBM.Mods[index]
            if type(candidate) == "table" and not Util.IsSecret(candidate.id)
                and tostring(candidate.id) == wanted then
                mod = candidate
                break
            end
        end
    end

    return encounterIDForMod(mod)
end

local function canSupplyBossTimers()
    if not _G.DBM then return false end
    if type(DBM.Options) ~= "table" then return true end

    -- DBM 12.1.3 Timer:Start returns before DBM_TimerBegin when either of
    -- these global boss-bar switches is enabled. In that mode DBM cannot be
    -- RLA's timer authority, so Blizzard-derived data must remain available.
    return DBM.Options.HideDBMBars ~= true
        and DBM.Options.DontShowBossTimers ~= true
end

function DBMProvider:IsAvailable()
    return _G.DBM and type(DBM.RegisterCallback) == "function"
end

function DBMProvider:CanSupplyBossTimers()
    return canSupplyBossTimers()
end

function DBMProvider:RefreshAuthority()
    if not self.sink or type(self.sink.SetBlizzardSuppressedByProvider) ~= "function" then return false end

    local ignoreBlizzard = _G.DBM and type(DBM.Options) == "table"
        and DBM.Options.IgnoreBlizzAPI == true
    return self.sink:SetBlizzardSuppressedByProvider("DBM", ignoreBlizzard and canSupplyBossTimers())
end

function DBMProvider:SeedEncounterHint()
    if not self.sink or not _G.DBM or type(DBM.Mods) ~= "table"
        or type(self.sink.ProviderEncounterHint) ~= "function" then
        return false
    end

    for index = 1, #DBM.Mods do
        local mod = DBM.Mods[index]
        if type(mod) == "table" and type(mod.IsInCombat) == "function" then
            local ok, inCombat = pcall(mod.IsInCombat, mod)
            if ok and inCombat == true then
                local encounterID = encounterIDForMod(mod)
                if encounterID then
                    self.sink:ProviderEncounterHint("DBM", encounterID)
                    return true
                end
            end
        end
    end

    return false
end

function DBMProvider:Start(sink)
    if not self:IsAvailable() then return false end

    self.sink = sink

    self.onBegin = function(_, id, message, duration, icon, simpleType, spellID, _, modID, _, fade, spellName, _, timerCount, _, _, hasVariance, _, isEnabled)
        self:RefreshAuthority()

        local timerID = normalizeTimerID(id)
        if not timerID then return end
        if Util.IsSecret(duration) or Util.IsSecret(simpleType) or Util.IsSecret(fade)
            or Util.IsSecret(hasVariance) or Util.IsSecret(isEnabled) then return end
        if type(duration) ~= "number" or duration <= 0 then return end
        if hasVariance == true or isEnabled ~= true then return end
        if not ALLOWED_TYPES[simpleType] then return end

        -- Current DBM exposes self.mod.id in TimerBegin. Resolve that public mod
        -- identity back to the loaded DBM boss module and require its real
        -- encounterId. This rejects utility/non-boss DBM timers and prevents a
        -- direct timer from being interpreted under another RLA encounter.
        local encounterID = encounterIDForModID(modID)
        if not encounterID then return end

        self.sink:ProviderTimerStarted("DBM", timerID, {
            key = Util.ToNumericID(spellID) or (not Util.IsSecret(spellID) and spellID or nil),
            name = not Util.IsSecret(spellName) and spellName or (not Util.IsSecret(message) and message or nil),
            duration = duration,
            icon = Util.NormalizeTexture(icon),
            count = normalizeTimerCount(timerCount),
            encounterID = encounterID,
            precision = "exact",
            faded = fade == true,
        })
    end

    self.onStop = function(_, id)
        local timerID = normalizeTimerID(id)
        if timerID then self.sink:ProviderTimerStopped("DBM", timerID, "stopped") end
    end

    self.onUpdate = function(_, id, elapsed, total)
        local timerID = normalizeTimerID(id)
        if not timerID or Util.IsSecret(elapsed) or Util.IsSecret(total) then return end
        self.sink:ProviderTimerUpdated("DBM", timerID, elapsed, total)
    end

    self.onPause = function(_, id)
        local timerID = normalizeTimerID(id)
        if timerID then self.sink:ProviderTimerPaused("DBM", timerID, true) end
    end

    self.onResume = function(_, id)
        local timerID = normalizeTimerID(id)
        if timerID then self.sink:ProviderTimerPaused("DBM", timerID, false) end
    end

    self.onFadeUpdate = function(_, id, _, _, fade)
        local timerID = normalizeTimerID(id)
        if not timerID or Util.IsSecret(fade) then return end
        if type(self.sink.ProviderTimerFaded) == "function" then
            self.sink:ProviderTimerFaded("DBM", timerID, fade == true)
        end
    end

    self.onIgnoreBlizzard = function()
        self:RefreshAuthority()
    end

    self.onResumeBlizzard = function()
        if type(self.sink.SetBlizzardSuppressedByProvider) == "function" then
            self.sink:SetBlizzardSuppressedByProvider("DBM", false)
        end
    end

    self.onPull = function(_, mod)
        local encounterID = encounterIDForMod(mod)
        if encounterID and type(self.sink.ProviderEncounterHint) == "function" then
            self.sink:ProviderEncounterHint("DBM", encounterID)
        end
    end

    self.onReset = function()
        self.sink:ProviderReset("DBM")
        if type(self.sink.SetBlizzardSuppressedByProvider) == "function" then
            self.sink:SetBlizzardSuppressedByProvider("DBM", false)
        end
    end

    DBM:RegisterCallback("DBM_TimerBegin", self.onBegin)
    DBM:RegisterCallback("DBM_TimerStop", self.onStop)
    DBM:RegisterCallback("DBM_TimerUpdate", self.onUpdate)
    DBM:RegisterCallback("DBM_TimerPause", self.onPause)
    DBM:RegisterCallback("DBM_TimerResume", self.onResume)
    DBM:RegisterCallback("DBM_TimerFadeUpdate", self.onFadeUpdate)
    DBM:RegisterCallback("DBM_IgnoreBlizzAPI", self.onIgnoreBlizzard)
    DBM:RegisterCallback("DBM_ResumeBlizzAPI", self.onResumeBlizzard)
    DBM:RegisterCallback("DBM_Pull", self.onPull)
    DBM:RegisterCallback("DBM_Wipe", self.onReset)
    DBM:RegisterCallback("DBM_Kill", self.onReset)

    -- A reload can happen after DBM has already taken authority over Blizzard's
    -- Encounter Timeline. Reconstruct the effective public DBM state instead of
    -- waiting for a callback that may already have happened. Global DBM bar-off
    -- settings always yield authority back to native Blizzard timing.
    self:RefreshAuthority()

    return true
end

function DBMProvider:Stop()
    if self.sink and type(self.sink.SetBlizzardSuppressedByProvider) == "function" then
        self.sink:SetBlizzardSuppressedByProvider("DBM", false)
    end

    if not _G.DBM or not DBM.UnregisterCallback then return end

    local callbacks = {
        DBM_TimerBegin = self.onBegin,
        DBM_TimerStop = self.onStop,
        DBM_TimerUpdate = self.onUpdate,
        DBM_TimerPause = self.onPause,
        DBM_TimerResume = self.onResume,
        DBM_TimerFadeUpdate = self.onFadeUpdate,
        DBM_IgnoreBlizzAPI = self.onIgnoreBlizzard,
        DBM_ResumeBlizzAPI = self.onResumeBlizzard,
        DBM_Pull = self.onPull,
        DBM_Wipe = self.onReset,
        DBM_Kill = self.onReset,
    }

    for eventName, callback in pairs(callbacks) do
        if callback then DBM:UnregisterCallback(eventName, callback) end
    end
end

ns:RegisterModule("Services.Providers.DBM", setmetatable({}, DBMProvider))
