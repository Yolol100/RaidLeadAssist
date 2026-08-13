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

local function makeTimerID(module, text, eventID)
    if eventID ~= nil and not Util.IsSecret(eventID) then
        return moduleID(module) .. "|event:" .. tostring(eventID)
    end
    return textAlias(module, text)
end

function BigWigsProvider:IsAvailable()
    return _G.BigWigsLoader and type(BigWigsLoader.RegisterMessage) == "function"
end

function BigWigsProvider:Remember(module, text, eventID, id)
    self.aliases = self.aliases or {}
    local alias = textAlias(module, text)
    if alias then self.aliases[alias] = id end
    if eventID ~= nil and not Util.IsSecret(eventID) then
        self.aliases["event:" .. tostring(eventID)] = id
    end
end

function BigWigsProvider:Resolve(module, text, eventID)
    local direct = makeTimerID(module, text, eventID)
    if direct and self.aliases and self.aliases[direct] then return self.aliases[direct] end
    if eventID ~= nil and not Util.IsSecret(eventID) and self.aliases then
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

    self.onStart = function(_, module, key, text, duration, icon, isApproximate, _, eventID, _)
        if Util.IsSecret(duration) or Util.IsSecret(key) or Util.IsSecret(text) or Util.IsSecret(isApproximate) then return end
        if isApproximate or type(duration) ~= "number" or duration <= 0 then return end

        local id = makeTimerID(module, text, eventID)
        if not id then return end
        self:Remember(module, text, eventID, id)
        self.timerModules[id] = moduleID(module)
        self.sink:ProviderTimerStarted("BigWigs", id, {
            key = key,
            name = text,
            duration = duration,
            icon = Util.NormalizeTexture(icon),
            nativeEventID = not Util.IsSecret(eventID) and eventID or nil,
            bridge = module == nil and "Blizzard" or nil,
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

    BigWigsLoader.RegisterMessage(self.owner, "BigWigs_StartBar", self.onStart)
    BigWigsLoader.RegisterMessage(self.owner, "BigWigs_StopBar", self.onStop)
    BigWigsLoader.RegisterMessage(self.owner, "BigWigs_PauseBar", self.onPause)
    BigWigsLoader.RegisterMessage(self.owner, "BigWigs_ResumeBar", self.onResume)
    BigWigsLoader.RegisterMessage(self.owner, "BigWigs_StopBars", self.onStopModule)
    BigWigsLoader.RegisterMessage(self.owner, "BigWigs_OnBossDisable", self.onStopModule)
    BigWigsLoader.RegisterMessage(self.owner, "BigWigs_OnBossWipe", self.onStopModule)
    BigWigsLoader.RegisterMessage(self.owner, "BigWigs_OnBossWin", self.onStopModule)
    return true
end

function BigWigsProvider:Stop()
    if not self.owner or not _G.BigWigsLoader or not BigWigsLoader.UnregisterMessage then return end

    local messages = {
        "BigWigs_StartBar",
        "BigWigs_StopBar",
        "BigWigs_PauseBar",
        "BigWigs_ResumeBar",
        "BigWigs_StopBars",
        "BigWigs_OnBossDisable",
        "BigWigs_OnBossWipe",
        "BigWigs_OnBossWin",
    }

    for _, message in ipairs(messages) do
        BigWigsLoader.UnregisterMessage(self.owner, message)
    end
    if self.aliases then table.wipe(self.aliases) end
    if self.timerModules then table.wipe(self.timerModules) end
end

ns:RegisterModule("Services.Providers.BigWigs", setmetatable({}, BigWigsProvider))
