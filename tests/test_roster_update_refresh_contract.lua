local function read(path)
    local file = assert(io.open(path, "rb"))
    local content = assert(file:read("*a"))
    file:close()
    return content
end

local assignments = read("Core/AssignmentIntegration.lua")
local productivity = read("Core/ProductivityIntegration.lua")

assert(assignments:find('frame:RegisterEvent("GROUP_ROSTER_UPDATE")', 1, true),
    "AssignmentIntegration must subscribe to the native GROUP_ROSTER_UPDATE event")
assert(assignments:find('EventBus:Emit("GROUP_ROSTER_UPDATED")', 1, true),
    "native roster updates must be bridged onto the internal EventBus")
assert(assignments:find('EventBus:On("GROUP_ROSTER_UPDATED", Integration, function()\n    refreshAssignmentSurface()\nend)', 1, true),
    "roster changes must immediately recompute dynamic call text and call availability")
assert(productivity:find('"GROUP_ROSTER_UPDATED",', 1, true),
    "roster changes must immediately recompute the visible READY/CHECK state")

local handler = assignments:match('EventBus:On%("GROUP_ROSTER_UPDATED", Integration, function%(%)%s*(.-)%s*end%)')
assert(handler and handler:find("refreshAssignmentSurface()", 1, true),
    "roster-update handler must refresh assignment surfaces")
assert(not handler:find("ResetRuntime", 1, true),
    "roster updates must not reset Coil or other assignment rotations")

print("ok - native roster updates refresh call/readiness surfaces without resetting rotations")
