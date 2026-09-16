local addonName, ns = ...

local Constants = ns:GetModule("Core.Constants")
local Database = ns:GetModule("Core.Database")
local EventBus = ns:GetModule("Core.EventBus")
local Registry = ns:GetModule("Encounters.Registry")
local Timeline = ns:GetModule("Services.TimelineService")
local Encounter = ns:GetModule("Services.EncounterService")
local BossMacros = ns:GetModule("Services.BossMacroService")
local ManagedMacros = ns:GetModule("Services.ManagedMacroService")
local Overlay = ns:GetModule("Services.ActionBarOverlayService")
local UI = ns:GetModule("UI.BossMacroManager")

local App = {
    db = nil,
    activeBossId = nil,
    activeBossKey = nil,
    activeDifficultyKey = "heroic",
}

local function validDifficulty(key)
    return Constants.DIFFICULTIES[key] ~= nil
end

function App:SetDifficulty(key)
    if not validDifficulty(key) then return false end
    self.activeDifficultyKey = key
    self.db.selectedDifficultyKey = key
    Registry:SetActiveDifficulty(key)
    return true
end

function App:SetBossContext(boss, preserveTimers)
    if type(boss) ~= "table" then return false end
    self.activeBossId = boss.id
    self.db.selectedBossId = boss.id

    local encounterKey = type(boss.sourceEncounterKey) == "string" and boss.sourceEncounterKey or nil
    self.activeBossKey = encounterKey
    if encounterKey then self.db.selectedBossKey = encounterKey end

    Timeline:SetEncounter(encounterKey, preserveTimers == true)
    return true
end

function App:SelectEncounterBoss(encounterID, encounterKey, preserveTimers)
    local boss
    if encounterID then boss = BossMacros:FindByEncounterID(encounterID) end
    if not boss and encounterKey then boss = BossMacros:GetBoss("encounter:" .. tostring(encounterKey)) end
    if not boss then
        Timeline:SetEncounter(nil)
        Overlay:HideAll()
        return false
    end

    if UI.frame then
        UI:SelectBoss(boss.id, false)
    else
        self:SetBossContext(boss, preserveTimers)
    end
    return true
end

function App:AcknowledgeMacro(macroId)
    if BossMacros:AcknowledgeMacro(macroId, Timeline) then
        Overlay:NotifyMacroAcknowledged()
    end
end

function App:OnEncounterStart(encounterID, difficultyID)
    local difficultyKey = Constants.DIFFICULTY_KEY_BY_ID[difficultyID]
    if difficultyKey then self:SetDifficulty(difficultyKey) end

    local registryEncounter = Registry:FindByEncounterID(encounterID)
    local encounterKey = registryEncounter and registryEncounter.key or nil
    self:SelectEncounterBoss(encounterID, encounterKey, true)
end

function App:OnEncounterRecovered(encounterID, difficultyID)
    local difficultyKey = Constants.DIFFICULTY_KEY_BY_ID[difficultyID]
    if difficultyKey then self:SetDifficulty(difficultyKey) end

    local registryEncounter = Registry:FindByEncounterID(encounterID)
    local encounterKey = registryEncounter and registryEncounter.key or nil
    self:SelectEncounterBoss(encounterID, encounterKey, true)
end

function App:RegisterEvents()
    EventBus:On("ENCOUNTER_SELECTED", self, function(owner, encounterKey)
        local encounter = Registry:Get(encounterKey)
        owner:SelectEncounterBoss(encounter and encounter.encounterID or nil, encounterKey, true)
    end)

    EventBus:On("ENCOUNTER_STARTED", self, function(owner, encounterID, difficultyID)
        owner:OnEncounterStart(encounterID, difficultyID)
    end)

    EventBus:On("ENCOUNTER_RECOVERED", self, function(owner, encounterID, difficultyID)
        owner:OnEncounterRecovered(encounterID, difficultyID)
    end)

    EventBus:On("ENCOUNTER_ENDED", self, function()
        Timeline:Reset()
        Overlay:NotifyMacroAcknowledged()
    end)
end

function App:PrintStatus()
    local boss = BossMacros:GetBoss(self.db.selectedBossId)
    local macros = boss and BossMacros:GetMacros(boss.id) or {}
    local managed = 0
    for _, macro in ipairs(macros) do
        if ManagedMacros:GetMacroIndex(macro.id) then managed = managed + 1 end
    end

    ns:Print(("Boss Macro Manager v%s | boss=%s | macros=%d | on action bars=%d"):format(
        tostring(ns.version),
        boss and boss.name or "none",
        #macros,
        managed
    ))
    local providers = Timeline:GetProviderDiagnostics()
    ns:Print("Timer providers: " .. (providers ~= "" and providers or "none detected"))
end

function App:RegisterSlashCommands()
    SLASH_RAIDLEADASSIST1 = "/rla"
    SlashCmdList.RAIDLEADASSIST = function(message)
        local command = tostring(message or ""):match("^%s*(.-)%s*$"):lower()
        if command == "" or command == "toggle" then
            UI:Toggle()
        elseif command == "show" then
            UI:Show()
        elseif command == "hide" then
            UI:Hide()
        elseif command == "provider" then
            local providers = Timeline:GetProviderDiagnostics()
            ns:Print("Timer providers: " .. (providers ~= "" and providers or "none detected"))
        elseif command == "status" then
            self:PrintStatus()
        elseif command == "resetpos" then
            Database:ResetPosition()
            if UI.frame then
                UI.frame:ClearAllPoints()
                UI.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
            end
            ns:Print("Boss Macro Manager position reset.")
        else
            ns:Print("Commands: /rla, show, hide, toggle, status, provider, resetpos")
        end
    end
end

function App:Initialize()
    Database:Initialize()
    self.db = Database:Get()

    if not validDifficulty(self.db.selectedDifficultyKey) then self.db.selectedDifficultyKey = "heroic" end
    self.activeDifficultyKey = self.db.selectedDifficultyKey
    Registry:SetActiveDifficulty(self.activeDifficultyKey)

    BossMacros:Initialize(self.db)
    Encounter:Initialize()
    self:RegisterEvents()

    local initialBoss = BossMacros:GetBoss(self.db.selectedBossId)
    if Encounter:IsActive() and not Encounter:HasKnownEncounter() then
        Timeline:SetEncounter(nil)
    elseif initialBoss then
        self:SetBossContext(initialBoss, false)
    else
        Timeline:SetEncounter(nil)
    end

    ManagedMacros:Initialize(self.db, function(macroId) self:AcknowledgeMacro(macroId) end)

    UI:Initialize(self.db, {
        getManagedOverhead = function(macroId) return ManagedMacros:GetManagedOverhead(macroId) end,
        getMacroMaxLength = function() return ManagedMacros:GetMacroBodyMax() end,
        onBossSelected = function(boss, userInitiated)
            self:SetBossContext(boss, userInitiated ~= true)
        end,
        onMacroSaved = function(macro)
            ManagedMacros:SyncMacro(macro)
            Overlay:RefreshBindings()
        end,
        onPickupMacro = function(macro)
            ManagedMacros:Pickup(macro)
            Overlay:RefreshBindings()
        end,
        onMacroDeleted = function(macro)
            ManagedMacros:DeleteManaged(macro)
            Overlay:RefreshBindings()
        end,
        onBossDeleting = function(_, macros)
            for _, macro in ipairs(macros or {}) do ManagedMacros:DeleteManaged(macro) end
            Overlay:RefreshBindings()
        end,
    })

    -- UI initialization re-selects the stored boss so its controls are populated.
    -- During a /reload inside an unknown encounter that must not re-enable timing
    -- for a stale boss after the fail-closed check above.
    if Encounter:IsActive() and not Encounter:HasKnownEncounter() then
        Timeline:SetEncounter(nil)
        Overlay:HideAll()
    end

    Timeline:Initialize()
    Overlay:Initialize(self.db)
    self:RegisterSlashCommands()

    C_Timer.After(1, function()
        Timeline:RefreshProviders()
        Overlay:RefreshBindings()
    end)

    if Database:HasNewerSchema() then
        ns:Print("Saved settings came from a newer Raid Lead Assist version. Editing is not guaranteed until the addon is updated.")
    end

    ns:Print("Boss Macro Manager loaded. Use /rla to open it.")
end

local bootstrap = CreateFrame("Frame")
bootstrap:RegisterEvent("ADDON_LOADED")
bootstrap:SetScript("OnEvent", function(_, _, loadedAddon)
    if loadedAddon ~= addonName then return end
    bootstrap:UnregisterEvent("ADDON_LOADED")
    App:Initialize()
end)

ns:RegisterModule("Core.App", App)