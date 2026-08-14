local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function calls(crateAction, crateWarning)
    return {
        { key="killorder", ability="Kill Order", action="Nama > Iku > Gebbo", warning="KILL ORDER > NAMA FIRST > IKU SECOND > GEBBO LAST", voice="Kill order", timing=false },
        { key="crates", ability="Throw Junk", action=crateAction, warning=crateWarning, voice="Crates", timing=false },
        { key="fish", ability="Final Ascension", action="Feed fish to an unused controlled tortollan", warning="FINAL ASCENSION > FEED FISH TO AN UNUSED CONTROLLED TORTOLLAN NOW", voice="Fish", timing=false, iconSpellID=1292779 },
        { key="thud", ability="Mighty Thud", action="3 targets > each target to soak group", warning="MIGHTY THUD > 3 TARGETS > EACH TARGET TO A SOAK GROUP", voice="Soak", spellIDs={1296092} },
        { key="blink", ability="Blink Nova", action="Target edge > raid move away", warning="BLINK NOVA > TARGET EDGE > RAID MOVE AWAY", voice="Move away", spellIDs={1290711} },
        { key="icebound", ability="Icebound Flames", action="Interrupt now", warning="ICEBOUND FLAMES > INTERRUPT NOW", voice="Interrupt", spellIDs={1286921} },
    }
end

Registry:Register({
    key="explorers", name="The Lost Explorers", encounterID=3497,
    strategyStatus="12.1 difficulty plans source-reviewed 2026-08-14; live validation pending",
    profiles={
        normal={
            explanation={
                "PLAN: STACK ALL 3 BOSSES FOR CLEAVE AND KILL NAMA > IKU > GEBBO.",
                "ASSIGNED CRATE BREAKERS OPEN BOXES BEFORE RELIC RUPTURE AND SAVE THE FISH.",
                "EACH TORTOLLAN CAN ONLY TAKE ONE FISH; TRACK WHICH TARGET IS STILL UNUSED.",
                "FINAL ASCENSION: FEED AN UNUSED CONTROLLED TORTOLLAN BEFORE THE CAST ENDS.",
                "MIGHTY THUD: 3 TARGETS EACH GO TO THEIR SOAK GROUP, THEN MOVE OUT.",
                "BLINK NOVA TARGET GOES EDGE; EVERYONE ELSE MOVES FAR AWAY.",
                "ICEBOUND FLAMES: INTERRUPT. FIRE CLEARS FROST; FROST CLEARS FIRE.",
            }, calls=calls(
                "Assigned breaker > open crate > get fish",
                "CRATES > ASSIGNED BREAKER > OPEN BEFORE RUPTURE > GET FISH"
            ),
        },
        heroic={
            explanation={
                "PLAN: 3 STATIONS. KEEP ALL 3 BOSSES 35+ YARDS APART UNTIL NAMA DIES.",
                "KILL NAMA FIRST. AFTER NAMA DIES, STACK IKU + GEBBO AND KILL IKU NEXT.",
                "ROTATE ASSIGNED CRATE BREAKERS SO SPLINTERS DO NOT STACK TOO HIGH.",
                "OPEN CRATES BEFORE RELIC RUPTURE; EACH TORTOLLAN CAN ONLY TAKE ONE FISH.",
                "FINAL ASCENSION: FEED AN UNUSED CONTROLLED TORTOLLAN BEFORE THE CAST ENDS.",
                "MIGHTY THUD: 3 TARGETS EACH GO TO A SOAK GROUP, THEN MOVE OUT.",
                "BLINK TARGET EDGE; RAID FAR AWAY. INTERRUPT ICEBOUND FLAMES.",
                "TANKS SWAP BEFORE STEADY STRIKES OR SHREDDING SHARDS BECOME DANGEROUS.",
            }, calls=calls(
                "Next breaker only > control Splinters > get fish",
                "CRATES > NEXT ASSIGNED BREAKER ONLY > CONTROL SPLINTERS > GET FISH"
            ),
        },
        mythic={
            explanation={
                "PLAN: 3 FIXED STATIONS. KEEP ALL 3 BOSSES 35+ YARDS APART UNTIL NAMA DIES.",
                "KILL NAMA FIRST; THEN STACK IKU + GEBBO, KILL IKU, FINISH GEBBO.",
                "BREAK ONE CRATE AT A TIME; MYTHIC SPLINTERS HITS THE RAID AND STACKS.",
                "SPACE CRATE BREAKS, OPEN BEFORE RUPTURE, AND SAVE THE FISH.",
                "EACH TORTOLLAN GETS ONE FISH; FINAL ASCENSION ALWAYS USES AN UNUSED TARGET.",
                "MIGHTY THUD: 3 FIXED SOAK GROUPS. EACH MARK GOES TO ITS GROUP.",
                "BLINK TARGET EDGE; RAID FAR. INTERRUPT ICEBOUND FLAMES EVERY TIME.",
                "USE DEFENSIVES AFTER EACH DEATH AS THE REMAINING BOSS PRESSURE RISES.",
            }, calls=calls(
                "One break at a time > space raid bleed > get fish",
                "CRATES > ONE BREAK AT A TIME > SPACE RAID BLEEDS > GET FISH"
            ),
        },
    },
})
