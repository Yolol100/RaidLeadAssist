local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function calls(coilText, includeMythic)
    local result = {
        { key="waves", ability="Caustic Waves", action="Dodge > keep waves off eggs", warning="CAUSTIC WAVES > DODGE > KEEP WAVES OFF EGGS", voice="Waves", timing=false, iconSpellID=1292188 },
        { key="coils", ability="Spectral Coils", action=coilText, warning=coilText, voice="Coils", timing=false, iconSpellID=1300530 },
        { key="serpents", ability="Call of the Serpent", action="Dodge impacts > kill adds", warning="CALL OF SERPENT > DODGE IMPACTS > KILL ADDS", voice="Adds", timing=false, iconSpellID=1300751 },
        { key="heart", ability="Rage of the Shackled", action="Dodge debris > burn heart", warning="RAGE > DODGE DEBRIS > BURN EXPOSED HEART", voice="Heart", timing=false, iconSpellID=1286860 },
    }
    if includeMythic then
        result[#result+1] = { key="eggs", ability="Hardened Eggs", action="Break shell > carriers spread 3+", warning="HARDENED EGGS > BREAK SHELL > CARRIERS SPREAD 3+ YARDS", voice="Eggs", timing=false, iconSpellID=1292188 }
        result[#result+1] = { key="incubation", ability="Toxic Incubation", action="Assigned intercepts rotate", warning="TOXIC INCUBATION > ASSIGNED INTERCEPTS ROTATE > DO NOT DOUBLE SOAK", voice="Intercept", timing=false, iconSpellID=1302982 }
    end
    return result
end

Registry:Register({
    key="ulatek", name="Ula'tek", encounterID=3492,
    strategyStatus="12.1 Journal-derived difficulty plans; final boss not public PTR-tested; timing disabled",
    profiles={
        normal={
            explanation={
                "PLAN: KEEP CAUSTIC WAVES AWAY FROM EGGS AND CONTROL WHICH EGGS HATCH.",
                "SPECTRAL COILS: USE THE ASSIGNED RAID SOAK POINT TO SPLIT THE DAMAGE.",
                "CALL OF THE SERPENT: DODGE FALLING SPAWNS, THEN HARD SWAP TO ADDS.",
                "RAGE: DODGE FALLING DEBRIS; WHEN THE HEART OPENS, USE DPS CDS ON IT.",
                "INTERMISSION: KILL WARDENS AND BREAK DANGEROUS CLUTCHES BEFORE THEY MATURE.",
                "FINAL: KEEP SAFE SPACE OPEN, DODGE DEMOLISH, AND KEEP ADD CONTROL CLEAN.",
            }, calls=calls("SPECTRAL COILS > RAID STACK AT SOAK POINT", false),
        },
        heroic={
            explanation={
                "PLAN: NORMAL POSITIONING, BUT HEROIC SPAWNS ARE MORE DANGEROUS IF EGGS HATCH.",
                "KEEP CAUSTIC WAVES OFF EGGS. KILL BIRTHLINGS AND VIPERS QUICKLY.",
                "SPECTRAL COILS: RAID STACKS AT THE ASSIGNED SOAK POINT.",
                "PETRIFYING STING: TARGET MOVES AWAY SO THE RAID IS NOT PETRIFIED.",
                "RAGE: DODGE DEBRIS, THEN USE DPS CDS ON THE EXPOSED HEART.",
                "FINAL: PROTECT SAFE SPACE, KILL ADDS FAST, AND DODGE DEMOLISH.",
            }, calls=calls("SPECTRAL COILS > RAID STACK AT SOAK POINT", false),
        },
        mythic={
            explanation={
                "PLAN: JOURNAL-DERIVED ONLY UNTIL LIVE. ASSIGN EGG CARRIERS AND INCUBATION SOAKERS.",
                "HARDENED EGGS: BREAK THE SHIELD FIRST; CARRIERS STAY 3+ YARDS APART.",
                "SPECTRAL COILS: ROTATE SOAK GROUPS BECAUSE SOUL CONSTRICTOR BLOCKS THE NEXT ONE.",
                "DOOMSCALE EGG: ONLY DISTURB IT WHEN THAT SIDE IS READY FOR MASS GESTATION.",
                "TOXIC WOMB: KILL THE BLIGHTSCALE; ROTATE TOXIC INCUBATION INTERCEPTS.",
                "NO PLAYER TAKES REPEAT INCUBATION HITS WHILE TOXIC BURN IS ACTIVE.",
                "RAGE: DODGE DEBRIS AND BURN HEART. FINAL: PRESERVE SAFE SPACE AT ALL COSTS.",
            }, calls=calls("SPECTRAL COILS > NEXT SOAK GROUP IN > ROTATE GROUPS", true),
        },
    },
})
