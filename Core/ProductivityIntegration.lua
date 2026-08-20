local addonName, ns = ...

local Constants = ns:GetModule("Core.Constants")
local Database = ns:GetModule("Core.Database")
local EventBus = ns:GetModule("Core.EventBus")
local Presets = ns:GetModule("Services.AssignmentPresetService")
local PersonalAssignments = ns:GetModule("Services.PersonalAssignmentService")
local Encounter = ns:GetModule("Services.EncounterService")
local ActionButton = ns:GetModule("UI.ActionButton")
local UI = ns:GetModule("UI.MainFrame")
local Readiness = ns:GetModule("Core.ReadinessIntegration")
local App = ns:GetModule("Core.App")

local Integration = {
    readinessButton = nil,
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

local function refreshReadinessButton()
    local button = Integration.readinessButton
    if not button or not Readiness or type(Readiness.GetState) ~= "function" then return end
    local state = Readiness:GetState()
    button:SetActionText(state.label or "CHECK")
    button:SetActionVariant(state.ready and "primary" or "secondary")
    button.readinessState = state
end

local function attachReadinessButton()
    if Integration.readinessButton or not UI.frame or not UI.frame.settingsButton then return end
    local button = ActionButton:Create(UI.frame, {
        text = "CHECK",
        width = 60,
        height = 24,
        fontSize = 9,
        variant = "secondary",
    })
    button:SetPoint("RIGHT", UI.frame.settingsButton, "LEFT", -4, 0)
    if UI.frame.drag then button:SetFrameLevel(UI.frame.drag:GetFrameLevel() + 1) end
    button:SetScript("OnClick", function()
        refreshReadinessButton()
        App:PrintDoctor()
    end)
    button:HookScript("OnEnter", function(control)
        refreshReadinessButton()
        local state = control.readinessState or Readiness:GetState()
        GameTooltip:SetOwner(control, "ANCHOR_TOP")
        GameTooltip:SetText(state.ready and "Raid plan readiness: READY" or "Raid plan readiness: CHECK", 0.82, 0.86, 0.82, 1)
        GameTooltip:AddLine(table.concat(state.states or {}, " | "), 0.60, 0.72, 0.64, true)
        GameTooltip:AddLine("Click for the full doctor report.", 0.55, 0.63, 0.58, true)
        GameTooltip:Show()
    end)
    button:HookScript("OnLeave", function() GameTooltip:Hide() end)
    Integration.readinessButton = button
    refreshReadinessButton()
end

local function setTimingLead(argument)
    local mode, rest = argument:match("^(%S+)%s*(.-)$")
    mode = (mode or ""):lower()
    if mode == "reset" then
        App.db.timingLead = { prepare = Constants.PREPARE_SECONDS, press = Constants.PRESS_SECONDS }
        ns:Print(("Lead windows reset: PREPARE %.1fs | PRESS %.1fs"):format(
            App.db.timingLead.prepare, App.db.timingLead.press
        ))
        return true
    end
    if mode ~= "lead" then return false end

    local prepareText, pressText = rest:match("^(%S+)%s+(%S+)%s*$")
    local prepare, press = tonumber(prepareText), tonumber(pressText)
    local normalizedPrepare, normalizedPress, valid = Constants.NormalizeTimingLead({ prepare = prepare, press = press })
    if not valid then
        ns:Print(("Lead windows: PREPARE %d-%ds, PRESS %d-%ds, and PREPARE must be greater than PRESS."):format(
            Constants.MIN_PREPARE_SECONDS,
            Constants.MAX_PREPARE_SECONDS,
            Constants.MIN_PRESS_SECONDS,
            Constants.MAX_PRESS_SECONDS
        ))
        return true
    end

    App.db.timingLead = { prepare = normalizedPrepare, press = normalizedPress }
    ns:Print(("Lead windows saved: PREPARE %.1fs | PRESS %.1fs"):format(normalizedPrepare, normalizedPress))
    return true
end

local function printPresetList()
    local names = Presets:List(App.activeBossKey, App.activeDifficultyKey)
    if #names == 0 then
        ns:Print("Assignment presets: none for this boss/difficulty.")
    else
        ns:Print("Assignment presets: " .. table.concat(names, ", "))
    end
end

local function printPersonalAssignments()
    local playerName, subgroup = PersonalAssignments:ResolvePlayer()
    if not playerName then
        ns:Print("Personal assignments unavailable: player identity is not readable.")
        return
    end

    local lines = PersonalAssignments:GetLines(App.activeBossKey, App.activeDifficultyKey, playerName, subgroup)
    local groupText = subgroup and (" | group " .. subgroup) or ""
    ns:Print("Personal assignments: " .. playerName .. groupText)
    if #lines == 0 then
        ns:Print("No direct player/group assignments for this boss/difficulty.")
        return
    end
    for index = 1, #lines do
        ns:Print(("%d. %s: %s"):format(index, lines[index].label, lines[index].value))
    end
end

local function handlePreset(argument)
    local action, name = argument:match("^(%S*)%s*(.-)$")
    action = (action or ""):lower()
    if action == "list" or action == "" then
        printPresetList()
        return true
    end

    local allowed, reason = canEditPlan()
    if not allowed then
        ns:Print(reason)
        return true
    end

    local ok, result
    if action == "save" then
        ok, result = Presets:Save(name, App.activeBossKey, App.activeDifficultyKey)
        ns:Print(ok and ("Assignment preset saved: " .. result) or ("Preset not saved: " .. tostring(result)))
        return true
    elseif action == "load" then
        ok, result = Presets:Load(name, App.activeBossKey, App.activeDifficultyKey)
        ns:Print(ok and ("Assignment preset loaded: " .. result) or ("Preset not loaded: " .. tostring(result)))
        refreshReadinessButton()
        return true
    elseif action == "delete" then
        ok, result = Presets:Delete(name, App.activeBossKey, App.activeDifficultyKey)
        ns:Print(ok and ("Assignment preset deleted: " .. result) or ("Preset not deleted: " .. tostring(result)))
        return true
    end

    ns:Print("Preset commands: /rla preset list | save <name> | load <name> | delete <name>")
    return true
end

local function install()
    if Integration.installed or type(App.db) ~= "table" then return end
    local previousSlash = SlashCmdList and SlashCmdList.RAIDLEADASSIST or nil
    if type(previousSlash) ~= "function" then return end

    Presets:Initialize(App.db)
    attachReadinessButton()
    SlashCmdList.RAIDLEADASSIST = function(message)
        local command, argument = "", ""
        if type(message) == "string" then
            command, argument = message:match("^(%S*)%s*(.-)$")
        end
        command = (command or ""):lower()
        argument = argument or ""
        if command == "timing" and setTimingLead(argument) then
            return
        elseif command == "preset" then
            handlePreset(argument)
            return
        elseif command == "my" then
            printPersonalAssignments()
            return
        end
        previousSlash(message)
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
    EventBus:On(eventName, Integration, function() refreshReadinessButton() end)
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
