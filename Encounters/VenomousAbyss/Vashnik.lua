local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local BOSSMOD_RULE = "CALL PRIORITY: FOLLOW DBM OR BIGWIGS FOR YOUR PERSONAL DEBUFFS, DODGES, ROLE WARNINGS AND TIMERS. FOLLOW RLA/RAID-LEADER CALLS FOR GROUPS, MARKERS, SOAKS, TARGET PRIORITY AND SHARED RAID MOVEMENT."

local function timedCall(key, ability, warning, voice, spellIDs, prepareSeconds, pressSeconds)
    return { key=key, ability=ability, action=warning, warning=warning, voice=voice, spellIDs=spellIDs, prepareSeconds=prepareSeconds, pressSeconds=pressSeconds }
end

local function manualCall(key, ability, warning, voice)
    return { key=key, ability=ability, action=warning, warning=warning, voice=voice, timing=false }
end

local killAdds = timedCall("imbibe", "Imbibe", "IMBIBE > KILL ADDS", "Kill adds", { 1283164 }, 8, 5)
local fireStagger = manualCall("fire_stagger", "Burning Venoms", "SKULL FIRST > WAIT > X", "Stagger fire adds")
local siphon = manualCall("siphon", "Siphoning Infection", "SIPHON > STACK HELPERS ON TARGET", "Stack for siphon")
local catalyst = timedCall("catalyst", "Malignant Catalyst", "BILE > SOAK EVERY GREEN CIRCLE", "Soak every circle", { 1282525, 1282509 }, 7, 4)
local frothMythic = timedCall("froth", "Plague Froth", "FROTH > AIM WAVES THROUGH TUMORS", "Aim at tumors", { 1281907 }, 6, 3)
local killTumors = manualCall("tumors", "Malignant Tumors", "KILL EXPOSED TUMORS", "Kill tumors")

local function normalCalls() return { killAdds, siphon } end
local function heroicCalls() return { killAdds, fireStagger, siphon, catalyst } end
local function mythicCalls() return { killAdds, fireStagger, siphon, catalyst, frothMythic, killTumors } end

Registry:Register({
    key = "vashnik",
    name = "Vashnik the Malignant",
    encounterID = 3455,
    strategyStatus = "12.1 Journal + current Wowhead + DBM/BigWigs source-reviewed 2026-08-18; current guide lists no fixed key assignments; raidlead-only shared calls; live validation pending",
    profiles = {
        normal = {
            explanation = {
                "BLOODLUST ON PULL. PLAN: FLAME > SHADOW > SHADOW > BLOOD > BLOOD > FLAME. EACH IMBIBE USES THE TWO NEAREST FOUNTAINS.",
                "KILL LIVING VENOMS BEFORE CENTER. FIRE: KILL ADDS. SHADOW: DODGE SWIRLIES. BLOOD: STACK HELPERS ON SIPHON TARGETS.",
                "FROTH TARGETS MOVE OUT AND AIM WAVES AWAY. EXPLODING INFECTION GOES FAR OUT; STYGIAN INFECTION SPREADS AND KEEPS MOVING.",
                BOSSMOD_RULE,
            },
            calls = normalCalls(),
        },
        heroic = {
            explanation = {
                "BLOODLUST ON PULL. PLAN: FLAME > SHADOW > SHADOW > BLOOD > BLOOD > FLAME. EACH IMBIBE USES THE TWO NEAREST FOUNTAINS.",
                "KILL LIVING VENOMS BEFORE CENTER. FIRE: KILL SKULL, WAIT, THEN X SO CAUSTIC SURGE STACKS DO NOT OVERLAP.",
                "MALIGNANT CATALYST: SOAK EVERY GREEN CIRCLE; EACH IMPACT MUST HIT AT LEAST ONE PLAYER. BLOOD: STACK HELPERS FOR SIPHON.",
                "FROTH TARGETS MOVE OUT AND AIM WAVES AWAY. EXPLODING INFECTION GOES FAR OUT; STYGIAN INFECTION SPREADS AND KEEPS MOVING.",
                BOSSMOD_RULE,
            },
            calls = heroicCalls(),
        },
        mythic = {
            explanation = {
                "BLOODLUST ON PULL. USE THE HEROIC ROUTE AND FIRE STAGGER. KILL LIVING VENOMS BEFORE CENTER.",
                "MALIGNANT CATALYST: SOAK EVERY GREEN CIRCLE; EACH IMPACT MUST HIT AT LEAST ONE PLAYER. NO FIXED BILE TEAM IS REQUIRED.",
                "FROTH TARGETS AIM PLAGUE WAVES THROUGH TUMORS TO REMOVE HARDENED TUMOR, THEN KILL THE EXPOSED TUMORS.",
                "BLOOD: STACK HELPERS ON SIPHON TARGETS. PERSONAL INFECTION DISPELS, SPREADS AND SHADOW MOVEMENT STAY BOSSMOD-OWNED.",
                BOSSMOD_RULE,
            },
            calls = mythicCalls(),
        },
    },
})
