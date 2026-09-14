local _, ns = ...

local Constants = ns:GetModule("Core.Constants")
local EventBus = ns:GetModule("Core.EventBus")
local Registry = ns:GetModule("Encounters.Registry")
local Audio = ns:GetModule("Services.AudioService")
local Guidance = ns:GetModule("Services.TimingGuidance")
local UI = ns:GetModule("UI.MainFrame")
local App = ns:GetModule("Core.App")

local Integration = {}

local function profileUsesAutomaticTiming(profile)
    if type(profile) ~= "table" or type(profile.calls) ~= "table" then return false end
    for index = 1, #profile.calls do
        if profile.calls[index].timing ~= false then return true end
    end
    return false
end

local function calledState(owner, callKey, now)
    return (owner.visualCalledUntil[callKey] or 0) > now
        or (owner.manualLockUntil[callKey] or 0) > now
end

local originalSendCall = App.SendCall
App.SendCall = function(self, callKey)
    local now = GetTime()
    originalSendCall(self, callKey)
    if (self.manualLockUntil[callKey] or 0) > now then
        Guidance:Acknowledge(callKey)
    end
end

-- Phase 4 replaces the old per-button timer scan with one normalized current
-- mechanic. The raid leader still clicks the Raid Warning button manually; this
-- layer only guides which single call matters and when.
App.UpdateTiming = function(self)
    local profile = Registry:GetProfile(self.activeBossKey, self.activeDifficultyKey)
    if not profile then return end

    local now = GetTime()

    if not self:IsAutomaticTimingEnabled() then
        Guidance:Reset()
        for index = 1, #profile.calls do
            local call = profile.calls[index]
            UI:SetCallState(call.key, calledState(self, call.key, now)
                and Constants.CallState.CALLED or Constants.CallState.IDLE)
        end
        UI.timeline:SetIdle("AUTO TIMING OFF")
        return
    end

    if not profileUsesAutomaticTiming(profile) then
        Guidance:Reset()
        for index = 1, #profile.calls do
            local call = profile.calls[index]
            UI:SetCallState(call.key, calledState(self, call.key, now)
                and Constants.CallState.CALLED or Constants.CallState.IDLE)
        end
        UI.timeline:SetIdle("MANUAL CALLS ONLY")
        return
    end

    -- First neutralize every call. Only the normalized current mechanic may be
    -- promoted to WAIT/SOON/PRESS NOW/LATE; recent manual calls keep CALLED.
    for index = 1, #profile.calls do
        local call = profile.calls[index]
        UI:SetCallState(call.key, calledState(self, call.key, now)
            and Constants.CallState.CALLED or Constants.CallState.IDLE)
    end

    local mechanic = Guidance:GetNextMechanic(self.activeBossKey, self.activeDifficultyKey)
    if not mechanic then
        UI.timeline:SetIdle("NO VERIFIED TIMER")
        return
    end

    local state = mechanic.state
    if calledState(self, mechanic.callKey, now) then state = Constants.CallState.CALLED end
    UI:SetCallState(mechanic.callKey, state)

    UI.timeline:SetTimer(mechanic.timer, mechanic.remaining)
    UI.timeline:SetState(state)

    if state ~= Constants.CallState.PREPARE and state ~= Constants.CallState.PRESS then return end

    local occurrenceKey = table.concat({
        mechanic.callKey,
        tostring(mechanic.occurrenceID or mechanic.sourceID or "unknown"),
    }, ":")
    local audioKey = occurrenceKey .. ":" .. state
    if self.audioStates[audioKey] then return end

    self.audioStates[audioKey] = true
    if state == Constants.CallState.PREPARE then
        Audio:Prepare(mechanic.call)
    else
        Audio:Press(mechanic.call)
    end
end

EventBus:On("ENCOUNTER_STARTED", Integration, function()
    Guidance:Reset()
end)
EventBus:On("ENCOUNTER_ENDED", Integration, function()
    Guidance:Reset()
end)
EventBus:On("ENCOUNTER_RECOVERED", Integration, function()
    Guidance:Reset()
end)

ns:RegisterModule("Core.TimingGuidanceIntegration", Integration)
