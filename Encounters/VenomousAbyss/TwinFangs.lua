local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local adds = { key="adds", ability="Venomous Emergence", action="Kill spawns now", warning="VENOMOUS EMERGENCE > KILL SPAWNS NOW", voice="Adds", spellIDs={1291404} }

Registry:Register({
    key="twinfangs", name="The Twin Fangs", encounterID=3421,
    strategyStatus="12.1 difficulty plans source-reviewed 2026-08-13; live validation pending",
    profiles={
        normal={
            explanation={
                "PLAN: KEEP BOTH BOSSES TOGETHER FOR CLEAVE AND WATCH YOUR ETERNAL VENOM.",
                "HIGH VENOM PLAYERS JOIN RAVENOUS FEAST TO REMOVE STACKS.",
                "FEAST HITS 3 TIMES. ON NORMAL THE SAME SOAKERS CAN HELP AGAIN IF NEEDED.",
                "VENOMOUS EMERGENCE: HARD SWAP AND KILL THE SPAWNS FAST.",
                "AT 100 ENERGY: DODGE VILE FLOOD AND SANGUINE STORM.",
                "DO NOT CHASE A FIXED STACK NUMBER; SOAK EARLY ENOUGH TO STAY SAFE.",
            },
            calls={
                { key="feast", ability="Ravenous Feast", action="High Venom players soak", warning="RAVENOUS FEAST > HIGH VENOM PLAYERS SOAK > CLEAR STACKS", voice="Feast", spellIDs={1290516} },
                adds,
            },
        },
        heroic={
            explanation={
                "PLAN: KEEP BOTH BOSSES TOGETHER AND USE 3 ASSIGNED FEAST GROUPS.",
                "RAVENOUS FEAST HITS 3 TIMES. USE A DIFFERENT GROUP FOR EACH HIT.",
                "FEASTED PLAYERS DO NOT TAKE THE NEXT HIT; ROTATE A > B > C.",
                "VENOMOUS EMERGENCE: HARD SWAP AND KILL SPAWNS FAST.",
                "AT 100 ENERGY: DODGE VILE FLOOD AND SANGUINE STORM.",
                "IF YOUR VENOM IS HIGH, MOVE INTO YOUR NEXT ASSIGNED FEAST GROUP.",
            },
            calls={
                { key="feast", ability="Ravenous Feast", action="3 hits > rotate A > B > C", warning="RAVENOUS FEAST > 3 HITS > ROTATE SOAK GROUPS A > B > C", voice="Feast", spellIDs={1290516} },
                adds,
            },
        },
        mythic={
            explanation={
                "PLAN: HEROIC FEAST ROTATION PLUS FAST INTERRUPT TEAMS FOR MYTHIC ADDS.",
                "FEAST: ROTATE A > B > C. NEVER SEND FEASTED PLAYERS BACK IN EARLY.",
                "ROUSE THE BROOD: EACH BROODLING GETS AN INTERRUPT; A KICK MAKES IT RETREAT.",
                "BLOOD TORRENT: HEAL THE TANK ABSORB AND INTERRUPT BARBED BULWARKS.",
                "VENOMOUS EMERGENCE ADDS DIE FAST. AVOID EXTRA DEATHS WITH ETERNAL VENOM.",
                "AT 100 ENERGY: DODGE VILE FLOOD AND SANGUINE STORM.",
            },
            calls={
                { key="feast", ability="Ravenous Feast", action="3 hits > rotate A > B > C", warning="RAVENOUS FEAST > ROTATE SOAK GROUPS A > B > C", voice="Feast", spellIDs={1290516} },
                adds,
                { key="blood", ability="Blood Torrent", action="Heal tank absorb > break Bulwarks", warning="BLOOD TORRENT > HEAL TANK ABSORB > INTERRUPT BARBED BULWARKS", voice="Blood", spellIDs={1303230} },
                { key="brood", ability="Rouse the Brood", action="Interrupt every Broodling", warning="ROUSE THE BROOD > INTERRUPT EVERY BROODLING NOW", voice="Interrupt", spellIDs={1308356} },
            },
        },
    },
})
