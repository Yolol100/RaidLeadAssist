local function read(path)
    local handle = assert(io.open(path, "rb"))
    local content = handle:read("*a")
    handle:close()
    return content
end

local main = read("UI/MainFrame.lua")
local app = read("Core/App.lua")
local timeline = read("UI/TimelineBar.lua")

local function contains(text, needle)
    return string.find(text, needle, 1, true) ~= nil
end

-- Primary utility controls should not be smaller than the project's compact 24px-equivalent target.
assert(contains(main, 'frame.settingsButton:SetSize(62, 26)'),
    "Settings control should use an easier compact hit target")

-- The plan action is only valid before the pull; its label should say so before users click it.
assert(contains(main, 'SetText("SEND PRE-PULL PLAN")'),
    "Boss Plan action should expose its pre-pull lifecycle in the visible label")

-- Moving the panel currently requires a modifier, so that hidden interaction needs discoverability.
assert(contains(main, 'Shift-drag to move Raid Lead Assist'),
    "Main panel should explain its Shift-drag movement affordance")

-- Deliberate states must not look like a broken timer integration.
assert(contains(app, 'UI.timeline:SetIdle("AUTO TIMING OFF")'),
    "Disabled automatic timing should be explicit")
assert(contains(app, 'UI.timeline:SetIdle("MANUAL CALLS ONLY")'),
    "Profiles with no automatic calls should display intentional manual-only state")
assert(contains(timeline, 'function TimelineBar:SetIdle(label)'),
    "Timeline idle state should support a contextual label")

print("ok - raid-leader surface exposes pre-pull, movement, compact target and manual-timing states")
