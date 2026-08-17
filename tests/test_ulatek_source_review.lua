local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/VenomousAbyss/Ulatek.lua", ns)
T.Load("Encounters/AssignmentRegistry.lua", ns)

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

-- Pre-release strategy currently scopes Soul Constrictor and Mass Gestation to Mythic.
-- Keep strategy in the briefing; mechanic buttons should remain immediate-action only.
assert(not contains(planText("heroic"), "SOUL CONSTRICTOR"), "Heroic plan must not include Soul Constrictor before live validation supports it")
assert(not contains(planText("heroic"), "MASS GESTATION"), "Heroic plan must not include Mass Gestation before live validation supports it")
assert(contains(planText("mythic"), "SOUL CONSTRICTOR"), "Mythic should retain Soul Constrictor rotation guidance")
assert(contains(planText("mythic"), "MASS GESTATION"), "Mythic should retain Mass Gestation guidance")

-- Current pre-release plan treats Heroic Spectral Coils as a shared raid soak;
-- alternating-group assignment remains Mythic-only pending live validation.
assert(not contains(heroic.callsByKey.coils.warning, "NEXT SOAK GROUP"), "Heroic Spectral Coils must not force a pre-release Mythic rotation")
assert(contains(mythic.callsByKey.coils.warning, "NEXT SOAK GROUP"), "Mythic Spectral Coils button must call only the next assigned group")
assert(not hasDefinition("heroic", "coil_a") and not hasDefinition("heroic", "coil_b"),
    "Heroic assignment layout must not require Coil rotation groups in the current pre-release plan")
assert(hasDefinition("mythic", "coil_a") and hasDefinition("mythic", "coil_b"),
    "Mythic assignment layout must keep Coil rotation groups")

-- Heroic egg ownership is canonical and deliberately avoids Mass Gestation copy until live validation.
local heroicLayout = Assignments:GetLayout("ulatek", "heroic")
for _, section in ipairs(heroicLayout.sections) do
    assert(not contains(section.description, "Mass Gestation"), "Heroic egg assignment copy must not claim Mass Gestation before live validation")
end
assert(hasDefinition("heroic", "egg_left") and hasDefinition("heroic", "egg_right"),
    "Heroic may still preassign left/right Doomscale Egg owners")

assert(normal.callsByKey.fangs == nil, "Normal should not expose a Heroic mechanic")
assert(heroic.callsByKey.fangs, "Heroic requires a Grasping Fangs manual call")
assert(mythic.callsByKey.fangs, "Mythic requires a Grasping Fangs manual call")
assert(contains(mythic.callsByKey.fangs.warning, "ONE AT A TIME"),
    "Mythic Fangs copy should warn against stacking raid-wide Blight Vein")

for _, profile in ipairs({ normal, heroic, mythic }) do
    assert(profile.callsByKey.bite, "Every Ula'tek difficulty requires a Serpent's Bite manual call")
    assert(contains(profile.callsByKey.bite.warning, "LEECH"), "Serpent's Bite call must tell the raid to leech the venom")
    assert(contains(profile.callsByKey.bite.warning, "7+"), "Volatile Purge call must preserve 7+ yard spread guidance")
end
assert(contains(mythic.callsByKey.bite.warning, "WAVES"),
    "Mythic Serpent's Bite should warn that Volatile Purge creates Caustic Waves")

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

print("ok - Ula'tek pre-release plan keeps difficulty rules, display identities and manual-only timing guarded")
