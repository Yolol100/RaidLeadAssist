local function read(path)
    local handle = assert(io.open(path, "rb"))
    local content = handle:read("*a")
    handle:close()
    return content
end

local toc = read("RaidLeadAssist.toc")
local ui = read("UI/AssignmentPreview.lua")
local assignmentFrame = read("UI/AssignmentFrame.lua")
local assignmentCore = read("Core/AssignmentIntegration.lua")
local productivityCore = read("Core/ProductivityIntegration.lua")
local assignmentService = read("Services/AssignmentService.lua")
local service = read("Services/AssignmentPlanService.lua")

local function contains(text, needle)
    return string.find(text, needle, 1, true) ~= nil
end

local function before(first, second)
    local a = assert(string.find(toc, first, 1, true), first .. " missing from TOC")
    local b = assert(string.find(toc, second, 1, true), second .. " missing from TOC")
    return a < b
end

assert(before("Services/AssignmentService.lua", "Services/AssignmentPlanService.lua"),
    "plan renderer must load after authoritative assignment validation")
assert(before("UI/AssignmentFrame.lua", "UI/AssignmentPreview.lua"),
    "preview control must load after the assignment surface it extends")
assert(before("UI/AssignmentPreview.lua", "Core/AssignmentIntegration.lua"),
    "preview UI must exist before assignment integration wires callbacks")

assert(contains(ui, 'text = "PREVIEW"')
    and contains(ui, 'button:SetPoint("RIGHT", assignmentUI.announceButton, "LEFT", -8, 0)'),
    "preview belongs beside ANNOUNCE in the existing pre-pull assignment footer")
assert(contains(ui, "assignmentUI:GetDraftValues()"),
    "preview must inspect the current unsaved draft rather than stale saved state")
assert(contains(ui, "Nothing is sent to raid chat") and contains(ui, "draft is not saved"),
    "preview must clearly communicate its local read-only boundary")
assert(contains(assignmentFrame, 'self.status:SetPoint("BOTTOMLEFT", 18, 63)')
    and contains(assignmentFrame, 'self.status:SetPoint("RIGHT", -18, 0)')
    and contains(assignmentFrame, 'self.required:SetPoint("BOTTOMLEFT", 18, 51)')
    and contains(assignmentFrame, 'self.required:SetPoint("RIGHT", -18, 0)'),
    "AssignmentFrame must own the full-width footer feedback layout above the action row")
assert(not contains(ui, "assignmentUI.status:ClearAllPoints()")
    and not contains(ui, "assignmentUI.required:ClearAllPoints()"),
    "preview extension must not mutate footer elements owned by AssignmentFrame")

assert(contains(service, "Assignments:ValidateBossDraft")
    and contains(service, "Assignments:GetMissingRequired"),
    "plan rendering must reuse authoritative assignment validation instead of duplicating it")
assert(contains(service, "Assignments.MAX_WARNING_LENGTH")
    and contains(service, "Assignments.MAX_PLAN_LINES"),
    "plan rendering must reuse the existing raid warning and plan budgets")
assert(not contains(assignmentService, "function AssignmentService:GetPlanLines"),
    "legacy assignment plan rendering must not coexist with the canonical AssignmentPlanService")
assert(contains(assignmentCore, "local allowed, reason = canEditAssignments()")
    and contains(assignmentCore, "AssignmentPlan:BuildLines(bossKey, difficultyKey, values)"),
    "preview must retain the canonical pre-pull/combat/schema boundary")
assert(contains(assignmentCore, "AssignmentPlan:BuildLines(bossKey, difficultyKey, Assignments:GetValues(bossKey, difficultyKey))"),
    "ANNOUNCE must use the same canonical renderer as PREVIEW")
assert(not contains(assignmentCore, "Assignments:GetPlanLines(bossKey, difficultyKey)"),
    "ANNOUNCE must not bypass the shared plan renderer")
assert(contains(assignmentCore, "AssignmentPreviewUI:Attach(AssignmentUI, previewAssignments)"),
    "assignment integration must own the preview callback")
assert(not contains(productivityCore, "AssignmentPreviewUI") and not contains(productivityCore, "previewAssignments"),
    "productivity integration must not own assignment preview behavior")

for _, forbidden in ipairs({
    "SendChatMessage", "SendAddonMessage", "CombatLogGetCurrentEventInfo", "COMBAT_LOG_EVENT_UNFILTERED",
    "UnitAura", "UnitHealth", "UnitPower", "TargetUnit", "FocusUnit", "SetRaidTarget", "UseAction",
}) do
    assert(not contains(ui, forbidden), "preview UI must not add combat/network automation surface: " .. forbidden)
    assert(not contains(service, forbidden), "plan service must not add combat/network automation surface: " .. forbidden)
end

print("ok - assignment preview is in-context, full-width, draft-aware, local-only and cleanly owned")
