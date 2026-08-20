local T = dofile("tests/testlib.lua")
local ns = T.NewNamespace()

_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/VenomousAbyss/Explorers.lua", ns)

local Registry = ns:GetModule("Encounters.Registry")
for _, difficulty in ipairs({ "normal", "heroic", "mythic" }) do
    local finalAscension = Registry:MatchCall("explorers", difficulty, 1292779, "Final Ascension")
    assert(finalAscension and finalAscension.key == "fish",
        difficulty .. ": Final Ascension must remain the RLA fish-order timing identity")

    local flingFish = Registry:MatchCall("explorers", difficulty, 1295817, "Fling Fish")
    assert(flingFish == nil,
        difficulty .. ": BigWigs Fling Fish bar must not alias the separate Final Ascension raidleader call")

    local throwJunk = Registry:MatchCall("explorers", difficulty, 1291933, "Throw Junk")
    assert(throwJunk and throwJunk.key == "crates",
        difficulty .. ": Throw Junk must remain the crates call after BigWigs count-reset changes")
end

print("ok - current BigWigs Fling Fish remains isolated from RLA Final Ascension while Throw Junk stays mapped to crates")
