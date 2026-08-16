local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function calls(coilText, fangsText, includeSting, biteText, includeMythic)
    local result = {
        { key="waves", ability="Caustic Waves", action="Dodge > keep waves off eggs", warning="CAUSTIC WAVES > DODGE > KEEP WAVES OFF EGGS", voice="Waves", timing=false, iconSpellID=1292188 },
        { key="coils", ability="Spectral Coils", action=coilText, warning=coilText, voice="Coils", timing=false, iconSpellID=1300530 },
        { key="serpents", ability="Call of the Serpent", action="Dodge impacts > kill adds", warning="CALL OF SERPENT > DODGE IMPACTS > KILL ADDS", voice="Adds", timing=false, iconSpellID=1300751 },
        { key="heart", ability="Rage of the Shackled", action="Dodge debris > burn heart", warning="RAGE > DODGE DEBRIS > BURN EXPOSED HEART", voice="Heart", timing=false, iconSpellID=1286860 },
        { key="bite", ability="Serpent's Bite", action=biteText, warning=biteText, voice="Bite", timing=false, iconSpellID=1295905 },
    }
    if fangsText then
        result[#result+1] = { key="fangs", ability="Grasping Fangs", action=fangsText, warning=fangsText, voice="Fangs", timing=false, iconSpellID=1311611 }
    end
    if includeSting then
        result[#result+1] = { key="sting", ability="Petrifying Sting", action="Target out > everyone clear 10+ yards", warning="PETRIFYING STING > TARGET OUT > EVERYONE CLEAR 10+ YARDS", voice="Sting", timing=false, iconSpellID=1303414 }
    end
    if includeMythic then
        result[#result+1] = { key="eggs", ability="Hardened Eggs", action="Break shell > carriers spread 3+", warning="HARDENED EGGS > BREAK SHELL > CARRIERS SPREAD 3+ YARDS", voice="Eggs", timing=false, iconSpellID=1299650 }
        result[#result+1] = { key="incubation", ability="Toxic Incubation", action="Assigned intercepts rotate", warning="TOXIC INCUBATION > ASSIGNED INTERCEPTS ROTATE > DO NOT DOUBLE SOAK", voice="Intercept", timing=false, iconSpellID=1299759 }
    end
    return result
end

Registry:Register({
    key="ulatek", name="Ula'tek", encounterID=3492,
    strategyStatus="12.1 pre-release Journal + current DBM/BigWigs source review (2026-08-16); live validation pending; timing disabled",
    profiles={
        normal={
            explanation={
                "PLAN: KEEP CAUSTIC WAVES AWAY FROM EGGS AND CONTROL WHICH EGGS HATCH.",
                "SPECTRAL COILS: USE THE ASSIGNED RAID SOAK POINT TO SPLIT THE DAMAGE.",
                "CALL OF THE SERPENT: DODGE FALLING SPAWNS, THEN HARD SWAP TO ADDS.",
                "RAGE: DODGE FALLING DEBRIS; WHEN THE HEART OPENS, USE DPS CDS ON IT.",
                "INTERMISSION: KILL WARDENS AND BREAK DANGEROUS CLUTCHES BEFORE THEY MATURE.",
                "SERPENT'S BITE: LEECH THE VENOM BEFORE CALCIFICATION; PURGERS SPREAD 7+ YARDS.",
                "FINAL: KEEP SAFE SPACE OPEN, DODGE DEMOLISH, AND KEEP ADD CONTROL CLEAN.",
            }, calls=calls(
                "SPECTRAL COILS > RAID STACK AT SOAK POINT",
                nil,
                false,
                "SERPENT'S BITE > LEECH VENOM > PURGERS SPREAD 7+ YARDS",
                false
            ),
        },
        heroic={
            explanation={
                "PLAN: NORMAL POSITIONING, BUT HEROIC ADDS GAIN EXTRA PLAYER-TARGETED MECHANICS.",
                "KEEP CAUSTIC WAVES OFF EGGS. KILL BIRTHLINGS AND VIPERS QUICKLY.",
                "SPECTRAL COILS: RAID STACKS AT THE SOAK POINT; NO MYTHIC ROTATION ON HEROIC.",
                "GRASPING FANGS: BREAK THE FANGS, THEN HEAL THE TARGETS THROUGH BLIGHT VEIN.",
                "PETRIFYING STING: TARGET MOVES OUT; EVERYONE ELSE CLEARS 10+ YARDS.",
                "SERPENT'S BITE: LEECH THE VENOM BEFORE CALCIFICATION; PURGERS SPREAD 7+ YARDS.",
                "RAGE: DODGE DEBRIS, BURN THE HEART. FINAL: PRESERVE SAFE SPACE AND KILL ADDS.",
            }, calls=calls(
                "SPECTRAL COILS > RAID STACK AT SOAK POINT",
                "GRASPING FANGS > BREAK FANGS > HEAL BLIGHT VEIN",
                true,
                "SERPENT'S BITE > LEECH VENOM > PURGERS SPREAD 7+ YARDS",
                false
            ),
        },
        mythic={
            explanation={
                "PLAN: PRE-RELEASE ONLY. ASSIGN EGG CARRIERS, COIL GROUPS, AND INCUBATION SOAKERS.",
                "HARDENED EGGS: BREAK THE SHIELD FIRST; CARRIERS STAY 3+ YARDS APART.",
                "SPECTRAL COILS: ROTATE SOAK GROUPS; SOUL CONSTRICTOR BLOCKS THE NEXT SOAK.",
                "GRASPING FANGS: BREAK ONE AT A TIME; RAID-WIDE BLIGHT VEIN STACKS ON EACH SNAP.",
                "DOOMSCALE EGG: ONLY DISTURB IT WHEN THAT SIDE IS READY FOR MASS GESTATION.",
                "TOXIC WOMB: KILL THE BLIGHTSCALE; ROTATE INCUBATION SOAKERS TO AVOID TOXIC BURN.",
                "SERPENT'S BITE: LEECH, SPREAD PURGERS 7+, THEN DODGE THEIR CAUSTIC WAVES.",
                "RAGE: DODGE DEBRIS AND BURN HEART. FINAL: PRESERVE SAFE SPACE AT ALL COSTS.",
            }, calls=calls(
                "SPECTRAL COILS > NEXT SOAK GROUP IN > ROTATE GROUPS",
                "GRASPING FANGS > BREAK ONE AT A TIME > DO NOT STACK BLIGHT VEIN",
                true,
                "SERPENT'S BITE > LEECH > PURGERS SPREAD 7+ > EXPECT WAVES",
                true
            ),
        },
    },
})
