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
        { key="bomb", ability="Explosive Surprise", action="Bomb edge > mushroom over wave", warning="BOMB > EDGE > MUSHROOM OVER WAVE", voice="Bomb to edge", spellIDs={1296249}, prepareSeconds=6, pressSeconds=3 },
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
    strategyStatus="12.1 Journal + current Wowhead/Raidstrats + Ready Check Pull recap + DBM/BigWigs source-reviewed 2026-08-18; live validation pending",
    profiles={
        normal={
            explanation={
                "PLAN: BLOODLUST ON PULL. STACK IKU + NAMA + GEBBO. KEEP ALL THREE HEALTH BARS EVEN AND FINISH TOGETHER.",
                "OPEN GEBBO CRATES UNTIL YOU FIND FISH. RECOMMENDED FISH ORDER: NAMA > IKU > GEBBO; USE FISH BEFORE MOR'ZAHI REACHES FULL ENERGY.",
                "THUD TARGETS GO TO THREE SEPARATE SOAK POINTS, THEN MOVE OUT OF THE PATCHES. DODGE SHELLS. BLINK TARGET GOES EDGE; RAID MOVES AWAY.",
                "IKU EMPOWER: PAIR FROST/FIRE, DROP BESIDE EACH OTHER, THEN CLEAR WITH THE OPPOSITE PATCH. GEBBO BOMB: DROP EDGE, THEN USE A MUSHROOM TO BOUNCE OVER THE WAVE.",
            }, calls=calls(
                "Assigned breaker opens crate",
                "CRATES > ASSIGNED BREAKER OPEN",
                false
            ),
        },
        heroic={
            explanation={
                "PLAN: BLOODLUST ON PULL. CHOSEN SETUP: STACK IKU + GEBBO; KEEP NAMA 30+ YARDS AWAY SO UNITED DEFENSE NEVER ACTIVATES. KEEP HP EVEN; FINISH TOGETHER.",
                "ROTATE CRATE BREAKERS FOR SPLINTERS. RECOMMENDED FISH ORDER: NAMA > IKU > GEBBO; USE FISH BEFORE MOR'ZAHI REACHES FULL ENERGY.",
                "THUD TARGETS GO TO THREE SOAK POINTS, THEN CLEAR THE PATCHES. DODGE SHELLS. BLINK TARGET EDGE; RAID AWAY.",
                "IKU EMPOWER: PAIR FROST/FIRE, DROP TOGETHER, CLEAR WITH OPPOSITE. GEBBO BOMB: DROP EDGE, THEN MUSHROOM OVER THE WAVE; HANDLE SPREADING FLAMES.",
            }, calls=calls(
                "Next breaker opens crate",
                "CRATES > NEXT BREAKER OPEN",
                true
            ),
        },
        mythic={
            explanation={
                "PLAN: BLOODLUST ON PULL. USE THE HEROIC TWO-BOSS SETUP: IKU + GEBBO TOGETHER, NAMA 30+ YARDS AWAY. KEEP HP EVEN; FINISH TOGETHER.",
                "ROTATE CRATE BREAKERS FOR SPLINTERS. BEFORE A MYTHIC CRATE BREAK, RAID CLEARS 15+ YARDS. FISH ORDER: NAMA > IKU > GEBBO; USE BEFORE FULL ENERGY.",
                "THUD TARGETS USE THREE SOAK POINTS, THEN CLEAR PATCHES. DODGE SHELLS. BLINK TARGET EDGE; RAID AWAY.",
                "IKU EMPOWER: PAIR FROST/FIRE AND CLEAR WITH OPPOSITE. GEBBO BOMB: DROP EDGE, THEN MUSHROOM OVER THE WAVE; HANDLE SPREADING FLAMES.",
            }, calls=calls(
                "Next breaker opens crate > raid clear 15 yards",
                "CRATE > BREAKER IN > RAID 15+ YARDS OUT",
                true
            ),
        },
    },
})
