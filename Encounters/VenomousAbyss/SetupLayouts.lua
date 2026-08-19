local _, ns = ...

local Setup = ns:GetModule("Encounters.SetupRegistry")

local function layout(summary, markers, checks)
    return {
        summary = summary,
        markers = markers or {},
        checks = checks or {},
    }
end

local function sameForAll(profile)
    return { normal = profile, heroic = profile, mythic = profile }
end

Setup:RegisterLayouts("nekzali", {
    normal = layout(
        "Normal needs no fixed raidleader markers or assignments.",
        {},
        {}
    ),
    heroic = layout(
        "Assign only the Heroic Pyre soak group before pull.",
        {},
        {
            "Set the Pyre soak group; everyone else stays outside for fire circles.",
            "Fire-circle players burn dead Amani corpses with their expiration.",
        }
    ),
    mythic = layout(
        "Keep the Pyre group and add two fresh Grasping Depths groups.",
        {},
        {
            "Set the Pyre soak group.",
            "Set two different well groups for alternating Grasping Depths entries.",
        }
    ),
})

Setup:RegisterLayouts("sentinels", sameForAll(layout(
    "Set two fixed physical raid sides; players stay while tanks swap bosses after Stasis.",
    {
        { key="breath_side", kind="world", icon=4, label="Green / Breath side", purpose="Triangle is the fixed green-side position." },
        { key="blood_side", kind="world", icon=7, label="Red / Blood side", purpose="Cross is the fixed red-side position." },
    },
    {
        "Assign the Green Side to Triangle and Red Side to Cross.",
        "Both sides stay in place after Stasis while tanks swap bosses.",
    }
)))

Setup:RegisterLayouts("explorers", {
    normal = layout(
        "Place the three Mighty Thud soak points. No roster assignment is required.",
        {
            { key="thud_one", kind="world", icon=1, label="Thud 1", purpose="Star is Mighty Thud soak point 1." },
            { key="thud_two", kind="world", icon=2, label="Thud 2", purpose="Circle is Mighty Thud soak point 2." },
            { key="thud_three", kind="world", icon=3, label="Thud 3", purpose="Diamond is Mighty Thud soak point 3." },
        },
        {
            "Use fish order: Nama, then Iku, then Gebbo.",
            "Open crates as needed until the next fish appears.",
        }
    ),
    heroic = layout(
        "Keep the three Thud points. Heroic still needs no fixed crate roster.",
        {
            { key="thud_one", kind="world", icon=1, label="Thud 1", purpose="Star is Mighty Thud soak point 1." },
            { key="thud_two", kind="world", icon=2, label="Thud 2", purpose="Circle is Mighty Thud soak point 2." },
            { key="thud_three", kind="world", icon=3, label="Thud 3", purpose="Diamond is Mighty Thud soak point 3." },
        },
        {
            "Use fish order: Nama, then Iku, then Gebbo.",
            "Open crates as needed until the next fish appears.",
        }
    ),
    mythic = layout(
        "Keep the Thud points and assign a controlled crate rotation for 15+ yard clearance.",
        {
            { key="thud_one", kind="world", icon=1, label="Thud 1", purpose="Star is Mighty Thud soak point 1." },
            { key="thud_two", kind="world", icon=2, label="Thud 2", purpose="Circle is Mighty Thud soak point 2." },
            { key="thud_three", kind="world", icon=3, label="Thud 3", purpose="Diamond is Mighty Thud soak point 3." },
        },
        {
            "Use fish order: Nama, then Iku, then Gebbo.",
            "Assign the crate rotation; raid clears 15+ yards before each break.",
        }
    ),
})

Setup:RegisterLayouts("vashnik", {
    normal = layout(
        "Use the fixed three-pair fountain route; no player assignment is required.",
        {},
        {
            "Route: Flame+Shadow, then Shadow+Blood, then Blood+Flame.",
            "Before each Imbibe, position Vashnik between the next fountain pair.",
        }
    ),
    heroic = layout(
        "Keep the fountain route and reserve Skull/Cross for the two Fire adds.",
        {
            { key="fire_first", kind="target", icon=8, label="Fire add first", purpose="Skull is the first Burning Venom kill target." },
            { key="fire_second", kind="target", icon=7, label="Fire add second", purpose="Cross dies after the first Fire DoT has ended." },
        },
        {
            "Route: Flame+Shadow, then Shadow+Blood, then Blood+Flame.",
            "Fire pair: kill Skull, wait for the DoT, then kill Cross.",
        }
    ),
    mythic = layout(
        "Keep the same fountain route and Skull/Cross Fire-add stagger.",
        {
            { key="fire_first", kind="target", icon=8, label="Fire add first", purpose="Skull is the first Burning Venom kill target." },
            { key="fire_second", kind="target", icon=7, label="Fire add second", purpose="Cross dies after the first Fire DoT has ended." },
        },
        {
            "Route: Flame+Shadow, then Shadow+Blood, then Blood+Flame.",
            "Fire pair: kill Skull, wait for the DoT, then kill Cross.",
        }
    ),
})

Setup:RegisterLayouts("sszorak", sameForAll(layout(
    "Place three saved-Cyst markers and prepare Mutilate groups plus Cyst Poppers.",
    {
        { key="cyst_one", kind="world", icon=1, label="Cyst 1", purpose="Star is the first saved Cyst position." },
        { key="cyst_two", kind="world", icon=2, label="Cyst 2", purpose="Circle is the second saved Cyst position." },
        { key="cyst_three", kind="world", icon=3, label="Cyst 3", purpose="Diamond is the third saved Cyst position." },
    },
    {
        "Place each Cyst marker opposite a different tornado cluster.",
        "Assign Poppers 1/2/3 and two different Mutilate soak groups.",
    }
)))

Setup:RegisterLayouts("twinfangs", {
    normal = layout(
        "Normal Feast is dynamic; every hit still needs fresh eligible soakers.",
        {},
        {
            "Each Feast hit needs 3+ players who skipped earlier hits in that cast.",
        }
    ),
    heroic = layout(
        "Assign three different Feast groups, one for each hit.",
        {},
        {
            "Set three different 3+ Feast groups for hits 1, 2 and 3.",
        }
    ),
    mythic = layout(
        "Keep the three Feast groups and add Broodling interrupt owners.",
        {},
        {
            "Set three different 3+ Feast groups for hits 1, 2 and 3.",
            "Assign Broodling interrupts; Tainted Blood needs no fixed roster group.",
        }
    ),
})

Setup:RegisterLayouts("altar", {
    normal = layout(
        "Mark both platform ends and prepare Orb Collectors plus Wail interrupt ownership.",
        {
            { key="sever_end", kind="world", icon=4, label="Orb / Sever end", purpose="Triangle is the orb collection and Sever reference end." },
            { key="soul_end", kind="world", icon=7, label="Ghost / Soul Sever end", purpose="Cross is the ghost routing and Soul Sever reference end." },
        },
        {
            "Assign 2-3 mobile Orb Collectors and a primary Wail interrupt.",
            "Normal Guillotine needs any 5+ soakers; no fixed team is required.",
        }
    ),
    heroic = layout(
        "Use the same markers; add two different Guillotine groups and Wail interrupts.",
        {
            { key="sever_end", kind="world", icon=4, label="Orb / Sever end", purpose="Triangle is the orb collection and Sever reference end." },
            { key="soul_end", kind="world", icon=7, label="Ghost / Soul Sever end", purpose="Cross is the ghost routing and Soul Sever reference end." },
        },
        {
            "Assign 2-3 mobile Orb Collectors.",
            "Assign two different 5+ Guillotine groups and at least two Wail kicks.",
        }
    ),
    mythic = layout(
        "Use the same markers; prepare fresh Guillotine groups and Wail interrupts.",
        {
            { key="sever_end", kind="world", icon=4, label="Orb / Sever end", purpose="Triangle is the orb collection and Sever reference end." },
            { key="soul_end", kind="world", icon=7, label="Ghost / Soul Sever end", purpose="Cross is the ghost routing and Soul Sever reference end." },
        },
        {
            "Assign 2-3 mobile Orb Collectors.",
            "Plan fresh 5+ Guillotine groups and at least two Wail kicks.",
        }
    ),
})

Setup:RegisterLayouts("ulatek", {
    normal = layout(
        "Give Spectral Coils one fixed soak marker and assign the planned egg handler.",
        {
            { key="coils_soak", kind="world", icon=6, label="Coils soak", purpose="Square is the full-raid Spectral Coils soak point." },
        },
        {
            "Assign the Doomscale Egg handler and choose the planned egg before pull.",
        }
    ),
    heroic = layout(
        "Keep the full-raid Coils marker and the same egg handler as Normal.",
        {
            { key="coils_soak", kind="world", icon=6, label="Coils soak", purpose="Square is the full-raid Spectral Coils soak point." },
        },
        {
            "Assign the Doomscale Egg handler and choose the planned egg before pull.",
        }
    ),
    mythic = layout(
        "Mythic needs alternating Coils groups plus left/right egg-side references.",
        {
            { key="coils_soak", kind="world", icon=6, label="Coils soak", purpose="Square is the Spectral Coils soak point for the called group." },
            { key="egg_left", kind="world", icon=4, label="Left eggs", purpose="Triangle labels the planned left egg side." },
            { key="egg_right", kind="world", icon=7, label="Right eggs", purpose="Cross labels the planned right egg side." },
        },
        {
            "Assign alternating Coils groups and left/right egg carriers.",
            "Assign a 4+ Toxic Incubation intercept group; call the active egg side.",
        }
    ),
})
