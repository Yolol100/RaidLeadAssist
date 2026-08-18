local _, ns = ...

local SetupRegistry = ns:GetModule("Encounters.SetupRegistry")

local SetupService = {
    confirmations = {},
}

local VALID_DIFFICULTIES = { normal = true, heroic = true, mythic = true }

local function confirmationKey(bossKey, difficultyKey)
    return tostring(bossKey) .. ":" .. tostring(difficultyKey)
end

function SetupService:Initialize()
    self.confirmations = {}
end

function SetupService:IsReady(bossKey, difficultyKey)
    if not SetupRegistry:HasSetup(bossKey, difficultyKey) then return true end
    return self.confirmations[confirmationKey(bossKey, difficultyKey)] == true
end

function SetupService:SetReady(bossKey, difficultyKey, ready)
    if not VALID_DIFFICULTIES[difficultyKey] then return false end
    if not SetupRegistry:HasSetup(bossKey, difficultyKey) then return false end

    local key = confirmationKey(bossKey, difficultyKey)
    self.confirmations[key] = ready == true or nil
    return true
end

function SetupService:Toggle(bossKey, difficultyKey)
    local nextReady = not self:IsReady(bossKey, difficultyKey)
    if not self:SetReady(bossKey, difficultyKey, nextReady) then return false end
    return nextReady
end

function SetupService:ResetBoss(bossKey, difficultyKey)
    self.confirmations[confirmationKey(bossKey, difficultyKey)] = nil
end

function SetupService:ResetAll()
    self.confirmations = {}
end

ns:RegisterModule("Services.SetupService", SetupService)
