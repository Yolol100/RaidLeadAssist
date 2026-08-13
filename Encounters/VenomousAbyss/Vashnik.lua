local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function imbibeCall(text)
    return { key="imbibe", ability="Imbibe", action=text, warning=text, voice="Imbibe", spellIDs={1283164} }
end
local froth = { key="froth", ability="Plague Froth", action="Targets out > dodge 4 waves", warning="PLAGUE FROTH > TARGETS MOVE OUT > DODGE 4 WAVES", voice="Froth", spellIDs={1281907} }
local catalyst = { key="catalyst", ability="Malignant Catalyst", action="1 player in every Bile circle", warning="CATALYST > 1 PLAYER IN EVERY BILE CIRCLE", voice="Catalyst", spellIDs={1282525,1282509} }

Registry:Register({
    key="vashnik", name="Vashnik the Malignant", encounterID=3455,
    strategyStatus="12.1 difficulty plans source-reviewed 2026-08-13; live validation pending",
    profiles={
        normal={
            explanation={
                "PLAN: MOVE THE BOSS TO THE NEXT PLANNED FOUNTAIN PAIR BEFORE EACH IMBIBE.",
                "ROTATE PAIRS SO ONE FOUNTAIN DOES NOT KEEP GETTING EXTRA INFUSION STACKS.",
                "IMBIBE: HARD SWAP TO LIVING VENOMS AND KILL THEM BEFORE THE CENTER.",
                "FROTH TARGETS MOVE OUT. WHEN IT ENDS, EVERYONE DODGES THE 4 WAVES.",
                "TANKS SWAP AS DRIPPING FANGS BECOMES DANGEROUS.",
            },
            calls={ imbibeCall("IMBIBE > BOSS TO PLANNED PAIR > KILL VENOMS BEFORE CENTER"), froth },
        },
        heroic={
            explanation={
                "PLAN: ROTATE FOUNTAIN PAIRS; DO NOT KEEP EMPOWERING THE SAME FOUNTAIN.",
                "IMBIBE: HARD SWAP TO LIVING VENOMS AND KILL THEM BEFORE THE CENTER.",
                "CATALYST: PREASSIGN SOAKERS; EVERY BILE CIRCLE MUST HAVE 1+ PLAYER.",
                "FROTH TARGETS MOVE OUT. WHEN IT ENDS, DODGE ALL 4 WAVES.",
                "USE HEALING CDS FOR LATER IMBIBES AS TOXIC VAPOR BUILDS.",
            },
            calls={ imbibeCall("IMBIBE > BOSS TO PLANNED PAIR > KILL VENOMS BEFORE CENTER"), catalyst, froth },
        },
        mythic={
            explanation={
                "PLAN: HEROIC FOUNTAIN ROTATION PLUS MALIGNANT TOTEMS ON EVERY IMBIBE.",
                "IMBIBE: KILL MALIGNANT TOTEMS FIRST, THEN KILL VENOMS BEFORE CENTER.",
                "TOTEMS MUST DIE FAST; EACH MALIGNANCE WAVE MAKES LATER DAMAGE WORSE.",
                "CATALYST: EVERY BILE CIRCLE GETS A PREASSIGNED SOAKER.",
                "FROTH TARGETS OUT; DODGE THE 4 WAVES. KEEP FOUNTAIN STACKS BALANCED.",
                "USE HEALING CDS ON PLANNED IMBIBES AS TOXIC VAPOR RAMPS.",
            },
            calls={
                imbibeCall("IMBIBE > KILL MALIGNANT TOTEMS > THEN VENOMS BEFORE CENTER"),
                { key="totems", ability="Malignant Totems", action="Kill totems first", warning="MALIGNANT TOTEMS > HARD SWAP > KILL THEM FIRST", voice="Totems", timing=false, iconSpellID=1283164 },
                catalyst, froth,
            },
        },
    },
})
