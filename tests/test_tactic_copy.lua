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
assert(#encounters == 8, "expected all eight Venomous Abyss encounters")

for _, encounter in ipairs(encounters) do
    for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
        local profile = Registry:GetProfile(encounter.key, difficultyKey)
        assert(profile, encounter.key .. " missing " .. difficultyKey .. " profile")
        assert(#profile.explanation >= 1 and #profile.explanation <= 8, encounter.key .. "/" .. difficultyKey .. " explanation line count")
        for _, line in ipairs(profile.explanation) do
            assert(#line <= 110, encounter.key .. "/" .. difficultyKey .. " explanation line is too dense: " .. line)
        end
        for _, call in ipairs(profile.calls) do
            assert(#call.action <= 70, encounter.key .. "/" .. difficultyKey .. "/" .. call.key .. " button action is too dense")
            assert(#call.warning <= 90, encounter.key .. "/" .. difficultyKey .. "/" .. call.key .. " raid warning is too dense")
        end
    end
end

local explorersN = Registry:GetProfile("explorers", "normal")
local explorersH = Registry:GetProfile("explorers", "heroic")
assert(explorersN.explanation[1]:find("STACK ALL 3", 1, true), "Normal Explorers should use cleave stack plan")
assert(explorersH.explanation[1]:find("30+ YARDS APART", 1, true), "Heroic Explorers must separate all three bosses")

assert(Registry:GetProfile("vashnik", "normal").callsByKey.catalyst == nil, "Catalyst must not appear on Normal")
assert(Registry:GetProfile("vashnik", "heroic").callsByKey.catalyst, "Catalyst must appear on Heroic")
assert(Registry:GetProfile("vashnik", "mythic").callsByKey.totems, "Mythic Vashnik needs a totem call")

assert(Registry:GetProfile("nekzali", "mythic").callsByKey.grasping, "Mythic Nekzali needs Grasping Depths")
assert(Registry:GetProfile("nekzali", "heroic").calsByKey.grasping == nil, "Grasping Depths must be Mythic-only")
assert(Registry:GetProfile("sentinels", "mythic").callsByKey.protovenom, "Mythic Sentinels need Protovenom call")
assert(Registry:GetProfile("sszorak", "mythic").calsByKey.serpent, "Mythic Sszorak needs Serpent's Fury call")
assert(Registry:GetProfile("twinfangs", "mythic").callsByKey.blood, "Mythic Twin Fangs need Blood Torrent call")
assert(Registry:GetProfile("twinfangs", "mythic").callsByKey.brood, "Mythic Twin Fangs need Brood call")
assert(Registry:GetProfile("altar", "mythic").calsByKey.guillotine.warning:find("FRESH 5+", 1, true), "Mythic Guillotine must use fresh soak teams")

for _, difficultyKey in ipairs(Constants.DIFFICULTY_ORDER) do
    for _, call in ipairs(Registry:GetProfile("ulatek", difficultyKey).calls) do
        assert(call.timing == false, "Ula'tek automatic timing must remain disabled before live validation")
    end
end

assert(Registry:SetActiveDifficulty("normal"))
assert(Registry:Get("vashnik").calsByKey.catalyst == nil, "active Normal alias must hide Heroic-only call")
assert(Registry:SetActiveDifficulty("mythic"))
assert(Registry:Get("vashnik").callsByKey.totems, "active Mythic alias must expose Mythic call")
assert(Registry:MatchCall("twinfangs", "mythic", 1308356, nil).key == "brood")
assert(Registry:SetActiveDifficulty("heroic"))

print("ok - 24 difficulty plans and critical difficulty-specific calls")
