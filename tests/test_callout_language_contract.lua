local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
for _, file in ipairs({
    "CoiledAltar.lua",
    "Explorers.lua",
    "Nekzali.lua",
    "Sentinels.lua",
    "Sszorak.lua",
    "TwinFangs.lua",
    "Ulatek.lua",
    "Vashnik.lua",
}) do
    T.Load("Encounters/VenomousAbyss/" .. file, ns)
end

local Registry = ns:GetModule("Encounters.Registry")

local expectedCalls = {
    nekzali = {
        normal = { "adds", "echoes", "pyre", "phase2" },
        heroic = { "adds", "echoes", "pyre", "phase2" },
        mythic = { "adds", "grasping", "echoes", "pyre", "phase2" },
    },
    sentinels = {
        normal = { "coagulation", "miasma", "stasis", "side_swap", "balance_stop_breath", "balance_stop_blood", "balance_resume" },
        heroic = { "coagulation", "miasma", "stasis", "side_swap", "balance_stop_breath", "balance_stop_blood", "balance_resume" },
        mythic = { "coagulation", "miasma", "stasis", "side_swap", "balance_stop_breath", "balance_stop_blood", "balance_resume", "protovenom" },
    },
    explorers = {
        normal = { "crates", "fish", "thud" },
        heroic = { "crates", "fish", "thud" },
        mythic = { "crates", "fish", "thud" },
    },
    vashnik = {
        normal = { "imbibe", "siphon" },
        heroic = { "imbibe", "fire_stagger", "siphon", "catalyst" },
        mythic = { "imbibe", "fire_stagger", "siphon", "catalyst", "froth", "tumors" },
    },
    sszorak = {
        normal = { "venom", "crosswinds", "maelstrom", "apex" },
        heroic = { "venom", "crosswinds", "maelstrom", "apex" },
        mythic = { "venom", "crosswinds", "maelstrom", "apex", "serpent" },
    },
    twinfangs = {
        normal = { "globules", "adds", "feast", "energy" },
        heroic = { "globules", "adds", "feast", "energy" },
        mythic = { "globules", "adds", "feast", "tainted", "bulwark", "brood", "energy" },
    },
    altar = {
        normal = { "toxic", "guillotine", "dreadmarch", "nightfall", "spiritcackle", "intermission", "final" },
        heroic = { "toxic", "guillotine", "dreadmarch", "nightfall", "spiritcackle", "intermission", "final" },
        mythic = { "toxic", "guillotine", "dreadmarch", "nightfall", "spiritcackle", "gloombomb", "intermission", "final" },
    },
    ulatek = {
        normal = { "coils", "warden", "eggs", "serpents", "heart", "phase3", "demolish" },
        heroic = { "coils", "warden", "eggs", "serpents", "heart", "fangs", "phase3", "demolish" },
        mythic = { "coils", "warden", "eggs", "serpents", "heart", "fangs", "incubation", "phase3", "demolish" },
    },
}

local function sameKeys(profile, expected, label)
    assert(#profile.calls == #expected, label .. " should expose only shared raidleader callouts")
    for index, key in ipairs(expected) do
        assert(profile.calls[index].key == key, label .. " call order drift at " .. index)
    end
end

for bossKey, difficulties in pairs(expectedCalls) do
    for difficultyKey, expected in pairs(difficulties) do
        local profile = assert(Registry:GetProfile(bossKey, difficultyKey))
        local label = bossKey .. "/" .. difficultyKey
        sameKeys(profile, expected, label)

        for _, call in ipairs(profile.calls) do
            assert(call.action:find("%l"), label .. "/" .. call.key .. " action should use sentence case")
            assert(call.warning:find("%l"), label .. "/" .. call.key .. " warning should use sentence case")
            assert(not call.action:find(" > ", 1, true), label .. "/" .. call.key .. " action should read as natural language")
            assert(not call.warning:find(" > ", 1, true), label .. "/" .. call.key .. " warning should read as natural language")
            assert(not call.action:lower():find("raid leader", 1, true), label .. "/" .. call.key .. " action must not contain operator meta-language")
            assert(not call.warning:lower():find("raid leader", 1, true), label .. "/" .. call.key .. " warning must not contain operator meta-language")
            assert(call.warning:find(":", 1, true), label .. "/" .. call.key .. " warning should use cue: action structure")
            assert(call.warning:sub(-1) == ".", label .. "/" .. call.key .. " warning should be a complete short sentence")
            assert(#call.action <= 64, label .. "/" .. call.key .. " action is too long for glance reading")
            assert(#call.warning <= 96, label .. "/" .. call.key .. " warning is too long for rapid parsing")
        end
    end
end

assert(Registry:GetProfile("nekzali", "heroic").callsByKey.flame == nil,
    "Cremation is a personal execution mechanic and must stay out of raidleader buttons")
assert(not Registry:GetProfile("twinfangs", "normal").callsByKey.adds.warning:lower():find("spit", 1, true),
    "Twin Fangs add call should keep personal spit handling in the Boss Plan/bossmod layer")

print("ok - callout copy uses concise cue-action language and only shared raidleader calls")
