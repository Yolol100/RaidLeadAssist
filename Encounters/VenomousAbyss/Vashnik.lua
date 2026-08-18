local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function timedCall(key, ability, warning, voice, spellIDs, prepareSeconds, pressSeconds)
    return {
        key = key,
        ability = ability,
        action = warning,
        warning = warning,
        voice = voice,
        spellIDs = spellIDs,
        prepareSeconds = prepareSeconds,
        pressSeconds = pressSeconds,
    }
end

local function manualCall(key, ability, warning, voice)
    return {
        key = key,
        ability = ability,
        action = warning,
        warning = warning,
        voice = voice,
        timing = false,
    }
end

local killAdds = timedCall("imbibe", "Imbibe", "KILL ADDS", "Kill adds", { 1283164 }, 8, 5)
local fireNormal = manualCall("fire_stagger", "Burning Venoms", "KILL FIRE ADDS", "Kill fire adds")
local fireStagger = manualCall("fire_stagger", "Burning Venoms", "SKULL FIRST > WAIT > X", "Stagger fire adds")
local dodgeSwirlies = manualCall("shadow_dodge", "Shrouded Venoms", "DODGE SWIRLIES", "Dodge swirlies")
local adaptive = timedCall("infection", "Adaptive Infection", "INFECTION > CHECK TYPE", "Check infection", { 1282114, 1282117 }, 6, 3)
local siphon = manualCall("siphon", "Siphoning Infection", "SIPHON > STACK HELPERS ON TARGET", "Stack for siphon")
local exploding = manualCall("exploding", "Exploding Infection", "BIG CIRCLE > MOVE FAR OUT", "Move far out")
local stygian = manualCall("stygian", "Stygian Infection", "SPREAD > KEEP MOVING", "Spread and move")
local catalyst = timedCall("catalyst", "Malignant Catalyst", "SOAK BILE", "Soak bile", { 1282525, 1282509 }, 7, 4)

local frothNormal = timedCall("froth", "Plague Froth", "FROTH > MOVE OUT > AIM AWAY", "Aim waves away", { 1281907 }, 6, 3)
local frothMythic = timedCall("froth", "Plague Froth", "FROTH > AIM AT TUMORS", "Aim at tumors", { 1281907 }, 6, 3)
local killTumors = manualCall("tumors", "Malignant Tumors", "KILL TUMORS", "Kill tumors")

local function normalCalls()
    return {
        killAdds,
        fireNormal,
        dodgeSwirlies,
        adaptive,
        siphon,
        frothNormal,
        exploding,
        stygian,
    }
end

local function heroicCalls()
    return {
        killAdds,
        fireStagger,
        dodgeSwirlies,
        adaptive,
        siphon,
        frothNormal,
        catalyst,
        exploding,
        stygian,
    }
end

local function mythicCalls()
    return {
        killAdds,
        fireStagger,
        dodgeSwirlies,
        adaptive,
        siphon,
        frothMythic,
        catalyst,
        exploding,
        stygian,
        killTumors,
    }
end

Registry:Register({
    key = "vashnik",
    name = "Vashnik the Malignant",
    encounterID = 3455,
    strategyStatus = "12.1 Journal + current Wowhead/Raidstrats + DBM/BigWigs source-reviewed 2026-08-18; live validation pending",
    profiles = {
        normal = {
            explanation = {
                "PLAN: FLAME > SHADOW > SHADOW > BLOOD > BLOOD > FLAME. EACH IMBIBE USES THE TWO NEAREST FOUNTAINS. KILL ADDS BEFORE CENTER.",
                "FIRE: KILL ADDS. SHADOW: DODGE SWIRLIES. BLOOD: STACK HELPERS ON THE SIPHON TARGET TO CLEAR THE HEAL ABSORB.",
                "FROTH: MOVE OUT AND AIM WAVES AWAY. BIG CIRCLE: MOVE FAR OUT. SHADOW INFECTION: SPREAD AND KEEP MOVING.",
            },
            calls = normalCalls(),
        },
        heroic = {
            explanation = {
                "PLAN: FLAME > SHADOW > SHADOW > BLOOD > BLOOD > FLAME. EACH IMBIBE USES THE TWO NEAREST FOUNTAINS. KILL ADDS BEFORE CENTER.",
                "FIRE: KILL SKULL, WAIT, THEN X SO CAUSTIC SURGE STACKS DO NOT OVERLAP. SHADOW: DODGE SWIRLIES. BLOOD: STACK HELPERS FOR SIPHON.",
                "FROTH: MOVE OUT AND AIM WAVES AWAY. SOAK EVERY BILE. BIG CIRCLE: MOVE FAR OUT. SHADOW INFECTION: SPREAD AND KEEP MOVING.",
            },
            calls = heroicCalls(),
        },
        mythic = {
            explanation = {
                "PLAN: USE THE HEROIC ROUTE AND RULES. KILL ADDS BEFORE CENTER; FIRE STAYS STAGGERED; SOAK EVERY BILE.",
                "FROTH TARGETS AIM A WAVE THROUGH TUMORS TO REMOVE HARDENED TUMOR, THEN KILL THE EXPOSED TUMORS.",
                "BLOOD: STACK HELPERS ON SIPHON TARGETS. BIG CIRCLE: MOVE FAR OUT. SHADOW INFECTION: SPREAD AND KEEP MOVING.",
                "MYTHIC MALIGNANCE MAKES REPEATED INFECTION MISTAKES MORE DANGEROUS.",
            },
            calls = mythicCalls(),
        },
    },
})
