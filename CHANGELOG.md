# Changelog

## 0.9.0-beta.58 — 2026-08-20

- Add a deterministic SPDX 2.3 SBOM for the exact runtime-only release ZIP, including per-file hashes, package verification code and the ZIP SHA-256 digest.
- Build the SBOM independently alongside both release builds and require byte-identical ZIP, checksum and SBOM results before provenance can advance.
- Bind the verified ZIP to the SPDX document with a dedicated GitHub/Sigstore SBOM attestation in addition to the existing SLSA build-provenance attestation.
- Verify both attestation predicate types before creating the version-locked prerelease and publish the SBOM as a release asset.
- Keep the repository license field `NOASSERTION` in the SBOM because choosing a project license remains an explicit owner/legal decision rather than an automated code change.
- Extend security governance with explicit CODEOWNERS for workflow/audit/provider/timeline/encounter trust boundaries, weekly GitHub Actions Dependabot and evidence-gated Private Vulnerability Reporting guidance.
- Recheck all watched DBM and BigWigs paths on 2026-08-20. DBM's watched timer/BossMod/raid sources remain unchanged; BigWigs Ula'tek advanced with Phase 3 initial-timer and custom-bar fixes, so its fingerprint is refreshed while RLA keeps Ula'tek strictly manual-only.

## 0.9.0-beta.57 — 2026-08-19

- Re-review the post-beta.56 BigWigs Ula'tek implementation after upstream added substantial Normal/Heroic/Mythic Encounter Timeline handlers and custom bars on live-launch day.
- Keep all Ula'tek Raid Lead Assist calls explicitly manual-only instead of promoting newly available bossmod bars before real Retail pull evidence establishes stable timing identities and cadence.
- Add a controlled-runtime regression that presents an exact BigWigs-style provider timer and proves Normal/Heroic/Mythic Ula'tek still performs zero automatic timer queries, emits no PREPARE/PRESS audio and remains `MANUAL CALLS ONLY`.
- Pin the new BigWigs Ula'tek source fingerprint and assign the review a new immutable prerelease identity because beta.56 already exists as a versioned tag.

## 0.9.0-beta.56 — 2026-08-19

- Re-review another late Season 2 day-one upstream movement after beta.55: DBM Coiled Altar now enables preliminary Normal hardcoded timelines in addition to Heroic, while unknown rows still fail closed through `ResumeBlizzardAPI`.
- Refresh the DBM Coiled Altar fingerprint after confirming beta.55's encounter-wide authority rule already keeps exactness bound to active hardcoded DBM authority rather than provider name.
- Refresh BigWigs Nek'zali after the non-Mythic Phase 2 Possession Barrage 28-second timeline routing fix; RLA does not consume Possession Barrage as a raidleader call identity, so no encounter call mapping changes.
- Keep beta.56 prerelease/live-pending and assign the refreshed source evidence a new immutable version rather than mutating the already published beta.55 identity.

## 0.9.0-beta.55 — 2026-08-19

- Generalize DBM timing provenance across all eight current Venomous Abyss modules: a DBM callback is exact only while DBM has asserted hardcoded Encounter Timeline authority; after `ResumeBlizzardAPI` the DBM copy is preview-only until another direct source independently proves exact timing.
- Add regression coverage for every reviewed Venomous Abyss encounter ID so provider priority cannot launder Blizzard fallback timing into actionable PREPARE/PRESS/TTS state.
- Refresh late day-one DBM drift for Vashnik, Nek'zali and the shared `TLBatchTrackLatest` batch-routing helper; add the shared BossMod timeline helper to the automated upstream drift oracle.
- Refresh BigWigs Nek'zali after its Phase 1 Essence Rend duplicate/cancel routing fix; RLA does not consume Essence Rend directly, so raidleader call identities remain unchanged while the new source fingerprint is pinned.
- Expand live Retail acceptance for authority-release transitions, Vashnik/Nek'zali hardcoded-to-Blizzard fallback, duplicate timeline batches and current BigWigs Nek'zali. Beta.55 remains prerelease/live-pending.

## 0.9.0-beta.54 — 2026-08-19

- Preserve timing provenance across bossmod fallback paths: BigWigs' Blizzard bridge is preview-only when it does not expose `isApproximate`, and current DBM Lost Explorers fallback is preview-only unless DBM explicitly asserts hardcoded timeline authority.
