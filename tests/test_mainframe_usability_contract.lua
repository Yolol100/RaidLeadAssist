local function read(path)
    local handle = assert(io.open(path, "rb"))
    local content = handle:read("*a")
    handle:close()
    return content
end

local mainFrame = read("UI/MainFrame.lua")
local app = read("Core/App.lua")
local timeline = read("UI/TimelineBar.lua")
local productivityUI = read("UI/ProductivityPanel.lua")
local productivityCore = read("Core/ProductivityIntegration.lua")
local toc = read("RaidLeadAssist.toc")

local function contains(text, needle)
    return string.find(text, needle, 1, true) ~= nil
end

-- Primary utility controls should not be smaller than the project's compact 24px-equivalent target.
assert(contains(mainFrame, 'frame.settingsButton:SetSize(62, 26)'),
    "Settings control should use an easier compact hit target")
assert(contains(productivityUI, 'width = 60') and contains(productivityUI, 'height = 24'),
    "Readiness control should meet the compact hit-target contract")
assert(contains(productivityUI, 'state.ready and "READY"') or contains(productivityUI, 'state.label or (state.ready and "READY"'),
    "Raid readiness should be visible from the main panel rather than doctor-only")
assert(contains(productivityUI, 'Click for the full doctor report.'),
    "readiness status must explain how to open the detailed report")

-- Productivity controls belong to the UI layer and reuse the canonical theme/widgets.
assert(contains(productivityUI, 'ns:GetModule("UI.Theme")') and contains(productivityUI, 'ns:GetModule("UI.ActionButton")'),
    "productivity controls must reuse the canonical Raid Lead Assist theme and action buttons")
assert(contains(productivityUI, 'button:SetPoint("RIGHT", SettingsUI.timingButton, "LEFT", -6, 0)'),
    "lead-window control should sit with the existing timing control in Settings")
assert(contains(productivityUI, 'text = "PRESETS"') and contains(productivityUI, 'text = "MY TASKS"'),
    "preset and personal-assignment controls should live in the pre-pull assignment surface")
assert(contains(productivityUI, 'AssignmentUI.currentBossKey') and contains(productivityUI, 'AssignmentUI.currentDifficultyKey'),
    "assignment productivity controls must follow the assignment window context")
assert(not contains(productivityCore, 'ns:GetModule("UI.ActionButton")') and not contains(productivityCore, 'ActionButton:Create('),
    "Core productivity integration must not own visual child construction")

-- The plan action is only valid before the pull; its label should say so before users click it.
assert(contains(mainFrame, 'SetText("SEND PRE-PULL PLAN")'),
    "Boss Plan action should expose its pre-pull lifecycle in the visible label")

-- Moving the panel currently requires a modifier, so that hidden interaction needs discoverability.
assert(contains(mainFrame, 'Shift-drag to move Raid Lead Assist'),
    "Main panel should explain its Shift-drag movement affordance")

-- Deliberate states must not look like a broken timer integration.
assert(contains(app, 'UI.timeline:SetIdle("AUTO TIMING OFF")'),
    "Disabled automatic timing should be explicit")
assert(contains(app, 'UI.timeline:SetIdle("MANUAL CALLS ONLY")'),
    "Profiles with no automatic calls should display intentional manual-only state")
assert(contains(timeline, 'function TimelineBar:SetIdle(label)'),
    "Timeline idle state should support a contextual label")

-- Productivity tools attach after the canonical App bootstrap and preserve slash fallbacks for power users.
assert(contains(productivityCore, 'C_Timer.After(0, install)'),
    "productivity controls should defer until the canonical App initialization has completed")
assert(contains(productivityCore, '/rla preset list | save <name> | load <name> | delete <name>'),
    "assignment preset workflow should remain discoverable from the slash fallback")
assert(contains(productivityCore, 'command == "my"') and contains(productivityCore, '/rla my'),
    "personal assignment view should be both implemented and discoverable")
assert(contains(toc, "Services/PersonalAssignmentService.lua") and contains(toc, "UI/ProductivityPanel.lua"),
    "personal assignment service and productivity UI must be part of the audited runtime inventory")

-- These behaviors are canonical now; the runtime should not depend on obsolete enhancement layers.
assert(not contains(toc, "UI/MainFrameEnhancements.lua"),
    "Main-frame usability behavior should not depend on an obsolete enhancement layer")
assert(not contains(toc, "Core/TimingStatusIntegration.lua"),
    "Timing status behavior should stay canonical")
assert(not contains(toc, "Encounters/VenomousAbyss/UlatekAssignmentPolicy.lua"),
    "Ula'tek assignment policy should live in AssignmentRegistry.lua")

print("ok - raid-leader surface exposes themed readiness, lead, preset, personal, pre-pull and manual-timing states safely")
