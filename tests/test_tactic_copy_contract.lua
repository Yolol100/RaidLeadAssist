local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
for _, file in ipairs({"CoiledAltar.lua","Explorers.lua","Nekzali.lua","Sentinels.lua","Sszorak.lua","TwinFangs.lua","Ulatek.lua","Vashnik.lua"}) do
    T.Load("Encounters/VenomousAbyss/" .. file, ns)
end

local Registry = ns:GetModule("Encounters.Registry")
local bosses = { "altar", "explorers", "nekzali", "sentinels", "sszorak", "twinfangs", "ulatek", "vashnik" }

for _, bossKey in ipairs(bosses) do
    assert(Registry:GetProfile(bossKey, "normal") == nil,
        "Normal tactic copy must remain retired: " .. bossKey)
    for _, difficulty in ipairs({ "heroic", "mythic" }) do
        local profile = assert(Registry:GetProfile(bossKey, difficulty), "missing profile: " .. bossKey .. "/" .. difficulty)
        assert(type(profile.explanation) == "table" and #profile.explanation > 0, "missing briefing: " .. bossKey .. "/" .. difficulty)
        for index, line in ipairs(profile.explanation) do
            assert(type(line) == "string" and line ~= "", "empty briefing: " .. bossKey .. "/" .. difficulty .. "/" .. index)
            assert(#line <= 250, "briefing line exceeds 250 bytes: " .. bossKey .. "/" .. difficulty .. "/" .. index .. " (" .. #line .. ")")
        end
        for _, call in ipairs(profile.calls or {}) do
            assert(type(call.action) == "string" and call.action ~= "", "missing action: " .. bossKey .. "/" .. difficulty .. "/" .. tostring(call.key))
            assert(type(call.warning) == "string" and call.warning ~= "", "missing warning: " .. bossKey .. "/" .. difficulty .. "/" .. tostring(call.key))
            assert(#call.action <= 96, "button action too long: " .. bossKey .. "/" .. difficulty .. "/" .. tostring(call.key) .. " (" .. #call.action .. ")")
            assert(#call.warning <= 160, "raid-warning call too long: " .. bossKey .. "/" .. difficulty .. "/" .. tostring(call.key) .. " (" .. #call.warning .. ")")
        end
    end
end

print("ok - Heroic/Mythic tactic briefings stay bounded and mechanic calls stay action-first")
