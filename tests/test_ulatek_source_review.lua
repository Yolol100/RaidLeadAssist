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

local function assertTimedID(profile, key, spellID)
    local call = assert(profile.callsByKey[key], "missing Ula'tek call: " .. key)
    assert(call.timing ~= false, key .. " must be eligible for fail-closed provider timing")
    assert(type(call.spellIDs) == "table" and call.spellIDs[1] == spellID,
        key .. " must keep the reviewed provider spell identity")
end

local normal = Registry:GetProfile("ulatek", "normal")
local heroic = Registry:GetProfile("ulatek", "heroic")
local mythic = Registry:GetProfile("ulatek", "mythic")

-- Blizzard's live hotfix requires 40% of the raid for minimum Spectral Coils damage.
-- Soul Constrictor remains a Mythic rotation mechanic in the current encounter source.
assert(contains(normal.callsByKey.coils.warning, "40%"))
assert(contains(heroic.callsByKey.coils.warning, "40%"))
assert(mythic.callsByKey.coils.warning == "Coils: assigned team soak the active Coil.",
    "Mythic Spectral Coils uses the assigned alternating group rotation")
assert(not hasDefinition("heroic", "coil_a") and not hasDefinition("heroic", "coil_b"),
    "Heroic must not invent the Mythic Soul Constrictor rotation")
assert(hasDefinition("mythic", "coil_a") and hasDefinition("mythic", "coil_b"),
    "Mythic assignment layout keeps Coil rotation groups")

-- Normal/Heroic use one planned egg handler. Mythic adds side-specific carriers.
assert(hasDefinition("normal", "egg_handler"))
assert(hasDefinition("heroic", "egg_handler"))
assert(not hasDefinition("heroic", "egg_left") and not hasDefinition("heroic", "egg_right"),
    "Heroic must not expose Mythic egg-side assignments")
assert(hasDefinition("mythic", "egg_left") and hasDefinition("mythic", "egg_right"),
    "Mythic needs left/right egg carriers for the planned side")

-- Heroic Grasping Fangs now targets three players per side and should be cleared sequentially.
assert(normal.callsByKey.fangs == nil, "Normal Grasping Fangs stays outside shared raidleader calls")
assert(heroic.callsByKey.fangs and heroic.callsByKey.fangs.timing == false)
assert(mythic.callsByKey.fangs and mythic.callsByKey.fangs.timing == false)
assert(contains(planText("heroic"), "three players per side"))
assert(contains(planText("heroic"), "sequentially"))
assert(contains(heroic.callsByKey.fangs.warning, "one tether at a time"))

-- Stable public bossmod identities may now drive timing, but no private cooldown schedule is copied.
for _, profile in ipairs({ normal, heroic, mythic }) do
    assertTimedID(profile, "waves", 1292188)
    assertTimedID(profile, "coils", 1300530)
    assertTimedID(profile, "heart", 1286860)
    assertTimedID(profile, "serpents", 1300751)
    assertTimedID(profile, "bite", 1295905)
    assertTimedID(profile, "circling", 1301510)
    assert(profile.callsByKey.warden.timing == false)
    assert(profile.callsByKey.eggs.timing == false)
    assert(profile.callsByKey.phase3.timing == false)
end

-- Serpent's Bite is a timed warning for a leech handoff, not a fabricated fixed soak-group assignment.
assert(contains(normal.callsByKey.bite.warning, "helpers leech within 15s"))
assert(contains(heroic.callsByKey.bite.warning, "Purge helpers move 7+ yards out"))
assert(contains(mythic.callsByKey.bite.warning, "dodge its waves"),
    "Mythic Volatile Purge must remind the raid about the emitted Caustic Waves")

-- Mythic Toxic Incubation keeps provider identity separate from the display identity.
assert(mythic.callsByKey.incubation, "Mythic must keep the Toxic Incubation call")
assert(mythic.callsByKey.incubation.timing ~= false)
assert(mythic.callsByKey.incubation.spellIDs[1] == 1299757,
    "Toxic Incubation must match the stable DBM/BigWigs provider timer identity")
assert(mythic.callsByKey.incubation.iconSpellID == 1299759,
    "Toxic Incubation UI must keep the display spell identity")
assert(hasDefinition("mythic", "incubation_team"), "Mythic needs the 4+ Incubation team")

-- Live hotfixes and current bossmods identify 1301510 as Circling Prey/platform break.
assert(normal.callsByKey.circling and normal.callsByKey.circling.spellIDs[1] == 1301510)
assert(normal.callsByKey.demolish == nil, "stale Demolish identity must stay removed")
assert(contains(planText("normal"), "swimming underneath no longer works"))
assert(contains(planText("heroic"), "40%"))
assert(contains(planText("mythic"), "Soul Constrictor"))

print("ok - Ula'tek live tactics, exact provider identities and manual milestone boundaries guarded")
