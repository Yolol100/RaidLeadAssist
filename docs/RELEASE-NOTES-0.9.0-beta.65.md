# Raid Lead Assist 0.9.0-beta.65

## Provider audit currentness

- Refresh `/rla doctor` to report the semantically reviewed DBM `12.1.6` and BigWigs `v424.1` provider contracts instead of obsolete versions.
- Keep the existing DBM/BigWigs/Blizzard authority, precision, deduplication and fail-closed behavior unchanged.
- Keep Ula'tek manual-only; provider source availability still does not count as live timing proof.

## Maintenance cleanup

- Synchronize the living README, audit source register and live Retail matrix with the 2026-08-31 upstream review.
- Preserve historical release notes and dated provider-review documents unchanged as historical evidence.
- Add a regression guard so future provider-baseline refreshes must also update the runtime diagnostic and current operational documentation.

## Validation boundary

This beta remains source/CI validated only until the applicable live Retail matrix rows are recorded as `PASS-LIVE` against the exact installed version/SHA. No source-only audit claims live rendering, taint, performance or encounter cadence proof.
