local _, ns = ...

local ActionButton = ns:GetModule("UI.ActionButton")

local AssignmentPreview = {}

function AssignmentPreview.Attach(_, assignmentUI, onPreview)
    if not assignmentUI or not assignmentUI.frame or not assignmentUI.announceButton then return end
    if assignmentUI.previewButton then return assignmentUI.previewButton end

    local button = ActionButton:Create(assignmentUI.frame, {
        text = "PREVIEW",
        width = 88,
        height = 30,
        fontSize = 9,
        variant = "secondary",
    })
    button:SetPoint("RIGHT", assignmentUI.announceButton, "LEFT", -8, 0)
    button:SetScript("OnClick", function()
        if onPreview then
            onPreview(
                assignmentUI.currentBossKey,
                assignmentUI.currentDifficultyKey,
                assignmentUI:GetDraftValues()
            )
        end
    end)

    -- The original footer reserves 350 px on the right for three actions. Preview
    -- becomes the fourth action, so keep the status copy clear of that control row.
    if assignmentUI.status then
        assignmentUI.status:ClearAllPoints()
        assignmentUI.status:SetPoint("BOTTOMLEFT", 18, 37)
        assignmentUI.status:SetPoint("RIGHT", -445, 0)
        assignmentUI.status:SetJustifyH("LEFT")
    end
    if assignmentUI.required then
        assignmentUI.required:ClearAllPoints()
        assignmentUI.required:SetPoint("BOTTOMLEFT", 18, 18)
        assignmentUI.required:SetPoint("RIGHT", -445, 0)
        assignmentUI.required:SetJustifyH("LEFT")
    end

    assignmentUI.previewButton = button
    return button
end

ns:RegisterModule("UI.AssignmentPreview", AssignmentPreview)
