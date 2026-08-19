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

for _, difficultyKey in ipairs({ "normal", "heroic", "mythic" }) do
    counts("sentinels", difficultyKey, 2, 0, 2)
    counts("explorers", difficultyKey, 3, 0, 2)
    counts("sszorak", difficultyKey, 3, 0, 2)
    counts("altar", difficultyKey, 2, 0, 2)
end

counts("nekzali", "normal", 0, 0, 0)
counts("nekzali", "heroic", 0, 0, 2)
counts("nekzali", "mythic", 0, 0, 2)

counts("vashnik", "normal", 0, 0, 2)
counts("vashnik", "heroic", 0, 2, 2)
counts("vashnik", "mythic", 0, 2, 2)

counts("twinfangs", "normal", 0, 0, 1)
counts("twinfangs", "heroic", 0, 0, 1)
counts("twinfangs", "mythic", 0, 0, 2)

counts("ulatek", "normal", 1, 0, 1)
counts("ulatek", "heroic", 1, 0, 1)
counts("ulatek", "mythic", 3, 0, 2)

local sentinels = Registry:GetLayout("sentinels", "heroic")
assert(sentinels.markers[1].icon == 4 and sentinels.markers[1].label == "Green / Breath side")
assert(sentinels.markers[2].icon == 7 and sentinels.markers[2].label == "Red / Blood side")

local vashnik = Registry:GetLayout("vashnik", "heroic")
assert(vashnik.markers[1].kind == "target" and vashnik.markers[1].icon == 8, "Vashnik first Fire target must be Skull")
assert(vashnik.markers[2].kind == "target" and vashnik.markers[2].icon == 7, "Vashnik second Fire target must be Cross")

local ulatekHeroic = Registry:GetLayout("ulatek", "heroic")
assert(#ulatekHeroic.markers == 1 and ulatekHeroic.markers[1].icon == 6,
    "Ula'tek Heroic keeps only the full-raid Coils marker")
local ulatekMythic = Registry:GetLayout("ulatek", "mythic")
assert(#ulatekMythic.markers == 3,
    "Ula'tek Mythic adds both egg-side markers to the Coils marker")

Setup:Initialize()
assert(not Setup:IsReady("sszorak", "heroic"), "required setup starts unchecked each addon session")
assert(Setup:Toggle("sszorak", "heroic") == true, "setup can be manually confirmed")
assert(Setup:IsReady("sszorak", "heroic"), "manual confirmation makes setup ready")
assert(Setup:Toggle("sszorak", "heroic") == false, "setup confirmation can be revoked")
assert(not Setup:IsReady("sszorak", "heroic"), "revoked setup returns to check")
assert(Setup:IsReady("nekzali", "normal"), "bosses without setup are ready by definition")

Setup:SetReady("altar", "heroic", true)
Setup:Initialize()
assert(not Setup:IsReady("altar", "heroic"), "setup readiness must not persist across addon initialization")

print("ok - pre-pull marker and raidleader-prep contracts")
