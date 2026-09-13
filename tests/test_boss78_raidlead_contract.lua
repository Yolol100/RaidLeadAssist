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
local Registry = ns:GetModule("Encounters.Registry")
local AR = ns:GetModule("Encounters.AssignmentRegistry")

for _, d in ipairs({"normal","heroic","mythic"}) do
    local altar = Registry:GetProfile("altar",d)
    assert(altar.callsByKey.sever == nil)
    assert(altar.callsByKey.intermission.warning:find("Bloodlust",1,true))
    assert(altar.callsByKey.final.warning == "Final phase: keep health even; kill together.")
    local defs = AR:GetDefinitions("altar",d)
    assert(defs[1].key == "orb_collectors" and defs[1].minPlayers == 2 and defs[1].required)

    local ulatek = Registry:GetProfile("ulatek",d)
    for _, key in ipairs({ "waves", "coils", "heart", "serpents", "bite", "circling" }) do
        assert(ulatek.callsByKey[key] and ulatek.callsByKey[key].timing ~= false,
            d .. " Ula'tek must expose selected provider-timed call " .. key)
    end
    for _, key in ipairs({ "warden", "eggs", "phase3" }) do
        assert(ulatek.callsByKey[key] and ulatek.callsByKey[key].timing == false,
            d .. " Ula'tek milestone must remain manual: " .. key)
    end
end

assert(Registry:GetProfile("altar", "normal").callsByKey.guillotine.warning:find("at least 3", 1, true),
    "Normal Guillotine must reflect the live 3-player minimum")
assert(#AR:GetCallDefinitions("altar", "normal", "guillotine") == 0,
    "Normal Guillotine uses any 3+ players and needs no fixed roster group")
local heroicGuillotine = AR:GetCallDefinitions("altar", "heroic", "guillotine")
assert(#heroicGuillotine == 2,
    "Heroic Guillotine requires two assigned soak groups")
for _, definition in ipairs(heroicGuillotine) do
    assert(definition.minPlayers == 3, "Heroic Guillotine assignment minimum must track the live hotfix")
end
local mythicGuillotine = AR:GetCallDefinitions("altar", "mythic", "guillotine")
assert(#mythicGuillotine == 4,
    "Mythic exposes fresh Guillotine groups for the permanent debuff")
for _, definition in ipairs(mythicGuillotine) do
    assert(definition.minPlayers == 5, "Mythic Guillotine keeps the 5+ fresh-group contract")
end

local h = AR:GetDefinitions("altar","heroic")
local requiredWail=0
for _,def in ipairs(h) do if def.key:find("wail_kick_",1,true) and def.required then requiredWail=requiredWail+1 end end
assert(requiredWail == 2)

local function keysFor(difficulty)
    local found = {}
    for _, definition in ipairs(AR:GetDefinitions("ulatek", difficulty)) do found[definition.key] = definition end
    return found
end

local un = keysFor("normal")
assert(un.egg_left and un.egg_right, "Normal Ula'tek needs one Phase 2 egg carrier per side")
assert(un.bite_melee and un.bite_ranged and un.bite_healer,
    "Normal Ula'tek needs three Phase 3 Serpent's Bite helper sectors")
assert(not un.coil_a and not un.coil_b, "Normal may soak Spectral Coils as one raid group")

local uh = keysFor("heroic")
assert(uh.coil_a and uh.coil_b,
    "Heroic Ula'tek needs two alternating near-equal Spectral Coils teams")
assert(uh.egg_left and uh.egg_right,
    "Heroic Ula'tek needs one Doomscale egg carrier per side")
assert(uh.bite_melee and uh.bite_ranged and uh.bite_healer,
    "Heroic Ula'tek needs melee/ranged/healer Serpent's Bite helper sectors")

local um = keysFor("mythic")
assert(um.coil_a and um.coil_b and um.egg_left and um.egg_right and um.incubation_team,
    "Mythic Ula'tek keeps Coil rotation, egg carriers and Incubation team")
assert(um.bite_melee and um.bite_ranged and um.bite_healer,
    "Mythic Ula'tek keeps three Bite helper sectors for Purge wave control")

local normalUlatek = Registry:GetProfile("ulatek","normal")
assert(normalUlatek.callsByKey.circling and normalUlatek.callsByKey.circling.spellIDs[1] == 1301510,
    "Ula'tek platform-break timing must use current bossmod Circling Prey identity 1301510")
assert(normalUlatek.callsByKey.demolish == nil,
    "stale Demolish call identity must not return")
assert(Registry:GetProfile("ulatek","mythic").callsByKey.incubation.timing ~= false,
    "Mythic Toxic Incubation may use the reviewed exact provider timer")

print("ok - Coiled Altar and Ula'tek live tactic contracts stay difficulty-specific and fail-closed")
