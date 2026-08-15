local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
ns:RegisterModule("Core.EventBus", { Emit = function() end })
T.Load("Encounters/Registry.lua", ns)
for _, file in ipairs({"CoiledAltar.lua","Explorers.lua","Nekzali.lua","Sentinels.lua","Sszorak.lua","TwinFangs.lua","Ulatek.lua","Vashnik.lua"}) do
    T.Load("Encounters/VenomousAbyss/" .. file, ns)
end
T.Load("Encounters/AssignmentRegistry.lua", ns)

local Registry = ns:GetModule("Encounters.Registry")
local Assignments = ns:GetModule("Encounters.AssignmentRegistry")

for _, bossKey in ipairs(Assignments:GetBossKeys()) do
    for _, difficultyKey in ipairs({ "normal", "heroic", "mythic" }) do
        local profile = Registry:GetProfile(bossKey, difficultyKey)
        assert(profile, "missing encounter profile for assignment template: " .. bossKey .. "/" .. difficultyKey)
        for _, definition in ipairs(Assignments:GetDefinitions(bossKey, difficultyKey)) do
            if definition.callKey then
                assert(profile.callsByKey[definition.callKey],
                    "assignment callKey has no encounter call: " .. bossKey .. "/" .. difficultyKey .. "/" .. definition.key .. " -> " .. definition.callKey)
            end
            if definition.rotation then
                assert(definition.kind == "rotation", "rotating assignment must declare rotation kind")
            end
            if definition.kind == "rule" or definition.kind == "sequence" then
                assert(definition.rotation == nil, "rule/sequence fields must never advance runtime rotations")
            end
        end
    end
end

print("ok - every assignment call binding exists in its boss/difficulty profile")
