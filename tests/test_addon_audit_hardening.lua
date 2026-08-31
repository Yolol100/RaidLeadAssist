local function read(path)
    local file = assert(io.open(path, "rb"))
    local content = assert(file:read("*a"))
    file:close()
    return content
end

local registry = read("Encounters/AssignmentRegistry.lua")
assert(registry:find("function AssignmentRegistry:Register%(", 1))
assert(registry:find("function AssignmentRegistry:RegisterLayouts%(", 1))

for _, path in ipairs({
    "Encounters/Boss12AssignmentOverride.lua",
    "Encounters/Boss34AssignmentOverride.lua",
    "Encounters/SszorakAssignmentOverride.lua",
    "Encounters/TwinFangsAssignmentOverride.lua",
    "Encounters/Boss78AssignmentOverride.lua",
}) do
    local source = read(path)
    assert(source:find("AssignmentRegistry:Register", 1, true), path .. " must register layouts")
    assert(not source:find("function AssignmentRegistry:GetLayout", 1, true), path .. " must not monkey-patch GetLayout")
    assert(not source:find("originalGetLayout", 1, true), path .. " must not depend on override load order")
end

local messages = read("Services/MessageService.lua")
assert(messages:find("defaultFingerprint", 1, true))
assert(messages:find("GetCustomCurrentness", 1, true))
assert(messages:find('and "current" or "review"', 1, true))

local readiness = read("Core/ReadinessIntegration.lua")
for _, marker in ipairs({
    "CHECK ASSIGNMENTS",
    "CHECK ROSTER",
    "CHECK CUSTOM TEXT",
    "CHECK PROVIDER DRIFT",
    "READY TIMED",
    "READY MANUAL",
    "assigned player(s) not currently in raid",
}) do
    assert(readiness:find(marker, 1, true), "missing readiness marker: " .. marker)
end

local raidWarning = read("Services/RaidWarningService.lua")
assert(raidWarning:find("compactAssignmentLines", 1, true))
assert(raidWarning:find('lines%[index%]:find%("%^ASSIGN > "%)'))
assert(raidWarning:find("MAX_CHAT_LENGTH = 200", 1, true))

local workflow = read(".github/workflows/validate.yml")
assert(workflow:find("reproducibility:", 1, true))
assert(workflow:find("reproducibility%-check:"))
assert(workflow:find("cmp primary/RaidLeadAssist.zip repro/RaidLeadAssist.zip", 1, true))
assert(workflow:find("gh attestation verify dist/RaidLeadAssist.zip", 1, true))
assert(workflow:find("runs%-on: ubuntu%-24%.04"))
local checkoutCount = select(2, workflow:gsub("actions/checkout@", ""))
local nonPersistingCheckoutCount = select(2, workflow:gsub("persist%-credentials:%s*false", ""))
assert(checkoutCount == 3, "validate workflow checkout inventory drifted")
assert(nonPersistingCheckoutCount == checkoutCount,
    "every validate/release checkout must disable persisted Git credentials")

local driftWorkflow = read(".github/workflows/upstream-drift.yml")
assert(select(2, driftWorkflow:gsub("actions/checkout@", "")) == 1,
    "upstream drift checkout inventory drifted")
assert(select(2, driftWorkflow:gsub("persist%-credentials:%s*false", "")) == 1,
    "upstream drift checkout must disable persisted Git credentials")
assert(driftWorkflow:find("pull_request:", 1, true),
    "provider baseline changes must run the online drift check before merge")
assert(driftWorkflow:find("docs/UPSTREAM_BASELINES.json", 1, true),
    "provider baseline path must trigger the online drift check")

local codeowners = read(".github/CODEOWNERS")
for _, marker in ipairs({
    "/.github/CODEOWNERS @Yolol100",
    "/.github/dependabot.yml @Yolol100",
    "/.github/workflows/ @Yolol100",
    "/scripts/ @Yolol100",
    "/tests/ @Yolol100",
    "/Services/Providers/ @Yolol100",
    "/Services/TimelineService.lua @Yolol100",
    "/RaidLeadAssist.toc @Yolol100",
    "/SECURITY.md @Yolol100",
}) do
    assert(codeowners:find(marker, 1, true), "missing critical CODEOWNER boundary: " .. marker)
end
local dependabot = read(".github/dependabot.yml")
assert(dependabot:find("package%-ecosystem:%s*github%-actions"), "GitHub Actions Dependabot must remain enabled")
assert(dependabot:find("interval:%s*weekly"), "GitHub Actions Dependabot must remain weekly")

local baseline = read("docs/UPSTREAM_BASELINES.json")
for _, path in ipairs({
    "BossMod.lua", "Nekzali.lua", "TwinFangs.lua", "CoiledAltar.lua", "Sentinels.lua", "Explorers.lua", "Vashnik.lua", "Sszorak.lua", "Ulatek.lua",
    "NekzalitheSoulcoiler.lua", "TheTwinFangs.lua", "TheCoiledAltar.lua", "EntombedSentinels.lua", "TheLostExplorers.lua", "VashniktheMalignant.lua",
    "DBM-Raids-Midnight_Mainline.toc", "BigWigs_TheVenomousAbyss_Mainline.toc",
}) do
    assert(baseline:find(path, 1, true), "missing provider watch: " .. path)
end
assert(baseline:find('"reviewedAt": "2026-08-31"', 1, true), "provider baseline review date must stay current")
assert(baseline:find('"releaseTag": "12.1.6"', 1, true), "DBM stable release pin must be 12.1.6")
assert(baseline:find("c08dbfd91a006bad45352ea0d3d1a0cc1bc8367e", 1, true),
    "DBM 12.1.6 release commit must stay pinned")
assert(baseline:find("143e09575c4f98e61da7b8900040a2bcb82d79ec", 1, true),
    "DBM Timer callback baseline must stay pinned")
assert(baseline:find("a03a3faba696f09eb700bf39c6ada25b9f3d00d3", 1, true),
    "DBM shared boss-module baseline must stay pinned")
assert(baseline:find("1d0929c17f7979984fe68b13cd94322e1815f761", 1, true),
    "Nek'zali post-12.1.6 source baseline must stay pinned")
assert(baseline:find("9f49ebd546fd507cbc83a18cb95d1530aa556c73", 1, true),
    "Vashnik post-12.1.6 source baseline must stay pinned")
assert(baseline:find("5a23305ff25835a807fa0d625bc613378af93c6a", 1, true),
    "Twin Fangs post-12.1.6 source baseline must stay pinned")
assert(baseline:find("3d7af3cf25ff27b10d0c454effeab3d7593ae6b4", 1, true),
    "Coiled Altar post-12.1.6 source baseline must stay pinned")
assert(baseline:find("7dc8483696f8501cad0d0d7ad45e209373f87e56", 1, true),
    "Sentinels post-12.1.6 source baseline must stay pinned")
assert(baseline:find("484ed1b02b1195ad6a35e2709a571a43c5e09210", 1, true),
    "Lost Explorers post-12.1.6 source baseline must stay pinned")
assert(baseline:find("a3c5072cb60d526e5cd9f7fe5e7d34c6d3627b05", 1, true),
    "Sszorak post-12.1.6 source baseline must stay pinned")
assert(baseline:find("7a60ab6bdacf226538c5b488edaca4088295ae49", 1, true),
    "Ula'tek current Normal/Heroic-routing source baseline must stay pinned")

assert(baseline:find('"releaseTag": "v424.1"', 1, true), "BigWigs stable release pin must be v424.1")
assert(baseline:find("2f04791c4ac04a13f96757298e407014682d6d12", 1, true),
    "BigWigs v424.1 release commit must stay pinned")
assert(baseline:find("d1d2846ddaacf44af341f792c3ed82a5fab6d686", 1, true),
    "BigWigs current BossPrototype source baseline must stay pinned")
assert(baseline:find("990fee7abd2928ee0c437fc998b28f3d9774fc9f", 1, true),
    "Nek'zali BigWigs v424.1 baseline must stay pinned")
assert(baseline:find("06c97ad137b5a7d956f727e4e2477801efdc4050", 1, true),
    "Sentinels BigWigs v424.1 baseline must stay pinned")
assert(baseline:find("f7eaa1da682a3b02636ac97868aa5807f4cfb158", 1, true),
    "Twin Fangs BigWigs current baseline must stay pinned")
assert(baseline:find("58ef05b8dc62335f4f0ad56489d2f36a7b794701", 1, true),
    "Coiled Altar BigWigs current baseline must stay pinned")
assert(baseline:find("33fc9cccabee460d16d27f5bc83dade2f2691feb", 1, true),
    "Vashnik BigWigs v424.1 baseline must stay pinned")
assert(baseline:find("bc9bd703b7a3dad07f9d6864ada922f2e3da6a5e", 1, true),
    "Lost Explorers BigWigs v424.1 baseline must stay pinned")
assert(baseline:find("3c917465baad18138df0e68e71c8f413a67096e7", 1, true),
    "Sszorak BigWigs v424.1 baseline must stay pinned")
assert(baseline:find("4c1f560e09a23191a5164a74884a5cfd3aae760e", 1, true),
    "Ula'tek BigWigs v424.1 baseline must stay pinned")

local security = read("SECURITY.md")
assert(security:find("RaidLeadAssist.toc", 1, true))
assert(security:find("audited runtime files referenced by that TOC", 1, true))
assert(security:find("Private Vulnerability Reporting", 1, true),
    "security policy must document the private vulnerability-reporting path without claiming it is enabled")
assert(security:find("must be verified independently", 1, true),
    "repository-native security settings must remain evidence-gated")
assert(not security:find("audited TOC runtime plus README", 1, true))
