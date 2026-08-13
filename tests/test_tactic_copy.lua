local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

_G.issecretvalue = function() return false end

T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)

local files = {
    "CoiledAltar.lua",
    "Explorers.lua",
    "Nekzali.lua",
    "Sentinels.lua",
    "Sszorak.lua",
    "TwinFangs.lua",
    "Ulatek.lua",
    "Vashnik.lua",
}
for _, file in ipairs(files) do
    T.Load("Encounters/VenomousAbyss/" .. file, ns)
end

local Registry = ns:GetModule("Encounters.Registry")
local encounters = Registry:GetOrdered()
assert(#encounters == 8, "expected all eight Venomous Abyss encounters")

for _, encounter in ipairs(encounters) do
    assert(#encounter.explanation >= 1 and #encounter.explanation <= 8, encounter.key .. " explanation line count")
    for _, line in ipairs(encounter.explanation) do
        assert(#line <= 100, encounter.key .. " explanation line is too dense: " .. line)
    end
    for _, call in ipairs(encounter.calls) do
        assert(#call.action <= 60, encounter.key .. "/" .. call.key .. " button action is too dense")
        assert(#call.warning <= 80, encounter.key .. "/" .. call.key .. " raid warning is too dense")
    end
end

local altar = Registry:Get("altar")
assert(altar.callsByKey.guillotine.warning:find("5+", 1, true), "Guillotine must state the minimum soak size")
assert(Registry:MatchCall("altar", 1283489, nil).key == "guillotine")
assert(Registry:MatchCall("altar", 1289900, nil).key == "dreadmarch")

local explorers = Registry:Get("explorers")
assert(explorers.callsByKey.thud.warning:find("3 TARGETS", 1, true), "Mighty Thud must explain the three targets")
assert(Registry:MatchCall("explorers", 1296092, nil).key == "thud")

local nekzali = Registry:Get("nekzali")
assert(not nekzali.callsByKey.rend.warning:find("DISPEL", 1, true), "Essence Rend must not claim an unsupported dispel")
assert(nekzali.callsByKey.pyre.warning:find("AMANI REMAINS", 1, true), "Pyre must explain where flame targets go")
assert(Registry:MatchCall("nekzali", 1305421, nil).key == "pyre")

local sentinels = Registry:Get("sentinels")
assert(sentinels.callsByKey.droplets.warning:find("STEP ON", 1, true), "Toxic Droplets must tell players to step on them")
assert(not sentinels.callsByKey.droplets.warning:find("SOAK", 1, true), "Toxic Droplets must not be mislabeled as a soak")
assert(Registry:MatchCall("sentinels", 1284434, nil).key == "droplets")

local sszorak = Registry:Get("sszorak")
assert(sszorak.callsByKey.apex and sszorak.callsByKey.apex.warning:find("5+", 1, true), "Apex Predator Mutilate soak call is required")
assert(Registry:MatchCall("sszorak", 1277025, nil).key == "apex")

local twinFangs = Registry:Get("twinfangs")
assert(twinFangs.callsByKey.feast.warning:find("ROTATE", 1, true), "Heroic Ravenous Feast must call the soak rotation")
assert(Registry:MatchCall("twinfangs", 1290516, nil).key == "feast")

local vashnik = Registry:Get("vashnik")
assert(vashnik.callsByKey.froth, "Plague Froth needs a raid-leader call")
assert(Registry:MatchCall("vashnik", 1281907, nil).key == "froth")

local ulatek = Registry:Get("ulatek")
for _, call in ipairs(ulatek.calls) do
    assert(call.timing == false, "Ula'tek automatic timing must remain disabled before live validation")
end

print("ok - source-reviewed tactic copy and critical call mappings")
