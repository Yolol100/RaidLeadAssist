local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

local function read(path)
    local file = assert(io.open(path, "rb"))
    local content = assert(file:read("*a"))
    file:close()
    return content
end

T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss78AssignmentOverride.lua", ns)

local Registry = ns:GetModule("Encounters.AssignmentRegistry")
local coils = Registry:GetCallDefinitions("ulatek", "heroic", "coils")
assert(#coils == 2, "Heroic Ula'tek must expose both Coil teams")
assert(coils[1].compactGroups == true and coils[2].compactGroups == true,
    "both Ula'tek Coil teams must request compact raid-group serialization")

local assignmentFrame = read("UI/AssignmentFrame.lua")
local rosterPicker = read("UI/RosterPicker.lua")

assert(assignmentFrame:find("end, definition and definition.compactGroups == true)", 1, true),
    "AssignmentFrame must pass the assignment definition's compactGroups contract to RosterPicker")
assert(rosterPicker:find("self.compactGroups = shouldCompactGroups(label, compactGroups)", 1, true),
    "RosterPicker must honor the explicit compactGroups argument")
assert(rosterPicker:find("orderedSelection(self.roster or {}, self.selected, self.extras, self.compactGroups)", 1, true),
    "RosterPicker apply must serialize the selection using the explicit compact-group mode")
assert(rosterPicker:find('values[#values + 1] = "Groups " .. table.concat(labels, "+")', 1, true),
    "complete selected raid groups must serialize to compact Groups 1+2 style syntax")

print("ok - Ula'tek compact-group assignment intent reaches the roster picker and serializer")
