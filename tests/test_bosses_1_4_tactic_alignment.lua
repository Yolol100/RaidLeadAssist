local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
for _, file in ipairs({"Nekzali.lua","Sentinels.lua","Explorers.lua","Vashnik.lua"}) do
    T.Load("Encounters/VenomousAbyss/" .. file, ns)
end
local Registry = ns:GetModule("Encounters.Registry")

local expected = {
    nekzali = {
        explanation = { "BL START" },
        warnings = { "KILL ADDS", "DEBUFF — GO TO THE SIDE", "BURN CORPSES", "MELEE + TANK — SOAK" },
    },
    sentinels = {
        explanation = { "{{GROUP_SPLIT:RED:GREEN}}" },
        warnings = { "GREEN — SOAK DROPLETS", "GREEN — KILL BLOB", "GREEN — DODGE RETURN LINES", "RED — GROUP SOAK", "STASIS — 1+3 / 2+2" },
    },
    explorers = {
        explanation = { "GEBBO → NAMA → IKU" },
        warnings = { "FISH NOW → GEBBO", "FISH NOW → NAMA", "FISH NOW → IKU", "USE MUSHROOM FOR WAVE", "SOAK MARKS", "SPREAD FIRE/FROST — CLEAR WITH OPPOSITE" },
    },
    vashnik = {
        explanation = { "PURPLE + ORANGE ONLY — BL ON PULL" },
        warnings = { "KILL ADDS", "STAGGER DISPELS", "DODGE CROSS", "SOAK BILE" },
    },
}

for bossKey, contract in pairs(expected) do
    assert(Registry:GetProfile(bossKey, "normal") == nil, bossKey .. " Normal profile must be removed")
    local profile = assert(Registry:GetProfile(bossKey, "heroic"))
    assert(table.concat(profile.explanation, "\n") == table.concat(contract.explanation, "\n"))
    assert(#profile.calls == #contract.warnings, bossKey .. " Heroic call count drifted")
    for index = 1, #contract.warnings do
        assert(profile.calls[index].warning == contract.warnings[index], bossKey .. " Heroic call order/text drifted at " .. index)
    end
    assert(Registry:GetProfile(bossKey, "mythic"), bossKey .. " Mythic profile must remain supported")
end

print("ok - bosses 1-4 Heroic tactics are exact, Normal is removed and Mythic remains separate")
