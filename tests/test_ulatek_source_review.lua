local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/VenomousAbyss/Ulatek.lua", ns)
T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss78AssignmentOverride.lua", ns)

local Registry = ns:GetModule("Encounters.Registry")
local Assignments = ns:GetModule("Encounters.AssignmentRegistry")

local function contains(text, needle)
    return string.find(text or "", needle, 1, true) ~= nil
end

local function planText(difficultyKey)
    return table.concat(Registry:GetProfile("ulatek", difficultyKey).explanation, "\n")
end

local function hasDefinition(difficultyKey, key)
    for _, definition in ipairs(Assignments:GetDefinitions("ulatek", difficultyKey)) do
        if definition.key == key then return true end
    end
    return false
end

local normal = Registry:GetProfile("ulatek", "normal")
local heroic = Registry:GetProfile("ulatek", "heroic")
local mythic = Registry:GetProfile("ulatek", "mythic")

-- Current 12.1 Journal data explicitly places Soul Constrictor and Mass Gestation on Heroic as well as Mythic.
assert(contains(planText("heroic"), "SOUL CONSTRICTOR"), "Heroic plan must preserve the source-backed Soul Constrictor rotation")
assert(contains(planText("heroic"), "MASS GESTATION"), "Heroic plan must preserve the source-backed Mass Gestation side rule")
assert(contains(planText("mythic"), "SOUL CONSTRICTOR"), "Mythic should retain Soul Constrictor rotation guidance")
assert(contains(planText("mythic"), "MASS GESTATION"), "Mythic should retain Mass Gestation guidance")

-- Heroic and Mythic Spectral Coils need alternating groups because affected players cannot mitigate the next Coils.
assert(contains(heroic.callsByKey.coils.warning, "NEXT SOAK GROUP"), "Heroic Spectral Coils must call the next assigned group")
assert(contains(mythic.callsByKey.coils.warning, "NEXT SOAK GROUP"), "Mythic Spectral Coils must call the next assigned group")
assert(hasDefinition("heroic", "coil_a") and hasDefinition("heroic", "coil_b"),
    "Heroic assignment layout must expose Coil rotation groups")
assert(hasDefinition("mythic", "coil_a") and hasDefinition("mythic", "coil_b"),
    "Mythic assignment layout must keep Coil rotation groups")

-- Heroic/Mythic egg ownership is preassigned because Mass Gestation is side-specific.
local heroicLayout = Assignments:GetLayout("ulatek", "heroic")
local sawMassGestation = false
for _, section in ipairs(heroicLayout.sections) do
    if contains(section.description, "Mass Gestation") then sawMassGestation = true end
end
assert(sawMassGestation, "Heroic egg assignment copy must explain the Mass Gestation side consequence")
assert(hasDefinition("heroic", "egg_left") and hasDefinition("heroic", "egg_right"),
    "Heroic requires distinct left/right Doomscale Egg owners")

-- Normal Fangs are a personal removal; Heroic/Mythic removal causes raidwide Blight Vein and needs shared spacing.
assert(normal.callsByKey.fangs == nil, "Normal Grasping Fangs must stay bossmod-owned")
assert(heroic.callsByKey.fangs, "Heroic requires a shared Grasping Fangs manual call")
assert(mythic.callsByKey.fangs, "Mythic requires a shared Grasping Fangs manual call")
assert(contains(heroic.callsByKey.fangs.warning, "ONE AT A TIME"))
assert(contains(mythic.callsByKey.fangs.warning, "ONE AT A TIME"),
    "Mythic Fangs copy should warn against stacking raid-wide Blight Vein")

-- Personal target mechanics are intentionally delegated to DBM/BigWigs rather than duplicated by RLA.
for _, profile in ipairs({ normal, heroic, mythic }) do
    assert(profile.callsByKey.bite == nil, "Serpent/Bite target reactions must remain bossmod-owned")
    assert(profile.callsByKey.sting == nil, "Petrifying Sting target reactions must remain bossmod-owned")
    assert(profile.callsByKey.waves == nil, "Caustic Wave dodging must remain bossmod-owned")
end

assert(mythic.callsByKey.eggs.iconSpellID == 1299650,
    "Hardened Eggs must use the Hardened spell identity")
assert(mythic.callsByKey.incubation.iconSpellID == 1299759,
    "Toxic Incubation must use the Toxic Incubation display spell identity")
assert(mythic.callsByKey.eggs.iconSpellID ~= 1292188,
    "Hardened Eggs must not reuse the Caustic Waves spell identity")
assert(mythic.callsByKey.incubation.iconSpellID ~= 1302982,
    "Toxic Incubation must not reuse the Virulent Spit spell identity")
assert(mythic.callsByKey.incubation.iconSpellID ~= 1299757,
    "Toxic Incubation display identity must not be replaced with DBM's current provider timer key")

for _, difficultyKey in ipairs({ "normal", "heroic", "mythic" }) do
    for _, call in ipairs(Registry:GetProfile("ulatek", difficultyKey).calls) do
        assert(call.timing == false, difficultyKey .. " Ula'tek call unexpectedly enabled automatic timing")
    end
end

print("ok - Ula'tek current Journal difficulty rules, raidleader ownership, display identities and manual-only timing guarded")
