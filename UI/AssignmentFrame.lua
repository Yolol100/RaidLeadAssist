local _, ns = ...

local Constants = ns:GetModule("Core.Constants")
local Registry = ns:GetModule("Encounters.Registry")
local AssignmentRegistry = ns:GetModule("Encounters.AssignmentRegistry")
local Assignments = ns:GetModule("Services.AssignmentService")
local Theme = ns:GetModule("UI.Theme")
local Dropdown = ns:GetModule("UI.Dropdown")
local ActionButton = ns:GetModule("UI.ActionButton")
local ConfirmDialog = ns:GetModule("UI.ConfirmDialog")
local AssignmentSlot = ns:GetModule("UI.AssignmentSlot")
local RosterPicker = ns:GetModule("UI.RosterPicker")

local AssignmentFrame = {
    currentBossKey = nil,
    currentDifficultyKey = "heroic",
    slotPool = {},
    sectionPool = {},
    activeSlots = {},
    difficultyTabs = {},
    dirty = false,
    allowHide = false,
    callbacks = {},
}

local function setBackdrop(frame, color)
    frame:SetBackdropColor(color[1], color[2], color[3], color[4] or 1)
end

local function sectionHeight(section)
    local columns = math.max(1, tonumber(section.columns) or 1)
    local rows = math.max(1, math.ceil(#section.slots / columns))
    return 48 + (rows * 68) + (math.max(0, rows - 1) * 8) + 12
end

local function hasAnyValue(values)
    for _, value in pairs(values or {}) do
        if type(value) == "string" and value:match("%S") then return true end
    end
    return false
end

function AssignmentFrame:SetStatus(text, kind)
    if not self.status then return end
    self.status:SetText(text or "")
    local color = Theme.colors.muted
    if kind == "error" then color = Theme.colors.error end
    if kind == "success" then color = Theme.colors.success end
    self.status:SetTextColor(color[1], color[2], color[3], 1)
end

function AssignmentFrame:SetDirty(dirty)
    self.dirty = dirty == true
    if self.saveButton then self.saveButton:SetActionEnabled(self.dirty) end
end

function AssignmentFrame:RefreshDifficultyTabs()
    for _, key in ipairs(Constants.DIFFICULTY_ORDER) do
        local tab = self.difficultyTabs[key]
        if tab then
            local selected = key == self.currentDifficultyKey
            setBackdrop(tab, selected and Theme.colors.venomDark or Theme.colors.surface)
            local border = selected and Theme.colors.venom or Theme.colors.border
            tab:SetBackdropBorderColor(border[1], border[2], border[3], 1)
            local text = selected and Theme.colors.text or Theme.colors.muted
            tab.text:SetTextColor(text[1], text[2], text[3], 1)
        end
    end
end

function AssignmentFrame:Initialize(database, callbacks)
    if self.frame then return end
    self.database = database
    self.callbacks = callbacks or {}

    local frame = CreateFrame("Frame", "RaidLeadAssistAssignmentFrame", UIParent, "BackdropTemplate")
    frame:SetSize(760, 680)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetBackdrop({ bgFile = Theme.texture, edgeFile = Theme.texture, edgeSize = 1 })
    setBackdrop(frame, Theme.colors.backgroundSolid)
    frame:SetBackdropBorderColor(Theme.colors.border[1], Theme.colors.border[2], Theme.colors.border[3], 1)
    local safeScale = math.min(1, (UIParent:GetWidth() - 40) / 760, (UIParent:GetHeight() - 40) / 680)
    frame:SetScale(math.max(0.72, safeScale))
    frame:Hide()

    local eyebrow = frame:CreateFontString(nil, "OVERLAY")
    eyebrow:SetFont(Theme.font, 10, "OUTLINE")
    eyebrow:SetPoint("TOPLEFT", 18, -14)
    eyebrow:SetText("RAID LEAD ASSIST · PRE-PULL")
    eyebrow:SetTextColor(Theme.colors.venom[1], Theme.colors.venom[2], Theme.colors.venom[3], 1)

    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(Theme.font, 17, "OUTLINE")
    title:SetPoint("TOPLEFT", eyebrow, "BOTTOMLEFT", 0, -6)
    title:SetText("Boss Assignments")
    title:SetTextColor(1, 1, 1, 1)

    local subtitle = frame:CreateFontString(nil, "OVERLAY")
    subtitle:SetFont(Theme.font, 9, "OUTLINE")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    subtitle:SetText("Each boss shows only the jobs its tactic needs. Dynamic targets use pre-pull rules, not live decisions.")
    subtitle:SetTextColor(Theme.colors.muted[1], Theme.colors.muted[2], Theme.colors.muted[3], 1)

    local close = CreateFrame("Button", nil, frame)
    close:SetSize(32, 32)
    close:SetPoint("TOPRIGHT", -8, -8)
    close.text = close:CreateFontString(nil, "OVERLAY")
    close.text:SetAllPoints()
    close.text:SetFont(Theme.font, 14, "OUTLINE")
    close.text:SetText("X")
    close:SetScript("OnClick", function() self:RequestClose() end)

    self.bossDropdown = Dropdown:Create(frame)
    self.bossDropdown.frame:SetPoint("TOPLEFT", 18, -82)
    self.bossDropdown.frame:SetPoint("TOPRIGHT", -18, -82)
    self.bossDropdown.menu:SetPoint("TOPLEFT", self.bossDropdown.frame, "BOTTOMLEFT", 0, -2)
    self.bossDropdown.menu:SetPoint("TOPRIGHT", self.bossDropdown.frame, "BOTTOMRIGHT", 0, -2)

    local tabWidth = (724 - 12) / 3
    local previous
    for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
        local info = Constants.DIFFICULTIES[difficultyKey]
        local tab = CreateFrame("Button", nil, frame, "BackdropTemplate")
        tab:SetSize(tabWidth, 30)
        tab:SetBackdrop({ bgFile = Theme.texture, edgeFile = Theme.texture, edgeSize = 1 })
        if previous then tab:SetPoint("LEFT", previous, "RIGHT", 6, 0) else tab:SetPoint("TOPLEFT", self.bossDropdown.frame, "BOTTOMLEFT", 0, -7) end
        tab.text = tab:CreateFontString(nil, "OVERLAY")
        tab.text:SetAllPoints()
        tab.text:SetFont(Theme.font, 10, "OUTLINE")
        tab.text:SetText(info.label)
        tab:SetScript("OnClick", function() self:RequestDifficultyChange(difficultyKey) end)
        self.difficultyTabs[difficultyKey] = tab
        previous = tab
    end

    self.summary = frame:CreateFontString(nil, "OVERLAY")
    self.summary:SetFont(Theme.font, 9, "OUTLINE")
    self.summary:SetPoint("TOPLEFT", self.difficultyTabs.normal, "BOTTOMLEFT", 2, -10)
    self.summary:SetPoint("RIGHT", -20, 0)
    self.summary:SetJustifyH("LEFT")
    self.summary:SetTextColor(Theme.colors.muted[1], Theme.colors.muted[2], Theme.colors.muted[3], 1)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 18, -157)
    scroll:SetPoint("BOTTOMRIGHT", -36, 76)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(700)
    content:SetHeight(1)
    scroll:SetScrollChild(content)
    self.content = content

    self.status = frame:CreateFontString(nil, "OVERLAY")
    self.status:SetFont(Theme.font, 9, "OUTLINE")
    self.status:SetPoint("BOTTOMLEFT", 18, 37)
    self.status:SetPoint("RIGHT", -350, 0)
    self.status:SetJustifyH("LEFT")

    self.required = frame:CreateFontString(nil, "OVERLAY")
    self.required:SetFont(Theme.font, 8, "OUTLINE")
    self.required:SetPoint("BOTTOMLEFT", 18, 18)
    self.required:SetPoint("RIGHT", -350, 0)
    self.required:SetJustifyH("LEFT")
    self.required:SetTextColor(Theme.colors.muted[1], Theme.colors.muted[2], Theme.colors.muted[3], 1)

    self.resetButton = ActionButton:Create(frame, { text = "CLEAR DRAFT", width = 96, height = 30, fontSize = 9, variant = "secondary" })
    self.resetButton:SetPoint("BOTTOMRIGHT", -18, 18)
    self.resetButton:SetScript("OnClick", function() self:ResetCurrent() end)

    self.saveButton = ActionButton:Create(frame, { text = "SAVE", width = 88, height = 30, fontSize = 9, variant = "primary" })
    self.saveButton:SetPoint("RIGHT", self.resetButton, "LEFT", -8, 0)
    self.saveButton:SetScript("OnClick", function() self:SaveCurrent(false) end)

    self.announceButton = ActionButton:Create(frame, { text = "ANNOUNCE", width = 102, height = 30, fontSize = 9, variant = "secondary" })
    self.announceButton:SetPoint("RIGHT", self.saveButton, "LEFT", -8, 0)
    self.announceButton:SetScript("OnClick", function()
        local values = self:GetDraftValues()
        local missing = Assignments:GetMissingRequired(self.currentBossKey, self.currentDifficultyKey, values)
        if #missing > 0 then
            self:SetStatus("Complete required assignments before announcing.", "error")
            return
        end
        local valid, validation = Assignments:ValidateBossDraft(self.currentBossKey, self.currentDifficultyKey, values)
        if not valid then
            self:SetStatus(validation and validation.message or "Fix invalid assignments before announcing.", "error")
            self:RefreshRequiredStatus()
            return
        end
        if self.dirty and not self:SaveCurrent(true) then return end
        if self.callbacks.onAnnounce then self.callbacks.onAnnounce(self.currentBossKey, self.currentDifficultyKey) end
    end)

    self.frame = frame
    self.confirmDialog = ConfirmDialog:Create(frame)

    frame:SetScript("OnHide", function()
        if self.allowHide then return end
        if self.confirmDialog and self.confirmDialog:IsShown() then
            frame:Show()
            self.confirmDialog:Hide()
            return
        end
        if not self.dirty then return end
        frame:Show()
        self:RequestClose()
    end)

    table.insert(UISpecialFrames, "RaidLeadAssistAssignmentFrame")
    self:SetDirty(false)
end

function AssignmentFrame:EnsureSection(index)
    if self.sectionPool[index] then return self.sectionPool[index] end
    local section = CreateFrame("Frame", nil, self.content, "BackdropTemplate")
    section:SetBackdrop({ bgFile = Theme.texture, edgeFile = Theme.texture, edgeSize = 1 })
    section:SetBackdropColor(Theme.colors.background[1], Theme.colors.background[2], Theme.colors.background[3], 0.74)
    section:SetBackdropBorderColor(Theme.colors.border[1], Theme.colors.border[2], Theme.colors.border[3], 0.9)

    section.title = section:CreateFontString(nil, "OVERLAY")
    section.title:SetFont(Theme.font, 12, "OUTLINE")
    section.title:SetPoint("TOPLEFT", 10, -9)
    section.title:SetTextColor(Theme.colors.text[1], Theme.colors.text[2], Theme.colors.text[3], 1)

    section.description = section:CreateFontString(nil, "OVERLAY")
    section.description:SetFont(Theme.font, 8, "OUTLINE")
    section.description:SetPoint("TOPLEFT", section.title, "BOTTOMLEFT", 0, -4)
    section.description:SetPoint("RIGHT", -10, 0)
    section.description:SetJustifyH("LEFT")
    section.description:SetTextColor(Theme.colors.muted[1], Theme.colors.muted[2], Theme.colors.muted[3], 1)

    self.sectionPool[index] = section
    return section
end

function AssignmentFrame:FocusAdjacentSlot(control, backwards)
    for index = 1, #self.activeSlots do
        if self.activeSlots[index] == control then
            local target = backwards and index - 1 or index + 1
            if target < 1 then target = #self.activeSlots end
            if target > #self.activeSlots then target = 1 end
            if self.activeSlots[target] then self.activeSlots[target]:Focus() end
            return
        end
    end
end

function AssignmentFrame:EnsureSlot(index)
    if self.slotPool[index] then return self.slotPool[index] end
    local slot = AssignmentSlot:Create(self.content)
    slot:SetOnChanged(function()
        slot:SetInvalid(false)
        self:SetDirty(true)
        self:SetStatus("Unsaved assignment changes.", "muted")
        self:RefreshRequiredStatus()
    end)
    slot:SetOnRoster(function(control)
        local definition = control.definition
        RosterPicker:Open(definition and definition.label, control:GetText(), function(value)
            control:SetText(value)
            self:SetDirty(true)
            self:SetStatus("Roster selection added. Save to apply.", "muted")
            self:RefreshRequiredStatus()
        end)
    end)
    slot:SetOnTab(function(control, backwards) self:FocusAdjacentSlot(control, backwards) end)
    self.slotPool[index] = slot
    return slot
end

function AssignmentFrame:GetDraftValues()
    local values = {}
    for index = 1, #self.activeSlots do
        local slot = self.activeSlots[index]
        if slot.assignmentKey then values[slot.assignmentKey] = slot:GetText() end
    end
    return values
end

function AssignmentFrame:RefreshRequiredStatus()
    if not self.currentBossKey then return end
    local values = self:GetDraftValues()
    for index = 1, #self.activeSlots do self.activeSlots[index]:SetInvalid(false) end

    local missing = Assignments:GetMissingRequired(self.currentBossKey, self.currentDifficultyKey, values)
    if #missing > 0 then
        self.required:SetText(("Missing %d required: %s"):format(#missing, table.concat(missing, ", ")))
        self.required:SetTextColor(Theme.colors.error[1], Theme.colors.error[2], Theme.colors.error[3], 1)
        if self.announceButton then self.announceButton:SetActionEnabled(false) end
        return
    end

    local valid, validation = Assignments:ValidateBossDraft(self.currentBossKey, self.currentDifficultyKey, values)
    if not valid then
        self.required:SetText(validation and validation.message or "Fix invalid assignments.")
        self.required:SetTextColor(Theme.colors.error[1], Theme.colors.error[2], Theme.colors.error[3], 1)
        if validation and validation.assignmentKey then
            for index = 1, #self.activeSlots do
                local slot = self.activeSlots[index]
                if slot.assignmentKey == validation.assignmentKey then slot:SetInvalid(true) break end
            end
        end
        if self.announceButton then self.announceButton:SetActionEnabled(false) end
        return
    end

    self.required:SetText("Required assignments complete and plan validation passed.")
    self.required:SetTextColor(Theme.colors.success[1], Theme.colors.success[2], Theme.colors.success[3], 1)
    if self.announceButton then self.announceButton:SetActionEnabled(hasAnyValue(values)) end
end

function AssignmentFrame:BuildLayout()
    local layout = AssignmentRegistry:GetLayout(self.currentBossKey, self.currentDifficultyKey)
    self.summary:SetText(layout.summary or "")
    self.activeSlots = {}

    for index = 1, #self.sectionPool do self.sectionPool[index]:Hide() end
    for index = 1, #self.slotPool do self.slotPool[index].frame:Hide() end

    if #layout.sections == 0 then
        local section = self:EnsureSection(1)
        section:ClearAllPoints()
        section:SetPoint("TOPLEFT", 0, 0)
        section:SetPoint("RIGHT", self.content, "RIGHT", 0, 0)
        section:SetHeight(92)
        section.title:SetText("No fixed assignments needed")
        section.description:SetText("Use the normal Boss Plan and combat call buttons for this difficulty.")
        section:Show()
        self.content:SetHeight(100)
        self.announceButton:SetActionEnabled(false)
        return
    end

    local y = 0
    local slotIndex = 0
    for sectionIndex = 1, #layout.sections do
        local definition = layout.sections[sectionIndex]
        local section = self:EnsureSection(sectionIndex)
        section:ClearAllPoints()
        section:SetPoint("TOPLEFT", 0, -y)
        section:SetPoint("RIGHT", self.content, "RIGHT", 0, 0)
        local height = sectionHeight(definition)
        section:SetHeight(height)
        section.title:SetText(definition.title)
        section.description:SetText(definition.description or "")
        section:Show()

        local columns = math.max(1, math.min(4, definition.columns or 1))
        local gap = 8
        local usable = 680
        local width = (usable - ((columns - 1) * gap)) / columns
        for localIndex = 1, #definition.slots do
            slotIndex = slotIndex + 1
            local slot = self:EnsureSlot(slotIndex)
            local slotDefinition = definition.slots[localIndex]
            local row = math.floor((localIndex - 1) / columns)
            local col = (localIndex - 1) % columns
            slot.frame:ClearAllPoints()
            slot.frame:SetParent(section)
            slot.frame:SetWidth(width)
            slot.frame:SetPoint("TOPLEFT", 10 + (col * (width + gap)), -44 - (row * 76))
            slot:SetDefinition(slotDefinition)
            slot:SetText(Assignments:GetValue(self.currentBossKey, self.currentDifficultyKey, slotDefinition.key))
            slot:SetInvalid(false)
            slot.frame:Show()
            self.activeSlots[#self.activeSlots + 1] = slot
        end
        y = y + height + 9
    end

    self.content:SetHeight(math.max(1, y))
end

function AssignmentFrame:Load(bossKey, difficultyKey)
    if not Registry:Get(bossKey) or not Constants.DIFFICULTIES[difficultyKey] then return false end
    self.currentBossKey = bossKey
    self.currentDifficultyKey = difficultyKey
    self.bossDropdown:SetOptions(Registry:GetOrdered(), bossKey, function(key) self:RequestBossChange(key) end)
    self:RefreshDifficultyTabs()
    self:BuildLayout()
    self:SetDirty(false)
    self:SetStatus("Fill only the jobs this tactic needs, then save.", "muted")
    self:RefreshRequiredStatus()
    return true
end

function AssignmentFrame:SaveCurrent(silent)
    if not self.currentBossKey then return false end
    for index = 1, #self.activeSlots do self.activeSlots[index]:SetInvalid(false) end
    local ok, result = Assignments:ApplyBossDraft(self.currentBossKey, self.currentDifficultyKey, self:GetDraftValues())
    if not ok then
        for index = 1, #self.activeSlots do
            local slot = self.activeSlots[index]
            if result and result.assignmentKey == slot.assignmentKey then
                slot:SetInvalid(true)
                slot:Focus()
                break
            end
        end
        self:SetStatus(result and result.message or "Unable to save assignments.", "error")
        self:RefreshRequiredStatus()
        return false
    end
    self:SetDirty(false)
    self:RefreshRequiredStatus()
    local missing = Assignments:GetMissingRequired(self.currentBossKey, self.currentDifficultyKey)
    if #missing > 0 then
        self:SetStatus(("Saved as draft · %d required assignment(s) still empty."):format(#missing), "error")
    else
        self:SetStatus("Saved. Calls now use this validated pre-pull plan.", "success")
    end
    if not silent then ns:Print("Assignments saved for " .. Registry:Get(self.currentBossKey).name .. ".") end
    return true
end

function AssignmentFrame:ResetCurrent()
    for index = 1, #self.activeSlots do
        self.activeSlots[index]:SetText("")
        self.activeSlots[index]:SetInvalid(false)
    end
    self:SetDirty(true)
    self:SetStatus("Assignments cleared as a draft. Save to apply or close and discard.", "muted")
    self:RefreshRequiredStatus()
end

function AssignmentFrame:ConfirmTransition(message, onContinue, onCancel)
    if not self.dirty then
        onContinue()
        return
    end
    self.confirmDialog:Show(
        "Unsaved assignment changes",
        message,
        function()
            if self:SaveCurrent(true) then onContinue() end
        end,
        function() onContinue() end,
        onCancel
    )
end

function AssignmentFrame:RequestBossChange(key)
    if key == self.currentBossKey or not Registry:Get(key) then return end
    local current = self.currentBossKey
    self:ConfirmTransition(
        "Save this assignment plan before switching bosses?",
        function() self:Load(key, self.currentDifficultyKey) end,
        function() self.bossDropdown:SetSelected(current, Registry:GetOrdered()) end
    )
end

function AssignmentFrame:RequestDifficultyChange(key)
    if key == self.currentDifficultyKey or not Constants.DIFFICULTIES[key] then return end
    self:ConfirmTransition(
        "Save this assignment plan before switching difficulty?",
        function() self:Load(self.currentBossKey, key) end,
        function() self:RefreshDifficultyTabs() end
    )
end

function AssignmentFrame:Open(bossKey, difficultyKey)
    if self.callbacks.canOpen then
        local allowed, reason = self.callbacks.canOpen()
        if not allowed then
            ns:Print(reason or "Assignments are available outside active encounters.")
            return false
        end
    end
    self:Initialize(self.database, self.callbacks)
    self:Load(bossKey or self.database.selectedBossKey, difficultyKey or self.database.selectedDifficultyKey or "heroic")
    self.frame:Show()
    self.frame:Raise()
    return true
end

function AssignmentFrame:HideNow()
    RosterPicker:Hide()
    if self.bossDropdown and self.bossDropdown.Close then self.bossDropdown:Close() end
    self.allowHide = true
    if self.frame then self.frame:Hide() end
    self.allowHide = false
end

function AssignmentFrame:RequestClose()
    if self.confirmDialog and self.confirmDialog:IsShown() then return end
    self:ConfirmTransition(
        "Save this assignment plan before closing?",
        function() self:HideNow() end,
        function() end
    )
end

function AssignmentFrame:Close()
    self:RequestClose()
end

function AssignmentFrame:CloseForEncounter()
    RosterPicker:Hide()
    self.dirty = false
    if self.confirmDialog and self.confirmDialog:IsShown() then
        self.confirmDialog:ClearCallbacks()
        self.confirmDialog.overlay:Hide()
    end
    self:HideNow()
end

ns:RegisterModule("UI.AssignmentFrame", AssignmentFrame)
