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

-- Ula'tek was not publicly PTR-tested. Current guide/wiki consensus places
-- Soul Constrictor and Mass Gestation on Mythic, so Heroic stays conservative
-- until live Retail evidence resolves the conflicting Journal/NPC presentation.
assert(normal.callsByKey.coils.warning == "Spectral Coils: stack at Square.")
assert(heroic.callsByKey.coils.warning == "Spectral Coils: stack at Square.",
    "Heroic must keep the full-raid Coils instruction until live evidence proves a rotation")
assert(contains(mythic.callsByKey.coils.warning, "called group"),
    "Mythic Spectral Coils uses the assigned alternating group rotation")
assert(not hasDefinition("heroic", "coil_a") and not hasDefinition("heroic", "coil_b"),
    "Heroic must not invent Mythic Coil rotation assignments")
assert(hasDefinition("mythic", "coil_a") and hasDefinition("mythic", "coil_b"),
    "Mythic assignment layout keeps Coil rotation groups")

-- Normal/Heroic use one planned egg handler. Mythic adds side-specific carriers.
assert(hasDefinition("normal", "egg_handler"))
assert(hasDefinition("heroic", "egg_handler"))
assert(not hasDefinition("heroic", "egg_left") and not hasDefinition("heroic", "egg_right"),
    "Heroic must not expose Mythic egg-side assignments")
assert(hasDefinition("mythic", "egg_left") and hasDefinition("mythic", "egg_right"),
    "Mythic needs left/right egg carriers for the planned side")

-- Heroic additions stay limited to the source-backed Fang/Viper/Birthling reactions.
assert(normal.callsByKey.fangs == nil, "Normal Grasping Fangs stays outside shared raidleader calls")
assert(heroic.callsByKey.fangs, "Heroic requires a shared Grasping Fangs call")
assert(mythic.callsByKey.fangs, "Mythic retains the shared Grasping Fangs call")
assert(contains(planText("heroic"), "Grasping Fangs"))
assert(contains(planText("heroic"), "Petrifying Sting"))
assert(contains(planText("heroic"), "Birthlings"))
assert(not contains(planText("heroic"), "Coil group"),
    "Heroic delta must not contain the Mythic Coil rotation")

-- Mythic adds Incubation, hardened egg handling and Coil/egg-side coordination.
assert(mythic.callsByKey.incubation, "Mythic must keep the Toxic Incubation call")
assert(mythic.callsByKey.incubation.warning == "Toxic Incubation: each interceptor takes one hit.")
assert(hasDefinition("mythic", "incubation_team"), "Mythic needs the 4+ Incubation team")
assert(contains(planText("mythic"), "Toxic Incubation"))
assert(contains(planText("mythic"), "Hardened egg"))
assert(contains(planText("mythic"), "Egg carriers stay 3+ yards"))

-- Correct display identities and the phase-3 movement identity remain guarded.
assert(mythic.callsByKey.eggs.iconSpellID == 1299650,
    "Hardened Eggs must use the Hardened spell identity")
assert(mythic.callsByKey.incubation.iconSpellID == 1299759,
    "Toxic Incubation must use the Toxic Incubation display spell identity")
assert(mythic.callsByKey.eggs.iconSpellID ~= 1292188)
assert(mythic.callsByKey.incubation.iconSpellID ~= 1302982)
assert(normal.callsByKey.demolish and normal.callsByKey.demolish.iconSpellID == 1301510,
    "1301510 is Demolish, not Circling Prey")
assert(normal.callsByKey.circling == nil, "stale Circling Prey call identity must stay removed")

for _, difficultyKey in ipairs({ "normal", "heroic", "mythic" }) do
    for _, call in ipairs(Registry:GetProfile("ulatek", difficultyKey).calls) do
        assert(call.timing == false, difficultyKey .. " Ula'tek call unexpectedly enabled automatic timing")
    end
end

print("ok - Ula'tek conservative difficulty split, concise callouts, identities and manual timing guarded")
