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
local bossKeys = { "nekzali", "sentinels", "explorers", "vashnik", "sszorak", "twinfangs", "altar", "ulatek" }
local difficulties = { "heroic", "mythic" }

local function wordCount(value)
    local count = 0
    for _ in tostring(value or ""):gmatch("%S+") do count = count + 1 end
    return count
end

local function cleanText(value)
    return type(value) == "string"
        and value ~= ""
        and not value:find("[\r\n]")
        and not value:find("[%z\1-\8\11\12\14-\31\127]")
end

for _, bossKey in ipairs(bossKeys) do
    assert(Registry:GetProfile(bossKey, "normal") == nil,
        bossKey .. " Normal profile must stay retired")

    for _, difficultyKey in ipairs(difficulties) do
        local profile = assert(Registry:GetProfile(bossKey, difficultyKey),
            bossKey .. "/" .. difficultyKey .. " profile is missing")
        local label = bossKey .. "/" .. difficultyKey
        assert(type(profile.calls) == "table" and #profile.calls > 0,
            label .. " must expose raid-lead calls")

        local seen = {}
        for _, call in ipairs(profile.calls) do
            local callLabel = label .. "/" .. tostring(call.key)
            assert(type(call.key) == "string" and call.key ~= "", callLabel .. " key is missing")
            assert(not seen[call.key], callLabel .. " key is duplicated")
            seen[call.key] = true

            assert(cleanText(call.action), callLabel .. " action must be clean single-line text")
            assert(cleanText(call.warning), callLabel .. " warning must be clean single-line text")
            assert(not call.action:find(" > ", 1, true), callLabel .. " action should read naturally")
            assert(not call.warning:find(" > ", 1, true), callLabel .. " warning should read naturally")
            assert(not call.action:lower():find("raid leader", 1, true), callLabel .. " action must not contain operator meta-language")
            assert(not call.warning:lower():find("raid leader", 1, true), callLabel .. " warning must not contain operator meta-language")
            assert(wordCount(call.action) <= 12, callLabel .. " action exceeds the glance target")
            assert(wordCount(call.warning) <= 14, callLabel .. " warning exceeds the rapid-call target")
            assert(#call.action <= 96, callLabel .. " action is too long for glance reading")
            assert(#call.warning <= 160, callLabel .. " warning is too long for rapid parsing")
        end
    end
end

assert(Registry:GetProfile("nekzali", "heroic").callsByKey.flame == nil,
    "Cremation is a personal execution mechanic and must stay out of Heroic raid-lead buttons")
assert(not Registry:GetProfile("twinfangs", "heroic").callsByKey.adds.warning:lower():find("spit", 1, true),
    "Twin Fangs add call should keep personal spit handling in the Boss Plan/bossmod layer")

_G.issecretvalue = nil
print("ok - Heroic/Mythic raid-lead calls stay unique, clean, concise and operator-focused")
