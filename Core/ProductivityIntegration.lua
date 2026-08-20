local addonName, ns = ...

local Constants = ns:GetModule("Core.Constants")
local Database = ns:GetModule("Core.Database")
local EventBus = ns:GetModule("Core.EventBus")
local Presets = ns:GetModule("Services.AssignmentPresetService")
local PersonalAssignments = ns:GetModule("Services.PersonalAssignmentService")
local Encounter = ns:GetModule("Services.EncounterService")
local ProductivityUI = ns:GetModule("UI.ProductivityPanel")
local Readiness = ns:GetModule("Core.ReadinessIntegration")
local App = ns:GetModule("Core.App")

local Integration = {
    installed = false,
}

local function canEditPlan()
    if Encounter:IsActive() then return false, "Assignment presets are pre-pull only." end
    if type(InCombatLockdown) == "function" and InCombatLockdown() then
        return false, "Leave combat before changing assignment presets."
    end
    if Database:HasNewerSchema() then
        return false, "Saved settings use a newer schema; update Raid Lead Assist before changing presets."
    end
    return true
end

local function canEditTiming()
    if Encounter:IsActive() then return false, "Timing preferences are pre-pull only; finish the active encounter first." end
    if type(InCombatLockdown) == "function" and InCombatLockdown() then
        return false, "Leave combat before changing timing preferences."
    end
    if Database:HasNewerSchema() then
        return false, "Saved settings use a newer schema; update Raid Lead Assist before changing timing preferences."
    end
    return true
end

local function refreshReadiness()
    if not Readiness or type(Readiness.GetState) ~= "function" then return end
    ProductivityUI:SetReadinessState(Readiness:GetState())
end

local function getTimingLead()
    return Constants.GetCallTiming(nil, App.db and App.db.timingLead)
end

local function saveTimingLead(prepareText, pressText)
    local allowed, reason = canEditTiming()
    if not allowed then return false, reason end

    local prepare, press = tonumber(prepareText), tonumber(pressText)
    local normalizedPrepare, normalizedPress, valid = Constants.NormalizeTimingLead({ prepare = prepare, press = press })
    if not valid then
        return false, ("PREPARE must be %d-%ds, PRESS %d-%ds, and PREPARE must be greater than PRESS."):format(
            Constants.MIN_PREPARE_SECONDS,
            Constants.MAX_PREPARE_SECONDS,
            Constants.MIN_PRESS_SECONDS,
            Constants.MAX_PRESS_SECONDS
        )
    end

    App.db.timingLead = { prepare = normalizedPrepare, press = normalizedPress }
    return true, ("Default lead windows saved: PREPARE %gs | PRESS %gs."):format(normalizedPrepare, normalizedPress)
end

local function resetTimingLead()
    local allowed, reason = canEditTiming()
    if not allowed then return false, reason end
    App.db.timingLead = { prepare = Constants.PREPARE_SECONDS, press = Constants.PRESS_SECONDS }
    return true, ("Default lead windows reset: PREPARE %gs | PRESS %gs."):format(
        Constants.PREPARE_SECONDS, Constants.PRESS_SECONDS
    )
end

local function setTimingLead(argument)
    local mode, rest = argument:match("^(%S+)%s*(.-)$")
    mode = (mode or ""):lower()
    if mode == "reset" then
        local ok, message = resetTimingLead()
        ns:Print(message)
        if ok then ProductivityUI:RefreshTiming() end
        return true
    end
    if mode ~= "lead" then return false end

    local prepareText, pressText = rest:match("^(%S+)%s+(%S+)%s*$")
    local ok, message = saveTimingLead(prepareText, pressText)
    ns:Print(message)
    if ok then ProductivityUI:RefreshTiming() end
    return true
end

local function listPresets(bossKey, difficultyKey)
    return Presets:List(bossKey, difficultyKey)
end

local function savePreset(name, bossKey, difficultyKey)
    local allowed, reason = canEditPlan()
    if not allowed then return false, reason end
    local ok, result = Presets:Save(name, bossKey, difficultyKey)
    if ok then
        refreshReadiness()
        return true, "Assignment preset saved: " .. result
    end
    return false, "Preset not saved: " .. tostring(result)
end

local function loadPreset(name, bossKey, difficultyKey)
    local allowed, reason = canEditPlan()
    if not allowed then return false, reason end
    local ok, result = Presets:Load(name, bossKey, difficultyKey)
    if ok then
        refreshReadiness()
        return true, "Assignment preset loaded: " .. result
    end
    return false, "Preset not loaded: " .. tostring(result)
end

local function deletePreset(name, bossKey, difficultyKey)
    local allowed, reason = canEditPlan()
    if not allowed then return false, reason end
    local ok, result = Presets:Delete(name, bossKey, difficultyKey)
    if ok then return true, "Assignment preset deleted: " .. result end
    return false, "Preset not deleted: " .. tostring(result)
end

local function printPresetList(bossKey, difficultyKey)
    local names = listPresets(bossKey, difficultyKey)
    if #names == 0 then
        ns:Print("Assignment presets: none for this boss/difficulty.")
    else
        ns:Print("Assignment presets: " .. table.concat(names, ", "))
    end
end

local function printPersonalAssignments(bossKey, difficultyKey)
    bossKey = bossKey or App.activeBossKey
    difficultyKey = difficultyKey or App.activeDifficultyKey
    local playerName, subgroup = PersonalAssignments:ResolvePlayer()
    if not playerName then
        ns:Print("Personal assignments unavailable: player identity is not readable.")
        return false
    end

    local lines = PersonalAssignments:GetLines(bossKey, difficultyKey, playerName, subgroup)
    local groupText = subgroup and (" | group " .. subgroup) or ""
    ns:Print("Personal assignments: " .. playerName .. groupText)
    if #lines == 0 then
        ns:Print("No direct player/group assignments for this boss/difficulty.")
        return true
    end
    for index = 1, #lines do
        ns:Print(("%d. %s: %s"):format(index, lines[index].label, lines[index].value))
    end
    return true
end

local function printProductivityHelp()
    ns:Print("Beta.60: use the in-panel READY/CHECK, Settings LEADS and Assignment PRESETS/MY TASKS controls; slash fallbacks: /rla my | /rla preset list|save|load|delete <name> | /rla timing lead <prepare> <press> | /rla timing reset")
end

local function handlePreset(argument)
    local action, name = argument:match("^(%S*)%s*(.-)$")
    action = (action or ""):lower()
    if action == "list" or action == "" then
        printPresetList(App.activeBossKey, App.activeDifficultyKey)
        return true
    end

    local ok, message
    if action == "save" then
        ok, message = savePreset(name, App.activeBossKey, App.activeDifficultyKey)
    elseif action == "load" then
        ok, message = loadPreset(name, App.activeBossKey, App.activeDifficultyKey)
    elseif action == "delete" then
        ok, message = deletePreset(name, App.activeBossKey, App.activeDifficultyKey)
    else
        ns:Print("Preset commands: /rla preset list | save <name> | load <name> | delete <name>")
        return true
    end
    ns:Print(message)
    if ok then ProductivityUI:RefreshPresetPanel() end
    return true
end

local function install()
    if Integration.installed or type(App.db) ~= "table" then return end
    local previousSlash = SlashCmdList and SlashCmdList.RAIDLEADASSIST or nil
    if type(previousSlash) ~= "function" then return end

    Presets:Initialize(App.db)
    ProductivityUI:Attach({
        onReadiness = function()
            refreshReadiness()
            App:PrintDoctor()
        end,
        getTimingLead = getTimingLead,
        saveTimingLead = saveTimingLead,
        resetTimingLead = resetTimingLead,
        listPresets = listPresets,
        savePreset = savePreset,
        loadPreset = loadPreset,
        deletePreset = deletePreset,
        showPersonalAssignments = printPersonalAssignments,
    })
    refreshReadiness()

    SlashCmdList.RAIDLEADASSIST = function(message)
        local command, argument = "", ""
        if type(message) == "string" then
            command, argument = message:match("^(%S*)%s*(.-)$")
        end
        command = (command or ""):lower()
        argument = argument or ""
        if command == "timing" then
            if setTimingLead(argument) then return end
            local normalized = argument:lower()
            if normalized == "on" or normalized == "off" then
                local allowed, reason = canEditTiming()
                if not allowed then
                    ns:Print(reason)
                    return
                end
            end
        elseif command == "preset" then
            handlePreset(argument)
            return
        elseif command == "my" then
            printPersonalAssignments(App.activeBossKey, App.activeDifficultyKey)
            return
        elseif command == "" or command == "help" then
            previousSlash(message)
            printProductivityHelp()
            return
        end
        previousSlash(message)
        if command == "timing" then ProductivityUI:RefreshTiming() end
    end
    Integration.installed = true
end

for _, eventName in ipairs({
    "ASSIGNMENTS_CHANGED",
    "TIMELINE_PROVIDER_CHANGED",
    "ENCOUNTER_STARTED",
    "ENCOUNTER_RECOVERED",
    "ENCOUNTER_ENDED",
    "ZONE_STATUS_CHANGED",
}) do
    EventBus:On(eventName, Integration, function() refreshReadiness() end)
end

local installer = CreateFrame("Frame")
installer:RegisterEvent("ADDON_LOADED")
installer:SetScript("OnEvent", function(frame, _, loadedAddon)
    if loadedAddon ~= addonName then return end
    frame:UnregisterEvent("ADDON_LOADED")
    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(0, install)
    else
        install()
    end
end)

ns:RegisterModule("Core.ProductivityIntegration", Integration)
