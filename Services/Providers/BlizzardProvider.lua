local _, ns = ...

local Util = ns:GetModule("Core.Util")

local BlizzardProvider = {}
BlizzardProvider.__index = BlizzardProvider

local timelineStates = Enum and Enum.EncounterTimelineEventState
local ACTIVE = timelineStates and timelineStates.Active or 0
local PAUSED = timelineStates and timelineStates.Paused or 1
local FINISHED = timelineStates and timelineStates.Finished or 2
local CANCELED = timelineStates and timelineStates.Canceled or 3

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
    if Util.IsSecret(eventID) or eventID == nil then return nil end
    local remaining = safeTimelineCall("GetEventTimeRemaining", eventID)
    if Util.IsSecret(remaining) or type(remaining) ~= "number" then return nil end
    return math.max(0, remaining)
end

function BlizzardProvider:SeedExistingEvents()
    if type(C_EncounterTimeline.GetEventList) ~= "function" then return end

    local eventIDs = safeTimelineCall("GetEventList")
    if Util.IsSecret(eventIDs) or type(eventIDs) ~= "table" then return end

    for _, eventID in ipairs(eventIDs) do
        if not Util.IsSecret(eventID) then
            local state = safeTimelineCall("GetEventState", eventID)
            if not Util.IsSecret(state) and (state == ACTIVE or state == PAUSED) then
                local info = safeTimelineCall("GetEventInfo", eventID)
                if info then
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
    if not info or Util.IsSecret(info.source) or info.source ~= 0 then return end
    if Util.IsSecret(info.duration) or type(info.duration) ~= "number" then return end

    local eventID = fallbackEventID or info.id
    if Util.IsSecret(eventID) or eventID == nil then return end

    local duration = durationOverride
    if type(duration) ~= "number" or duration <= 0 then duration = info.duration end
    if Util.IsSecret(duration) or type(duration) ~= "number" or duration <= 0 then return end

    local key = not Util.IsSecret(info.spellID) and info.spellID or nil
    local name = not Util.IsSecret(info.spellName) and info.spellName or nil
    local icon = not Util.IsSecret(info.iconFileID) and info.iconFileID or nil

    self.sink:ProviderTimerStarted("Blizzard", tostring(eventID), {
        key = key,
        name = name,
        duration = duration,
        icon = icon,
        nativeEventID = eventID,
        precision = "native",
    })
end

function BlizzardProvider:OnEvent(eventName, ...)
    if eventName == "ENCOUNTER_TIMELINE_EVENT_ADDED" then
        local info = ...
        if not info then return end
        local eventID = not Util.IsSecret(info.id) and info.id or nil
        self:AddEvent(info, eventID)
        if eventID then
            local state = safeTimelineCall("GetEventState", eventID)
            if not Util.IsSecret(state) and state == PAUSED then
                self.sink:ProviderTimerPaused("Blizzard", tostring(eventID), true)
            end
        end
        return
    end

    local eventID = ...
    if Util.IsSecret(eventID) or eventID == nil then return end

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
    local eventID = timer.nativeEventID
    if not eventID then return nil end

    local remaining = self:GetSafeRemaining(eventID)
    if remaining ~= nil then return remaining end

    if type(C_EncounterTimeline.GetEventTimeElapsed) ~= "function" then return nil end
    local elapsed = safeTimelineCall("GetEventTimeElapsed", eventID)
    if Util.IsSecret(elapsed) or type(elapsed) ~= "number" then return nil end
    return math.max(0, timer.duration - elapsed)
end

ns:RegisterModule("Services.Providers.Blizzard", setmetatable({}, BlizzardProvider))
