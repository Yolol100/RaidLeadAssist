local _, ns = ...
local Registry = ns:GetModule("Encounters.Registry")

local sever = { key="sever", ability="Sever", action="Tank aim through venom > raid clear front", warning="SEVER > TANK THROUGH VENOM > RAID CLEAR FRONT", voice="Sever", spellIDs={1299680} }
local dread = { key="dreadmarch", ability="Dreadmarch", action="Break shields > fixates face ghosts", warning="DREADMARCH > BREAK SHIELDS > FIXATES FACE GHOSTS", voice="Dreadmarch", spellIDs={1289900}, prepareSeconds=7, pressSeconds=4 }
local night = { key="nightfall", ability="Eternal Nightfall", action="Break shield > interrupt", warning="NIGHTFALL > BREAK SHIELD > INTERRUPT", voice="Nightfall", spellIDs={1286918}, prepareSeconds=5, pressSeconds=2 }
local spirit = { key="spiritcackle", ability="Spiritcackle", action="Kill Soulcoilers > interrupt Wail", warning="SPIRITCACKLE > KILL ADDS > INTERRUPT WAIL", voice="Add", spellIDs={1286441} }
local intermission = { key="intermission", ability="Soulbinding", action="Stomp one fragment at a time", warning="SOULBINDING > ONE FRAGMENT AT A TIME", voice="Fragments", timing=false }
local final = { key="final", ability="Final Phase", action="Keep both even > kill together", warning="FINAL > KEEP BOTH EVEN > KILL TOGETHER", voice="Final phase", timing=false, iconSpellID=1298381 }
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
    strategyStatus="12.1 Journal + current community strategy source-reviewed 2026-08-17; live validation pending",
    profiles={
        normal={
            explanation={
                "P1 PLAN: USE SEVER TO CLEAR VENOM. GUILLOTINE NEEDS 5+ ASSIGNED SOAKERS; AFTER THE AXE, RAID MOVES 40+ YARDS AWAY.",
                "P2: BREAK DREADMARCH SHIELDS; FIXATED PLAYERS FACE GHOSTS FOR SOUL SEVER. BREAK NIGHTFALL SHIELD THEN INTERRUPT; KILL SOULCOILERS AND KICK WAIL.",
                "GLOOMBOMBS GO 15+ YARDS OUT. RECLAIM SOUL FRAGMENTS. SOULBINDING STOMPS ONE AT A TIME. FINAL: KEEP BOTH BOSSES EVEN AND KILL TOGETHER.",
            },
            calls={
                sever,
                toxic("TOXIC DELUGE > DODGE > SET VENOM FOR SEVER"),
                guillotine("GUILLOTINE > 5+ SOAK > THEN RAID 40+ YARDS"),
                dread, night, spirit,
                gloombomb("GLOOMBOMB > 15+ YARDS OUT > RECLAIM FRAGMENTS"),
                intermission, final,
            },
        },
        heroic={
            explanation={
                "P1 PLAN: SEVER CLEARS VENOM. GUILLOTINE TEAMS A/B ALTERNATE 5+ SOAKS BECAUSE REPEAT DAMAGE IS HEAVILY INCREASED; RAID THEN MOVES 40+ YARDS FROM THE AXE.",
                "P2: BREAK DREADMARCH SHIELDS; FIXATES FACE GHOSTS. BREAK NIGHTFALL SHIELD THEN KICK. KILL SOULCOILERS AND KICK WAIL.",
                "GLOOMBOMBS GO 15+ OUT; GRAVEBOUND PLAYERS RECLAIM FRAGMENTS. SOULBINDING ONE AT A TIME. FINAL: KEEP BOTH BOSSES EVEN AND KILL TOGETHER.",
            },
            calls={
                sever,
                toxic("TOXIC DELUGE > SPACE CLEARS > NO CHAIN RUPTURES"),
                guillotine("GUILLOTINE > TEAM A/B 5+ SOAK > RAID 40+ YARDS"),
                dread, night, spirit,
                gloombomb("GLOOMBOMB > 15+ OUT > RECLAIM FRAGMENTS"),
                intermission, final,
            },
        },
        mythic={
            explanation={
                "P1 PLAN: GUILLOTINED IS PERMANENT, SO EVERY AXE USES A FRESH 5+ SOAK TEAM. AXEGRINDERS NEVER DESPAWN; KEEP MOVEMENT LANES CLEAN.",
                "DREAD GHOSTS ARE PERSONAL; FIXATED PLAYERS FACE THEM FOR SOUL SEVER. WAIL INTERRUPTS BRIEFLY REVEAL HIDDEN GHOSTS.",
                "AIM GLOOMBOMBS INTO SOULCOILERS TO STRIP SHIELDS. CLEAR TOXIC MUTATIONS BEFORE THE NEXT DELUGE. FINAL: KEEP BOTH BOSSES EVEN AND KILL TOGETHER.",
            },
            calls={
                sever,
                guillotine("GUILLOTINE > FRESH 5+ TEAM > RAID 40+ YARDS"),
                dread, night,
                { key="spiritcackle", ability="Spiritcackle", action="Gloombombs into Soulcoilers > interrupt Wail", warning="SPIRITCACKLE > GLOOMBOMBS INTO ADDS > INTERRUPT WAIL", voice="Add", spellIDs={1286441} },
                gloombomb("GLOOMBOMB > AIM AT SOULCOILERS > RECLAIM FRAGMENTS"),
                toxic("TOXIC DELUGE > CLEAR MUTATIONS > NO CHAIN RUPTURES"),
                intermission, final,
            },
        },
    },
})
