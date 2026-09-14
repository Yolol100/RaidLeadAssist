# Raid Lead Assist 0.9.0-beta.68

This candidate combines the beta67 encounter/tactic review with the Phase 4 timing-guidance engine and Phase 5 QA hardening.

## Timing guidance

- Automatic guidance requires a reviewed stable numeric spell identity owned by the selected call.
- Only one verified mechanic is emphasized at a time.
- Guidance is shown as `WAIT -> SOON -> PRESS NOW -> LATE`.
- `LATE` is bounded to the existing one-second expiry grace.
- Same-occurrence provider authority remains DBM, then BigWigs, then Blizzard.
- Simultaneous distinct mechanics resolve deterministically by encounter profile call order.
- Localized/name-only, wrong-ID, approximate, faded, malformed or otherwise unverified timer representations do not become actionable guidance.

## Phase 5 hardening

- A timer cancelled well before its deadline can no longer resurface later as a phantom `LATE` call.
- A removed paused timer cannot synthesize a missed-mechanic state.
- Near-zero bar removal still permits the deliberately bounded late snapshot when the mechanic was observed inside the final grace window.
- Documentation and the Retail acceptance matrix now describe the same beta68 guidance contract.

## Final repository audit

- The 2026-09-14 scheduled provider drift was reviewed against current BigWigs master before its watched fingerprints were refreshed.
- The required `validation` context now includes live upstream-baseline verification, and provenance/release wait for that complete gate.
- Dynamic difficulty tabs also own their downstream anchors; no post-tab layout depends on named Heroic/Mythic tab fields.
- Private addon methods with no runtime/test references were removed rather than carried as dormant API surface.
- The living ten-of-ten acceptance document now matches the 16 supported Heroic/Mythic profiles and Ula'tek's bounded timing contract.

## Manual action boundary

Raid Warning delivery remains manual. DBM, BigWigs and Blizzard timing can guide the raid leader, but the addon never sends the timed Raid Warning without the raid leader clicking the call button.

## Evidence boundary

Repository validation, source review and simulated provider regressions can establish `PASS-CI`. They do not establish `PASS-LIVE`. Real Retail pulls, provider combinations, wipe/repull recovery, taint/performance and UI/accessibility checks remain required under `docs/LIVE_TEST_MATRIX.md` before claiming live acceptance.
