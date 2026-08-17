local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function calls(coilText, fangsText, includeSting, biteText, includeMythic)
    local result = {
        { key="waves", ability="Caustic Waves", action="Dodge > keep waves off eggs", warning="CAUSTIC WAVES > DODGE > KEEP OFF EGGS", voice="Waves", timing=false, iconSpellID=1292188 },
        { key="coils", ability="Spectral Coils", action=coilText, warning=coilText, voice="Coils", timing=false, iconSpellID=1300530 },
        { key="serpents", ability="Call of the Serpent", action="Dodge impacts > kill adds", warning="CALL OF SERPENT > DODGE > KILL ADDS", voice="Adds", timing=false, iconSpellID=1300751 },
        { key="heart", ability="Rage of the Shackled", action="Dodge > burn heart", warning="RAGE > DODGE > BURN HEART", voice="Heart", timing=false, iconSpellID=1286860 },
        { key="bite", ability="Serpent's Bite", action=biteText, warning=biteText, voice="Bite", timing=false, iconSpellID=1295905 },
    }
    if fangsText then
        result[#result+1] = { key="fangs", ability="Grasping Fangs", action=fangsText, warning=fangsText, voice="Fangs", timing=false, iconSpellID=1311611 }
    end
    if includeSting then
        result[#result+1] = { key="sting", ability="Petrifying Sting", action="Target out > raid clear 10+", warning="PETRIFYING STING > TARGET OUT > RAID 10+ YARDS", voice="Sting", timing=false, iconSpellID=1303414 }
    end
    if includeMythic then
        result[#result+1] = { key="eggs", ability="Hardened Eggs", action="Break shell > carriers spread 3+", warning="HARDENED EGGS > BREAK SHELL > CARRIERS 3+ YARDS", voice="Eggs", timing=false, iconSpellID=1299650 }
        result[#result+1] = { key="incubation", ability="Toxic Incubation", action="Next assigned interceptor in", warning="TOXIC INCUBATION > NEXT INTERCEPTOR IN", voice="Intercept", timing=false, iconSpellID=1299759 }
    end
    return result
end

Registry:Register({
    key="ulatek", name="Ula'tek", encounterID=3492,
    strategyStatus="12.1 Journal + current bossmod source review 2026-08-17; final boss was not PTR-tested; live validation required; timing disabled",
    profiles={
        normal={
            explanation={
                "PLAN: KEEP CAUSTIC WAVES OFF EGGS AND CONTROL WHICH EGGS HATCH. STACK AT THE ASSIGNED SPECTRAL COIL SOAK POINT.",
                "DODGE CALL OF THE SERPENT IMPACTS AND KILL ADDS. DURING RAGE, DODGE DEBRIS AND BURN THE EXPOSED HEART.",
                "SERPENT'S BITE: LEECH VENOM BEFORE CALCIFICATION; PURGERS SPREAD 7+ YARDS. PRESERVE SAFE SPACE FOR THE FINAL PHASE.",
            }, calls=calls(
                "COILS > STACK AT SOAK POINT",
                nil,
                false,
                "SERPENT'S BITE > LEECH > PURGERS 7+ YARDS",
                false
            ),
        },
        heroic={
            explanation={
                "PLAN: NORMAL POSITIONING PLUS HEROIC ADD MECHANICS. KEEP WAVES OFF EGGS; KILL BIRTHLINGS/VIPERS QUICKLY; STACK AT THE COIL SOAK POINT.",
                "BREAK GRASPING FANGS AND HEAL TARGETS THROUGH BLIGHT VEIN. PETRIFYING STING TARGET OUT; RAID CLEARS 10+ YARDS.",
                "SERPENT'S BITE: LEECH BEFORE CALCIFICATION, PURGERS 7+ YARDS. RAGE: DODGE AND BURN HEART. PRESERVE SAFE SPACE.",
            }, calls=calls(
                "COILS > STACK AT SOAK POINT",
                "GRASPING FANGS > BREAK FANGS > HEAL TARGETS",
                true,
                "SERPENT'S BITE > LEECH > PURGERS 7+ YARDS",
                false
            ),
        },
        mythic={
            explanation={
                "PLAN: JOURNAL-BASED UNTIL LIVE. ASSIGN EGG CARRIERS, ALTERNATING COIL GROUPS, FANG ORDER, AND TOXIC INCUBATION INTERCEPTORS BEFORE PULL.",
                "HARDENED EGG CARRIERS STAY 3+ YARDS APART. ROTATE COIL GROUPS BECAUSE SOUL CONSTRICTOR BLOCKS REPEAT SOAKS. BREAK FANGS ONE AT A TIME.",
                "TOXIC WOMB: KILL BLIGHTSCALE AND ROTATE INCUBATION INTERCEPTS. BITE: LEECH, PURGERS 7+ YARDS, THEN DODGE THEIR WAVES. PRESERVE SAFE SPACE.",
            }, calls=calls(
                "COILS > NEXT SOAK GROUP IN",
                "GRASPING FANGS > BREAK ONE AT A TIME",
                true,
                "SERPENT'S BITE > LEECH > PURGERS 7+ > DODGE WAVES",
                true
            ),
        },
    },
})
