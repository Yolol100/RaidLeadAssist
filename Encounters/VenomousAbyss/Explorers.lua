local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function calls(crateAction, crateWarning, includeUnitedDefense)
    local result = {
        { key="crates", ability="Throw Junk", action=crateAction, warning=crateWarning, voice="Crates", spellIDs={1291933}, prepareSeconds=6, pressSeconds=3 },
        { key="fish", ability="Final Ascension", action="Feed fish to unused controlled boss", warning="FISH > FEED UNUSED CONTROLLED BOSS", voice="Fish", spellIDs={1292779}, prepareSeconds=8, pressSeconds=5 },
        { key="thud", ability="Mighty Thud", action="Targets to soak points", warning="MIGHTY THUD > TARGETS TO SOAK POINTS", voice="Soak", spellIDs={1296092}, prepareSeconds=7, pressSeconds=4 },
        { key="shell", ability="Shell Spin", action="Dodge shells", warning="SHELL SPIN > DODGE SHELLS", voice="Dodge shells", spellIDs={1291759}, prepareSeconds=6, pressSeconds=3 },
        { key="blink", ability="Blink Nova", action="Target edge > raid away", warning="BLINK NOVA > TARGET EDGE > RAID AWAY", voice="Move away", spellIDs={1290711}, prepareSeconds=6, pressSeconds=3 },
        { key="volley", ability="Frostfire Volley", action="Clear with opposite element", warning="FROST/FIRE > CLEAR WITH OPPOSITE", voice="Use opposite", spellIDs={1295886,1295935}, prepareSeconds=6, pressSeconds=3 },
        { key="bomb", ability="Explosive Surprise", action="Move out from bomb", warning="BOMB > MOVE OUT", voice="Move out", spellIDs={1296249}, prepareSeconds=6, pressSeconds=3 },
    }
    if includeUnitedDefense then
        result[#result + 1] = {
            key="position",
            ability="Aura of Unity",
            action="Stack Iku + Gebbo > Nama away",
            warning="STACK IKU + GEBBO > NAMA 30+ YARDS AWAY",
            voice="Keep Nama away",
            timing=false,
        }
    end
    return result
end

Registry:Register({
    key="explorers", name="The Lost Explorers", encounterID=3497,
    strategyStatus="12.1 Journal + current Wowhead/Raidstrats + DBM/BigWigs source-reviewed 2026-08-18; live validation pending",
    profiles={
        normal={
            explanation={
                "PLAN: STACK IKU + NAMA + GEBBO. KEEP ALL THREE HEALTH BARS EVEN AND FINISH TOGETHER.",
                "OPEN CRATES BEFORE RELIC RUPTURE. SAVE FISH; DURING FINAL ASCENSION FEED AN UNUSED CONTROLLED BOSS.",
                "THUD TARGETS GO TO THREE SEPARATE SOAK POINTS. DODGE SHELLS. BLINK TARGET GOES EDGE; RAID MOVES AWAY.",
                "IKU EMPOWER: CLEAR FROST/FIRE WITH THE OPPOSITE ELEMENT. GEBBO EMPOWER: MOVE OUT FROM BOMBS AND THEIR WAVES.",
            }, calls=calls(
                "Assigned breaker opens crate",
                "CRATES > ASSIGNED BREAKER OPEN",
                false
            ),
        },
        heroic={
            explanation={
                "PLAN: STACK IKU + GEBBO. KEEP NAMA 30+ YARDS AWAY SO UNITED DEFENSE NEVER ACTIVATES. KEEP ALL THREE HP EVEN; FINISH TOGETHER.",
                "ROTATE CRATE BREAKERS FOR SPLINTERS; OPEN BEFORE RELIC RUPTURE. SAVE FISH; FEED AN UNUSED CONTROLLED BOSS DURING FINAL ASCENSION.",
                "THUD TARGETS TO THREE SOAK POINTS. DODGE SHELLS. BLINK TARGET EDGE; RAID AWAY.",
                "IKU EMPOWER: CLEAR FROST/FIRE WITH OPPOSITE. GEBBO EMPOWER: MOVE OUT FROM BOMBS/WAVES AND SPREADING FLAMES.",
            }, calls=calls(
                "Next breaker opens crate",
                "CRATES > NEXT BREAKER OPEN",
                true
            ),
        },
        mythic={
            explanation={
                "PLAN: STACK IKU + GEBBO. KEEP NAMA 30+ YARDS AWAY. KEEP ALL THREE HP EVEN AND FINISH TOGETHER.",
                "ROTATE CRATE BREAKERS FOR SPLINTERS. WHEN BREAKING A CRATE, RAID CLEARS 15+ YARDS; OPEN BEFORE RELIC RUPTURE. SAVE FISH.",
                "FINAL ASCENSION: FEED AN UNUSED CONTROLLED BOSS. THUD TARGETS USE THREE SOAK POINTS. DODGE SHELLS.",
                "IKU EMPOWER: CLEAR FROST/FIRE WITH OPPOSITE. GEBBO EMPOWER: MOVE OUT FROM BOMBS/WAVES AND SPREADING FLAMES.",
            }, calls=calls(
                "Next breaker opens crate > raid clear 15 yards",
                "CRATE > BREAKER IN > RAID 15+ YARDS OUT",
                true
            ),
        },
    },
})
