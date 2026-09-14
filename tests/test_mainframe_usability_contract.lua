local function read(path)
    local handle = assert(io.open(path, "rb"))
    local content = handle:read("*a")
    handle:close()
    return content
end

local mainFrame = read("UI/MainFrame.lua")
local callButton = read("UI/CallButton.lua")
local settingsFrame = read("UI/SettingsFrame.lua")
local assignmentFrame = read("UI/AssignmentFrame.lua")
local app = read("Core/App.lua")
local database = read("Core/Database.lua")
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


assert(not contains(mainFrame, 'difficultyTabs.normal') and not contains(assignmentFrame, 'difficultyTabs.normal'),
    "Heroic/Mythic-only UI must not anchor controls to the retired Normal tab")
assert(contains(mainFrame, 'local difficultyCount = #Constants.DIFFICULTY_ORDER')
    and contains(assignmentFrame, 'local difficultyCount = #Constants.DIFFICULTY_ORDER'),
    "difficulty tab geometry must derive from the active Heroic/Mythic order")
assert(contains(mainFrame, 'local firstDifficultyKey = Constants.DIFFICULTY_ORDER[1]')
    and contains(mainFrame, 'local lastDifficultyKey = Constants.DIFFICULTY_ORDER[difficultyCount]')
    and contains(assignmentFrame, 'local firstDifficultyKey = Constants.DIFFICULTY_ORDER[1]'),
    "post-tab anchors must derive from the same active difficulty order")
assert(not contains(mainFrame, 'difficultyTabs.heroic') and not contains(mainFrame, 'difficultyTabs.mythic')
    and not contains(assignmentFrame, 'difficultyTabs.heroic'),
    "dynamic difficulty geometry must not fall back to named-tab anchors")

-- The plan action is only valid before the pull; its label should say so before users click it.
assert(contains(mainFrame, 'SetText("SEND PRE-PULL PLAN")'),
    "Boss Plan action should expose its pre-pull lifecycle in the visible label")

-- The main surface must be directly movable and scalable without a hidden modifier-only drag gesture.
assert(contains(mainFrame, 'GameTooltip:SetText("Drag to move Raid Lead Assist"'),
    "Main panel should expose direct drag movement")
assert(contains(mainFrame, 'frame.drag:EnableMouseWheel(true)') and contains(mainFrame, 'IsControlKeyDown()'),
    "Main panel header should expose bounded Ctrl-wheel resizing")
assert(contains(mainFrame, 'self.database.uiScale = scale') and contains(mainFrame, 'frame:SetScale(clampUIScale'),
    "Main panel scale should persist and restore")
assert(contains(database, 'uiScale = 1') and contains(database, 'math.max(0.70, math.min(1.10, scale))'),
    "saved UI scale must be bounded to the supported 70-110 percent range")

-- Settings and assignment surfaces must also move and adapt instead of occupying fixed oversized panels.
assert(contains(settingsFrame, 'frame:SetMovable(true)') and contains(settingsFrame, 'GameTooltip:SetText("Drag to move Settings"'),
    "Settings should be directly draggable")
assert(contains(settingsFrame, 'local desiredHeight = math.max(430, math.min(Theme.settings.height, contentHeight + 165))'),
    "Settings height should follow actual content within safe bounds")
assert(contains(assignmentFrame, 'frame:SetMovable(true)') and contains(assignmentFrame, 'GameTooltip:SetText("Drag to move Boss Assignments"'),
    "Assignments should be directly draggable")
assert(contains(assignmentFrame, 'self:UpdateFrameHeight(86)') and contains(assignmentFrame, 'math.max(350, math.min(620'),
    "assignment window should collapse when a tactic has little or no assignment content")

-- Idle buttons must not recreate the screenshot's full-lime, dark-text readability failure.
assert(contains(callButton, 'setBackdropColor(frame, Theme.colors.surfaceRaised)'),
    "idle call buttons should use the dark raised surface")
assert(contains(callButton, 'frame.name:SetTextColor(Theme.colors.text[1]'),
    "idle call labels should use the readable light text color")

-- Large final-boss call lists must remain usable on shorter effective screen heights/UI scales.
assert(contains(mainFrame, 'CreateFrame("ScrollFrame", nil, frame)'),
    "combat calls should live in a clipped scroll viewport")
assert(contains(mainFrame, 'self.callScroll:SetScrollChild(self.callContent)'),
    "combat-call scroll frame must own a bounded content frame")
assert(contains(mainFrame, 'self.callScroll:EnableMouseWheel(true)'),
    "combat-call viewport must be directly scrollable")
assert(contains(mainFrame, 'UIParent:GetHeight()') and contains(mainFrame, '(parentHeight - 48) / scale'),
    "main panel height must account for effective UI scale when capped to screen")
assert(contains(mainFrame, 'self.callScroll:SetVerticalScroll(0)'),
    "changing boss/difficulty should reset the call list to its first action")
assert(contains(mainFrame, 'CallButton:Create(self.callContent)'),
    "combat buttons must be children of the scroll content rather than escape clipping")

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

print("ok - raid-leader surfaces are compact, dark/readable, movable, scalable and safely scrollable")
