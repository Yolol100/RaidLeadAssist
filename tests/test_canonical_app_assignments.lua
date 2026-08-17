local function read(path)
    local handle = assert(io.open(path, "rb"))
    local content = handle:read("*a")
    handle:close()
    return content
end

local app = read("Core/App.lua")
local toc = read("RaidLeadAssist.toc")
local function contains(text, needle) return string.find(text, needle, 1, true) ~= nil end

assert(not contains(toc, "Core/AssignmentIntegration.lua"),
    "assignment behavior must be canonical in Core/App.lua, not a late integration overlay")
assert(contains(app, 'ns:GetModule("Services.AssignmentService")'))
assert(contains(app, 'ns:GetModule("UI.AssignmentFrame")'))
assert(contains(app, 'Assignments:Initialize(self.db)'))
assert(contains(app, 'Assignments:BuildCallWarning'))
assert(contains(app, 'Assignments:AdvanceCall'))
assert(contains(app, 'AssignmentUI:Initialize(self.db'))
assert(not contains(app, "originalInitialize"))
assert(not contains(app, "originalSelectBoss"))
assert(not contains(app, "originalSelectDifficulty"))
assert(not contains(app, "originalSendExplanation"))

print("ok - assignments and call safety are canonical in Core/App.lua")
