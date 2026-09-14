local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
T.Load("Encounters/SetupRegistry.lua", ns)
T.Load("Encounters/VenomousAbyss/SetupLayouts.lua", ns)
T.Load("Services/SetupService.lua", ns)
local Registry = ns:GetModule("Encounters.SetupRegistry")
local Setup = ns:GetModule("Services.SetupService")

local function counts(bossKey, difficultyKey, world, target, checks)
    local actualWorld, actualTarget, actualChecks = Registry:GetCounts(bossKey, difficultyKey)
    assert(actualWorld == world, bossKey .. "/" .. difficultyKey .. " world marker count")
    assert(actualTarget == target, bossKey .. "/" .. difficultyKey .. " target marker count")
    assert(actualChecks == checks, bossKey .. "/" .. difficultyKey .. " setup check count")
end

for _, bossKey in ipairs({"nekzali","sentinels","explorers","vashnik","sszorak","twinfangs","altar","ulatek"}) do
    counts(bossKey, "normal", 0, 0, 0)
end
counts("nekzali", "heroic", 0, 0, 1); counts("nekzali", "mythic", 0, 0, 2)
counts("sentinels", "heroic", 2, 0, 1); counts("sentinels", "mythic", 2, 0, 1)
counts("explorers", "heroic", 3, 0, 1); counts("explorers", "mythic", 3, 0, 1)
counts("vashnik", "heroic", 0, 0, 2); counts("vashnik", "mythic", 0, 2, 1)
counts("sszorak", "heroic", 4, 0, 2); counts("sszorak", "mythic", 3, 0, 1)
counts("twinfangs", "heroic", 0, 0, 3); counts("twinfangs", "mythic", 0, 0, 2)
counts("altar", "heroic", 2, 0, 2); counts("altar", "mythic", 2, 0, 2)
counts("ulatek", "heroic", 3, 0, 2); counts("ulatek", "mythic", 3, 0, 2)

local sentinels = Registry:GetLayout("sentinels", "heroic")
assert(sentinels.markers[1].icon == 7 and sentinels.markers[1].label == "Red side")
assert(sentinels.markers[2].icon == 4 and sentinels.markers[2].label == "Green side")
local ssz = Registry:GetLayout("sszorak", "heroic")
assert(#ssz.markers == 4)
assert(ssz.markers[1].icon == 6 and ssz.markers[2].icon == 5,
    "Blue must be opposite Moon")
assert(ssz.markers[3].icon == 7 and ssz.markers[4].icon == 4,
    "X must be opposite Green")
assert(Registry:GetLayout("vashnik", "heroic").summary:find("Purple/Shadow + Orange/Fire", 1, true))
assert(Registry:GetLayout("twinfangs", "heroic").checks[1]:find("raid soaks", 1, true))

Setup:Initialize()
assert(not Setup:IsReady("sszorak", "heroic"))
assert(Setup:Toggle("sszorak", "heroic") == true)
assert(Setup:IsReady("sszorak", "heroic"))
assert(Setup:Toggle("sszorak", "heroic") == false)
assert(not Setup:IsReady("sszorak", "heroic"))
assert(Setup:IsReady("nekzali", "normal"), "unsupported Normal has no setup and is inert")

print("ok - pre-pull setup exposes only current Heroic/Mythic marker contracts")
