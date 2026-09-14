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
assert(baseline:find('"reviewedAt": "2026-09-13"', 1, true), "provider baseline review date must stay current")
assert(baseline:find('"releaseTag": "12.1.9"', 1, true), "DBM source-reviewed stable release pin must be 12.1.9")
assert(baseline:find("f2aa0876ef91a6c80d48bde620bed58402bd8878", 1, true),
    "DBM 12.1.9 release commit must stay pinned")
assert(baseline:find("f60f91c1316d8b43adfba07bcdff067acd9b74af", 1, true),
    "DBM Timer callback baseline must stay pinned")
assert(baseline:find("52fd0a9aaf0ddac138034d433005f6fe5b42c812", 1, true),
    "DBM shared boss-module baseline must stay pinned")
assert(baseline:find("1d0929c17f7979984fe68b13cd94322e1815f761", 1, true),
    "Nek'zali current DBM source baseline must stay pinned")
assert(baseline:find("ea3b45f901efa58a8955b1674342a3b80cb60bb3", 1, true),
    "Vashnik current DBM source baseline must stay pinned")
assert(baseline:find("c0786819f9474b01f53810f32dacbe7626d204f0", 1, true),
    "Twin Fangs current DBM source baseline must stay pinned")
assert(baseline:find("3bcd4e36ae515e1f1bb4991226aa3b26d3cf10e8", 1, true),
    "Coiled Altar current DBM source baseline must stay pinned")
assert(baseline:find("dd2b3f5377c6ca670b797621f62f076941bec06b", 1, true),
    "Sentinels current DBM source baseline must stay pinned")
assert(baseline:find("8356b32cd076f557292f6087539464e9448126a2", 1, true),
    "Lost Explorers current DBM source baseline must stay pinned")
assert(baseline:find("a3c5072cb60d526e5cd9f7fe5e7d34c6d3627b05", 1, true),
    "Sszorak current DBM source baseline must stay pinned")
assert(baseline:find("2f9fdaf2a4d6b2d986d18c6ed8eb78464e544939", 1, true),
    "Ula'tek current Heroic-routing source baseline must stay pinned")

assert(baseline:find('"releaseTag": "v424.8"', 1, true), "BigWigs source-reviewed stable release pin must be v424.8")
assert(baseline:find("8177bf9d06f2f1b6c51b54bf8da330a39e4c3651", 1, true),
    "BigWigs v424.8 release commit must stay pinned")
assert(baseline:find("4c9aea8bebb365878ac298d166dadf21e4e807ce", 1, true),
    "BigWigs current BossPrototype source baseline must stay pinned")
assert(baseline:find("01b5f12872ad9abfe165cbb77ea2f00dccba7002", 1, true),
    "Nek'zali BigWigs current baseline must stay pinned")
assert(baseline:find("4ecb9e02052022626df84c5f19e7f716dd6b5f74", 1, true),
    "Sentinels BigWigs current baseline must stay pinned")
assert(baseline:find("727c7760366f8ae77278412c9acd8437b15a5b93", 1, true),
    "Twin Fangs BigWigs current baseline must stay pinned")
assert(baseline:find("3ab07136ce8bce7eeb870b90d1f70410a5e4ed54", 1, true),
    "Coiled Altar BigWigs current baseline must stay pinned")
assert(baseline:find("fe00dfe004d9603ff0837b219267a52c6092c4ef", 1, true),
    "Vashnik BigWigs current baseline must stay pinned")
assert(baseline:find("e00ac888c416c227f0b2463ce15089b08e61caa2", 1, true),
    "Lost Explorers BigWigs current baseline must stay pinned")
assert(baseline:find("6ee0b32ced6c574aa9319907973820e526b3065f", 1, true),
    "Sszorak BigWigs current baseline must stay pinned")
assert(baseline:find("7982e9cdac7364edae2efa282df59b541f387da1", 1, true),
    "Ula'tek BigWigs current baseline must stay pinned")

local app = read("Core/App.lua")
assert(app:find("Tested bossmod contracts: DBM 12.1.6; BigWigs v424.1", 1, true),
    "runtime doctor must keep the last live-tested contracts until new live Retail evidence exists")

local readme = read("README.md")
assert(readme:find("DBM 12.1.9", 1, true), "README source-reviewed DBM contract must track the audited baseline")
assert(readme:find("BigWigs v424.8", 1, true), "README source-reviewed BigWigs contract must track the audited baseline")
assert(readme:find("2026-09-13", 1, true), "README provider source-review date must stay current")
assert(readme:find("live-tested", 1, true), "README must distinguish source review from live-tested evidence")
assert(readme:find("PROVIDER_REVIEW_2026-09-13.md", 1, true),
    "README must route the current provider review to the dated evidence document")
assert(readme:find("FINAL_BOSSES_REVIEW_2026-09-13.md", 1, true),
    "README must route final-boss tactics to the dated product review")
assert(readme:find("Ula'tek is no longer globally manual-only", 1, true),
    "README must retain the bounded Ula'tek timing decision")
assert(readme:find("not yet PASS-LIVE", 1, true),
    "README must not turn source/CI evidence into a live-runtime claim")
assert(readme:find("WAIT -> SOON -> PRESS NOW -> LATE", 1, true),
    "README must describe the beta68 guidance contract")

local providerReview = read("docs/PROVIDER_REVIEW_2026-09-13.md")
assert(providerReview:find("DBM stable release reviewed: `12.1.9`", 1, true),
    "current provider review must document DBM 12.1.9")
assert(providerReview:find("BigWigs stable release reviewed: `v424.8`", 1, true),
    "current provider review must document BigWigs v424.8")
assert(providerReview:find("Ula'tek", 1, true) and providerReview:find("manual-only", 1, true),
    "the earlier provider-only review must retain its historical manual-only decision")
assert(providerReview:find("scripts/native_ats_prospecting.py", 1, true),
    "current provider review must retain cleanup evidence and rollback context")

local finalBossReview = read("docs/FINAL_BOSSES_REVIEW_2026-09-13.md")
for _, marker in ipairs({
    "0.9.0-beta.67",
    "3-player minimum",
    "Spectral Coils requires **40% of the raid**",
    "Circling Prey / platform break — `1301510`",
    "Toxic Incubation provider timer — `1299757`",
    "Approximate bars remain non-actionable previews",
    "PASS-LIVE",
}) do
    assert(finalBossReview:find(marker, 1, true), "missing final-boss review marker: " .. marker)
end

local auditSources = read("docs/AUDIT_SOURCES.md")
assert(auditSources:find("Review date: 2026-09-03", 1, true),
    "dated audit source register must retain its recorded review date")
assert(auditSources:find("DBM `12.1.8`", 1, true),
    "dated audit source register must preserve the provider state it actually reviewed")
assert(auditSources:find("BigWigs `v424.5`", 1, true),
    "dated audit source register must preserve the provider state it actually reviewed")
assert(auditSources:find("EncounterTimelineDocumentation.lua", 1, true),
    "audit source register must document the Blizzard timeline drift watch")

local liveMatrix = read("docs/LIVE_TEST_MATRIX.md")
assert(liveMatrix:find("0.9.0-beta.68", 1, true), "live matrix must target the current beta68 runtime candidate")
assert(liveMatrix:find("DBM 12.1.6", 1, true), "live matrix must retain the last live-tested DBM contract")
assert(liveMatrix:find("BigWigs v424.1", 1, true), "live matrix must retain the last live-tested BigWigs contract")
assert(liveMatrix:find("2026-08-31", 1, true), "live matrix must retain its actual live evidence date")
assert(liveMatrix:find("beta67 tactic review", 1, true),
    "live matrix must preserve the historical Ula'tek strategy evidence boundary")
assert(liveMatrix:find("missing/overlapping required assignments failing closed", 1, true),
    "live matrix must require negative live assignment validation")
assert(liveMatrix:find("source/CI green candidate; Retail PASS-LIVE pending", 1, true),
    "live matrix must keep beta68 source/CI evidence separate from PASS-LIVE")
assert(liveMatrix:find("phantom `LATE`", 1, true),
    "live matrix must cover the Phase 5 early-cancel regression")

local toc = read("RaidLeadAssist.toc")
assert(toc:find("## Version: 0.9.0-beta.68", 1, true), "TOC version must match the current beta68 runtime candidate")
local changelog = read("CHANGELOG.md")
assert(changelog:find("## 0.9.0-beta.68 — 2026-09-14", 1, true),
    "changelog must document the current beta68 runtime candidate")

local security = read("SECURITY.md")
assert(security:find("RaidLeadAssist.toc", 1, true))
assert(security:find("audited runtime files referenced by that TOC", 1, true))
assert(security:find("Private Vulnerability Reporting", 1, true),
    "security policy must document the private vulnerability-reporting path without claiming it is enabled")
assert(security:find("must be verified independently", 1, true),
    "repository-native security settings must remain evidence-gated")
assert(not security:find("audited TOC runtime plus README", 1, true))

print("ok - addon audit hardening contracts")
