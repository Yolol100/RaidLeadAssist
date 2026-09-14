local _, ns = ...

local Constants = ns:GetModule("Core.Constants")
local Registry = ns:GetModule("Encounters.Registry")
local Timeline = ns:GetModule("Services.TimelineService")
local Util = ns:GetModule("Core.Util")

local TimingGuidance = {
    contextKey = nil,
    lastMechanic = nil,
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
    return first and second
        and first.callKey == second.callKey
        and first.occurrenceID ~= nil
        and first.occurrenceID == second.occurrenceID
end

local function betterFuture(candidate, current)
    if not current then return true end
    if sameOccurrence(candidate, current) then
        local candidateRank = providerRank[candidate.providerName] or 999
        local currentRank = providerRank[current.providerName] or 999
        if candidateRank ~= currentRank then return candidateRank < currentRank end
    end
    if candidate.remaining ~= current.remaining then return candidate.remaining < current.remaining end
    return (providerRank[candidate.providerName] or 999) < (providerRank[current.providerName] or 999)
end

local function betterLate(candidate, current)
    if not current then return true end
    if sameOccurrence(candidate, current) then
        local candidateRank = providerRank[candidate.providerName] or 999
        local currentRank = providerRank[current.providerName] or 999
        if candidateRank ~= currentRank then return candidateRank < currentRank end
    end
    -- Closest-to-zero negative value is the most recently missed occurrence.
    if candidate.remaining ~= current.remaining then return candidate.remaining > current.remaining end
    return (providerRank[candidate.providerName] or 999) < (providerRank[current.providerName] or 999)
end

function TimingGuidance:Reset()
    self.lastMechanic = nil
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

function TimingGuidance:Acknowledge(callKey)
    if self.lastMechanic and self.lastMechanic.callKey == callKey then
        self.lastMechanic = nil
        return true
    end
    return false
end

function TimingGuidance:BuildMechanic(timer, call, remaining, state)
    return {
        timer = timer,
        call = call,
        callKey = call.key,
        providerName = timer.providerName,
        sourceID = timer.sourceID,
        occurrenceID = timer.occurrenceID,
        precision = timer.precision,
        expiration = timer.expiration,
        remaining = remaining,
        state = state,
    }
end

function TimingGuidance:GetNextMechanic(encounterKey, difficultyKey)
    self:SetContext(encounterKey, difficultyKey)

    local profile = Registry:GetProfile(encounterKey, difficultyKey)
    if not profile or type(profile.callsByKey) ~= "table" then
        self:Reset()
        return nil
    end

    local now = GetTime()
    local bestFuture, bestLate

    for _, timer in pairs(Timeline.timers or {}) do
        local callKey = timer.call and timer.call.key or nil
        local call = callKey and profile.callsByKey[callKey] or nil
        if call and call.timing ~= false
            and timer.acknowledged ~= true
            and Timeline:IsActionable(timer)
            and self:IsStableTimerForCall(timer, call) then
            local remaining = signedRemaining(timer, now)
            if finite(remaining) and remaining >= -Constants.TIMER_EXPIRY_GRACE_SECONDS then
                local state = Constants.GetGuidanceState(call, remaining, true)
                if state ~= Constants.CallState.IDLE then
                    local candidate = self:BuildMechanic(timer, call, remaining, state)
                    if remaining < 0 then
                        if betterLate(candidate, bestLate) then bestLate = candidate end
                    elseif betterFuture(candidate, bestFuture) then
                        bestFuture = candidate
                    end
                end
            end
        end
    end

    -- A missed mechanic gets a short, deterministic LATE state before guidance
    -- advances to a later mechanic. Keep the snapshot even if the bossmod removes
    -- its bar exactly at zero.
    if not bestLate and self.lastMechanic
        and finite(self.lastMechanic.expiration)
        and now > self.lastMechanic.expiration
        and now <= self.lastMechanic.expiration + Constants.TIMER_EXPIRY_GRACE_SECONDS then
        local call = profile.callsByKey[self.lastMechanic.callKey]
        if call and call.timing ~= false then
            local remaining = self.lastMechanic.expiration - now
            local state = Constants.GetGuidanceState(call, remaining, true)
            if state == Constants.CallState.LATE then
                bestLate = {
                    timer = self.lastMechanic.timer,
                    call = call,
                    callKey = call.key,
                    providerName = self.lastMechanic.providerName,
                    sourceID = self.lastMechanic.sourceID,
                    occurrenceID = self.lastMechanic.occurrenceID,
                    precision = self.lastMechanic.precision,
                    expiration = self.lastMechanic.expiration,
                    remaining = remaining,
                    state = state,
                }
            end
        end
    end

    local selected = bestLate or bestFuture
    if not selected then
        if self.lastMechanic and finite(self.lastMechanic.expiration)
            and now > self.lastMechanic.expiration + Constants.TIMER_EXPIRY_GRACE_SECONDS then
            self.lastMechanic = nil
        end
        return nil
    end

    if selected.state ~= Constants.CallState.LATE then
        self.lastMechanic = {
            timer = selected.timer,
            callKey = selected.callKey,
            providerName = selected.providerName,
            sourceID = selected.sourceID,
            occurrenceID = selected.occurrenceID,
            precision = selected.precision,
            expiration = selected.expiration,
        }
    end

    return selected
end

ns:RegisterModule("Services.TimingGuidance", TimingGuidance)
