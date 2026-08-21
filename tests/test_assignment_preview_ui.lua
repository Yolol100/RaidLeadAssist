local function read(path)
    local handle = assert(io.open(path, "rb"))
    local content = handle:read("*a")
    handle:close()
    return content
end

local toc = read("RaidLeadAssist.toc")
local ui = read("UI/AssignmentPreview.lua")
local core = read("Core/ProductivityIntegration.lua")
local service = read("Services/AssignmentPreviewService.lua")

local function contains(text, needle)
    return string.find(text, needle, 1, true) ~= nil
end

local function before(first, second)
    local a = assert(string.find(toc, first, 1, true), first .. " missing from TOC")
    local b = assert(string.find(toc, second, 1, true), second .. " missing from TOC")
    return a < b
end

assert(before("Services/AssignmentService.lua", "Services/AssignmentPreviewService.lua"),
    "preview service must load after authoritative assignment validation")
assert(before("UI/AssignmentFrame.lua", "UI/AssignmentPreview.lua"),
    "preview control must load after the assignment surface it extends")
assert(before("UI/AssignmentPreview.lua", "Core/ProductivityIntegration.lua"),
    "preview UI must exist before productivity integration wires callbacks")

assert(contains(ui, 'text = "PREVIEW"')
    and contains(ui, 'button:SetPoint("RIGHT", assignmentUI.announceButton, "LEFT", -8, 0)'),
    "preview belongs beside ANNOUNCE in the existing pre-pull assignment footer")
assert(contains(ui, "assignmentUI:GetDraftValues()"),
    "preview must inspect the current unsaved draft rather than stale saved state")
assert(contains(ui, "Nothing is sent to raid chat") and contains(ui, "draft is not saved"),
    "preview must clearly communicate its local read-only boundary")

assert(contains(service, "Assignments:ValidateBossDraft")
    and contains(service, "Assignments:GetMissingRequired"),
    "preview must reuse authoritative assignment validation instead of duplicating it")
assert(contains(service, "Assignments.MAX_WARNING_LENGTH")
    and contains(service, "Assignments.MAX_PLAN_LINES"),
    "preview must reuse the existing raid warning and plan budgets")
assert(contains(core, "Assignment preview is pre-pull only.")
    and contains(core, "InCombatLockdown"),
    "preview must retain the pre-pull/combat planning boundary")
assert(contains(core, "AssignmentPreviewUI:Attach(AssignmentUI, previewAssignments)"),
    "productivity integration must wire the preview through a bounded callback")

for _, forbidden in ipairs({
    "SendChatMessage", "SendAddonMessage", "CombatLogGetCurrentEventInfo", "COMBAT_LOG_EVENT_UNFILTERED",
    "UnitAura", "UnitHealth", "UnitPower", "TargetUnit", "FocusUnit", "SetRaidTarget", "UseAction",
}) do
    assert(not contains(ui, forbidden), "preview UI must not add combat/network automation surface: " .. forbidden)
    assert(not contains(service, forbidden), "preview service must not add combat/network automation surface: " .. forbidden)
end

print("ok - assignment preview is in-context, draft-aware, local-only and safely wired")
