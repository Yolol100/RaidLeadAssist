local _, ns = ...

local Registry = ns:GetModule("Encounters.Registry")
local SetupRegistry = ns:GetModule("Encounters.SetupRegistry")
local Messages = ns:GetModule("Services.MessageService")
local Assignments = ns:GetModule("Services.AssignmentService")
local Setup = ns:GetModule("Services.SetupService")
local Roster = ns:GetModule("Services.RosterService")
local Timeline = ns:GetModule("Services.TimelineService")
local App = ns:GetModule("Core.App")

local function normalizeRosterName(name)
    if type(name) ~= "string" then return nil end
    local lowered = name:lower()
    local short = lowered:match("^([^%-]+)")
    return lowered, short
end

local function rosterMap()
    local result = {}
    for _, member in ipairs(Roster:GetRoster()) do
        local full, short = normalizeRosterName(member.name)
        if full then result[full] = true end
        if short then result[short] = true end
    end
    return result
end

local function assignedPlayersNotInRoster(bossKey, difficultyKey)
    local current = rosterMap()
    if next(current) == nil then return {} end

    local missing, seen = {}, {}
    local definitions = Assignments:GetDefinitions(bossKey, difficultyKey)
    for _, definition in ipairs(definitions) do
        if definition.kind == "assignee" or definition.kind == "rotation" then
            local value = Assignments:GetValue(bossKey, difficultyKey, definition.key)
            for token in tostring(value or ""):gmatch("[^,]+") do
                local name = token:match("^%s*(.-)%s*$") or ""
                -- Group/rule labels remain valid for pre-planning and are not treated as player names.
                if name ~= "" and not name:find("%s") and not name:find("%+") then
                    local full, short = normalizeRosterName(name)
                    if full and not current[full] and not current[short] and not seen[full] then
                        seen[full] = true
                        missing[#missing + 1] = name
                    end
                end
            end
        end
    end
    table.sort(missing)
    return missing
end

local function timedProviderCoverage(profile)
    local timedKeys = {}
    for _, call in ipairs((profile and profile.calls) or {}) do
        if call.timing ~= false then timedKeys[call.key] = true end
    end

    local total = 0
    for _ in pairs(timedKeys) do total = total + 1 end
    if total == 0 then return 0, 0 end

    local observed = {}
    for _, timer in pairs(Timeline.timers or {}) do
        local key = timer.call and timer.call.key
        if key and timedKeys[key] then observed[key] = true end
    end
    local covered = 0
    for _ in pairs(observed) do covered = covered + 1 end
    return covered, total
end

local originalPrintDoctor = App.PrintDoctor
function App:PrintDoctor()
    originalPrintDoctor(self)

    local profile = Registry:GetProfile(self.activeBossKey, self.activeDifficultyKey)
    if not profile then return end

    local missingRequired = Assignments:GetMissingRequired(self.activeBossKey, self.activeDifficultyKey)
    local rosterMissing = assignedPlayersNotInRoster(self.activeBossKey, self.activeDifficultyKey)
    local customCurrentness = Messages:GetCustomCurrentness(self.activeBossKey, self.activeDifficultyKey)
    local covered, timed = timedProviderCoverage(profile)
    local setupRequired = SetupRegistry:HasSetup(self.activeBossKey, self.activeDifficultyKey)
    local setupReady = Setup:IsReady(self.activeBossKey, self.activeDifficultyKey)
    local worldMarkers, targetMarkers, prepSteps = SetupRegistry:GetCounts(self.activeBossKey, self.activeDifficultyKey)

    local states = {}
    if #missingRequired > 0 then states[#states + 1] = "CHECK ASSIGNMENTS" end
    if #rosterMissing > 0 then states[#states + 1] = "CHECK ROSTER" end
    if setupRequired and not setupReady then states[#states + 1] = "CHECK SETUP" end
    if customCurrentness == "review" then states[#states + 1] = "CHECK CUSTOM TEXT" end
    if timed > 0 and self.db.automaticTimingEnabled ~= false and Timeline:GetProviderSummary() == "" then
        states[#states + 1] = "CHECK PROVIDER DRIFT"
    end

    if #states == 0 then
        states[1] = (timed > 0 and self.db.automaticTimingEnabled ~= false) and "READY TIMED" or "READY MANUAL"
    end

    ns:Print("Readiness: " .. table.concat(states, " | "))
    ns:Print(("Assignments: required=%s | roster-current=%s"):format(
        #missingRequired == 0 and "complete" or ("missing " .. #missingRequired),
        #rosterMissing == 0 and "yes" or ("no; " .. #rosterMissing .. " assigned player(s) not currently in raid")
    ))
    if #rosterMissing > 0 then ns:Print("Roster review: " .. table.concat(rosterMissing, ", ")) end
    ns:Print(("Pre-pull setup: %s | world=%d | target=%d | prep=%d"):format(
        setupRequired and (setupReady and "ready" or "check") or "not required",
        worldMarkers,
        targetMarkers,
        prepSteps
    ))
    ns:Print("Custom text: " .. customCurrentness)
    ns:Print(("Timed provider coverage observed: %d/%d call(s)"):format(covered, timed))
end

ns:RegisterModule("Core.ReadinessIntegration", {})
