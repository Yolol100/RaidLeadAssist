local T = dofile("tests/testlib.lua")
local ns = T.NewNamespace()

local created
ns:RegisterModule("UI.ActionButton", {
    Create = function(_, parent, options)
        local button = { parent = parent, options = options }
        function button:SetPoint(...) self.point = { ... } end
        function button:SetScript(kind, callback) self[kind] = callback end
        created = button
        return button
    end,
})

T.Load("UI/AssignmentPreview.lua", ns)
local Preview = ns:GetModule("UI.AssignmentPreview")

local function fontString()
    local item = { points = {} }
    function item:ClearAllPoints() self.points = {} end
    function item:SetPoint(...) self.points[#self.points + 1] = { ... } end
    function item:SetJustifyH(value) self.justify = value end
    return item
end

local frame = {}
local announce = {}
local status = fontString()
local required = fontString()
local draft = { soak = "Playerone" }
local ui = {
    frame = frame,
    announceButton = announce,
    currentBossKey = "coiledaltar",
    currentDifficultyKey = "heroic",
    status = status,
    required = required,
}
function ui:GetDraftValues() return draft end

local received
local button = Preview:Attach(ui, function(bossKey, difficultyKey, values)
    received = { bossKey, difficultyKey, values }
end)

assert(button == created, "preview must use the canonical ActionButton component")
assert(button.options.text == "PREVIEW", "preview button label drifted")
assert(button.options.variant == "secondary", "preview must use the existing secondary action style")
assert(button.options.width == 88 and button.options.height == 30 and button.options.fontSize == 9, "preview must match the assignment footer sizing")
assert(button.point[1] == "RIGHT" and button.point[2] == announce and button.point[3] == "LEFT" and button.point[4] == -8, "preview must sit immediately left of ANNOUNCE")
assert(status.points[2][1] == "RIGHT" and status.points[2][2] == -445, "status copy must leave room for the fourth footer action")
assert(required.points[2][1] == "RIGHT" and required.points[2][2] == -445, "required copy must leave room for the fourth footer action")
assert(ui.previewButton == button, "assignment frame must own the attached preview control")
assert(Preview:Attach(ui, function() error("must stay idempotent") end) == button, "preview attachment must be idempotent")

assert(type(button.OnClick) == "function", "preview click handler is missing")
button.OnClick()
assert(received and received[1] == "coiledaltar" and received[2] == "heroic" and received[3] == draft, "preview must pass the current unsaved draft without mutating it")

local file = assert(io.open("Core/AssignmentIntegration.lua", "rb"))
local source = file:read("*a")
file:close()
local previewBody = assert(source:match("local function previewAssignments(.-)local function announceAssignments"), "preview integration function is missing")
assert(previewBody:find("Assignments:ValidateBossDraft", 1, true), "preview must validate the complete draft")
assert(previewBody:find("Assignments:GetMissingRequired", 1, true), "preview must reject missing required assignments")
assert(previewBody:find("Assignments.MAX_WARNING_LENGTH", 1, true), "preview must enforce the same per-line warning budget")
assert(previewBody:find("Assignments.MAX_PLAN_LINES", 1, true), "preview must enforce the same plan-line budget")
assert(previewBody:find("local only", 1, true), "preview output must clearly say it is local-only")
assert(not previewBody:find("RaidWarning", 1, true), "preview must never send raid chat")
assert(source:find("Preview:Attach(AssignmentUI, previewAssignments)", 1, true), "preview must attach only after the canonical AssignmentFrame is initialized")

print("ok - assignment preview uses the existing UI system, previews unsaved validated drafts locally and cannot send raid chat")
