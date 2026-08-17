local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function baseCalls()
    return {
        { key="venom", ability="Venomous Surge", action="Targets out > drop cysts edge", warning="VENOMOUS SURGE > TARGETS OUT > CYSTS EDGE", voice="Venom", spellIDs={1305959} },
        { key="crosswinds", ability="Raging Crosswinds", action="Pair with opposite gust", warning="CROSSWINDS > PAIR WITH OPPOSITE GUST", voice="Crosswinds", timing=false },
        { key="maelstrom", ability="Howling Maelstrom", action="Pop safe cyst > stay on platform", warning="MAELSTROM > POP SAFE CYST > STAY ON PLATFORM", voice="Maelstrom", spellIDs={1285732}, prepareSeconds=8, pressSeconds=5 },
        { key="apex", ability="Apex Predator", action="Next 5+ soak team in", warning="MUTILATE > NEXT 5+ SOAK TEAM IN", voice="Soak", spellIDs={1277025,1285430}, prepareSeconds=7, pressSeconds=4 },
    }
end

Registry:Register({
    key="sszorak", name="Sszorak", encounterID=3420,
    strategyStatus="12.1 Journal + current community strategy source-reviewed 2026-08-17; live validation pending",
    profiles={
        normal={
            explanation={
                "PLAN: DROP CYSTS AROUND THE OUTSIDE AND KEEP THE CENTER OPEN. PAIR OPPOSITE CROSSWIND DIRECTIONS SO KNOCKBACKS KEEP PLAYERS ON THE PLATFORM.",
                "SAVE A SAFE CYST FOR EACH MAELSTROM AND POP IT JUST BEFORE THE WIND. USE THE DAMAGE WINDOW ON THE BOSS.",
                "APEX/MUTILATE: ROTATE DISTINCT 5+ PLAYER SOAK TEAMS WITH THE TANK.",
            }, calls=baseCalls(),
        },
        heroic={
            explanation={
                "PLAN: CLEAN CYST RING OUTSIDE, CENTER OPEN. CROSSWINDS PLAYERS PAIR WITH THE OPPOSITE GUST DIRECTION TO CONTROL KNOCKBACKS.",
                "SAVE ONE SAFE CYST FOR EACH MAELSTROM. APEX/MUTILATE USES DISTINCT 5+ TEAMS BECAUSE REPEAT DAMAGE IS HEAVILY INCREASED.",
                "DO NOT WASTE CYSTS EARLY; THEY ARE THE MAELSTROM SAFETY TOOL.",
            }, calls=baseCalls(),
        },
        mythic={
            explanation={
                "PLAN: HEROIC CYST/CROSSWIND RULES PLUS A FIXED SERPENT'S FURY STACK POINT.",
                "SERPENT'S FURY NEEDS 14+ PLAYERS ON THE MARK; AFTER THE CHARGE, SPREAD VIRULENCE CLEANLY AND AVOID RESIDUE.",
                "SAVE A SAFE CYST FOR EACH MAELSTROM. ROTATE DISTINCT 5+ PLAYER MUTILATE TEAMS EVERY TIME.",
            },
            calls={
                baseCalls()[1], baseCalls()[2], baseCalls()[3], baseCalls()[4],
                { key="serpent", ability="Serpent's Fury", action="14+ stack on mark", warning="SERPENT'S FURY > 14+ STACK ON MARK", voice="Stack", timing=false, iconSpellID=1305621 },
            },
        },
    },
})
