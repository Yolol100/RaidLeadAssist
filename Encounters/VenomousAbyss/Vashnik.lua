local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function imbibeCall(text)
    return { key="imbibe", ability="Imbibe", action=text, warning=text, voice="Imbibe", spellIDs={1283164}, prepareSeconds=8, pressSeconds=5 }
end
local function frothCall(text)
    return { key="froth", ability="Plague Froth", action=text, warning=text, voice="Froth", spellIDs={1281907}, prepareSeconds=6, pressSeconds=3 }
end
local catalyst = { key="catalyst", ability="Malignant Catalyst", action="One player per Bile circle", warning="CATALYST > ONE PLAYER PER BILE CIRCLE", voice="Catalyst", spellIDs={1282525,1282509}, prepareSeconds=7, pressSeconds=4 }
local siphon = { key="siphon", ability="Siphoning Infection", action="Targets spread > heal absorb", warning="SIPHONING > TARGETS SPREAD > HEAL ABSORB", voice="Siphoning", timing=false }
local exploding = { key="exploding", ability="Exploding Infection", action="Targets far out", warning="EXPLODING > TARGETS FAR OUT", voice="Exploding", timing=false }
local stygian = { key="stygian", ability="Stygian Infection", action="Targets spread > keep moving", warning="STYGIAN > TARGETS SPREAD > KEEP MOVING", voice="Stygian", timing=false }
local tankswap = { key="tankswap", ability="Dripping Fangs", action="Tanks swap", warning="TANKS > SWAP", voice="Tank swap", timing=false }

local function infectionCalls()
    return { siphon, exploding, stygian, tankswap }
end

local function append(target, additions)
    for _, call in ipairs(additions) do target[#target + 1] = call end
    return target
end

Registry:Register({
    key="vashnik", name="Vashnik the Malignant", encounterID=3455,
    strategyStatus="12.1 Journal + current community strategy source-reviewed 2026-08-17; live validation pending",
    profiles={
        normal={
            explanation={
                "PLAN: MOVE VASHNIK BETWEEN PLANNED FOUNTAIN PAIRS SO INFUSION STACKS STAY BALANCED. KILL LIVING VENOMS BEFORE THEY REACH CENTER.",
                "ADAPTIVE INFECTION: BLOOD TARGETS SPREAD AND NEED HEALING; FIRE TARGETS GO FAR OUT; SHADOW TARGETS SPREAD AND MOVE FROM BURSTS.",
                "FROTH TARGETS MOVE OUT, THEN EVERYONE DODGES THE FOUR WAVES. TANKS SWAP AS DRIPPING FANGS STACKS.",
            },
            calls=append({
                imbibeCall("IMBIBE > KILL VENOMS"),
                frothCall("FROTH > TARGETS OUT > DODGE WAVES"),
            }, infectionCalls()),
        },
        heroic={
            explanation={
                "PLAN: ROTATE FOUNTAIN PAIRS; DO NOT OVERSTACK ONE INFUSION. KILL LIVING VENOMS BEFORE CENTER AND PLAN HEALING CDS FOR LATER IMBIBES.",
                "CATALYST: PREASSIGN MOBILE SOAKERS SO EVERY BILE CIRCLE HAS A PLAYER. ADAPTIVE INFECTIONS FOLLOW BLOOD/FIRE/SHADOW RULES.",
                "FROTH TARGETS OUT, THEN DODGE FOUR WAVES. TANKS SWAP AS DRIPPING FANGS STACKS.",
            },
            calls=append({
                imbibeCall("IMBIBE > KILL VENOMS"),
                catalyst,
                frothCall("FROTH > TARGETS OUT > DODGE WAVES"),
            }, infectionCalls()),
        },
        mythic={
            explanation={
                "PLAN: HEROIC FOUNTAIN ROTATION PLUS TUMOR CONTROL. MARK TUMOR LANES BEFORE EACH FROTH AND KEEP INFUSION STACKS BALANCED.",
                "FROTH TARGETS AIM A WAVE THROUGH TUMORS TO REMOVE HARDENED DEFENSE, THEN RAID KILLS ANY TUMOR STILL ALIVE. CATALYST CIRCLES ALL GET SOAKERS.",
                "ADAPTIVE INFECTIONS: BLOOD SPREAD/HEAL, FIRE FAR OUT AND DISPEL SAFELY, SHADOW SPREAD/MOVE. TANKS SWAP ON FANGS.",
            },
            calls=append({
                imbibeCall("IMBIBE > CONTROL VENOMS > MARK TUMORS"),
                { key="totems", ability="Malignant Tumors", action="Aim Froth waves through Tumors", warning="TUMORS > AIM FROTH WAVES THROUGH THEM", voice="Tumors", timing=false, iconSpellID=1283164 },
                catalyst,
                frothCall("FROTH > AIM THROUGH TUMORS > DODGE"),
            }, infectionCalls()),
        },
    },
})
