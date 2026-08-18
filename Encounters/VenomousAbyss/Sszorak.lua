local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local function baseCalls()
    return {
        { key="venom", ability="Venomous Surge", action="Debuff to markers > drop cysts", warning="VENOM > DEBUFF TO MARKERS > DROP CYSTS", voice="Venom", spellIDs={1305959}, prepareSeconds=6, pressSeconds=3 },
        { key="crosswinds", ability="Raging Crosswinds", action="Pair opposites > collide", warning="CROSSWINDS > PAIR OPPOSITES > COLLIDE", voice="Crosswinds", spellIDs={1285425}, prepareSeconds=7, pressSeconds=4 },
        { key="maelstrom", ability="Howling Maelstrom", action="Cyst poppers 1/2/3 counter each wind", warning="MAELSTROM > POPPERS 1/2/3 > KNOCK AGAINST EACH WIND", voice="Maelstrom", spellIDs={1285732}, prepareSeconds=8, pressSeconds=5 },
        { key="apex", ability="Apex Predator", action="Next assigned team soaks green Mutilate", warning="GREEN MUTILATE > NEXT 5+ SOAK TEAM", voice="Soak", spellIDs={1277025,1285430}, prepareSeconds=7, pressSeconds=4 },
    }
end

Registry:Register({
    key="sszorak", name="Sszorak", encounterID=3420,
    strategyStatus="12.1 Journal + current Wowhead + DBM/BigWigs source-reviewed 2026-08-19; player briefing split from marker/poppers prep; live validation pending",
    profiles={
        normal={
            explanation={
                "Venom debuff on you: run to your assigned outer marker.",
                "Let it expire there and leave the Cyst for later.",
                "Wind arrow on you: find the player with the opposite direction.",
                "Position so both knockbacks send you toward each other.",
                "Maelstrom starts: only assigned Cyst Poppers touch saved Cysts.",
                "Mutilate frontal: assigned soak team enters; everyone else stays out.",
                "When Sszorak digs in, use major damage cooldowns.",
            }, calls=baseCalls(),
        },
        heroic={
            explanation={
                "Keep new poison pools at the arena edge.",
                "Use the other Mutilate soak team on every new cast.",
            }, calls=baseCalls(),
        },
        mythic={
            explanation={
                "Serpent's Fury marks a player: 14+ players stack on them.",
                "After the charge, Virulence players spread from everyone.",
                "Drop Virulence residue away from the raid.",
            },
            calls={
                baseCalls()[1], baseCalls()[2], baseCalls()[3], baseCalls()[4],
                { key="serpent", ability="Serpent's Fury", action="14+ stack on mark", warning="SERPENT'S FURY > 14+ STACK ON MARK", voice="Stack", timing=false, iconSpellID=1305621 },
            },
        },
    },
})
