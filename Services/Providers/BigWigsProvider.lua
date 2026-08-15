local _, ns = ...

local Util = ns:GetModule("Core.Util")

local BigWigsProvider = {}
BigWigsProvider.__index = BigWigsProvider

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

function BigWigsProvider:Start(sink)
    if not self:IsAvailable() then return false end

    self.sink = sink
    self.owner = self.owner or {}
    self.aliases = {}
    self.timerModules = {}

    -- BigWigs v419.2 and current upstream expose two relevant contracts:
    --   BigWigs_Timer(module, key, duration, maxTime, text, counter, icon, isApproximate, isBarEnabled)
    -- is the canonical boss-module timer data bus. It fires even when the visual bar is disabled,
    -- so RLA explicitly respects isBarEnabled and never turns a disabled BigWigs timer into a call.
    --   BigWigs_StartBar(nil, nil, text, duration, icon, maxQueueDuration, maxTime, eventID, ...)
    -- is also used by the BigWigs Blizzard Timeline bridge. Only that nil-module bridge shape is
    -- allowed to contribute native event identity; normal StartBar trailing values are not trusted
    -- as event IDs because the receiving contract also uses that slot for spell indicators.
    self.onTimer = function(_, module, key, duration, _, text, _, icon, isApproximate, isBarEnabled)
        if module == nil then return end
        if Util.IsSecret(duration) or Util.IsSecret(key) or Util.IsSecret(text)
            or Util.IsSecret(isApproximate) or Util.IsSecret(isBarEnabled) then return end
        if type(duration) ~= "number" or duration <= 0 or isBarEnabled ~= true then return end

        local id = makeTimerID(module, text, nil)
        if not id then return end
        self:Remember(module, text, nil, id)
        self.timerModules[id] = moduleID(module)
        self.sink:ProviderTimerStarted("BigWigs", id, {
            key = key,
            name = text,
            duration = duration,
            icon = Util.NormalizeTexture(icon),
            precision = isApproximate == true and "approximate" or "exact",
        })
    end

    self.onStart = function(_, module, key, text, duration, icon, reliability, _, eventIDA, eventIDB)
        local bridgeShape = module == nil and key == nil
        if not bridgeShape then return end
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
end

ns:RegisterModule("Services.Providers.BigWigs", setmetatable({}, BigWigsProvider))
