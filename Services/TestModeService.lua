local _, ns = ...

local Constants = ns:GetModule("Core.Constants")
local EventBus = ns:GetModule("Core.EventBus")
local Registry = ns:GetModule("Encounters.Registry")
local Timeline = ns:GetModule("Services.TimelineService")

local originalReset = Timeline.Reset
local originalGetRemaining = Timeline.GetRemaining
local originalGetTimerForCall = Timeline.GetTimerForCall
local originalGetActionableTimerForCall = Timeline.GetActionableTimerForCall

local function signedRemaining(timer)
    if not timer or type(timer.expiration) ~= "number" then return nil end
    return timer.expiration - GetTime()
end

local function lateTimerForCall(self, callKey, actionableOnly)
    local best, bestRemaining
    for _, timer in pairs(self.timers or {}) do
        if timer.call and timer.call.key == callKey and timer.acknowledged ~= true
            and (not actionableOnly or self:IsActionable(timer)) then
            local remaining = signedRemaining(timer)
            if type(remaining) == "number"
                and remaining < 0
                and remaining >= -Constants.TIMER_EXPIRY_GRACE_SECONDS
                and (bestRemaining == nil or remaining < bestRemaining) then
                best, bestRemaining = timer, remaining
            end
        end
    end
    return best, bestRemaining
end

function Timeline:GetRemaining(timer)
    local remaining = originalGetRemaining(self, timer)
    local signed = signedRemaining(timer)
    if type(signed) == "number" and signed < 0 and type(remaining) == "number" and remaining <= 0 then
        return signed
    end
    return remaining
end

function Timeline:GetTimerForCall(callKey)
    local timer, remaining = originalGetTimerForCall(self, callKey)
    if timer then return timer, remaining end
    return lateTimerForCall(self, callKey, false)
end

function Timeline:GetActionableTimerForCall(callKey)
    local timer, remaining = originalGetActionableTimerForCall(self, callKey)
    if timer then return timer, remaining end
    return lateTimerForCall(self, callKey, true)
end

function Timeline:StopTest()
    local id = self.testTimerID
    self.testGeneration = (self.testGeneration or 0) + 1
    self.testTimerID = nil
    if id and self.timers and self.timers[id] then
        self.timers[id] = nil
        EventBus:Emit("TIMELINE_CHANGED")
        return true
    end
    return false
end

function Timeline:IsTestActive(callKey)
    local timer = self.testTimerID and self.timers and self.timers[self.testTimerID] or nil
    return timer ~= nil and timer.acknowledged ~= true
        and (callKey == nil or (timer.call and timer.call.key == callKey))
end

function Timeline:StartTestCall(callKey, duration)
    if not self.encounterKey or type(callKey) ~= "string" or callKey == "" then return false end
    local profile = Registry:GetProfile(self.encounterKey, Registry:GetActiveDifficulty())
    local call = profile and profile.callsByKey and profile.callsByKey[callKey] or nil
    if not call or call.timing == false then return false end

    self:StopTest()
    local seconds = tonumber(duration) or math.max((tonumber(call.prepareSeconds) or 5) + 3, 9)
    seconds = math.max(6, math.min(seconds, 20))
    local now = GetTime()
    self.nextOccurrenceID = (self.nextOccurrenceID or 0) + 1
    self.testGeneration = (self.testGeneration or 0) + 1
    local generation = self.testGeneration
    local id = "Test|" .. callKey
    self.testTimerID = id
    self.timers[id] = {
        id = id,
        sourceID = callKey,
        providerName = "Test",
        key = call.spellIDs and call.spellIDs[1] or call.key,
        name = call.ability,
        duration = seconds,
        startedAt = now,
        expiration = now + seconds,
        precision = Constants.TimerPrecision.EXACT,
        faded = false,
        paused = false,
        acknowledged = false,
        occurrenceID = self.nextOccurrenceID,
        call = call,
    }
    EventBus:Emit("TIMELINE_CHANGED")
    C_Timer.After(seconds + Constants.TIMER_EXPIRY_GRACE_SECONDS + 0.5, function()
        if self.testGeneration == generation then self:StopTest() end
    end)
    return true
end

function Timeline:Reset(...)
    self.testGeneration = (self.testGeneration or 0) + 1
    self.testTimerID = nil
    return originalReset(self, ...)
end

ns:RegisterModule("Services.TestModeService", Timeline)
