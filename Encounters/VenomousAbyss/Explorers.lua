local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function calls(crateAction, crateWarning)
    return {
        {
            key = "crates",
            ability = "Throw Junk",
            action = crateAction,
            warning = crateWarning,
            voice = "Crates",
            spellIDs = { 1291933 },
            prepareSeconds = 6,
            pressSeconds = 3,
        },
        {
            key = "fish",
            ability = "Final Ascension",
            action = "Feed next unused controlled boss",
            warning = "FISH > FEED NEXT UNUSED CONTROLLED BOSS",
            voice = "Fish",
            spellIDs = { 1292779 },
            prepareSeconds = 8,
            pressSeconds = 5,
        },
        {
            key = "thud",
            ability = "Mighty Thud",
            action = "Three targets > three soak points",
            warning = "MIGHTY THUD > 3 TARGETS > 3 SOAK POINTS",
            voice = "Three soak points",
            spellIDs = { 1296092 },
            prepareSeconds = 7,
            pressSeconds = 4,
        },
    }
end

Registry:Register({
    key = "explorers",
    name = "The Lost Explorers",
    encounterID = 3497,
    strategyStatus = "12.1 Journal + current Wowhead/Raidstrats + Ready Check Pull recap + DBM/BigWigs source-reviewed 2026-08-18; raidlead-only call scope; live validation pending",
    profiles = {
        normal = {
            explanation = {
                "PLAN: BLOODLUST ON PULL. STACK IKU + NAMA + GEBBO. KEEP ALL THREE HEALTH BARS EVEN AND FINISH TOGETHER.",
                "OPEN GEBBO CRATES UNTIL YOU FIND FISH. FISH ORDER: NAMA > IKU > GEBBO; FEED THE NEXT UNUSED CONTROLLED BOSS BEFORE FINAL ASCENSION.",
                "MIGHTY THUD: THREE TARGETS GO TO THREE SEPARATE SOAK POINTS, THEN LEAVE THE PATCHES. INTERRUPT ICEBOUND FLAMES.",
                "DODGE SHELLS. BLINK TARGET GOES EDGE; RAID MOVES AWAY. FROST/FIRE PAIR AND CLEAR WITH OPPOSITE. BOMB EDGE, THEN MUSHROOM OVER WAVE.",
            },
            calls = calls(
                "Assigned breaker opens crate",
                "CRATE > ASSIGNED BREAKER READY"
            ),
        },
        heroic = {
            explanation = {
                "PLAN: BLOODLUST ON PULL. STACK IKU + GEBBO; KEEP NAMA 30+ YARDS AWAY. KEEP ALL THREE HP EVEN AND FINISH TOGETHER.",
                "ROTATE CRATE BREAKERS FOR SPLINTERS. FISH ORDER: NAMA > IKU > GEBBO; FEED THE NEXT UNUSED CONTROLLED BOSS BEFORE FINAL ASCENSION.",
                "MIGHTY THUD: THREE TARGETS USE THREE SOAK POINTS. INTERRUPT ICEBOUND FLAMES. DODGE SHELLS; BLINK TARGET EDGE, RAID AWAY.",
                "FROST/FIRE PAIR AND CLEAR WITH OPPOSITE. BOMB EDGE, THEN MUSHROOM OVER WAVE. HANDLE SPREADING FLAMES.",
            },
            calls = calls(
                "Next breaker opens crate",
                "CRATE > NEXT BREAKER READY"
            ),
        },
        mythic = {
            explanation = {
                "PLAN: BLOODLUST ON PULL. STACK IKU + GEBBO; KEEP NAMA 30+ YARDS AWAY. KEEP ALL THREE HP EVEN AND FINISH TOGETHER.",
                "ROTATE CRATE BREAKERS FOR SPLINTERS. BEFORE A CRATE BREAK, RAID CLEARS 15+ YARDS. FISH ORDER: NAMA > IKU > GEBBO.",
                "FEED THE NEXT UNUSED CONTROLLED BOSS BEFORE FINAL ASCENSION. THUD: THREE TARGETS USE THREE SOAK POINTS. INTERRUPT ICEBOUND FLAMES.",
                "DODGE SHELLS; BLINK TARGET EDGE, RAID AWAY. FROST/FIRE CLEAR WITH OPPOSITE. BOMB EDGE, THEN MUSHROOM OVER WAVE.",
            },
            calls = calls(
                "Next breaker opens crate > raid clear 15 yards",
                "CRATE > NEXT BREAKER > RAID 15+ YARDS CLEAR"
            ),
        },
    },
})
