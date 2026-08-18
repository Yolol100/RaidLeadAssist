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

Setup:RegisterLayouts("sentinels", sameForAll(layout(
    "Lock the two physical raid sides before pull; groups stay on those sides when the bosses swap.",
    {
        { key="breath_side", kind="world", icon=4, label="Breath side", purpose="Triangle marks Team A / Breath of Ula'tek starting side." },
        { key="blood_side", kind="world", icon=7, label="Blood side", purpose="Cross marks Team B / Blood of Ula'tek starting side." },
    },
    {
        "Confirm Team A starts at Triangle and Team B starts at Cross.",
        "Keep the same physical sides after Stasis; tanks swap the bosses across the groups.",
    }
)))

Setup:RegisterLayouts("explorers", sameForAll(layout(
    "Pre-place three distinct Mighty Thud soak points so marked players separate without improvising.",
    {
        { key="thud_one", kind="world", icon=1, label="Thud 1", purpose="Star is the first Mighty Thud soak point." },
        { key="thud_two", kind="world", icon=2, label="Thud 2", purpose="Circle is the second Mighty Thud soak point." },
        { key="thud_three", kind="world", icon=3, label="Thud 3", purpose="Diamond is the third Mighty Thud soak point." },
    },
    {
        "Leave enough spacing between all three soak points for separate Mighty Thud impacts.",
    }
)))

Setup:RegisterLayouts("vashnik", {
    normal = layout(
        "Normal has no fixed raidleader marker setup; use the Boss Plan and personal bossmod warnings.",
        {},
        {}
    ),
    heroic = layout(
        "Reserve Skull then Cross for the staggered Burning Venom kill order.",
        {
            { key="fire_first", kind="target", icon=8, label="Fire add first", purpose="Skull is the first Burning Venom kill target." },
            { key="fire_second", kind="target", icon=7, label="Fire add second", purpose="Cross is the second Burning Venom target; wait before killing it." },
        },
        {
            "Raid leader owns the Skull then Cross kill order for each Fire pair.",
        }
    ),
    mythic = layout(
        "Reserve Skull then Cross for the staggered Burning Venom kill order.",
        {
            { key="fire_first", kind="target", icon=8, label="Fire add first", purpose="Skull is the first Burning Venom kill target." },
            { key="fire_second", kind="target", icon=7, label="Fire add second", purpose="Cross is the second Burning Venom target; wait before killing it." },
        },
        {
            "Raid leader owns the Skull then Cross kill order for each Fire pair.",
        }
    ),
})

Setup:RegisterLayouts("sszorak", sameForAll(layout(
    "Place one cyst-drop marker opposite each tornado cluster before pull and keep the center clear.",
    {
        { key="cyst_one", kind="world", icon=1, label="Cyst 1", purpose="Star marks the first planned Cyst drop opposite a tornado cluster." },
        { key="cyst_two", kind="world", icon=2, label="Cyst 2", purpose="Circle marks the second planned Cyst drop opposite a tornado cluster." },
        { key="cyst_three", kind="world", icon=3, label="Cyst 3", purpose="Diamond marks the third planned Cyst drop opposite a tornado cluster." },
    },
    {
        "Confirm each marker is opposite a different tornado cluster.",
        "Confirm Cyst Poppers 1/2/3 know which prepared Cyst they own.",
    }
)))

Setup:RegisterLayouts("altar", sameForAll(layout(
    "Mark both platform ends so orb collection, Soul Sever and ghost routing use stable references all fight.",
    {
        { key="sever_end", kind="world", icon=4, label="Sever end", purpose="Triangle marks the active orb collection / Sever reference end." },
        { key="soul_end", kind="world", icon=7, label="Soul Sever end", purpose="Cross marks the opposite Soul Sever / ghost routing reference end." },
    },
    {
        "Confirm both platform ends are marked before pull.",
        "Reuse these same two reference ends in Phase 3 instead of inventing new positions.",
    }
)))

Setup:RegisterLayouts("ulatek", sameForAll(layout(
    "Give Spectral Coils a fixed soak reference and label both planned egg sides before pull.",
    {
        { key="coils_soak", kind="world", icon=6, label="Coils soak", purpose="Square is the Spectral Coils raid soak point." },
        { key="egg_left", kind="world", icon=4, label="Left eggs", purpose="Triangle labels the planned left egg side." },
        { key="egg_right", kind="world", icon=7, label="Right eggs", purpose="Cross labels the planned right egg side." },
    },
    {
        "Confirm the active egg plan names Triangle or Cross before pull.",
        "Keep Caustic Waves away from unplanned eggs and the Square soak reference.",
    }
)))

Setup:RegisterLayouts("nekzali", sameForAll(layout(
    "No fixed world or target markers are required by the current raidleader plan.",
    {},
    {}
)))

Setup:RegisterLayouts("twinfangs", sameForAll(layout(
    "No fixed raidleader marker setup is required; mechanic-generated marks remain bossmod-owned.",
    {},
    {}
)))
