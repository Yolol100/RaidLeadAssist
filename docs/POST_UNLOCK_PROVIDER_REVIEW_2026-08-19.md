# Second post-unlock provider review — 2026-08-19

This review supersedes earlier same-day wording that described DBM `master` as only two commits beyond stable 12.1.4. Provider source continued to change after the first audit.

## DBM

Stable release baseline remains **12.1.4**. The current reviewed `master` fingerprints are recorded in `UPSTREAM_BASELINES.json`.

Material post-unlock changes reviewed for RLA:

- **Entombed Sentinels:** Normal hardcoded routing is now confirmed from logs. RLA's consumed Stasis (`1284588`), Unstable Miasma (`1288232`) and Mythic Protovenom (`1296878`) identities remain compatible.
- **The Lost Explorers:** DBM rebuilt Normal hardcoded routing from fresh evidence and explicitly disables Heroic/Mythic hardcoded routing until equivalent evidence exists. Heroic/Mythic therefore use Blizzard fallback. RLA must not promote those fallback bars to exact merely because they arrive through `DBM_TimerBegin`.
- **Sszorak:** Normal/Heroic routing is log-confirmed; Mythic routing is explicitly extrapolated upstream. RLA's Venomous Surge (`1305959`), Raging Crosswinds (`1285425`), Howling Maelstrom (`1285732`) and Apex Predator (`1285430`/`1277025`) identities remain compatible. Mythic stays live-evidence-pending.
- **The Twin Fangs:** latest source adds Submerge lifecycle/safety-rounding coverage while preserving Ravenous Feast (`1290516`) and the RLA-consumed coordination identities.

### Precision consequence

RLA now treats Lost Explorers DBM timing as `approximate` unless DBM itself has asserted hardcoded timeline authority through the already-consumed `DBM_IgnoreBlizzAPI` state. Normal can therefore remain exact when DBM owns the reviewed hardcoded route, while current Heroic/Mythic fallback cannot drive PREPARE/PRESS/TTS.

## BigWigs

Stable release baseline remains **v419.2**. Current `master` has additional live-launch fixes.

- **Entombed Sentinels:** intermission/reset handling changed; consumed mechanic identities remain compatible.
- **The Twin Fangs:** additional Submerge timers are captured; Ravenous Feast/shared movement identities remain compatible.
- Direct `BigWigs_Timer` carries `isApproximate` and RLA preserves it.
- The nil-module `BigWigs_StartBar` Blizzard bridge does **not** carry Blizzard's `isApproximate` metadata. RLA therefore treats that bridge as preview-only. If the same underlying native event is exact, the direct Blizzard provider can independently supply the actionable copy.

## Release boundary

These changes are source/CI-reviewable but do not create `PASS-LIVE`. Beta.54 still requires the exact live scenarios in `LIVE_TEST_MATRIX.md`, especially Lost Explorers Normal vs Heroic/Mythic provider authority, Sentinels intermission/reset, Sszorak Mythic extrapolation and Twin Fangs Submerge lifecycle.
