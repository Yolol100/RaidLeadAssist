local _, ns = ...

local Util = ns:GetModule("Core.Util")

local BlizzardProvider = {}
BlizzardProvider.__index = BlizzardProvider

local timelineStates = Enum and Enum.EncounterTimelineEventState
local ACTIVE = timelineStates and timelineStates.Active or 0
local PAUSED = timelineStates and timelineStates.Paused or 1
local FINISHED = timelineStates and timelineStates.Finished or 2
local CANCELED = timelineStates and timelineStates.Canceled or 3

local function isFiniteNumber(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function normalizeEventID(value)
    if Util.IsSecret(value) then return nil end
    if type(value) == "string" then value = tonumber(value) end
    if not isFiniteNumber(value) or value <= 0 or value ~= math.floor(value) then return nil end
    return value
end

local function safeTimelineCall(methodName, ...)
    local api = C_EncounterTimeline and C_EncounterTimeline[methodName]
    if type(api) ~= "function" then return nil end

    local ok, result = pcall(api, ...)
    if not ok or Util.IsSecret(result) then return nil end
    return result
end

function BlizzardProvider:IsAvailable()
    return C_EncounterTimeline
        and type(C_EncounterTimeline.GetEventState) == "function"
        and type(C_EncounterTimeline.GetEventInfo) == "function"
end

function BlizzardProvider:Start(sink)
    if not self:IsAvailable() then return false end

    self.sink = sink
    self.frame = self.frame or CreateFrame("Frame")
    self.frame:SetScript("OnEvent", function(_, eventName, ...)
        self:OnEvent(eventName, ...)
    end)
    self.frame:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_ADDED")
    self.frame:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_STATE_CHANGED")
    self.frame:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_REMOVED")

    return true
end

function BlizzardProvider:Stop()
    if self.frame then self.frame:UnregisterAllEvents() end
end

function BlizzardProvider:GetSafeRemaining(eventID)
    eventID = normalizeEventID(eventID)
    if not eventID then return nil end
    local remaining = safeTimelineCall("GetEventTimeRemaining", eventID)
    if Util.IsSecret(remaining) or not isFiniteNumber(remaining) then return nil end
    return math.max(0, remaining)
end

function BlizzardProvider:SeedExistingEvents()
    if type(C_EncounterTimeline.GetEventList) ~= "function" then return end

    local eventIDs = safeTimelineCall("GetEventList")
    if Util.IsSecret(eventIDs) or type(eventIDs) ~= "table" then return end

    for _, rawEventID in ipairs(eventIDs) do
        local eventID = normalizeEventID(rawEventID)
        if eventID then
            local state = safeTimelineCall("GetEventState", eventID)
            if not Util.IsSecret(state) and (state == ACTIVE or state == PAUSED) then
                local info = safeTimelineCall("GetEventInfo", eventID)
                if type(info) == "table" and not Util.IsSecret(info) then
                    self:AddEvent(info, eventID, self:GetSafeRemaining(eventID))
                    if state == PAUSED then
                        self.sink:ProviderTimerPaused("Blizzard", tostring(eventID), true)
                    end
                end
            end
        end
    end
end

function BlizzardProvider:AddEvent(info, fallbackEventID, durationOverride)
    if Util.IsSecret(info) or type(info) ~= "table" then return end
    if Util.IsSecret(info.source) or info.source ~= 0 then return end
    if Util.IsSecret(info.duration) or not isFiniteNumber(info.duration) then return end
    if Util.IsSecret(info.isApproximate)
        or (info.isApproximate ~= nil and type(info.isApproximate) ~= "boolean") then
        return
    end

    local eventID = normalizeEventID(fallbackEventID or info.id)
    if not eventID then return end

    local duration = durationOverride
    if not isFiniteNumber(duration) or duration <= 0 then duration = info.duration end
    if Util.IsSecret(duration) or not isFiniteNumber(duration) or duration <= 0 then return end

    local key = not Util.IsSecret(info.spellID) and info.spellID or nil
    local name = not Util.IsSecret(info.spellName) and info.spellName or nil
    local icon = not Util.IsSecret(info.iconFileID) and info.iconFileID or nil

    self.sink:ProviderTimerStarted("Blizzard", tostring(eventID), {
        key = key,
        name = name,
        duration = duration,
        icon = icon,
        nativeEventID = eventID,
        precision = info.isApproximate == true and "approximate" or "native",
    })
end

function BlizzardProvider:OnEvent(eventName, ...)
    if eventName == "ENCOUNTER_TIMELINE_EVENT_ADDED" then
        local info = ...
        if Util.IsSecret(info) or type(info) ~= "table" then return end
        local eventID = normalizeEventID(info.id)
        self:AddEvent(info, eventID)
        if eventID then
            local state = safeTimelineCall("GetEventState", eventID)
            if not Util.IsSecret(state) and state == PAUSED then
                self.sink:ProviderTimerPaused("Blizzard", tostring(eventID), true)
            end
        end
        return
    end

    local eventID = normalizeEventID((...))
    if not eventID then return end

    if eventName == "ENCOUNTER_TIMELINE_EVENT_REMOVED" then
        self.sink:ProviderTimerStopped("Blizzard", tostring(eventID), "removed")
        return
    end

    if eventName ~= "ENCOUNTER_TIMELINE_EVENT_STATE_CHANGED" then return end

    local state = safeTimelineCall("GetEventState", eventID)
    if Util.IsSecret(state) then return end
    if state == PAUSED then
        self.sink:ProviderTimerPaused("Blizzard", tostring(eventID), true)
    elseif state == ACTIVE then
        self.sink:ProviderTimerPaused("Blizzard", tostring(eventID), false)
    elseif state == FINISHED then
        self.sink:ProviderTimerStopped("Blizzard", tostring(eventID), "finished")
    elseif state == CANCELED then
        self.sink:ProviderTimerStopped("Blizzard", tostring(eventID), "canceled")
    end
end

function BlizzardProvider:GetRemaining(timer)
    local eventID = normalizeEventID(timer and timer.nativeEventID)
    if not eventID then return nil end

    local remaining = self:GetSafeRemaining(eventID)
    if remaining ~= nil then return remaining end

    if type(C_EncounterTimeline.GetEventTimeElapsed) ~= "function" then return nil end
    local elapsed = safeTimelineCall("GetEventTimeElapsed", eventID)
    if Util.IsSecret(elapsed) or not isFiniteNumber(elapsed) then return nil end
    if not timer or not isFiniteNumber(timer.duration) then return nil end
    return math.max(0, timer.duration - elapsed)
end

ns:RegisterModule("Services.Providers.Blizzard", setmetatable({}, BlizzardProvider))
