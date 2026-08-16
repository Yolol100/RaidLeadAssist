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

-- Current 12.1 source review: Soul Constrictor and Mass Gestation are Mythic-only.
assert(not contains(planText("heroic"), "SOUL CONSTRICTOR"), "Heroic must not claim Mythic-only Soul Constrictor")
assert(not contains(planText("heroic"), "MASS GESTATION"), "Heroic must not claim Mythic-only Mass Gestation")
assert(contains(planText("mythic"), "SOUL CONSTRICTOR"), "Mythic should retain Soul Constrictor rotation guidance")
assert(contains(planText("mythic"), "MASS GESTATION"), "Mythic should retain Mass Gestation guidance")

-- Heroic Spectral Coils is a shared raid soak; only Mythic requires alternating groups.
assert(not contains(heroic.callsByKey.coils.warning, "ROTATE"), "Heroic Spectral Coils must not force a Mythic rotation")
assert(contains(mythic.callsByKey.coils.warning, "ROTATE"), "Mythic Spectral Coils must retain the rotation")
assert(not hasDefinition("heroic", "coil_a") and not hasDefinition("heroic", "coil_b"),
    "Heroic assignment layout must not require Mythic-only Coil rotation groups")
assert(hasDefinition("mythic", "coil_a") and hasDefinition("mythic", "coil_b"),
    "Mythic assignment layout must keep Coil rotation groups")

-- Doomscale Eggs exist on Normal/Heroic, but only Mythic links disturbing them to Mass Gestation.
local heroicLayout = Assignments:GetLayout("ulatek", "heroic")
for _, section in ipairs(heroicLayout.sections) do
    assert(not contains(section.description, "Mass Gestation"), "Heroic egg assignment copy must not claim Mass Gestation")
end
assert(hasDefinition("heroic", "egg_left") and hasDefinition("heroic", "egg_right"),
    "Heroic may still preassign left/right Doomscale Egg owners")

-- Grasping Fangs is a Heroic/Mythic raid-lead mechanic and must have a manual call.
assert(normal.callsByKey.fangs == nil, "Normal should not expose a Heroic mechanic")
assert(heroic.callsByKey.fangs, "Heroic requires a Grasping Fangs manual call")
assert(mythic.callsByKey.fangs, "Mythic requires a Grasping Fangs manual call")
assert(contains(mythic.callsByKey.fangs.warning, "ONE AT A TIME"),
    "Mythic Fangs copy should warn against stacking raid-wide Blight Vein")

-- Ula'tek stays deliberately manual-only until public bossmod timing is complete and stable.
for _, difficultyKey in ipairs({ "normal", "heroic", "mythic" }) do
    for _, call in ipairs(Registry:GetProfile("ulatek", difficultyKey).calls) do
        assert(call.timing == false, difficultyKey .. " Ula'tek call unexpectedly enabled automatic timing")
    end
end

print("ok - Ula'tek source review keeps Heroic and Mythic mechanics separated and manual calls current")
