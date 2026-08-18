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
        "Normal needs no fixed raidleader markers or preassigned rotation.",
        {},
        {}
    ),
    heroic = layout(
        "Prepare the Heroic Pyre/Cremation roles before pull; players only need their own job in the Boss Plan.",
        {},
        {
            "Set the Pyre soak group; everyone else stays outside for fire circles.",
            "Confirm fire-circle players use their explosion on dead Amani corpses.",
        }
    ),
    mythic = layout(
        "Prepare Pyre/Cremation roles plus fresh Grasping Depths well groups before pull.",
        {},
        {
            "Set separate Pyre soak and Cremation groups.",
            "Set two fresh well groups and the order they enter for Grasping Depths.",
        }
    ),
})

Setup:RegisterLayouts("sentinels", sameForAll(layout(
    "Set two fixed physical raid sides; after Stasis the groups stay put while tanks swap the bosses.",
    {
        { key="breath_side", kind="world", icon=4, label="Green / Breath side", purpose="Triangle is Team A's fixed green-side position." },
        { key="blood_side", kind="world", icon=7, label="Red / Blood side", purpose="Cross is Team B's fixed red-side position." },
    },
    {
        "Set Team A on Triangle / green and Team B on Cross / red.",
        "Confirm both teams stay on their physical side after Stasis.",
    }
)))

Setup:RegisterLayouts("explorers", {
    normal = layout(
        "Pre-place three Mighty Thud soak points and confirm the crate/fish plan before pull.",
        {
            { key="thud_one", kind="world", icon=1, label="Thud 1", purpose="Star is Mighty Thud soak point 1." },
            { key="thud_two", kind="world", icon=2, label="Thud 2", purpose="Circle is Mighty Thud soak point 2." },
            { key="thud_three", kind="world", icon=3, label="Thud 3", purpose="Diamond is Mighty Thud soak point 3." },
        },
        {
            "Use the fish order Nama > Iku > Gebbo.",
            "Confirm the crate breaker and fish runner are assigned.",
        }
    ),
    heroic = layout(
        "Keep the three Thud points and confirm the Heroic crate rotation plus fish plan.",
        {
            { key="thud_one", kind="world", icon=1, label="Thud 1", purpose="Star is Mighty Thud soak point 1." },
            { key="thud_two", kind="world", icon=2, label="Thud 2", purpose="Circle is Mighty Thud soak point 2." },
            { key="thud_three", kind="world", icon=3, label="Thud 3", purpose="Diamond is Mighty Thud soak point 3." },
        },
        {
            "Use the fish order Nama > Iku > Gebbo.",
            "Confirm the crate-breaker rotation and fish runner are assigned.",
        }
    ),
    mythic = layout(
        "Keep the three Thud points and confirm the Mythic crate rotation plus fish plan.",
        {
            { key="thud_one", kind="world", icon=1, label="Thud 1", purpose="Star is Mighty Thud soak point 1." },
            { key="thud_two", kind="world", icon=2, label="Thud 2", purpose="Circle is Mighty Thud soak point 2." },
            { key="thud_three", kind="world", icon=3, label="Thud 3", purpose="Diamond is Mighty Thud soak point 3." },
        },
        {
            "Use the fish order Nama > Iku > Gebbo.",
            "Confirm the crate-breaker rotation and fish runner are assigned.",
        }
    ),
})

Setup:RegisterLayouts("vashnik", {
    normal = layout(
        "Set the fountain route before pull so every Imbibe position is decided in advance.",
        {},
        {
            "Use the RLA route: Flame > Shadow > Shadow > Blood > Blood > Flame.",
            "Before each Imbibe, position Vashnik between the next planned fountains.",
        }
    ),
    heroic = layout(
        "Use the fixed fountain route and reserve Skull/Cross for the two Fire adds.",
        {
            { key="fire_first", kind="target", icon=8, label="Fire add first", purpose="Skull is the first Burning Venom kill target." },
            { key="fire_second", kind="target", icon=7, label="Fire add second", purpose="Cross dies only after the first Fire DoT has ended." },
        },
        {
            "Use the RLA route: Flame > Shadow > Shadow > Blood > Blood > Flame.",
            "For each Fire pair: Skull dies first; wait for the DoT, then kill Cross.",
        }
    ),
    mythic = layout(
        "Use the fixed fountain route and the same Skull/Cross Fire-add stagger as Heroic.",
        {
            { key="fire_first", kind="target", icon=8, label="Fire add first", purpose="Skull is the first Burning Venom kill target." },
            { key="fire_second", kind="target", icon=7, label="Fire add second", purpose="Cross dies only after the first Fire DoT has ended." },
        },
        {
            "Use the RLA route: Flame > Shadow > Shadow > Blood > Blood > Flame.",
            "For each Fire pair: Skull dies first; wait for the DoT, then kill Cross.",
        }
    ),
})

Setup:RegisterLayouts("sszorak", sameForAll(layout(
    "Place three Cyst-drop markers opposite the tornado clusters and prepare the soak/poppers rotation.",
    {
        { key="cyst_one", kind="world", icon=1, label="Cyst 1", purpose="Star is the first saved Cyst position." },
        { key="cyst_two", kind="world", icon=2, label="Cyst 2", purpose="Circle is the second saved Cyst position." },
        { key="cyst_three", kind="world", icon=3, label="Cyst 3", purpose="Diamond is the third saved Cyst position." },
    },
    {
        "Place each Cyst marker opposite a different tornado cluster.",
        "Assign Cyst Poppers 1/2/3 and separate Mutilate Teams A/B.",
    }
)))

Setup:RegisterLayouts("twinfangs", {
    normal = layout(
        "Normal can handle Feast dynamically, but every hit still needs fresh eligible soakers.",
        {},
        {
            "Confirm every Feast hit gets 3+ players who did not soak an earlier hit in that cast.",
        }
    ),
    heroic = layout(
        "Preassign three fresh Feast teams so each of the three hits has different soakers.",
        {},
        {
            "Set separate 3+ Feast Teams A, B and C for hits 1, 2 and 3.",
        }
    ),
    mythic = layout(
        "Keep the three Feast teams and add Mythic interrupt/healing coverage.",
        {},
        {
            "Set separate 3+ Feast Teams A, B and C for hits 1, 2 and 3.",
            "Confirm Broodling interrupts and Tainted Blood fount healing coverage.",
        }
    ),
})

Setup:RegisterLayouts("altar", {
    normal = layout(
        "Mark both platform ends and prepare the core orb, axe and interrupt jobs.",
        {
            { key="sever_end", kind="world", icon=4, label="Orb / Sever end", purpose="Triangle is the orb collection and Sever reference end." },
            { key="soul_end", kind="world", icon=7, label="Ghost / Soul Sever end", purpose="Cross is the ghost routing and Soul Sever reference end." },
        },
        {
            "Assign 2-3 mobile Orb Collectors.",
            "Set 5+ Guillotine soak coverage and Wail interrupt coverage.",
        }
    ),
    heroic = layout(
        "Use the same two platform markers and prepare the Heroic axe rotation and interrupts.",
        {
            { key="sever_end", kind="world", icon=4, label="Orb / Sever end", purpose="Triangle is the orb collection and Sever reference end." },
            { key="soul_end", kind="world", icon=7, label="Ghost / Soul Sever end", purpose="Cross is the ghost routing and Soul Sever reference end." },
        },
        {
            "Assign 2-3 mobile Orb Collectors.",
            "Set two separate 5+ Guillotine teams and 2-3 Wail interrupts.",
        }
    ),
    mythic = layout(
        "Use the same two platform markers and prepare fresh Mythic axe teams plus interrupts.",
        {
            { key="sever_end", kind="world", icon=4, label="Orb / Sever end", purpose="Triangle is the orb collection and Sever reference end." },
            { key="soul_end", kind="world", icon=7, label="Ghost / Soul Sever end", purpose="Cross is the ghost routing and Soul Sever reference end." },
        },
        {
            "Assign 2-3 mobile Orb Collectors.",
            "Plan fresh 5+ Guillotine teams for later axes and 2-3 Wail interrupts.",
        }
    ),
})

Setup:RegisterLayouts("ulatek", {
    normal = layout(
        "Give Spectral Coils one fixed soak reference and confirm the planned egg handler.",
        {
            { key="coils_soak", kind="world", icon=6, label="Coils soak", purpose="Square is the full-raid Spectral Coils soak point." },
        },
        {
            "Confirm the Doomscale Egg handler and planned egg before pull.",
        }
    ),
    heroic = layout(
        "Keep the full-raid Coils marker and the same planned egg-handler setup as Normal.",
        {
            { key="coils_soak", kind="world", icon=6, label="Coils soak", purpose="Square is the full-raid Spectral Coils soak point." },
        },
        {
            "Confirm the Doomscale Egg handler and planned egg before pull.",
        }
    ),
    mythic = layout(
        "Mythic needs alternating Coils groups plus planned left/right egg-side references.",
        {
            { key="coils_soak", kind="world", icon=6, label="Coils soak", purpose="Square is the Spectral Coils soak point for the called group." },
            { key="egg_left", kind="world", icon=4, label="Left eggs", purpose="Triangle labels the planned left egg side." },
            { key="egg_right", kind="world", icon=7, label="Right eggs", purpose="Cross labels the planned right egg side." },
        },
        {
            "Set alternating Coil Groups A/B and choose the active egg side.",
            "Confirm left/right egg carriers and the 4+ Toxic Incubation intercept team.",
        }
    ),
})
