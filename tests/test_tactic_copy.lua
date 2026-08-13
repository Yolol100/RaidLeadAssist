local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
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

local Constants = ns:GetModule("Core.Constants")
local Registry = ns:GetModule("Encounters.Registry")
local encounters = Registry:GetOrdered()
assert(#encounters == 8)

local profileCount = 0
for _, encounter in ipairs(encounters) do
    for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
        local profile = Registry:GetProfile(encounter.key, difficultyKey)
        assert(profile, encounter.key .. "/" .. difficultyKey)
        profileCount = profileCount + 1
        assert(#profile.explanation >= 1 and #profile.explanation <= 8)
        for _, line in ipairs(profile.explanation) do assert(#line <= 110) end
        for _, call in ipairs(profile.calls) do
            assert(#call.action <= 70)
            assert(#call.warning <= 90)
        end
    end
end
assert(profileCount == 24)

local explorersNormal = Registry:GetProfile("explorers", "normal")
local explorersHeroic = Registry:GetProfile("explorers", "heroic")
assert(table.concat(explorersNormal.explanation, "\n") ~= table.concat(explorersHeroic.explanation, "\n"))

assert(Registry:GetProfile("vashnik", "normal").callsByKey.catalyst == nil)
assert(Registry:GetProfile("vashnik", "heroic").callsByKey.catalyst)
assert(Registry:GetProfile("vashnik", "mythic").callsByKey.totems)
assert(Registry:GetProfile("nekzali", "mythic").callsByKey.grasping)
assert(Registry:GetProfile("nekzali", "heroic").callsByKey.grasping == nil)
assert(Registry:GetProfile("sentinels", "mythic").callsByKey.protovenom)
assert(Registry:GetProfile("sszorak", "mythic").callsByKey.serpent)
assert(Registry:GetProfile("twinfangs", "mythic").callsByKey.blood)
assert(Registry:GetProfile("twinfangs", "mythic").callsByKey.brood)
assert(Registry:GetProfile("altar", "mythic").callsByKey.toxic)

for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
    for _, call in ipairs(Registry:GetProfile("ulatek", difficultyKey).calls) do
        assert(call.timing == false)
    end
end

assert(Registry:SetActiveDifficulty("normal"))
assert(Registry:Get("vashnik").callsByKey.catalyst == nil)
assert(Registry:SetActiveDifficulty("mythic"))
assert(Registry:Get("vashnik").callsByKey.totems)
assert(Registry:MatchCall("twinfangs", "mythic", 1308356, nil).key == "brood")
assert(Registry:SetActiveDifficulty("heroic"))

print("ok - difficulty profiles")
