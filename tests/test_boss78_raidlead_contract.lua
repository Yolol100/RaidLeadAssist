local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/VenomousAbyss/CoiledAltar.lua", ns)
T.Load("Encounters/VenomousAbyss/Ulatek.lua", ns)
T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss78AssignmentOverride.lua", ns)
T.Load("Services/AssignmentService.lua", ns)

local Registry = ns:GetModule("Encounters.Registry")
local AssignmentRegistry = ns:GetModule("Encounters.AssignmentRegistry")
local AssignmentService = ns:GetModule("Services.AssignmentService")
AssignmentService:Initialize({ assignments = {} })

local function contains(value, needle)
    return string.find(value or "", needle, 1, true) ~= nil
end

for _, difficulty in ipairs({ "normal", "heroic", "mythic" }) do
    local altar = Registry:GetProfile("altar", difficulty)
    assert(altar.callsByKey.sever == nil, "Altar tank Sever execution must stay bossmod-owned")
    assert(altar.callsByKey.toxic and contains(altar.callsByKey.toxic.warning, "ORBS TO SEVER MARK"))
    assert(altar.callsByKey.guillotine and contains(altar.callsByKey.guillotine.warning, "5+"))
    assert(altar.callsByKey.final and contains(altar.callsByKey.final.warning, "BLOODLUST"))
    assert(contains(table.concat(altar.explanation, "\n"), "FOLLOW DBM OR BIGWIGS"))

    local altarDefinitions = AssignmentRegistry:GetDefinitions("altar", difficulty)
    assert(altarDefinitions[1].key == "orb_collectors" and altarDefinitions[1].required)
    assert(altarDefinitions[1].callKey == "toxic")

    local ulatek = Registry:GetProfile("ulatek", difficulty)
    assert(ulatek.callsByKey.coils and ulatek.callsByKey.warden and ulatek.callsByKey.eggs)
    assert(ulatek.callsByKey.heart and ulatek.callsByKey.phase3 and ulatek.callsByKey.circling)
    assert(ulatek.callsByKey.waves == nil and ulatek.callsByKey.bite == nil and ulatek.callsByKey.sting == nil)
    assert(contains(ulatek.callsByKey.phase3.warning, "BLOODLUST"))
    for _, call in ipairs(ulatek.calls) do assert(call.timing == false) end
end

local heroicDefinitions = AssignmentRegistry:GetDefinitions("ulatek", "heroic")
assert(heroicDefinitions[1].key == "coil_a" and heroicDefinitions[1].rotation == "coils")
assert(heroicDefinitions[2].key == "coil_b" and heroicDefinitions[2].rotation == "coils")

local mythicDefinitions = AssignmentRegistry:GetDefinitions("ulatek", "mythic")
local incubation
for _, definition in ipairs(mythicDefinitions) do
    if definition.key == "incubation_team" then incubation = definition end
end
assert(incubation and incubation.minPlayers == 4 and incubation.rotation == nil)

local ok = AssignmentService:ApplyBossDraft("ulatek", "mythic", {
    coil_a = "Alpha, Bravo, Charlie, Delta, Echo",
    coil_b = "Foxtrot, Golf, Hotel, India, Juliet",
    egg_left = "Kilo",
    egg_right = "Lima",
    incubation_team = "Mike, November, Oscar, Papa",
})
assert(ok)
local first = AssignmentService:BuildCallWarning("COILS > NEXT SOAK GROUP IN", "ulatek", "mythic", "coils")
assert(contains(first, "GROUP A: Alpha"))
AssignmentService:AdvanceCall("ulatek", "mythic", "coils")
local second = AssignmentService:BuildCallWarning("COILS > NEXT SOAK GROUP IN", "ulatek", "mythic", "coils")
assert(contains(second, "GROUP B: Foxtrot"))
local intercept = AssignmentService:BuildCallWarning("INCUBATION > 4 INTERCEPTORS > ONE HIT EACH", "ulatek", "mythic", "incubation")
assert(contains(intercept, "INTERCEPTORS: Mike"))

print("ok - bosses 7/8 raidleader ownership, assignments and pre-live timing boundary")
