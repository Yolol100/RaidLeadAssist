local _, ns = ...

local SetupRegistry = ns:GetModule("Encounters.SetupRegistry")

local SetupService = {
    database = nil,
}

local VALID_DIFFICULTIES = { normal = true, heroic = true, mythic = true }

local function hashText(text)
    local hash = 5381
    for index = 1, #text do
        hash = (hash * 33 + text:byte(index)) % 4294967296
    end
    return string.format("%08x", hash)
end

local function layoutFingerprint(layout)
    local parts = { "S:" .. tostring(layout.summary or "") }
    for index = 1, #(layout.markers or {}) do
        local marker = layout.markers[index]
        parts[#parts + 1] = table.concat({
            "M", tostring(marker.key), tostring(marker.kind), tostring(marker.icon),
            tostring(marker.label), tostring(marker.purpose),
        }, ":")
    end
    for index = 1, #(layout.checks or {}) do
        parts[#parts + 1] = "C:" .. tostring(layout.checks[index])
    end
    return hashText(table.concat(parts, "\n"))
end

local function cleanEmpty(database, bossKey)
    local boss = database.setupConfirmations and database.setupConfirmations[bossKey]
    if type(boss) == "table" and next(boss) == nil then database.setupConfirmations[bossKey] = nil end
end

function SetupService:Initialize(database)
    self.database = database
    if type(database.setupConfirmations) ~= "table" then database.setupConfirmations = {} end
    self:NormalizeStored()
end

function SetupService:NormalizeStored()
    if not self.database then return end
    for bossKey, difficulties in pairs(self.database.setupConfirmations) do
        if type(difficulties) ~= "table" then
            self.database.setupConfirmations[bossKey] = nil
        else
            for difficultyKey, fingerprint in pairs(difficulties) do
                if not VALID_DIFFICULTIES[difficultyKey]
                    or type(fingerprint) ~= "string"
                    or not SetupRegistry:HasSetup(bossKey, difficultyKey)
                    or fingerprint ~= self:GetFingerprint(bossKey, difficultyKey) then
                    difficulties[difficultyKey] = nil
                end
            end
            cleanEmpty(self.database, bossKey)
        end
    end
end

function SetupService:GetFingerprint(bossKey, difficultyKey)
    if not VALID_DIFFICULTIES[difficultyKey] then return nil end
    local layout = SetupRegistry:GetLayout(bossKey, difficultyKey)
    if not SetupRegistry:HasSetup(bossKey, difficultyKey) then return nil end
    return layoutFingerprint(layout)
end

function SetupService:IsReady(bossKey, difficultyKey)
    if not SetupRegistry:HasSetup(bossKey, difficultyKey) then return true end
    if not self.database then return false end
    local boss = self.database.setupConfirmations[bossKey]
    local stored = type(boss) == "table" and boss[difficultyKey] or nil
    local current = self:GetFingerprint(bossKey, difficultyKey)
    return type(stored) == "string" and stored == current
end

function SetupService:SetReady(bossKey, difficultyKey, ready)
    if not self.database or not VALID_DIFFICULTIES[difficultyKey] then return false end
    if not SetupRegistry:HasSetup(bossKey, difficultyKey) then return false end

    local boss = self.database.setupConfirmations[bossKey]
    if type(boss) ~= "table" then
        boss = {}
        self.database.setupConfirmations[bossKey] = boss
    end

    if ready == true then
        boss[difficultyKey] = self:GetFingerprint(bossKey, difficultyKey)
    else
        boss[difficultyKey] = nil
        cleanEmpty(self.database, bossKey)
    end
    return true
end

function SetupService:Toggle(bossKey, difficultyKey)
    local nextReady = not self:IsReady(bossKey, difficultyKey)
    if not self:SetReady(bossKey, difficultyKey, nextReady) then return false end
    return nextReady
end

function SetupService:ResetBoss(bossKey, difficultyKey)
    if not self.database or type(self.database.setupConfirmations) ~= "table" then return end
    local boss = self.database.setupConfirmations[bossKey]
    if type(boss) == "table" then boss[difficultyKey] = nil end
    cleanEmpty(self.database, bossKey)
end

ns:RegisterModule("Services.SetupService", SetupService)
