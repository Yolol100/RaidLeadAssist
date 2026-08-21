local _, ns = ...

local Assignments = ns:GetModule("Services.AssignmentService")

local AssignmentPreviewService = {}

function AssignmentPreviewService:BuildLines(bossKey, difficultyKey, values)
    local valid, clean = Assignments:ValidateBossDraft(bossKey, difficultyKey, values)
    if not valid then
        return nil, clean and clean.message or "Invalid assignments."
    end

    local missing = Assignments:GetMissingRequired(bossKey, difficultyKey, clean)
    if #missing > 0 then
        return nil, "Missing required: " .. table.concat(missing, ", ")
    end

    local lines = {}
    local definitions = Assignments:GetDefinitions(bossKey, difficultyKey)
    for index = 1, #definitions do
        local definition = definitions[index]
        local value = clean[definition.key]
        if type(value) == "string" and value ~= "" then
            local line = definition.label .. ": " .. value .. "."
            if #line > Assignments.MAX_WARNING_LENGTH then
                return nil, definition.label .. " exceeds the Raid Warning length limit."
            end
            lines[#lines + 1] = line
            if #lines >= Assignments.MAX_PLAN_LINES then break end
        end
    end

    return lines
end

ns:RegisterModule("Services.AssignmentPreviewService", AssignmentPreviewService)
