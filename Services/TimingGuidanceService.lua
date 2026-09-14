local _, ns = ...

local Constants = ns:GetModule("Core.Constants")
local Registry = ns:GetModule("Encounters.Registry")
local Timeline = ns:GetModule("Services.TimelineService")
local Util = ns:GetModule("Core.Util")

local TimingGuidance = {
    contextKey = nil,
    lastMechanic = nil,
    sequenceStates = {},
}

local providerRank = {}
for index, providerName in ipairs(Constants.PROVIDER_PRIORITY) do
    providerRank[providerName] = index
end

local function finite(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function stableSpellID(timer)
    if type(timer) ~= "table" then return nil end
    local numericID = Util.ToNumericID(timer.key)
    if not numericID or numericID <= 0 or numericID ~= math.floor(numericID) then return nil end
    return numericID
end

local function callOwnsSpellID(call, spellID)
    if type(call) ~= "table" or type(call.spellIDs) ~= "table" or not spellID then return false end
    for index = 1, #call.spellIDs do
        if Util.ToNumericID(call.spellIDs[index]) == spellID then return true end
    end
    return false
end

local function signedRemaining(timer, now)
    if type(timer) ~= "table" then return nil end
    if timer.paused == true then
        return finite(timer.pausedRemaining) and timer.pausedRemaining or nil
    end
    if not finite(timer.expiration) then return nil end
    return timer.expiration - now
end

local function sameOccurrence(first, second)
    local firstKey = first and (first.timelineCallKey or first.callKey)
    local secondKey = second and (second.timelineCallKey or second.callKey)
    return first and second
        and firstKey == secondKey
        and first.occurrenceID ~= nil
        and first.occurrenceID == second.occurrenceID
end

local function sourceTieKey(candidate)
    return table.concat({
        tostring(candidate.callKey or ""),
        tostring(candidate.providerName or ""),
        tostring(candidate.sourceID or ""),
    }, "|")
end

local function betterFuture(candidate, current)
    if not current then return true end
    if sameOccurrence(candidate, current) then
        local candidateRank = providerRank[candidate.providerName] or 999
        local currentRank = providerRank[current.providerName] or 999
        if candidateRank ~= currentRank then return candidateRank < currentRank end
    end
    if candidate.remaining ~= current.remaining then return candidate.remaining < current.remaining end
    if candidate.priority ~= current.priority then return candidate.priority < current.priority end
    local candidateRank = providerRank[candidate.providerName] or 999
    local currentRank = providerRank[current.providerName] or 999
    if candidateRank ~= currentRank then return candidateRank < currentRank end
    return sourceTieKey(candidate) < sourceTieKey(current)
end

local function betterLate(candidate, current)
    if not current then return true end
    if sameOccurrence(candidate, current) then
        local candidateRank = providerRank[candidate.providerName] or 999
        local currentRank = providerRank[current.providerName] or 999
        if candidateRank ~= currentRank then return candidateRank < currentRank end
    end
    if candidate.remaining ~= current.remaining then return candidate.remaining > current.remaining end
    if candidate.priority ~= current.priority then return candidate.priority < current.priority end
    local candidateRank = providerRank[candidate.providerName] or 999
    local currentRank = providerRank[current.providerName] or 999
    if candidateRank ~= currentRank then return candidateRank < currentRank end
    return sourceTieKey(candidate) < sourceTieKey(current)
end

local function sequenceDefinition(profile, timingCall)
    if type(timingCall) ~= "table" or timingCall.sequenceKey == nil then return nil end
    if type(timingCall.sequenceKey) ~= "string" or timingCall.sequenceKey == ""
        or type(timingCall.sequenceKeys) ~= "table" or #timingCall.sequenceKeys < 2 then
        return nil
    end
    for index = 1, #timingCall.sequenceKeys do
        local key = timingCall.sequenceKeys[index]
        if type(key) ~= "string" or not profile.callsByKey[key] then return nil end
    end
    return timingCall.sequenceKey, timingCall.sequenceKeys
end

function TimingGuidance:Reset()
    self.lastMechanic = nil
    self.sequenceStates = {}
end

function TimingGuidance:SetContext(encounterKey, difficultyKey)
    local nextContext = tostring(encounterKey or "") .. "/" .. tostring(difficultyKey or "")
    if self.contextKey == nextContext then return false end
    self.contextKey = nextContext
    self:Reset()
    return true
end

function TimingGuidance:IsStableTimerForCall(timer, call)
    if type(timer) ~= "table" or type(call) ~= "table" then return false end
    if timer.call and timer.call.key ~= call.key then return false end
    return callOwnsSpellID(call, stableSpellID(timer))
end

function TimingGuidance:AdvanceSequence(state)
    if not state or type(state.keys) ~= "table" or #state.keys == 0 then return end
    state.index = (state.index % #state.keys) + 1
    state.activeOccurrenceID = nil
    state.visibleCallKey = nil
    state.observedNearDeadline = false
    state.expiration = nil
end

function TimingGuidance:ResolveDisplayCall(profile, timingCall, timer, remaining)
    local sequenceKey, keys = sequenceDefinition(profile, timingCall)
    if not sequenceKey then return timingCall end

    local state = self.sequenceStates[sequenceKey]
    if not state then
        state = {
            key = sequenceKey,
            keys = keys,
            index = 1,
            baseCallKey = timingCall.key,
        }
        self.sequenceStates[sequenceKey] = state
    end

    local occurrenceID = timer.occurrenceID or (tostring(timer.providerName or "") .. ":" .. tostring(timer.sourceID or ""))
    if state.activeOccurrenceID ~= nil and state.activeOccurrenceID ~= occurrenceID then
        -- Only a previous occurrence actually observed at its deadline may
        -- advance automatically. An early cancellation/stop never advances the
        -- sequence and therefore cannot turn the next cast into step 2/3.
        if state.observedNearDeadline == true then self:AdvanceSequence(state) end
    end

    if state.activeOccurrenceID == nil then
        state.activeOccurrenceID = occurrenceID
        state.observedNearDeadline = false
    end
    if finite(remaining) and remaining <= Constants.TIMER_EXPIRY_GRACE_SECONDS then
        state.observedNearDeadline = true
    end
    state.expiration = timer.expiration
    state.baseCallKey = timingCall.key
    state.visibleCallKey = state.keys[state.index]

    return profile.callsByKey[state.visibleCallKey] or timingCall
end

function TimingGuidance:Acknowledge(callKey)
    local timelineCallKey = callKey
    for _, state in pairs(self.sequenceStates or {}) do
        if state.visibleCallKey == callKey then
            timelineCallKey = state.baseCallKey or callKey
            self:AdvanceSequence(state)
            break
        end
    end

    if self.lastMechanic and self.lastMechanic.callKey == callKey then
        self.lastMechanic = nil
    end
    return timelineCallKey
end

function TimingGuidance:BuildMechanic(timer, displayCall, timingCall, remaining, state, priority)
    return {
        timer = timer,
        call = displayCall,
        callKey = displayCall.key,
        timelineCallKey = timingCall.key,
        providerName = timer.providerName,
        sourceID = timer.sourceID,
        occurrenceID = timer.occurrenceID,
        precision = timer.precision,
        expiration = timer.expiration,
        remaining = remaining,
        state = state,
        priority = priority or math.huge,
    }
end

function TimingGuidance:GetNextMechanic(encounterKey, difficultyKey)
    self:SetContext(encounterKey, difficultyKey)

    local profile = Registry:GetProfile(encounterKey, difficultyKey)
    if not profile or type(profile.callsByKey) ~= "table" then
        self:Reset()
        return nil
    end

    local priorityByCallKey = {}
    for index = 1, #(profile.calls or {}) do
        local call = profile.calls[index]
        if call and call.key then priorityByCallKey[call.key] = index end
    end

    local now = GetTime()
    local bestFuture, bestLate

    for _, timer in pairs(Timeline.timers or {}) do
        local timingCallKey = timer.call and timer.call.key or nil
        local timingCall = timingCallKey and profile.callsByKey[timingCallKey] or nil
        if timingCall and timingCall.timing ~= false
            and timer.acknowledged ~= true
            and Timeline:IsActionable(timer)
            and self:IsStableTimerForCall(timer, timingCall) then
            local remaining = signedRemaining(timer, now)
            if finite(remaining) and remaining >= -Constants.TIMER_EXPIRY_GRACE_SECONDS then
                local displayCall = self:ResolveDisplayCall(profile, timingCall, timer, remaining)
                local state = Constants.GetGuidanceState(displayCall, remaining, true)
                if state ~= Constants.CallState.IDLE then
                    local candidate = self:BuildMechanic(
                        timer, displayCall, timingCall, remaining, state,
                        priorityByCallKey[displayCall.key]
                    )
                    if remaining < 0 then
                        if betterLate(candidate, bestLate) then bestLate = candidate end
                    elseif betterFuture(candidate, bestFuture) then
                        bestFuture = candidate
                    end
                end
            end
        end
    end

    if not bestLate and self.lastMechanic
        and finite(self.lastMechanic.expiration)
        and finite(self.lastMechanic.seenAt)
        and self.lastMechanic.seenAt >= self.lastMechanic.expiration - Constants.TIMER_EXPIRY_GRACE_SECONDS
        and now > self.lastMechanic.expiration
        and now <= self.lastMechanic.expiration + Constants.TIMER_EXPIRY_GRACE_SECONDS then
        local displayCall = profile.callsByKey[self.lastMechanic.callKey]
        local timingCall = profile.callsByKey[self.lastMechanic.timelineCallKey or self.lastMechanic.callKey]
        if displayCall and timingCall and timingCall.timing ~= false
            and not (self.lastMechanic.timer and self.lastMechanic.timer.paused == true) then
            local remaining = self.lastMechanic.expiration - now
            local state = Constants.GetGuidanceState(displayCall, remaining, true)
            if state == Constants.CallState.LATE then
                bestLate = {
                    timer = self.lastMechanic.timer,
                    call = displayCall,
                    callKey = displayCall.key,
                    timelineCallKey = timingCall.key,
                    providerName = self.lastMechanic.providerName,
                    sourceID = self.lastMechanic.sourceID,
                    occurrenceID = self.lastMechanic.occurrenceID,
                    precision = self.lastMechanic.precision,
                    expiration = self.lastMechanic.expiration,
                    remaining = remaining,
                    state = state,
                    priority = priorityByCallKey[displayCall.key] or math.huge,
                }
            end
        end
    end

    local selected = bestLate or bestFuture
    if not selected then
        if self.lastMechanic and finite(self.lastMechanic.expiration)
            and (now < self.lastMechanic.expiration - Constants.TIMER_EXPIRY_GRACE_SECONDS
                or now > self.lastMechanic.expiration + Constants.TIMER_EXPIRY_GRACE_SECONDS) then
            self.lastMechanic = nil
        end
        return nil
    end

    if selected.state ~= Constants.CallState.LATE then
        self.lastMechanic = {
            timer = selected.timer,
            callKey = selected.callKey,
            timelineCallKey = selected.timelineCallKey,
            providerName = selected.providerName,
            sourceID = selected.sourceID,
            occurrenceID = selected.occurrenceID,
            precision = selected.precision,
            expiration = selected.expiration,
            seenAt = now,
        }
    end

    return selected
end

ns:RegisterModule("Services.TimingGuidance", TimingGuidance)
