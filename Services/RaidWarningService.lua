local _, ns = ...

local Constants = ns:GetModule("Core.Constants")
local Util = ns:GetModule("Core.Util")

local RaidWarningService = {
    queuedTimers = {},
    briefingLockUntil = 0,
    briefingGeneration = 0,
}

local MAX_CHAT_LENGTH = 200

local function encounterInProgress()
    if not C_InstanceEncounter or type(C_InstanceEncounter.IsEncounterInProgress) ~= "function" then
        return false
    end
    local ok, active = pcall(C_InstanceEncounter.IsEncounterInProgress)
    return ok and active == true
end

local function compactAssignmentLines(lines)
    if type(lines) ~= "table" or #lines < 2 then return lines end
    for index = 1, #lines do
        if type(lines[index]) ~= "string" or not lines[index]:find("^ASSIGN > ") then return lines end
    end

    local result = {}
    local current = ""
    for index = 1, #lines do
        local fragment = lines[index]:gsub("^ASSIGN > ", "")
        local candidate = current == "" and ("ASSIGN > " .. fragment) or (current .. " | " .. fragment)
        if #candidate <= MAX_CHAT_LENGTH then
            current = candidate
        else
            result[#result + 1] = current
            current = "ASSIGN > " .. fragment
        end
    end
    if current ~= "" then result[#result + 1] = current end
    return result
end

function RaidWarningService:CanSend()
    return Util.IsRaidLeaderOrAssistant()
end

function RaidWarningService:SendRaw(text)
    if type(text) ~= "string" or text == "" then return false end
    if not C_ChatInfo or type(C_ChatInfo.SendChatMessage) ~= "function" then
        ns:Print("Raid Warning chat API is unavailable.")
        return false
    end

    local ok = pcall(C_ChatInfo.SendChatMessage, text, "RAID_WARNING")
    if not ok then
        ns:Print("Raid Warning could not be sent.")
        return false
    end
    return true
end

function RaidWarningService:CancelBriefing()
    self.briefingGeneration = self.briefingGeneration + 1
    for _, timer in ipairs(self.queuedTimers) do
        if timer and timer.Cancel then timer:Cancel() end
    end
    table.wipe(self.queuedTimers)
    self.briefingLockUntil = 0
end

function RaidWarningService:Send(text)
    if type(text) ~= "string" or text == "" then return false end

    if not self:CanSend() then
        ns:Print("Raid Warning requires raid leader or assistant.")
        return false
    end

    return self:SendRaw(text)
end

function RaidWarningService:SendBriefing(lines)
    if type(lines) ~= "table" or #lines == 0 then return false end
    if self.briefingLockUntil > GetTime() then return false end

    lines = compactAssignmentLines(lines)
    for index = 1, #lines do
        if type(lines[index]) ~= "string" or lines[index] == "" or #lines[index] > MAX_CHAT_LENGTH then
            ns:Print("Boss Explanation contains invalid text.")
            return false
        end
    end

    if encounterInProgress() then
        ns:Print("Boss Explanation is pre-pull only.")
        return false
    end

    if not self:CanSend() then
        ns:Print("Raid Warning requires raid leader or assistant.")
        return false
    end

    self:CancelBriefing()
    local generation = self.briefingGeneration

    local sequenceTime = math.max(0, (#lines - 1) * Constants.BRIEFING_LINE_DELAY)
    self.briefingLockUntil = GetTime() + math.max(Constants.BRIEFING_CLICK_LOCK_SECONDS, sequenceTime + 0.75)

    for index = 1, #lines do
        local lineIndex = index
        local text = lines[lineIndex]
        local ok, timer = pcall(C_Timer.NewTimer, (lineIndex - 1) * Constants.BRIEFING_LINE_DELAY, function()
            if generation ~= self.briefingGeneration then return end
            if encounterInProgress() or not self:CanSend() then
                self:CancelBriefing()
                return
            end
            if not self:SendRaw(text) then
                self:CancelBriefing()
                return
            end
            if lineIndex == #lines then table.wipe(self.queuedTimers) end
        end)
        if not ok or not timer then
            self:CancelBriefing()
            ns:Print("Boss Explanation could not be scheduled.")
            return false
        end
        self.queuedTimers[#self.queuedTimers + 1] = timer
    end

    return #self.queuedTimers == #lines
end

ns:RegisterModule("Services.RaidWarningService", RaidWarningService)
