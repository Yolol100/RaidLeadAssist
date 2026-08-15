local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local sever = { key="sever", ability="Sever", action="Tank through venom > raid clear frontal", warning="SEVER > TANK AIM THROUGH VENOM > RAID CLEAR FRONT", voice="Sever", spellIDs={1299680} }
local dread = { key="dreadmarch", ability="Dreadmarch", action="Break shields > fixates face ghosts", warning="DREADMARCH > BREAK SHIELDS > FIXATES FACE GHOSTS", voice="Dreadmarch", spellIDs={1289900}, prepareSeconds=7, pressSeconds=4 }
local night = { key="nightfall", ability="Eternal Nightfall", action="Break shield > interrupt", warning="ETERNAL NIGHTFALL > BREAK SHIELD > INTERRUPT", voice="Nightfall", spellIDs={1286918}, prepareSeconds=5, pressSeconds=2 }
local spirit = { key="spiritcackle", ability="Spiritcackle", action="Kill Soulcoilers > interrupt Wail", warning="SPIRITCACKLE > KILL SOULCOILERS > INTERRUPT WAIL", voice="Add", spellIDs={1286441} }
local intermission = { key="intermission", ability="Soulbinding", action="Stomp one fragment at a time", warning="SOULBINDING > STOMP 1 FRAGMENT AT A TIME > SPACE STOMPS", voice="Fragments", timing=false }
local final = { key="final", ability="Final Phase", action="Balance both > kill together", warning="FINAL PHASE > KEEP BOTH EVEN > KILL TOGETHER", voice="Final phase", timing=false, iconSpellID=1298381 }
local function guillotine(text)
    return { key="guillotine", ability="Guillotine", action=text, warning=text, voice="Guillotine", spellIDs={1283489,1283485,1299266}, timerNames={"Guillotine","Grim Guillotine"}, prepareSeconds=8, pressSeconds=5 }
end
local function gloombomb(text)
    return { key="gloombomb", ability="Gloombomb", action=text, warning=text, voice="Bomb", spellIDs={1286895} }
end
local function toxic(text)
    return { key="toxic", ability="Toxic Deluge", action=text, warning=text, voice="Venom", spellIDs={1299960}, prepareSeconds=7, pressSeconds=4 }
end

Registry:Register({
    key="altar", name="The Coiled Altar", encounterID=3429,
    encounterAliases={"The Bargained Crown"},
    strategyStatus="12.1 difficulty plans source-reviewed 2026-08-15; live validation pending",
    profiles={
        normal={
            explanation={
                "P1 PLAN: TANK AIMS SEVER THROUGH VENOM; RAID STAYS OUT OF THE FRONTAL.",
                "TOXIC DELUGE: DODGE IMPACTS AND SET COALESCED VENOM FOR THE NEXT SEVER.",
                "GUILLOTINE: 5+ PLAYERS SOAK. A SECOND COVERAGE TEAM IS OPTIONAL ON NORMAL.",
                "P2: BREAK DREADMARCH SHIELDS; FIXATES FACE GHOSTS FOR TANK SOUL SEVER.",
                "NIGHTFALL: BREAK SHIELD THEN INTERRUPT. SPIRITCACKLE: KILL ADDS, KICK WAIL.",
                "GLOOMBOMB TARGETS 15+ YARDS OUT. RECLAIM SOUL FRAGMENTS FAST.",
                "SOULBINDING: STOMP FRAGMENTS ONE AT A TIME. FINAL: KILL BOTH TOGETHER.",
            },
            calls={
                sever,
                toxic("TOXIC DELUGE > DODGE IMPACTS > SET GLOBULES FOR NEXT SEVER"),
                guillotine("GUILLOTINE > ASSIGNED 5+ SOAKERS IN > THEN RAID 40+ FROM AXE"),
                dread, night, spirit,
                gloombomb("GLOOMBOMB > TARGETS 15+ OUT > RECLAIM FRAGMENTS"),
                intermission, final,
            },
        },
        heroic={
            explanation={
                "P1 PLAN: SEVER CLEARS VENOM. GUILLOTINE TEAMS A/B ALTERNATE 5+ SOAKS.",
                "TOXIC DELUGE: SPACE GLOBULE CLEARS; NEVER STACK MULTIPLE VENOM RUPTURES.",
                "AFTER EACH GUILLOTINE, RAID MOVES 40+ YARDS FROM THE AXE EXPLOSION.",
                "P2: BREAK DREADMARCH SHIELDS; FIXATES FACE GHOSTS FOR TANK SOUL SEVER.",
                "NIGHTFALL: BREAK SHIELD THEN KICK. SPIRITCACKLE: KILL ADDS AND KICK WAIL.",
                "GLOOMBOMB TARGETS 15+ OUT; ANY GRAVEBOUND PLAYER RECLAIMS FRAGMENTS FAST.",
                "SOULBINDING: STOMP 1 FRAGMENT AT A TIME AND SPACE RAID DAMAGE.",
                "FINAL: HANDLE OLD MECHANICS, KEEP BOTH BOSSES EVEN, KILL TOGETHER.",
            },
            calls={
                sever,
                toxic("TOXIC DELUGE > SPACE GLOBULE CLEARS > NEVER STACK RUPTURES"),
                guillotine("GUILLOTINE > TEAM A/B ROTATE 5+ SOAK > THEN 40+ FROM AXE"),
                dread, night, spirit,
                gloombomb("GLOOMBOMB > 15+ OUT > GRAVEBOUND RECLAIM FRAGMENTS"),
                intermission, final,
            },
        },
        mythic={
            explanation={
                "P1 PLAN: PERMANENT GUILLOTINED MEANS EVERY AXE USES A FRESH 5+ SOAK TEAM.",
                "AXEGRINDERS NEVER DESPAWN: KEEP MOVEMENT LANES CLEAN AND DO NOT WASTE SPACE.",
                "DREAD GHOSTS ARE PERSONAL: FIXATED PLAYERS FACE THEM AND KEEP GHOSTS APART.",
                "SOUL SEVER KILLS GHOSTS. WAIL INTERRUPTS BRIEFLY REVEAL HIDDEN GHOSTS.",
                "SPIRITCACKLE: AIM GLOOMBOMBS INTO SOULCOILERS TO REMOVE SPIRIT SHIELDS.",
                "TOXIC DELUGE: CLEAR MUTATIONS BEFORE THE NEXT DELUGE; NEVER CHAIN RUPTURES.",
                "SOULBINDING: SPACE FRAGMENT STOMPS. FINAL: KEEP BOTH EVEN, KILL TOGETHER.",
            },
            calls={
                sever,
                guillotine("GUILLOTINE > FRESH 5+ SOAK TEAM > THEN RAID 40+ FROM AXE"),
                dread, night,
                { key="spiritcackle", ability="Spiritcackle", action="Gloombombs strip shields > kick Wail", warning="SPIRITCACKLE > AIM GLOOMBOMBS INTO SOULCOILERS > INTERRUPT WAIL", voice="Add", spellIDs={1286441} },
                gloombomb("GLOOMBOMB > AIM AT SOULCOILER SHIELDS > THEN RECLAIM FRAGMENTS"),
                toxic("TOXIC DELUGE > CLEAR MUTATIONS BEFORE NEXT DELUGE > NO CHAIN RUPTURES"),
                intermission, final,
            },
        },
    },
})
