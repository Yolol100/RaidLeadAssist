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
assert(baseline:find("EncounterTimelineDocumentation.lua", 1, true),
    "Blizzard EncounterTimeline API source must remain drift-watched")
assert(baseline:find('"reviewedAt": "2026-09-02"', 1, true), "provider baseline review date must stay current")
assert(baseline:find('"releaseTag": "12.1.8"', 1, true), "DBM source-reviewed stable release pin must be 12.1.8")
assert(baseline:find("16c154f3a01cb1bbf8b3c4f5f7eeccaa61c44789", 1, true),
    "DBM 12.1.8 release commit must stay pinned")
assert(baseline:find("143e09575c4f98e61da7b8900040a2bcb82d79ec", 1, true),
    "DBM Timer callback baseline must stay pinned")
assert(baseline:find("a03a3faba696f09eb700bf39c6ada25b9f3d00d3", 1, true),
    "DBM shared boss-module baseline must stay pinned")
assert(baseline:find("1d0929c17f7979984fe68b13cd94322e1815f761", 1, true),
    "Nek'zali current DBM source baseline must stay pinned")
assert(baseline:find("9f49ebd546fd507cbc83a18cb95d1530aa556c73", 1, true),
    "Vashnik current DBM source baseline must stay pinned")
assert(baseline:find("5a23305ff25835a807fa0d625bc613378af93c6a", 1, true),
    "Twin Fangs current DBM source baseline must stay pinned")
assert(baseline:find("3d7af3cf25ff27b10d0c454effeab3d7593ae6b4", 1, true),
    "Coiled Altar current DBM source baseline must stay pinned")
assert(baseline:find("7dc8483696f8501cad0d0d7ad45e209373f87e56", 1, true),
    "Sentinels current DBM source baseline must stay pinned")
assert(baseline:find("484ed1b02b1195ad6a35e2709a571a43c5e09210", 1, true),
    "Lost Explorers current DBM source baseline must stay pinned")
assert(baseline:find("a3c5072cb60d526e5cd9f7fe5e7d34c6d3627b05", 1, true),
    "Sszorak current DBM source baseline must stay pinned")
assert(baseline:find("2f9fdaf2a4d6b2d986d18c6ed8eb78464e544939", 1, true),
    "Ula'tek current Heroic-routing source baseline must stay pinned")

assert(baseline:find('"releaseTag": "v424.3"', 1, true), "BigWigs source-reviewed stable release pin must be v424.3")
assert(baseline:find("6a37cb326c3ce695026b361c2c8cae10e990c12b", 1, true),
    "BigWigs v424.3 release commit must stay pinned")
assert(baseline:find("d1d2846ddaacf44af341f792c3ed82a5fab6d686", 1, true),
    "BigWigs current BossPrototype source baseline must stay pinned")
assert(baseline:find("990fee7abd2928ee0c437fc998b28f3d9774fc9f", 1, true),
    "Nek'zali BigWigs current baseline must stay pinned")
assert(baseline:find("06c97ad137b5a7d956f727e4e2477801efdc4050", 1, true),
    "Sentinels BigWigs current baseline must stay pinned")
assert(baseline:find("f7eaa1da682a3b02636ac97868aa5807f4cfb158", 1, true),
    "Twin Fangs BigWigs current baseline must stay pinned")
assert(baseline:find("58ef05b8dc62335f4f0ad56489d2f36a7b794701", 1, true),
    "Coiled Altar BigWigs current baseline must stay pinned")
assert(baseline:find("33fc9cccabee460d16d27f5bc83dade2f2691feb", 1, true),
    "Vashnik BigWigs current baseline must stay pinned")
assert(baseline:find("bc9bd703b7a3dad07f9d6864ada922f2e3da6a5e", 1, true),
    "Lost Explorers BigWigs current baseline must stay pinned")
assert(baseline:find("3c917465baad18138df0e68e71c8f413a67096e7", 1, true),
    "Sszorak BigWigs current baseline must stay pinned")
assert(baseline:find("4c1f560e09a23191a5164a74884a5cfd3aae760e", 1, true),
    "Ula'tek BigWigs current baseline must stay pinned")

local app = read("Core/App.lua")
assert(app:find("Tested bossmod contracts: DBM 12.1.6; BigWigs v424.1", 1, true),
    "runtime doctor must keep the last live-tested contracts until new live Retail evidence exists")

local readme = read("README.md")
assert(readme:find("DBM 12.1.8", 1, true), "README source-reviewed DBM contract must track the audited baseline")
assert(readme:find("BigWigs v424.3", 1, true), "README source-reviewed BigWigs contract must track the audited baseline")
assert(readme:find("2026-09-02", 1, true), "README provider source-review date must stay current")
assert(readme:find("live-tested", 1, true), "README must distinguish source review from live-tested evidence")

local auditSources = read("docs/AUDIT_SOURCES.md")
assert(auditSources:find("Review date: 2026-09-02", 1, true), "audit source register must stay current")
assert(auditSources:find("DBM `12.1.8`", 1, true), "audit source DBM contract must track the baseline")
assert(auditSources:find("BigWigs `v424.3`", 1, true), "audit source BigWigs contract must track the baseline")
assert(auditSources:find("EncounterTimelineDocumentation.lua", 1, true),
    "audit source register must document the Blizzard timeline drift watch")

local liveMatrix = read("docs/LIVE_TEST_MATRIX.md")
assert(liveMatrix:find("0.9.0-beta.65", 1, true), "live matrix must target the current runtime candidate")
assert(liveMatrix:find("DBM 12.1.6", 1, true), "live matrix must retain the last live-tested DBM contract")
assert(liveMatrix:find("BigWigs v424.1", 1, true), "live matrix must retain the last live-tested BigWigs contract")
assert(liveMatrix:find("2026-08-31", 1, true), "live matrix must retain its actual evidence date")

local toc = read("RaidLeadAssist.toc")
assert(toc:find("## Version: 0.9.0-beta.65", 1, true), "TOC version must match the current runtime candidate")
local changelog = read("CHANGELOG.md")
assert(changelog:find("## 0.9.0-beta.65 — 2026-08-31", 1, true),
    "changelog must document the current runtime candidate")

local security = read("SECURITY.md")
assert(security:find("RaidLeadAssist.toc", 1, true))
assert(security:find("audited runtime files referenced by that TOC", 1, true))
assert(security:find("Private Vulnerability Reporting", 1, true),
    "security policy must document the private vulnerability-reporting path without claiming it is enabled")
assert(security:find("must be verified independently", 1, true),
    "repository-native security settings must remain evidence-gated")
assert(not security:find("audited TOC runtime plus README", 1, true))

print("ok - addon audit hardening contracts")
