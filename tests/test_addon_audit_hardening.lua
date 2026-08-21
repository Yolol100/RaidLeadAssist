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
assert(baseline:find('"reviewedAt": "2026-08-21"', 1, true), "provider baseline review date must stay current")
assert(baseline:find('"releaseTag": "12.1.5"', 1, true), "DBM stable release pin must be 12.1.5")
assert(baseline:find("9a3ab9e404312b2515f0143a67a1d8392e9ad6a2", 1, true),
    "DBM 12.1.5 release commit must stay pinned")
assert(baseline:find("c8039ffb656fabcc2eb8a36c3a60643128487ba9", 1, true),
    "DBM Timer callback baseline must stay pinned")
assert(baseline:find("74528cf69973360f748451aa55d3c6ceed5f0704", 1, true),
    "DBM shared timeline routing baseline must stay pinned")
assert(baseline:find("75274f407d3a29135adecdd0c52abda0aef3cf68", 1, true),
    "Nek'zali DBM 12.1.5 routing/fallback baseline must stay pinned")
assert(baseline:find("b21f6e488c10ebfc09985a15ddfb1472655e500d", 1, true),
    "Vashnik DBM 12.1.5 routing baseline must stay pinned")
assert(baseline:find("2789198e9825b995d48bd49fabd9a475f3e23e66", 1, true),
    "Twin Fangs DBM 12.1.5 lifecycle baseline must stay pinned")
assert(baseline:find("91913e00ad850dbd21e89c36b91563ca97706007", 1, true),
    "Coiled Altar DBM 12.1.5 routing/fallback baseline must stay pinned")
assert(baseline:find("06756c06cac3ef3f9590640bd14dc3b2d55e16c8", 1, true),
    "Sentinels DBM 12.1.5 routing baseline must stay pinned")
assert(baseline:find("9a96bdcf6ec53b05fc398dbc0c2d51a0823496ef", 1, true),
    "Lost Explorers DBM 12.1.5 routing baseline must stay pinned")
assert(baseline:find("7aae99a569460b7f632cc1735e3ccfe0c33f8ba6", 1, true),
    "Sszorak DBM 12.1.5 routing baseline must stay pinned")
assert(baseline:find("1c03fdccc9d440529e30eaf53edd6853976b6d27", 1, true),
    "Ula'tek DBM 12.1.5 source baseline must stay pinned")

assert(baseline:find('"releaseTag": "v422"', 1, true), "BigWigs stable release pin must be v422")
assert(baseline:find("881cd496a97f5479302ed936ecfe5fb0e50ac71b", 1, true),
    "BigWigs v422 release commit must stay pinned")
assert(baseline:find("4d9e26f894455743f66ae87908a043f6f8d6cb2f", 1, true),
    "BigWigs BossPrototype callback baseline must stay pinned")
assert(baseline:find("74f5521d9ec51d8e60973aaabe30207071b1f75f", 1, true),
    "Nek'zali BigWigs v422 baseline must stay pinned")
assert(baseline:find("9114bf6331598d210e20ffe3716e05842ccb43c6", 1, true),
    "Sentinels BigWigs v422 baseline must stay pinned")
assert(baseline:find("10d48f51a322d96343f9cfdf48c333eb0f21d6d6", 1, true),
    "Twin Fangs BigWigs v422 baseline must stay pinned")
assert(baseline:find("326009d05c5fe91167ad7fb897ea56a91c7f1540", 1, true),
    "Coiled Altar BigWigs v422 intermission/rename baseline must stay pinned")
assert(baseline:find("6531b296d147499bc45d27f571c86a812274665b", 1, true),
    "Vashnik BigWigs v422 baseline must stay pinned")
assert(baseline:find("8176b9593c9242b3c5894c6632a4e27882c9c68a", 1, true),
    "Lost Explorers BigWigs v422 baseline must stay pinned")
assert(baseline:find("f0e6b961c9801e0450d34a64b8f64cde82d95ffd", 1, true),
    "Sszorak BigWigs v422 baseline must stay pinned")
assert(baseline:find("2db5f87a85d5868a0800fa63ca4d9ff79f08eec4", 1, true),
    "Ula'tek BigWigs v422 baseline must stay pinned")

local security = read("SECURITY.md")
assert(security:find("RaidLeadAssist.toc", 1, true))
assert(security:find("audited runtime files referenced by that TOC", 1, true))
assert(security:find("Private Vulnerability Reporting", 1, true),
    "security policy must document the private vulnerability-reporting path without claiming it is enabled")
assert(security:find("must be verified independently", 1, true),
    "repository-native security settings must remain evidence-gated")
assert(not security:find("audited TOC runtime plus README", 1, true))

print("ok - addon audit hardening contracts are locked")
