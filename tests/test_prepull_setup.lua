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
    counts("explorers", difficultyKey, 3, 0, 1)
    counts("sszorak", difficultyKey, 3, 0, 2)
    counts("altar", difficultyKey, 2, 0, 2)
    counts("ulatek", difficultyKey, 3, 0, 2)
    counts("nekzali", difficultyKey, 0, 0, 0)
    counts("twinfangs", difficultyKey, 0, 0, 0)
end

counts("vashnik", "normal", 0, 0, 0)
counts("vashnik", "heroic", 0, 2, 1)
counts("vashnik", "mythic", 0, 2, 1)

local sentinels = Registry:GetLayout("sentinels", "heroic")
assert(sentinels.markers[1].icon == 4 and sentinels.markers[1].label == "Breath side")
assert(sentinels.markers[2].icon == 7 and sentinels.markers[2].label == "Blood side")

local vashnik = Registry:GetLayout("vashnik", "heroic")
assert(vashnik.markers[1].kind == "target" and vashnik.markers[1].icon == 8, "Vashnik first Fire target must be Skull")
assert(vashnik.markers[2].kind == "target" and vashnik.markers[2].icon == 7, "Vashnik second Fire target must be Cross")

Setup:Initialize()
assert(not Setup:IsReady("sszorak", "heroic"), "required setup starts unchecked each addon session")
assert(Setup:Toggle("sszorak", "heroic") == true, "setup can be manually confirmed")
assert(Setup:IsReady("sszorak", "heroic"), "manual confirmation makes setup ready")
assert(Setup:Toggle("sszorak", "heroic") == false, "setup confirmation can be revoked")
assert(not Setup:IsReady("sszorak", "heroic"), "revoked setup returns to check")
assert(Setup:IsReady("nekzali", "heroic"), "bosses without fixed setup are ready by definition")

Setup:SetReady("altar", "heroic", true)
Setup:Initialize()
assert(not Setup:IsReady("altar", "heroic"), "setup readiness must not persist across addon initialization")

print("ok - pre-pull marker setup contracts and session-scoped readiness")
