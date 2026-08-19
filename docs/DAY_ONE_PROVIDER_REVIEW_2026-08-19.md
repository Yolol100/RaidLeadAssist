# Season 2 day-one provider review — 2026-08-19

This review is later than `POST_UNLOCK_PROVIDER_REVIEW_2026-08-19.md` and supersedes its provider-currentness claims for beta.55. Historical findings in the earlier document remain useful context, but current source fingerprints live in `UPSTREAM_BASELINES.json`.

## Blizzard / release boundary

The EU Season 2 window is live on 2026-08-19: Mythic+ Season 2 and The Venomous Abyss are available in the published regional window. This source review does not turn any encounter into `PASS-LIVE`; Retail pulls are still required.

The same-day Blizzard review found the published Season 2 opening schedule and Patch 12.1 addon/UI restrictions, but no separately indexed 2026-08-19 Blizzard hotfix entry that justifies inventing new mechanic values. RLA therefore follows confirmed provider/live evidence and does not encode speculative tuning.

Patch 12.1's addon restrictions remain part of the design contract. New filtered-aura presentation APIs do not authorize RLA to consume underlying aura state for automated combat decisions. The repository audit continues to reject that expansion. Blizzard's UI texture-manifest change is not relevant to RLA because the repository has no `ManifestInterfaceData` dependency.

## DBM — source kept moving after beta.54

Stable release contract remains DBM `12.1.4`; current `master` is tracked separately and is not required for users.

The late day-one review found additional changes after beta.54 was assembled:

- `DBM-Core/modules/objects/BossMod.lua` changed shared Encounter Timeline batch handling. `TLBatchTrackLatest` now treats a resent identical event ID as already registered and replaces/cancels an older event in the same timer bucket. Because this helper can change which public DBM bar reaches RLA, it is now a first-class drift watch alongside `Timer.lua`.
- Vashnik gained Normal hardcoded routing plus duplicate-batch handling. If the live Blizzard timeline no longer matches the reviewed hardcoded route, DBM explicitly calls `ResumeBlizzardAPI()` and returns to Blizzard-backed timing.
- Nek'zali's current source also has Normal hardcoded routing with the same fail-closed ability to resume Blizzard when its route stops matching.
- The other reviewed Venomous Abyss modules already expose the same hardcoded-versus-Blizzard authority transition. Provider priority therefore cannot be treated as proof that a DBM callback is exact.

### Precision consequence

For all eight current Venomous Abyss encounter IDs, beta.55 treats a DBM callback as exact only while DBM has asserted its hardcoded timeline authority through the already-consumed `DBM_IgnoreBlizzAPI` state. After DBM resumes Blizzard, the DBM copy becomes preview-only. An independently exact direct Blizzard or bossmod source can still be actionable under its own normal checks.

This is deliberately conservative. It prevents a runtime fallback inside DBM from laundering a native approximate/unknown timeline into an exact RLA PREPARE/PRESS/TTS timer.

## BigWigs

Stable release baseline remains BigWigs `v419.2`; current `master` continues to receive live-launch encounter fixes.

After beta.54, Nek'zali received a Phase 1 Essence Rend timeline correction for duplicated/cancelled Encounter Timeline rows and ambiguous duration buckets. RLA does not consume Essence Rend as a raidleader call identity, so no tactic or call mapping changes are required. The new source fingerprint is nevertheless pinned because future changes in the same routing surface could affect observed provider bars.

The existing precision boundary remains unchanged: direct `BigWigs_Timer` preserves its explicit approximation metadata; the nil-module Blizzard `StartBar` bridge does not expose that metadata and stays preview-only.

## Required live re-test

Beta.55 remains prerelease/live-pending. In addition to the existing matrix, reproduce at minimum:

- Vashnik with DBM hardcoded authority, then a bad-state/fallback transition to Blizzard; exact timing must become preview-only after authority is released.
- Nek'zali, Sentinels, Sszorak, Twin Fangs, Coiled Altar, Ula'tek and Lost Explorers with DBM hardcoded timers disabled or Blizzard authority resumed; no DBM copy may drive actionable timing solely because its provider name is DBM.
- The same encounters while DBM explicitly owns the reviewed hardcoded timeline; direct reviewed timers may remain exact.
- BigWigs Nek'zali current source through repeated Phase 1 timeline rows; no duplicate/stale RLA timer should survive a cancel/replacement sequence.

No CI result substitutes for these Retail observations.
