local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function calls(crateAction, crateWarning)
    return {
        { key="balance", ability="Boss Health", action="Keep all 3 even", warning="BOSS HEALTH > KEEP ALL 3 EVEN", voice="Balance", timing=false },
        { key="crates", ability="Throw Junk", action=crateAction, warning=crateWarning, voice="Crates", timing=false },
        { key="fish", ability="Final Ascension", action="Feed fish to unused tortollan", warning="FINAL ASCENSION > FEED UNUSED TORTOLLAN", voice="Fish", timing=false, iconSpellID=1292779 },
        { key="thud", ability="Mighty Thud", action="Targets to soak points", warning="MIGHTY THUD > TARGETS TO SOAK POINTS", voice="Soak", spellIDs={1296092}, prepareSeconds=7, pressSeconds=4 },
        { key="blink", ability="Blink Nova", action="Target edge > raid away", warning="BLINK NOVA > TARGET EDGE > RAID AWAY", voice="Move away", spellIDs={1290711} },
        { key="icebound", ability="Icebound Flames", action="Interrupt", warning="ICEBOUND FLAMES > INTERRUPT", voice="Interrupt", spellIDs={1286921}, prepareSeconds=4, pressSeconds=1 },
    }
end

Registry:Register({
    key="explorers", name="The Lost Explorers", encounterID=3497,
    strategyStatus="12.1 Journal + current community strategy source-reviewed 2026-08-17; live validation pending",
    profiles={
        normal={
            explanation={
                "PLAN: KEEP BOSSES TOGETHER WHEN SAFE, BALANCE ALL THREE HEALTH BARS, AND FINISH TOGETHER.",
                "ASSIGNED BREAKER OPENS CRATES BEFORE RELIC RUPTURE; SAVE FISH AND FEED AN UNUSED CONTROLLED TORTOLLAN DURING FINAL ASCENSION.",
                "THUD TARGETS GO TO SEPARATE SOAK POINTS. BLINK TARGET GOES EDGE; RAID MOVES AWAY. INTERRUPT ICEBOUND FLAMES.",
            }, calls=calls(
                "Assigned breaker opens crate",
                "CRATES > ASSIGNED BREAKER OPEN"
            ),
        },
        heroic={
            explanation={
                "PLAN: KEEP UNITED DEFENSE BROKEN: TWO BOSSES MAY STACK, NEVER ALL THREE. BALANCE HEALTH AND FINISH TOGETHER.",
                "ROTATE CRATE BREAKERS TO CONTROL SPLINTERS; OPEN BEFORE RUPTURE. SAVE FISH FOR UNUSED TORTOLLANS DURING FINAL ASCENSION.",
                "THUD TARGETS TO SOAK POINTS; BLINK TARGET EDGE; INTERRUPT ICEBOUND. TANKS SWAP BEFORE REPEATED TANK HITS BECOME DANGEROUS.",
            }, calls=calls(
                "Next breaker opens crate",
                "CRATES > NEXT BREAKER OPEN"
            ),
        },
        mythic={
            explanation={
                "PLAN: HEROIC POSITIONING; BALANCE ALL THREE AND FINISH TOGETHER. BREAK ONE CRATE AT A TIME BECAUSE SPLINTERS DAMAGE AND STACK ON THE RAID.",
                "SPACE CRATE BREAKS, OPEN BEFORE RUPTURE, SAVE FISH, AND ALWAYS FEED AN UNUSED TORTOLLAN DURING FINAL ASCENSION.",
                "USE THREE FIXED THUD SOAK POINTS. BLINK TARGET EDGE; INTERRUPT ICEBOUND EVERY TIME; TANKS MANAGE STACKING TANK HITS.",
            }, calls=calls(
                "Break one crate at a time",
                "CRATES > ONE AT A TIME"
            ),
        },
    },
})
