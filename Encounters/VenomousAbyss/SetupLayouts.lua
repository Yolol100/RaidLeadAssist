local _, ns = ...
local Setup = ns:GetModule("Encounters.SetupRegistry")

local function layout(summary, markers, checks)
    return { summary=summary, markers=markers or {}, checks=checks or {} }
end

Setup:RegisterLayouts("nekzali", {
    heroic=layout("Heroic uses BL on pull and no fixed roster assignment.", {}, {"Melee+tank handle the called Pyre soak; ranged remain outside."}),
    mythic=layout("Keep the Mythic Pyre group and two fresh Grasping Depths groups.", {}, {"Set the Pyre soak group.", "Set two different well groups for alternating Grasping Depths entries."}),
})

Setup:RegisterLayouts("sentinels", {
    heroic=layout("RED/GREEN sides use the dynamic populated-subgroup split.", {
        {key="red_side", kind="world", icon=7, label="Red side", purpose="Cross marks the red-side reference."},
        {key="green_side", kind="world", icon=4, label="Green side", purpose="Triangle marks the green-side reference."},
    }, {"Briefing generates the closest balanced whole-group RED/GREEN split from the current roster.", "After Stasis, raid groups return to their physical side while tanks swap Sentinels."}),
    mythic=layout("Set two fixed physical Mythic sides; players hold sides while tanks swap bosses after Stasis.", {
        {key="green_side", kind="world", icon=4, label="Green side", purpose="Triangle is the green-side reference."},
        {key="red_side", kind="world", icon=7, label="Red side", purpose="Cross is the red-side reference."},
    }, {"Assign the two non-overlapping Mythic sides before pull."}),
})

local thudMarkers = {
    {key="thud_one", kind="world", icon=1, label="Thud 1", purpose="Star is Mighty Thud soak point 1."},
    {key="thud_two", kind="world", icon=2, label="Thud 2", purpose="Circle is Mighty Thud soak point 2."},
    {key="thud_three", kind="world", icon=3, label="Thud 3", purpose="Diamond is Mighty Thud soak point 3."},
}
Setup:RegisterLayouts("explorers", {
    heroic=layout("Place the three Mighty Thud soak points; Heroic fish order is Gebbo → Nama → Iku.", thudMarkers, {"Fish: Gebbo → Nama → Iku."}),
    mythic=layout("Keep the Thud points and assign a controlled crate rotation for 15+ yard clearance.", thudMarkers, {"Assign the crate rotation; raid clears 15+ yards before each break."}),
})

Setup:RegisterLayouts("vashnik", {
    heroic=layout("Heroic uses the current Purple/Shadow + Orange/Fire-only strategy.", {}, {"Keep the fight on Purple + Orange; do not use the old Blood/Red Heroic rotation.", "Stagger dangerous dispels/deaths and keep the cross/wave lane clear."}),
    mythic=layout("Mythic keeps its separate fountain/tumor execution.", {
        {key="fire_first", kind="target", icon=8, label="Fire add first", purpose="Skull is the first Burning Venom kill target."},
        {key="fire_second", kind="target", icon=7, label="Fire add second", purpose="Cross follows after the first Fire DoT ends."},
    }, {"Do not inherit the simplified Heroic Purple+Orange profile without a Mythic-specific call."}),
})

Setup:RegisterLayouts("sszorak", {
    heroic=layout("Use four outer markers: Blue opposite Moon; X opposite Green. BLUE/X teams are generated dynamically.", {
        {key="blue_team", kind="world", icon=6, label="Blue team", purpose="Square/Blue is the first raid-team reference."},
        {key="moon_opposite", kind="world", icon=5, label="Moon opposite Blue", purpose="Moon is directly opposite the Blue marker for the cyst/wind lane."},
        {key="x_team", kind="world", icon=7, label="X team", purpose="Cross/X is the second raid-team reference."},
        {key="green_opposite", kind="world", icon=4, label="Green opposite X", purpose="Triangle/Green is directly opposite X for the cyst/wind lane."},
    }, {"Briefing generates the closest balanced whole-group BLUE/X split from the current roster.", "Place cysts at the called wind mark and pop only one when the wind call occurs."}),
    mythic=layout("Mythic keeps saved-Cyst markers, Mutilate groups and Cyst Poppers.", {
        {key="cyst_one", kind="world", icon=1, label="Cyst 1", purpose="Star is the first saved Cyst position."},
        {key="cyst_two", kind="world", icon=2, label="Cyst 2", purpose="Circle is the second saved Cyst position."},
        {key="cyst_three", kind="world", icon=3, label="Cyst 3", purpose="Diamond is the third saved Cyst position."},
    }, {"Assign Poppers 1/2/3 and two different Mutilate soak groups."}),
})

Setup:RegisterLayouts("twinfangs", {
    heroic=layout("Heroic uses three fresh Ravenous Feast soak teams.", {}, {"Assign three non-overlapping Feast teams before pull.", "Each player soaks at most one of the three Feast hits; Feasted makes repeat hits unsafe."}),
    mythic=layout("Mythic keeps three Feast groups and Broodling interrupt owners.", {}, {"Set three different 3+ Feast groups.", "Assign Broodling interrupts."}),
})

local altarMarkers = {
    {key="sever_end", kind="world", icon=4, label="Orb / Sever end", purpose="Triangle is the orb collection and Sever reference end."},
    {key="soul_end", kind="world", icon=7, label="Ghost / Soul Sever end", purpose="Cross is the ghost routing and Soul Sever reference end."},
}
Setup:RegisterLayouts("altar", {
    heroic=layout("Use both platform-end markers; prepare Orb Collectors, Guillotine groups and Wail interrupts.", altarMarkers, {"Assign 2-3 Orb Collectors.", "Assign two different 3+ Guillotine groups and at least two Wail kicks."}),
    mythic=layout("Use the same markers; prepare fresh Guillotine groups and Wail interrupts.", altarMarkers, {"Assign 2-3 Orb Collectors.", "Plan fresh 5+ Guillotine groups and at least two Wail kicks."}),
})

local ulatekMarkers = {
    {key="coils_soak", kind="world", icon=6, label="Coils reference", purpose="Square is the shared Spectral Coils reference."},
    {key="egg_left", kind="world", icon=4, label="Left side", purpose="Triangle labels the left Phase 2 side."},
    {key="egg_right", kind="world", icon=7, label="Right side", purpose="Cross labels the right Phase 2 side."},
}
Setup:RegisterLayouts("ulatek", {
    heroic=layout("Mark left/right sides and pre-split two alternating Coils teams plus three Bite helper sectors.", ulatekMarkers, {"Assign two near-equal Coils/side teams and left/right egg carriers.", "Assign melee, ranged and healer Bite helper groups."}),
    mythic=layout("Mythic keeps alternating Coils teams, egg lanes, Bite helper sectors and Incubation intercepts.", ulatekMarkers, {"Assign alternating Coils teams, egg carriers and Bite groups.", "Assign a 4+ Toxic Incubation intercept group."}),
})