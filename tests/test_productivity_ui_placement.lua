local function read(path)
    local handle = assert(io.open(path, "rb"))
    local content = handle:read("*a")
    handle:close()
    return content
end

local toc = read("RaidLeadAssist.toc")
local ui = read("UI/ProductivityPanel.lua")
local core = read("Core/ProductivityIntegration.lua")

local function contains(text, needle)
    return string.find(text, needle, 1, true) ~= nil
end

local function before(first, second)
    local a = assert(string.find(toc, first, 1, true), first .. " missing from TOC")
    local b = assert(string.find(toc, second, 1, true), second .. " missing from TOC")
    return a < b
end

assert(before("Services/AssignmentPresetService.lua", "UI/ProductivityPanel.lua"),
    "preset state owner must load before the productivity UI")
assert(before("Services/PersonalAssignmentService.lua", "UI/ProductivityPanel.lua"),
    "personal assignment state owner must load before the productivity UI")
assert(before("UI/MainFrame.lua", "UI/ProductivityPanel.lua")
    and before("UI/SettingsFrame.lua", "UI/ProductivityPanel.lua")
    and before("UI/AssignmentFrame.lua", "UI/ProductivityPanel.lua"),
    "productivity UI must load after each surface it extends")
assert(before("UI/ProductivityPanel.lua", "Core/App.lua")
    and before("Core/App.lua", "Core/ProductivityIntegration.lua"),
    "visual module must exist before the post-App integration wires callbacks")

assert(contains(ui, 'button:SetPoint("RIGHT", MainUI.frame.settingsButton, "LEFT", -4, 0)'),
    "readiness belongs beside Settings on the main raid-control surface")
assert(contains(ui, 'button:SetPoint("RIGHT", SettingsUI.timingButton, "LEFT", -6, 0)'),
    "lead defaults belong beside AUTO timing in Settings")
assert(contains(ui, 'presetButton:SetPoint("TOPRIGHT", -48, -43)')
    and contains(ui, 'personalButton:SetPoint("RIGHT", presetButton, "LEFT", -6, 0)'),
    "presets and personal tasks belong in the pre-pull assignment header")
assert(contains(ui, 'createPopover(SettingsUI.frame, 340, 178)')
    and contains(ui, 'createPopover(AssignmentUI.frame, 470, 188)'),
    "secondary controls should use bounded in-context popovers rather than new global windows")
assert(contains(ui, 'panel:SetClampedToScreen(true)'),
    "productivity popovers must stay on screen")
assert(contains(ui, 'AssignmentUI:SaveCurrent(true)')
    and contains(ui, 'AssignmentUI:ConfirmTransition('),
    "preset UI must reuse the assignment draft validation/unsaved-change contract")
assert(contains(ui, 'self.callbacks.showPersonalAssignments(AssignmentUI.currentBossKey, AssignmentUI.currentDifficultyKey)'),
    "My Tasks must follow the assignment window boss/difficulty rather than stale main-frame context")

assert(contains(core, 'local function canEditTiming()')
    and contains(core, 'if Encounter:IsActive() then return false')
    and contains(core, 'InCombatLockdown')
    and contains(core, 'Database:HasNewerSchema()'),
    "timing preferences must use the same pre-pull/combat/schema safety boundary as other planning settings")
assert(contains(core, 'normalized == "on" or normalized == "off"'),
    "legacy timing on/off slash controls must not bypass the new pre-pull safety boundary")
assert(contains(core, 'saveTimingLead = saveTimingLead')
    and contains(core, 'resetTimingLead = resetTimingLead')
    and contains(core, 'savePreset = savePreset')
    and contains(core, 'loadPreset = loadPreset'),
    "UI should receive bounded callbacks rather than reach into service state directly")

for _, forbidden in ipairs({
    "SendChatMessage", "SendAddonMessage", "CombatLogGetCurrentEventInfo", "COMBAT_LOG_EVENT_UNFILTERED",
    "UnitAura", "UnitHealth", "UnitPower", "TargetUnit", "FocusUnit", "SetRaidTarget", "UseAction",
}) do
    assert(not contains(ui, forbidden), "productivity UI must not introduce combat/network automation surface: " .. forbidden)
end

print("ok - productivity controls are themed, context-owned, pre-pull safe and load-order correct")
