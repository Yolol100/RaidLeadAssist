# Changelog

## 0.9.0-beta.32 — 2026-08-17

- Re-audit all boss-facing tactic copy and difficulty splits against current pre-release encounter data.
- Replace The Lost Explorers' fixed Nama > Iku > Gebbo kill order with boss-health balancing and a synchronized finish on every difficulty.
- Replace the rigid Heroic/Mythic all-three 35+ yard split with explicit United Defense management and flexible two-boss stacking.
- Add a manual Boss Health call to The Twin Fangs and make the Uncoiled Wrath joint-finish requirement explicit on Normal, Heroic, and Mythic.
- Add tactic regressions that reject the obsolete Lost Explorers kill order/split and protect the Twin Fangs finish call.
- Keep all front-end tactic copy in English and leave Ula'tek manual-only until live Retail validation is available.

## 0.9.0-beta.31 — 2026-08-17

- Re-audit current DBM/BigWigs upstream state after DBM added Ula'tek drycode on 2026-08-17.
- Keep all Ula'tek calls manual-only; distinguish the Toxic Incubation display spell identity from DBM's current timer key.
- Add machine-readable DBM/BigWigs source baselines and a scheduled upstream-drift workflow.
- Expand release acceptance into a 58-point master audit covering platform, data, providers, state, UI, taint, performance, packaging and governance.
- Make CI prove release-ZIP reproducibility with a second clean build.
- Add signed GitHub build-provenance attestation for main-branch release ZIPs.
- Increase verified artifact retention from 14 to 90 days.
- Add SECURITY.md, CODEOWNERS and Dependabot governance/maintenance files.

## 0.9.0-beta.30 — 2026-08-17

- Skip provider lookups for profiles whose calls are intentionally manual-only.
- Preserve `AUTO TIMING OFF` and `MANUAL CALLS ONLY` as canonical timing states.

## 0.9.0-beta.29 — 2026-08-17

- Consolidate runtime compatibility/enhancement overlays into canonical modules.
- Remove obsolete timing-status, main-frame and Ula'tek assignment overlay files.
- Canonicalize Ula'tek Heroic assignment layout and protect corrected icon identities with regressions.
