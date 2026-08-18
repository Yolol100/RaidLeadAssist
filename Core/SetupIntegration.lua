local _, ns = ...

local EventBus = ns:GetModule("Core.EventBus")
local SetupRegistry = ns:GetModule("Encounters.SetupRegistry")
local Setup = ns:GetModule("Services.SetupService")
local Encounter = ns:GetModule("Services.EncounterService")
local SetupCard = ns:GetModule("UI.SetupCard")
local UI = ns:GetModule("UI.MainFrame")
local App = ns:GetModule("Core.App")

local Integration = {
    card = nil,
    extraHeight = 72,
    heightApplied = false,
}

local function hasSetup()
    return SetupRegistry:HasSetup(App.activeBossKey, App.activeDifficultyKey)
end

function Integration:Refresh()
    if not UI.frame or not UI.timeline or not UI.explanationTitle then return end

    if self.heightApplied then
        UI.frame:SetHeight(math.max(1, UI.frame:GetHeight() - self.extraHeight))
        self.heightApplied = false
    end

    if not self.card then self.card = SetupCard:Create(UI.frame) end

    UI.explanationTitle:ClearAllPoints()

    if not hasSetup() then
        self.card:Hide()
        UI.explanationTitle:SetPoint("TOPLEFT", UI.timeline.frame, "BOTTOMLEFT", 0, -16)
        return
    end

    local layout = SetupRegistry:GetLayout(App.activeBossKey, App.activeDifficultyKey)
    local ready = Setup:IsReady(App.activeBossKey, App.activeDifficultyKey)

    self.card.frame:ClearAllPoints()
    self.card.frame:SetPoint("TOPLEFT", UI.timeline.frame, "BOTTOMLEFT", 0, -12)
    self.card.frame:SetPoint("RIGHT", UI.timeline.frame, "RIGHT", 0, 0)
    self.card.frame:SetEnabled(not Encounter:IsActive())
    self.card:SetLayout(layout, ready, function()
        if Encounter:IsActive() then
            ns:Print("Pre-pull Setup is locked during an active encounter.")
            return
        end
        Setup:Toggle(App.activeBossKey, App.activeDifficultyKey)
        Integration:Refresh()
    end)

    UI.explanationTitle:SetPoint("TOPLEFT", self.card.frame, "BOTTOMLEFT", 0, -16)
    UI.frame:SetHeight(UI.frame:GetHeight() + self.extraHeight)
    self.heightApplied = true
end

local originalInitialize = App.Initialize
function App:Initialize(...)
    originalInitialize(self, ...)
    Setup:Initialize()
    Integration.heightApplied = false
    Integration:Refresh()
end

local originalSelectBoss = App.SelectBoss
function App:SelectBoss(key, automatic)
    local changed = originalSelectBoss(self, key, automatic)
    if changed then
        -- MainFrame:SetEncounter recalculates the native height before this wrapper returns.
        Integration.heightApplied = false
        Integration:Refresh()
    end
    return changed
end

local originalSelectDifficulty = App.SelectDifficulty
function App:SelectDifficulty(key, automatic)
    local changed = originalSelectDifficulty(self, key, automatic)
    if changed then
        -- MainFrame:SetEncounter recalculates the native height before this wrapper returns.
        Integration.heightApplied = false
        Integration:Refresh()
    end
    return changed
end

EventBus:On("ENCOUNTER_STARTED", Integration, function(owner)
    owner:Refresh()
end)

EventBus:On("ENCOUNTER_RECOVERED", Integration, function(owner)
    owner:Refresh()
end)

EventBus:On("ENCOUNTER_ENDED", Integration, function(owner)
    owner:Refresh()
end)

ns:RegisterModule("Core.SetupIntegration", Integration)
