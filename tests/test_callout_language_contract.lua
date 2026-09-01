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
        normal = { "adds", "barrage", "echoes", "pyre", "phase2" },
        heroic = { "adds", "barrage", "echoes", "pyre", "phase2" },
        mythic = { "adds", "barrage", "grasping", "echoes", "pyre", "phase2" },
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
        normal = { "venom", "crosswinds", "maelstrom", "apex", "dig_in" },
        heroic = { "venom", "crosswinds", "maelstrom", "apex", "dig_in" },
        mythic = { "venom", "crosswinds", "maelstrom", "apex", "dig_in", "serpent" },
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

local function wordCount(value)
    local count = 0
    for _ in tostring(value or ""):gmatch("%S+") do count = count + 1 end
    return count
end

for bossKey, difficulties in pairs(expectedCalls) do
    for difficultyKey, expected in pairs(difficulties) do
        local profile = assert(Registry:GetProfile(bossKey, difficultyKey))
        local label = bossKey .. "/" .. difficultyKey
        sameKeys(profile, expected, label)

        for _, call in ipairs(profile.calls) do
            local callLabel = label .. "/" .. call.key
            assert(call.action:find("%l"), callLabel .. " action should use sentence case")
            assert(call.warning:find("%l"), callLabel .. " warning should use sentence case")
            assert(not call.action:find(" > ", 1, true), callLabel .. " action should read as natural language")
            assert(not call.warning:find(" > ", 1, true), callLabel .. " warning should read as natural language")
            assert(not call.action:lower():find("raid leader", 1, true), callLabel .. " action must not contain operator meta-language")
            assert(not call.warning:lower():find("raid leader", 1, true), callLabel .. " warning must not contain operator meta-language")
            assert(call.warning:find(":", 1, true), callLabel .. " warning should use cue: action structure")
            assert(call.warning:sub(-1) == ".", callLabel .. " warning should be a complete short sentence")
            assert(wordCount(call.action) <= 7, callLabel .. " action exceeds 7-word glance target")
            assert(wordCount(call.warning) <= 9, callLabel .. " warning exceeds 9-word rapid-call target")
            assert(#call.action <= 64, callLabel .. " action is too long for glance reading")
            assert(#call.warning <= 96, callLabel .. " warning is too long for rapid parsing")
        end
    end
end

assert(Registry:GetProfile("nekzali", "heroic").callsByKey.flame == nil,
    "Cremation is a personal execution mechanic and must stay out of raidleader buttons")

local barrageProfile = Registry:GetProfile("nekzali", "heroic")
local barrage = assert(barrageProfile.callsByKey.barrage, "Nek'zali needs the timed Possession Barrage raidleader call")
assert(barrageProfile.spellMap[1292036] == "barrage", "BigWigs Possession Barrage ID must map to the barrage call")
assert(barrageProfile.spellMap[1284103] == "barrage", "DBM Possession Barrage ID must map to the barrage call")
assert(barrage.prepareSeconds == 7 and barrage.pressSeconds == 4,
    "Possession Barrage should arm the raidleader button before the provider timer expires")

local stasis = assert(Registry:GetProfile("sentinels", "heroic").callsByKey.stasis)
assert(stasis.prepareSeconds == 6 and stasis.pressSeconds == 2,
    "Vitriolic Stasis partner call should remain synced to the provider timer")
assert(stasis.warning:lower():find("spread", 1, true)
        and stasis.warning:find("1+3", 1, true)
        and stasis.warning:find("2+2", 1, true),
    "Vitriolic Stasis warning should tell the raid to spread and find the correct partner")

assert(not Registry:GetProfile("twinfangs", "normal").callsByKey.adds.warning:lower():find("spit", 1, true),
    "Twin Fangs add call should keep personal spit handling in the Boss Plan/bossmod layer")

print("ok - shared raidleader calls stay cue-first, single-step and glanceable")
