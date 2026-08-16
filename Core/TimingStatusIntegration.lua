local _, ns = ...

local App = ns:GetModule("Core.App")
local Registry = ns:GetModule("Encounters.Registry")
local UI = ns:GetModule("UI.MainFrame")

local originalUpdateTiming = App.UpdateTiming

local function profileHasAutomaticTiming(profile)
    if not profile or type(profile.calls) ~= "table" then return false end
    for index = 1, #profile.calls do
        if profile.calls[index].timing ~= false then return true end
    end
    return false
end

function App:UpdateTiming(...)
    originalUpdateTiming(self, ...)

    local profile = Registry:GetProfile(self.activeBossKey, self.activeDifficultyKey)
    if not profile then return end

    if not self:IsAutomaticTimingEnabled() then
        UI.timeline:SetIdle("AUTO TIMING OFF")
        return
    end

    if not profileHasAutomaticTiming(profile) then
        UI.timeline:SetIdle("MANUAL CALLS ONLY")
    end
end

ns:RegisterModule("Core.TimingStatusIntegration", {})