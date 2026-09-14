local function read(path)
    local handle = assert(io.open(path, "rb"), "missing Phase 5 contract file: " .. path)
    local content = handle:read("*a")
    handle:close()
    return content
end

local toc = read("RaidLeadAssist.toc")
local changelog = read("CHANGELOG.md")
local readme = read("README.md")
local live = read("docs/LIVE_TEST_MATRIX.md")
local releaseNotes = read("docs/RELEASE-NOTES-0.9.0-beta.68.md")
local guidance = read("Services/TimingGuidanceService.lua")

assert(toc:find("## Version: 0.9.0-beta.68", 1, true),
    "TOC must identify the Phase 5 beta68 runtime candidate")
assert(changelog:find("## 0.9.0-beta.68 — 2026-09-14", 1, true),
    "changelog must lead with the beta68 candidate")
assert(releaseNotes:find("# Raid Lead Assist 0.9.0-beta.68", 1, true),
    "versioned beta68 release notes are required")

assert(readme:find("WAIT -> SOON -> PRESS NOW -> LATE", 1, true),
    "README must describe the current four-state guidance contract")
assert(readme:find("schema **7**", 1, true),
    "README SavedVariables schema must stay synchronized with the runtime")
assert(readme:find("raid leader must click", 1, true),
    "README must preserve the manual Raid Warning action boundary")
assert(readme:find("PASS-CI", 1, true) and readme:find("PASS-LIVE", 1, true),
    "README must distinguish source/CI evidence from live Retail evidence")

assert(live:find("0.9.0-beta.68", 1, true),
    "live matrix must target the exact beta68 candidate")
assert(live:find("phantom `LATE`", 1, true),
    "live matrix must cover early-cancel phantom-LATE regression")
assert(live:find("profile call order", 1, true),
    "live matrix must cover deterministic simultaneous-mechanic ordering")
assert(live:find("raid leader clicking", 1, true),
    "live matrix must verify manual Raid Warning ownership")
assert(live:find("PASS-CI", 1, true) and live:find("PASS-LIVE", 1, true),
    "live matrix must not allow CI evidence to masquerade as Retail evidence")

assert(guidance:find("seenAt", 1, true),
    "guidance must retain a final-window observation before synthesizing LATE")
assert(guidance:find("priorityByCallKey", 1, true),
    "guidance must use deterministic encounter-profile priority")
assert(guidance:find("lastMechanic.seenAt >= self.lastMechanic.expiration", 1, true),
    "LATE snapshot must be gated by a near-deadline observation")

print("ok - Phase 5 beta68 candidate, deterministic guidance and PASS-CI/PASS-LIVE boundaries are synchronized")
