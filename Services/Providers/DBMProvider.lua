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

local function encounterIDForMod(mod)
    if type(mod) ~= "table" then return nil end
    local encounterID = mod.encounterId
    if Util.IsSecret(encounterID) then return nil end
    if type(encounterID) == "number" then return encounterID end
    if type(encounterID) == "string" then return tonumber(encounterID) end
end

function DBMProvider:IsAvailable()
    return _G.DBM and type(DBM.RegisterCallback) == "function"
end

function DBMProvider:Start(sink)
    if not self:IsAvailable() then return false end

    self.sink = sink

    self.onBegin = function(_, id, message, duration, icon, simpleType, spellID, _, _, _, fade, spellName, _, _, _, _, hasVariance, _, isEnabled)
        local timerID = normalizeTimerID(id)
        if not timerID then return end
        if Util.IsSecret(duration) or Util.IsSecret(simpleType) or Util.IsSecret(fade)
            or Util.IsSecret(hasVariance) or Util.IsSecret(isEnabled) then return end
        if type(duration) ~= "number" or duration <= 0 then return end
        if hasVariance == true or fade == true or isEnabled ~= true then return end
        if not ALLOWED_TYPES[simpleType] then return end

        self.sink:ProviderTimerStarted("DBM", timerID, {
            key = Util.ToNumericID(spellID) or (not Util.IsSecret(spellID) and spellID or nil),
            name = not Util.IsSecret(spellName) and spellName or (not Util.IsSecret(message) and message or nil),
            duration = duration,
            icon = Util.NormalizeTexture(icon),
            precision = "exact",
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
        if timerID and fade == true then
            self.sink:ProviderTimerStopped("DBM", timerID, "faded")
        end
    end

    self.onIgnoreBlizzard = function()
        if type(self.sink.SetBlizzardSuppressedByProvider) == "function" then
            self.sink:SetBlizzardSuppressedByProvider("DBM", true)
        end
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
    -- Encounter Timeline. Reconstruct that public DBM state instead of waiting
    -- for a callback that has already happened.
    if DBM.Options and DBM.Options.IgnoreBlizzAPI == true then
        self.onIgnoreBlizzard()
    end

    return true
end

function DBMProvider:Stop()
    if not _G.DBM or not DBM.UnregisterCallback then return end

    if self.sink and type(self.sink.SetBlizzardSuppressedByProvider) == "function" then
        self.sink:SetBlizzardSuppressedByProvider("DBM", false)
    end

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
