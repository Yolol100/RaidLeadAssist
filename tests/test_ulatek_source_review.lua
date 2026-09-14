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

assert(Registry:GetProfile("ulatek", "normal") == nil,
    "Normal Ula'tek must remain retired")
assert(#Assignments:GetDefinitions("ulatek", "normal") == 0,
    "Normal Ula'tek assignments must remain inactive")

local heroic = assert(Registry:GetProfile("ulatek", "heroic"))
local mythic = assert(Registry:GetProfile("ulatek", "mythic"))

-- Heroic/Mythic use two near-equal alternating Spectral Coils teams.
for _, difficulty in ipairs({ "heroic", "mythic" }) do
    assert(hasDefinition(difficulty, "coil_a") and hasDefinition(difficulty, "coil_b"),
        difficulty .. " needs two preassigned alternating Spectral Coils teams")
end
assert(heroic.callsByKey.coils.actionTemplate == "{{rotation:coils}} soak the active Coil")
assert(mythic.callsByKey.coils.actionTemplate == "{{rotation:coils}} soak the active Coil")
assert(contains(planText("heroic"), "two near-equal teams"))
assert(contains(planText("heroic"), "40%"))

-- Phase 2 keeps one mobile Doomscale egg carrier per side; marker wording differs by difficulty.
for _, difficulty in ipairs({ "heroic", "mythic" }) do
    assert(hasDefinition(difficulty, "egg_left") and hasDefinition(difficulty, "egg_right"),
        difficulty .. " needs left/right Doomscale egg carriers")
    local call = Registry:GetProfile("ulatek", difficulty).callsByKey.eggs
    assert(call and call.timing == false)
end
assert(heroic.callsByKey.eggs.actionTemplate == "Left {{egg_left}}; Right {{egg_right}}")
assert(mythic.callsByKey.eggs.actionTemplate == "Triangle {{egg_left}}; Cross {{egg_right}}")

-- Phase 3 Serpent's Bite uses three preassigned helper sectors.
for _, difficulty in ipairs({ "heroic", "mythic" }) do
    assert(hasDefinition(difficulty, "bite_melee"))
    assert(hasDefinition(difficulty, "bite_ranged"))
    assert(hasDefinition(difficulty, "bite_healer"))
    local call = Registry:GetProfile("ulatek", difficulty).callsByKey.bite
    assert(call.actionTemplate:find("bite_melee", 1, true))
    assert(call.actionTemplate:find("bite_ranged", 1, true))
    assert(call.actionTemplate:find("bite_healer", 1, true))
end
assert(contains(heroic.callsByKey.bite.warning, "Purge move out"))
assert(contains(mythic.callsByKey.bite.warning, "Purge waves out"),
    "Mythic Volatile Purge must remind the raid about emitted Caustic Waves")

-- Grasping Fangs remains a manual strategy milestone on both supported difficulties.
assert(heroic.callsByKey.fangs and heroic.callsByKey.fangs.timing == false)
assert(mythic.callsByKey.fangs and mythic.callsByKey.fangs.timing == false)
assert(contains(planText("heroic"), "three players per side"))
assert(contains(planText("heroic"), "sequentially"))
assert(contains(heroic.callsByKey.fangs.warning, "break one tether"))

-- Stable public bossmod identities may drive timing; strategy transitions stay manual.
for _, profile in ipairs({ heroic, mythic }) do
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

-- Mythic Toxic Incubation keeps provider identity separate from display identity.
assert(mythic.callsByKey.incubation, "Mythic must keep the Toxic Incubation call")
assert(mythic.callsByKey.incubation.timing ~= false)
assert(mythic.callsByKey.incubation.spellIDs[1] == 1299757,
    "Toxic Incubation must match the stable DBM/BigWigs provider timer identity")
assert(mythic.callsByKey.incubation.iconSpellID == 1299759,
    "Toxic Incubation UI must keep the display spell identity")
assert(hasDefinition("mythic", "incubation_team"), "Mythic needs the 4+ Incubation team")

assert(heroic.callsByKey.circling.spellIDs[1] == 1301510)
assert(heroic.callsByKey.demolish == nil and mythic.callsByKey.demolish == nil,
    "stale Demolish identity must stay removed")
assert(contains(planText("mythic"), "Soul Constrictor"))

print("ok - Ula'tek Heroic/Mythic source review guards live group tactics, exact IDs and manual milestones")
