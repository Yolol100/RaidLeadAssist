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
assert(baseline:find('"reviewedAt": "2026-08-20"', 1, true), "provider baseline review date must stay current")
assert(baseline:find('"releaseTag": "12.1.4"', 1, true), "DBM stable release pin must be 12.1.4")
assert(baseline:find("88ec781e9b213dbf7d9ca59164a584c2529d9bf9", 1, true),
    "DBM 12.1.4 release commit must stay pinned")
assert(baseline:find("c8039ffb656fabcc2eb8a36c3a60643128487ba9", 1, true),
    "DBM Timer callback baseline must stay pinned")
assert(baseline:find("57ba051543cac3612e273bf2f02ca3b7258fa388", 1, true),
    "DBM shared timeline batch-routing baseline must stay pinned")
assert(baseline:find("a0e89c8e31318fc8e934c94dc030afaeb792767e", 1, true),
    "Nek'zali DBM day-one Normal/fallback baseline must stay pinned")
assert(baseline:find("06b08a1d288d961d7efe89d85bb8aca215da8d7e", 1, true),
    "Vashnik DBM day-one Normal/fallback baseline must stay pinned")
assert(baseline:find("5314afd2931cd3ffc3234790acb7b4eb04816974", 1, true),
    "Twin Fangs DBM post-unlock lifecycle baseline must stay pinned")
assert(baseline:find("af76bc0cc67fc3a971fb6fd1a8b9f654c7d5200a", 1, true),
    "Coiled Altar DBM evening Normal-stage3 hardcoded/fallback baseline must stay pinned")
assert(baseline:find("c82ba65249ce3b4d98293c9d299fbf8530fb9cd0", 1, true),
    "Sentinels DBM post-unlock Normal-routing baseline must stay pinned")
assert(baseline:find("cd0a4de36fefbcd9490df2a26be6322efcd400ce", 1, true),
    "Lost Explorers DBM in-combat registration baseline must stay pinned")
assert(baseline:find("bcfbcc0fea3c4e0c06336c0066accd3fdf33b0fc", 1, true),
    "Sszorak DBM post-unlock routing baseline must stay pinned")
assert(baseline:find("4d9e26f894455743f66ae87908a043f6f8d6cb2f", 1, true),
    "BigWigs BossPrototype callback baseline must stay pinned")
assert(baseline:find("74f5521d9ec51d8e60973aaabe30207071b1f75f", 1, true),
    "Nek'zali BigWigs final aura-only baseline must stay pinned")
assert(baseline:find("9114bf6331598d210e20ffe3716e05842ccb43c6", 1, true),
    "Sentinels BigWigs intermission/reset baseline must stay pinned")
assert(baseline:find("10d48f51a322d96343f9cfdf48c333eb0f21d6d6", 1, true),
    "Twin Fangs BigWigs evening Submerge/aura baseline must stay pinned")
assert(baseline:find("5dfaa8188133c61647fc717151ccf284b9fe1ed4", 1, true),
    "Coiled Altar BigWigs evening Normal/Heroic mapping baseline must stay pinned")
assert(baseline:find("6531b296d147499bc45d27f571c86a812274665b", 1, true),
    "Vashnik BigWigs Normal/Heroic mapping baseline must stay pinned")
assert(baseline:find("8176b9593c9242b3c5894c6632a4e27882c9c68a", 1, true),
    "Lost Explorers BigWigs evening duration-routing baseline must stay pinned")
assert(baseline:find("f0e6b961c9801e0450d34a64b8f64cde82d95ffd", 1, true),
    "Sszorak BigWigs final aura-only baseline must stay pinned")
assert(baseline:find("2db5f87a85d5868a0800fa63ca4d9ff79f08eec4", 1, true),
    "Ula'tek BigWigs final aura-only phase-3/custom-bar baseline must stay pinned")

local security = read("SECURITY.md")
assert(security:find("RaidLeadAssist.toc", 1, true))
assert(security:find("audited runtime files referenced by that TOC", 1, true))
assert(security:find("Private Vulnerability Reporting", 1, true),
    "security policy must document the private vulnerability-reporting path without claiming it is enabled")
assert(security:find("must be verified independently", 1, true),
    "repository-native security settings must remain evidence-gated")
assert(not security:find("audited TOC runtime plus README", 1, true))

print("ok - addon audit hardening contracts are locked")
