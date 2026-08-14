local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function imbibeCall(text)
    return { key="imbibe", ability="Imbibe", action=text, warning=text, voice="Imbibe", spellIDs={1283164}, prepareSeconds=8, pressSeconds=5 }
end
local function frothCall(text)
    return { key="froth", ability="Plague Froth", action=text, warning=text, voice="Froth", spellIDs={1281907}, prepareSeconds=6, pressSeconds=3 }
end
local catalyst = { key="catalyst", ability="Malignant Catalyst", action="1 player in every Bile circle", warning="CATALYST > 1 PLAYER IN EVERY BILE CIRCLE", voice="Catalyst", spellIDs={1282525,1282509}, prepareSeconds=7, pressSeconds=4 }

Registry:Register({
    key="vashnik", name="Vashnik the Malignant", encounterID=3455,
    strategyStatus="12.1 difficulty plans source-reviewed 2026-08-14; live validation pending",
    profiles={
        normal={
            explanation={
                "PLAN: MOVE THE BOSS TO THE NEXT PLANNED FOUNTAIN PAIR BEFORE EACH IMBIBE.",
                "ROTATE PAIRS SO ONE FOUNTAIN DOES NOT KEEP GETTING EXTRA INFUSION STACKS.",
                "IMBIBE: HARD SWAP TO LIVING VENOMS AND KILL THEM BEFORE THE CENTER.",
                "FROTH TARGETS MOVE OUT. WHEN IT ENDS, EVERYONE DODGES THE 4 WAVES.",
                "TANKS SWAP AS DRIPPING FANGS BECOMES DANGEROUS.",
            },
            calls={
                imbibeCall("IMBIBE > BOSS TO PLANNED PAIR > KILL VENOMS BEFORE CENTER"),
                frothCall("PLAGUE FROTH > TARGETS MOVE OUT > DODGE 4 WAVES"),
            },
        },
        heroic={
            explanation={
                "PLAN: ROTATE FOUNTAIN PAIRS; DO NOT KEEP EMPOWERING THE SAME FOUNTAIN.",
                "IMBIBE: HARD SWAP TO LIVING VENOMS AND KILL THEM BEFORE THE CENTER.",
                "CATALYST: PREASSIGN SOAKERS; EVERY BILE CIRCLE MUST HAVE 1+ PLAYER.",
                "FROTH TARGETS MOVE OUT. WHEN IT ENDS, DODGE ALL 4 WAVES.",
                "USE HEALING CDS FOR LATER IMBIBES AS TOXIC VAPOR BUILDS.",
            },
            calls={
                imbibeCall("IMBIBE > BOSS TO PLANNED PAIR > KILL VENOMS BEFORE CENTER"),
                catalyst,
                frothCall("PLAGUE FROTH > TARGETS MOVE OUT > DODGE 4 WAVES"),
            },
        },
        mythic={
            explanation={
                "PLAN: HEROIC FOUNTAIN ROTATION PLUS MALIGNANT TUMORS ON EACH IMBIBE.",
                "IMBIBE: CONTROL LIVING VENOMS AND MARK TUMORS FOR THE NEXT PLAGUE FROTH.",
                "FROTH TARGETS: AIM A PLAGUE WAVE THROUGH TUMORS TO CLEAR THEIR HARDENED DEFENSE.",
                "AFTER THE WAVE: HARD SWAP ANY TUMOR STILL ALIVE, THEN FINISH LIVING VENOMS.",
                "CATALYST: EVERY BILE CIRCLE GETS A PREASSIGNED SOAKER.",
                "KEEP FOUNTAIN STACKS BALANCED AND USE HEALING CDS AS TOXIC VAPOR RAMPS.",
            },
            calls={
                imbibeCall("IMBIBE > CONTROL VENOMS > MARK TUMORS FOR PLAGUE FROTH"),
                { key="totems", ability="Malignant Tumors", action="Line Plague Waves through Tumors", warning="MALIGNANT TUMORS > FROTH TARGETS LINE PLAGUE WAVES THROUGH THEM", voice="Tumors", timing=false, iconSpellID=1283164 },
                catalyst,
                frothCall("PLAGUE FROTH > AIM WAVES THROUGH TUMORS > THEN DODGE"),
            },
        },
    },
})
