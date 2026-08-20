local function read(path)
    local handle = assert(io.open(path, "rb"))
    local content = handle:read("*a")
    handle:close()
    return content
end

local mainFrame = read("UI/MainFrame.lua")
local app = read("Core/App.lua")
local timeline = read("UI/TimelineBar.lua")
local productivity = read("Core/ProductivityIntegration.lua")
local toc = read("RaidLeadAssist.toc")

local function contains(text, needle)
    return string.find(text, needle, 1, true) ~= nil
end

-- Primary utility controls should not be smaller than the project's compact 24px-equivalent target.
assert(contains(mainFrame, 'frame.settingsButton:SetSize(62, 26)'),
    "Settings control should use an easier compact hit target")
assert(contains(productivity, 'width = 60') and contains(productivity, 'height = 24'),
    "Readiness control should meet the compact hit-target contract")
assert(contains(productivity, 'state.ready and "READY"') or contains(productivity, 'state.label or "CHECK"'),
    "Raid readiness should be visible from the main panel rather than doctor-only")
assert(contains(productivity, 'Click for the full doctor report.'),
    "readiness status must explain how to open the detailed report")

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

-- Productivity tools attach after the canonical App bootstrap; they must not race ADDON_LOADED initialization.
assert(contains(productivity, 'C_Timer.After(0, install)'),
    "productivity controls should defer until the canonical App initialization has completed")
assert(contains(productivity, '/rla preset list | save <name> | load <name> | delete <name>'),
    "assignment preset workflow should remain discoverable")

-- These behaviors are canonical now; the runtime should not depend on obsolete enhancement layers.
assert(not contains(toc, "UI/MainFrameEnhancements.lua"),
    "Main-frame usability behavior should live in UI/MainFrame.lua")
assert(not contains(toc, "Core/TimingStatusIntegration.lua"),
    "Timing status behavior should live in Core/App.lua")
assert(not contains(toc, "Encounters/VenomousAbyss/UlatekAssignmentPolicy.lua"),
    "Ula'tek assignment policy should live in AssignmentRegistry.lua")

print("ok - raid-leader surface exposes readiness, presets, pre-pull, movement and manual-timing states safely")
