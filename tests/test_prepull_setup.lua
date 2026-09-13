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

local altarNormal = Registry:GetLayout("altar", "normal")
local altarHeroic = Registry:GetLayout("altar", "heroic")
local altarMythic = Registry:GetLayout("altar", "mythic")
assert(altarNormal.checks[2]:find("3+ soakers", 1, true),
    "Normal setup must reflect Blizzard's live 3-player Guillotine minimum")
assert(altarHeroic.checks[2]:find("two different 3+ Guillotine groups", 1, true),
    "Heroic setup must match the 3+ assignment validation")
assert(altarMythic.checks[2]:find("fresh 5+ Guillotine groups", 1, true),
    "Mythic setup must preserve the separate fresh 5+ contract")

local ulatekNormal = Registry:GetLayout("ulatek", "normal")
local ulatekHeroic = Registry:GetLayout("ulatek", "heroic")
assert(ulatekNormal.markers[1].purpose:find("40%+ raid", 1, true),
    "Normal Ula'tek setup marker must match the live Spectral Coils floor")
assert(#ulatekHeroic.markers == 1 and ulatekHeroic.markers[1].icon == 6,
    "Ula'tek Heroic keeps only the Coils marker")
assert(ulatekHeroic.markers[1].purpose:find("40%+ raid", 1, true),
    "Heroic Ula'tek setup marker must match the live Spectral Coils floor")
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
