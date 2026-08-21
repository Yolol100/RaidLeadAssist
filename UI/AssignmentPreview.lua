local _, ns = ...

local ActionButton = ns:GetModule("UI.ActionButton")

local AssignmentPreview = {}

function AssignmentPreview:Attach(assignmentUI, onPreview)
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
        if not onPreview then return end
        local ok, message = onPreview(
            assignmentUI.currentBossKey,
            assignmentUI.currentDifficultyKey,
            assignmentUI:GetDraftValues()
        )
        if assignmentUI.SetStatus then
            assignmentUI:SetStatus(message or (ok and "Assignment preview printed locally." or "Assignment preview unavailable."), ok and "success" or "error")
        end
    end)
    button:HookScript("OnEnter", function(control)
        GameTooltip:SetOwner(control, "ANCHOR_TOP")
        GameTooltip:SetText("Preview assignment plan", 0.82, 0.86, 0.82, 1)
        GameTooltip:AddLine("Validates the current draft and prints the exact plan locally. Nothing is sent to raid chat and the draft is not saved.", 0.55, 0.63, 0.58, true)
        GameTooltip:Show()
    end)
    button:HookScript("OnLeave", function() GameTooltip:Hide() end)

    -- Keep feedback above the action row so adding PREVIEW does not squeeze
    -- validation text into a narrow column beside the footer buttons.
    if assignmentUI.status then
        assignmentUI.status:ClearAllPoints()
        assignmentUI.status:SetPoint("BOTTOMLEFT", 18, 63)
        assignmentUI.status:SetPoint("RIGHT", -18, 0)
        assignmentUI.status:SetJustifyH("LEFT")
        if assignmentUI.status.SetWordWrap then assignmentUI.status:SetWordWrap(false) end
    end
    if assignmentUI.required then
        assignmentUI.required:ClearAllPoints()
        assignmentUI.required:SetPoint("BOTTOMLEFT", 18, 51)
        assignmentUI.required:SetPoint("RIGHT", -18, 0)
        assignmentUI.required:SetJustifyH("LEFT")
        if assignmentUI.required.SetWordWrap then assignmentUI.required:SetWordWrap(false) end
    end

    assignmentUI.previewButton = button
    return button
end

ns:RegisterModule("UI.AssignmentPreview", AssignmentPreview)
