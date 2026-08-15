local _, ns = ...

local Util = ns:GetModule("Core.Util")

local BigWigsProvider = {}
BigWigsProvider.__index = BigWigsProvider

local PENDING_EVENT_MAX_AGE = 1

local function moduleID(module)
    if module == nil then return "blizzard-timeline" end
    if type(module) == "table" and type(module.moduleName) == "string" then return module.moduleName end
    return tostring(module)
end

local function textAlias(module, text)
    if Util.IsSecret(text) then return nil end
    return moduleID(module) .. "|text:" .. tostring(text)
end

local function validEventID(eventID)
    if Util.IsSecret(eventID) then return false end
    local valueType = type(eventID)
    return valueType == "string" or valueType == "number"
end

local function normalizeCounter(value)
    if Util.IsSecret(value) or type(value) ~= "number" then return nil end
    if value ~= value or value <= 0 or value == math.huge or value == -math.huge then return nil end
    if value ~= math.floor(value) then return nil end
    return value
end

local function clock()
    local getTime = _G.GetTime
    if type(getTime) ~= "function" then return nil end
    local ok, value = pcall(getTime)
    if not ok or Util.IsSecret(value) or type(value) ~= "number" or value ~= value then return nil end
    return value
end

local function makeTimerID(module, text, eventID)
    if validEventID(eventID) then
        return moduleID(module) .. "|event:" .. tostring(eventID)
    end
    return textAlias(module, text)
end

local function chooseEventID(primary, fallback)
    if validEventID(primary) then return primary end
    if validEventID(fallback) then return fallback end
    return nil
end

local function directTimerKey(module, key, text)
    if module == nil or Util.IsSecret(key) or Util.IsSecret(text) then return nil end
    local keyType = type(key)
    if keyType ~= "string" and keyType ~= "number" then return nil end
    return table.concat({ moduleID(module), tostring(key), tostring(text) }, "|")
end

local function encounterIDForModule(module)
    if type(module) ~= "table" then return nil end

    if type(module.GetEncounterID) == "function" then
        local ok, encounterID = pcall(module.GetEncounterID, module)
        if ok and not Util.IsSecret(encounterID) then
            if type(encounterID) == "number" then return encounterID end
            if type(encounterID) == "string" then return tonumber(encounterID) end
        end
    end

    local encounterID = module.engageId
    if Util.IsSecret(encounterID) then return nil end
    if type(encounterID) == "number" then return encounterID end
    if type(encounterID) == "string" then return tonumber(encounterID) end
end

function BigWigsProvider:IsAvailable()
    return _G.BigWigsLoader and type(BigWigsLoader.RegisterMessage) == "function"
end

function BigWigsProvider:Remember(module, text, eventID, id)
    self.aliases = self.aliases or {}
    local alias = textAlias(module, text)
    if alias then self.aliases[alias] = id end
    if validEventID(eventID) then
        self.aliases["event:" .. tostring(eventID)] = id
    end
end

function BigWigsProvider:Resolve(module, text, eventID)
    local direct = makeTimerID(module, text, eventID)
    if direct and self.aliases and self.aliases[direct] then return self.aliases[direct] end
    if validEventID(eventID) and self.aliases then
        local byEvent = self.aliases["event:" .. tostring(eventID)]
        if byEvent then return byEvent end
    end
    local alias = textAlias(module, text)
    return self.aliases and alias and self.aliases[alias] or direct
end

function BigWigsProvider:Forget(id)
    if not id or not self.aliases then return end
    for alias, value in pairs(self.aliases) do
        if value == id then self.aliases[alias] = nil end
    end
end

function BigWigsProvider:RememberPendingEventID(module, key, text, eventID)
    if not validEventID(eventID) then return end
    local correlation = directTimerKey(module, key, text)
    if not correlation then return end

    self.pendingEventIDs[correlation] = {
        eventID = eventID,
        recordedAt = clock(),
        moduleName = moduleID(module),
    }
end

function BigWigsProvider:TakePendingEventID(module, key, text)
    local correlation = directTimerKey(module, key, text)
    if not correlation then return nil end

    local pending = self.pendingEventIDs[correlation]
    self.pendingEventIDs[correlation] = nil
    if type(pending) ~= "table" or not validEventID(pending.eventID) then return nil end

    local current = clock()
    if pending.recordedAt and current
        and (current < pending.recordedAt or current - pending.recordedAt > PENDING_EVENT_MAX_AGE) then
        return nil
    end

    return pending.eventID
end

function BigWigsProvider:ClearPendingForModule(module)
    if not self.pendingEventIDs then return end
    local wanted = moduleID(module)
    for correlation, pending in pairs(self.pendingEventIDs) do
        if type(pending) == "table" and pending.moduleName == wanted then
            self.pendingEventIDs[correlation] = nil
        end
    end
end

function BigWigsProvider:SeedEncounterHint()
    if not self.sink or not _G.BigWigs or type(BigWigs.IterateBossModules) ~= "function"
        or type(self.sink.ProviderEncounterHint) ~= "function" then
        return false
    end

    local foundEncounterID
    local ok = pcall(function()
        for _, module in BigWigs:IterateBossModules() do
            if type(module) == "table" and type(module.IsEngaged) == "function" then
                local engagedOK, engaged = pcall(module.IsEngaged, module)
                if engagedOK and engaged == true then
                    foundEncounterID = encounterIDForModule(module)
                    if foundEncounterID then break end
                end
            end
        end
    end)

    if not ok or not foundEncounterID then return false end
    self.sink:ProviderEncounterHint("BigWigs", foundEncounterID)
    return true
end

function BigWigsProvider:Start(sink)
    if not self:IsAvailable() then return false end

    self.sink = sink
    self.owner = self.owner or {}
    self.aliases = {}
    self.timerModules = {}
    self.pendingEventIDs = {}

    -- BigWigs v419.2 and current upstream expose three relevant contracts:
    --   BigWigs_Timer(module, key, duration, maxTime, text, counter, icon, isApproximate, isBarEnabled)
    -- is the canonical regular boss-module timer data bus.
    --   BigWigs_CastTimer(module, key, duration, maxTime, text, counter, icon, rawText, isBarEnabled)
    -- is the equivalent data bus for boss cast bars. BigWigs plugins, API timers, wipe timers and
    -- keystone tools can also emit timer-like messages, so RLA only accepts direct timers from
    -- modules that expose a real public encounter ID.
    --   BigWigs_StartBar(nil, nil, text, duration, icon, maxQueueDuration, maxTime, eventID, ...)
    -- is used by the Blizzard Timeline bridge. For normal boss bars, BigWigs' own Bar/CDBar/CastBar
    -- code sends the optional timeline event ID in the final StartBar slot immediately before the
    -- matching Timer/CastTimer event. RLA records that value only as one-shot metadata and attaches
    -- it to the matching direct timer; StartBar itself never creates a second direct timer.
    local function startDirectTimer(module, key, duration, text, counter, icon, isApproximate, isBarEnabled)
        local encounterID = encounterIDForModule(module)
        if not encounterID then return end
        if Util.IsSecret(duration) or Util.IsSecret(key) or Util.IsSecret(text)
            or Util.IsSecret(isApproximate) or Util.IsSecret(isBarEnabled) then return end
        if type(duration) ~= "number" or duration <= 0 or isBarEnabled ~= true then return end

        local id = makeTimerID(module, text, nil)
        if not id then return end
        local nativeEventID = self:TakePendingEventID(module, key, text)
        self:Remember(module, text, nativeEventID, id)
        self.timerModules[id] = moduleID(module)
        self.sink:ProviderTimerStarted("BigWigs", id, {
            key = key,
            name = text,
            duration = duration,
            icon = Util.NormalizeTexture(icon),
            count = normalizeCounter(counter),
            encounterID = encounterID,
            nativeEventID = nativeEventID,
            precision = isApproximate == true and "approximate" or "exact",
        })
    end

    self.onTimer = function(_, module, key, duration, _, text, counter, icon, isApproximate, isBarEnabled)
        startDirectTimer(module, key, duration, text, counter, icon, isApproximate, isBarEnabled)
    end

    self.onCastTimer = function(_, module, key, duration, _, text, counter, icon, _, isBarEnabled)
        startDirectTimer(module, key, duration, text, counter, icon, false, isBarEnabled)
    end

    self.onStart = function(_, module, key, text, duration, icon, reliability, _, eventIDA, eventIDB)
        local bridgeShape = module == nil and key == nil
        if not bridgeShape then
            local encounterID = encounterIDForModule(module)
            if not encounterID or Util.IsSecret(duration) or Util.IsSecret(key) or Util.IsSecret(text) then return end
            if type(duration) ~= "number" or duration <= 0 then return end

            -- In v419.2/current BossPrototype, normal Bar/CDBar/CastBar puts its optional
            -- timeline event ID in the final StartBar slot. Treat it as metadata only after
            -- a real boss module has been verified and consume it exactly once. If the matching
            -- Timer/CastTimer never arrives, the metadata is considered stale after one second.
            if validEventID(eventIDB) then
                self:RememberPendingEventID(module, key, text, eventIDB)
            end
            return
        end

        if Util.IsSecret(duration) or Util.IsSecret(text) or Util.IsSecret(reliability) then return end
        if type(duration) ~= "number" or duration <= 0 then return end

        local eventID = chooseEventID(eventIDA, eventIDB)
        if not eventID then return end

        local id = makeTimerID(module, text, eventID)
        if not id then return end
        self:Remember(module, text, eventID, id)
        self.timerModules[id] = moduleID(module)
        self.sink:ProviderTimerStarted("BigWigs", id, {
            key = nil,
            name = text,
            duration = duration,
            icon = Util.NormalizeTexture(icon),
            nativeEventID = eventID,
            bridge = "Blizzard",
            precision = "native",
        })
    end

    self.onStop = function(_, module, text, eventID)
        local id = self:Resolve(module, text, eventID)
        if not id then return end
        self.sink:ProviderTimerStopped("BigWigs", id, "stopped")
        self.timerModules[id] = nil
        self:Forget(id)
    end

    self.onPause = function(_, module, text, eventID)
        local id = self:Resolve(module, text, eventID)
        if id then self.sink:ProviderTimerPaused("BigWigs", id, true) end
    end

    self.onResume = function(_, module, text, eventID)
        local id = self:Resolve(module, text, eventID)
        if id then self.sink:ProviderTimerPaused("BigWigs", id, false) end
    end

    self.onStopModule = function(_, module)
        local wanted = moduleID(module)
        self:ClearPendingForModule(module)

        local ids = {}
        for id, ownerModule in pairs(self.timerModules) do
            if ownerModule == wanted then ids[#ids + 1] = id end
        end
        for _, id in ipairs(ids) do
            self.sink:ProviderTimerStopped("BigWigs", id, "module-stopped")
            self.timerModules[id] = nil
            self:Forget(id)
        end
    end

    self.onEngage = function(_, module)
        local encounterID = encounterIDForModule(module)
        if encounterID and type(self.sink.ProviderEncounterHint) == "function" then
            self.sink:ProviderEncounterHint("BigWigs", encounterID)
        end
    end

    BigWigsLoader.RegisterMessage(self.owner, "BigWigs_Timer", self.onTimer)
    BigWigsLoader.RegisterMessage(self.owner, "BigWigs_CastTimer", self.onCastTimer)
    BigWigsLoader.RegisterMessage(self.owner, "BigWigs_StartBar", self.onStart)
    BigWigsLoader.RegisterMessage(self.owner, "BigWigs_StopBar", self.onStop)
    BigWigsLoader.RegisterMessage(self.owner, "BigWigs_PauseBar", self.onPause)
    BigWigsLoader.RegisterMessage(self.owner, "BigWigs_ResumeBar", self.onResume)
    BigWigsLoader.RegisterMessage(self.owner, "BigWigs_StopBars", self.onStopModule)
    BigWigsLoader.RegisterMessage(self.owner, "BigWigs_OnBossDisable", self.onStopModule)
    BigWigsLoader.RegisterMessage(self.owner, "BigWigs_OnBossWipe", self.onStopModule)
    BigWigsLoader.RegisterMessage(self.owner, "BigWigs_OnBossWin", self.onStopModule)
    BigWigsLoader.RegisterMessage(self.owner, "BigWigs_OnBossEngage", self.onEngage)
    BigWigsLoader.RegisterMessage(self.owner, "BigWigs_OnBossEngageMidEncounter", self.onEngage)
    return true
end

function BigWigsProvider:Stop()
    if not self.owner or not _G.BigWigsLoader or not BigWigsLoader.UnregisterMessage then return end

    local messages = {
        "BigWigs_Timer",
        "BigWigs_CastTimer",
        "BigWigs_StartBar",
        "BigWigs_StopBar",
        "BigWigs_PauseBar",
        "BigWigs_ResumeBar",
        "BigWigs_StopBars",
        "BigWigs_OnBossDisable",
        "BigWigs_OnBossWipe",
        "BigWigs_OnBossWin",
        "BigWigs_OnBossEngage",
        "BigWigs_OnBossEngageMidEncounter",
    }

    for _, message in ipairs(messages) do
        BigWigsLoader.UnregisterMessage(self.owner, message)
    end
    if self.aliases then table.wipe(self.aliases) end
    if self.timerModules then table.wipe(self.timerModules) end
    if self.pendingEventIDs then table.wipe(self.pendingEventIDs) end
end

ns:RegisterModule("Services.Providers.BigWigs", setmetatable({}, BigWigsProvider))
