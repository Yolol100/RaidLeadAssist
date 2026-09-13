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

-- Live strategy uses one raid group on Normal, but two near-equal alternating teams on Heroic/Mythic.
assert(contains(normal.callsByKey.coils.warning, "40%"))
assert(not hasDefinition("normal", "coil_a") and not hasDefinition("normal", "coil_b"),
    "Normal may soak Spectral Coils as one raid group")
assert(hasDefinition("heroic", "coil_a") and hasDefinition("heroic", "coil_b"),
    "Heroic needs two preassigned alternating Spectral Coils teams")
assert(hasDefinition("mythic", "coil_a") and hasDefinition("mythic", "coil_b"),
    "Mythic keeps the alternating Spectral Coils teams")
assert(heroic.callsByKey.coils.actionTemplate == "{{rotation:coils}} soak the active Coil")
assert(mythic.callsByKey.coils.actionTemplate == "{{rotation:coils}} soak the active Coil")
assert(contains(planText("heroic"), "two near-equal teams"))
assert(contains(planText("heroic"), "40%"))

-- Phase 2 has two sides; current guides recommend one mobile Doomscale egg carrier per side.
for _, difficulty in ipairs({ "normal", "heroic", "mythic" }) do
    assert(hasDefinition(difficulty, "egg_left") and hasDefinition(difficulty, "egg_right"),
        difficulty .. " needs left/right Doomscale egg carriers")
end
assert(normal.callsByKey.eggs.actionTemplate == "Left {{egg_left}}; Right {{egg_right}}")
assert(heroic.callsByKey.eggs.actionTemplate == "Left {{egg_left}}; Right {{egg_right}}")

-- Phase 3 Serpent's Bite uses three preassigned helper sectors: melee, ranged and healer.
for _, difficulty in ipairs({ "normal", "heroic", "mythic" }) do
    assert(hasDefinition(difficulty, "bite_melee"))
    assert(hasDefinition(difficulty, "bite_ranged"))
    assert(hasDefinition(difficulty, "bite_healer"))
    local call = Registry:GetProfile("ulatek", difficulty).callsByKey.bite
    assert(call.actionTemplate:find("bite_melee", 1, true))
    assert(call.actionTemplate:find("bite_ranged", 1, true))
    assert(call.actionTemplate:find("bite_healer", 1, true))
end
assert(contains(normal.callsByKey.bite.warning, "assigned groups soak"))
assert(contains(heroic.callsByKey.bite.warning, "Purge move out"))
assert(contains(mythic.callsByKey.bite.warning, "Purge waves out"),
    "Mythic Volatile Purge must remind the raid about emitted Caustic Waves")

-- Heroic Grasping Fangs targets three players per side and should be cleared sequentially.
assert(normal.callsByKey.fangs == nil, "Normal Grasping Fangs stays outside shared raidleader calls")
assert(heroic.callsByKey.fangs and heroic.callsByKey.fangs.timing == false)
assert(mythic.callsByKey.fangs and mythic.callsByKey.fangs.timing == false)
assert(contains(planText("heroic"), "three players per side"))
assert(contains(planText("heroic"), "sequentially"))
assert(contains(heroic.callsByKey.fangs.warning, "break one tether"))

-- Stable public bossmod identities may drive timing, but no private cooldown schedule is copied.
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
assert(contains(planText("mythic"), "Soul Constrictor"))

print("ok - Ula'tek live group tactics, exact provider identities and manual milestone boundaries guarded")
