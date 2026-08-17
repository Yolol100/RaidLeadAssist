# Changelog

## 0.9.0-beta.36 — 2026-08-17

- Correct release-governance wording: GitHub currently reports releases as mutable (`immutable: false`), so RLA no longer claims native GitHub release immutability.
- Keep the stronger property that CI actually enforces: a version tag is locked to one validated main SHA, and reusing that version for a different SHA fails the release job.
- Preserve verified ZIP/checksum release assets and provenance while keeping repository-admin release mutability explicit.
- Confirm there are no open pull requests, no open issues, no repository rulesets, and no repository-wide TODO/FIXME/HACK/XXX markers at this release boundary.

## 0.9.0-beta.35 — 2026-08-17

- Add blocking `luacheck` static analysis for every TOC runtime Lua file using Ubuntu Noble's maintained `lua-check` package.
- Resolve static-analysis shadowing findings and keep only two explicit, documented intentional Luacheck exceptions.
- Add a post-provenance release gate that creates one GitHub prerelease/tag for the exact validated main SHA and refuses same-version release drift.
- Publish the verified ZIP and SHA-256 file as durable GitHub Release assets in addition to the 90-day Actions artifact.
- Remove the audit-only temporary branches created during the beta.34 metadata verification.
- Recheck current DBM and BigWigs stable release baselines; they remain DBM 12.1.3 and BigWigs v419.2 on 2026-08-17.
- Keep branch/ruleset protection and license selection explicit owner/admin boundaries rather than silently making a legal or repository-administration choice.

## 0.9.0-beta.34 — 2026-08-17

- Recheck the exact main SHA, green CI, attested artifact and packaged runtime after the beta.33 audit hardening.
- Extend the permanent runtime audit to validate WoW-visible TOC metadata, including Interface, Title, Notes, SavedVariables and OptionalDeps.
- Reject Dutch or advertising/donation copy in WoW-visible TOC metadata as well as runtime Lua.
- Keep the release boundary explicit: source/CI may be technically green while live Retail raid, taint, accessibility and performance evidence remains manual.

## 0.9.0-beta.33 — 2026-08-17

- Complete an end-to-end source, runtime, UI, provider, structure, naming, packaging and governance audit.
- Add a permanent runtime hygiene gate for TOC completeness, canonical paths and filenames, case collisions, obsolete overlays, unfinished markers, English runtime copy, advertising/donation policy hygiene and version parity.
- Revalidate assignment lifecycle and active-encounter call safety without changing their proven integration behavior.
- Preserve Ula'tek manual-only timing until live Retail validation exists; source-only validation does not claim live-client proof.

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
- Expand release acceptance into a 58-point master audit covering platform, data, providers, state, UI, taint/performance, packaging, security and governance.
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
