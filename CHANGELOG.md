# Changelog

## 0.9.0-beta.38 — 2026-08-17

- Make the distributable addon ZIP strictly runtime-only: `RaidLeadAssist.toc` plus the exact Lua files listed by the TOC.
- Remove `README.md` from the shipped addon package; documentation, tests, audit scripts and GitHub maintenance files remain source-repository assets only.
- Keep all current runtime modules because the TOC/module-order audit confirms they are part of the active load graph; no runtime file is deleted merely to reduce repository size.
- Preserve the full CI/audit/test suite in source control so release cleanup does not weaken verification or future maintenance.

## 0.9.0-beta.37 — 2026-08-17

- Expand the permanent acceptance model from 58 to 160 checks covering product scope, repository structure, module/load-order integrity, Midnight combat boundaries, tactics, providers, reconciliation, assignments, UI/accessibility, data recovery, security, privacy, supply chain, release and live operations.
- Add a blocking repository audit for path portability, UTF-8/LF hygiene, committed-secret signatures, module dependency order, approved App patch surface, forbidden combat-automation APIs, workflow trigger/injection risks, full-SHA action pinning and behavioral-test inventory.
- Add `ARCHITECTURE.md`, `AUDIT_SOURCES.md`, `LIVE_TEST_MATRIX.md`, `PRIVACY.md` and `CONTRIBUTING.md` so every subsystem has documented ownership, lifecycle, purpose, evidence boundary and current source provenance.
- Add `.editorconfig` and `.gitattributes` to keep future source encoding/line endings deterministic across platforms; the new gate found and normalized the pre-existing missing final newline in `Core/App.lua`.
- Keep Luacheck exceptions narrowly named and documented: one BigWigs callback-shape secondary variable plus the two existing App settings-scope shadowings; every other runtime warning remains blocking.
- Recheck current stable bossmod releases: DBM remains `12.1.3` and BigWigs remains `v419.2` at this audit.
- Keep the single `AssignmentIntegration` App extension explicit and machine-locked instead of allowing additional runtime monkey patches to appear silently.
- Correct the beta.36 historical wording: there are no open pull requests, while owner/admin governance work is tracked in issue #14; no claim is made that the repository has zero open issues.

## 0.9.0-beta.36 — 2026-08-17

- Correct release-governance wording: GitHub currently reports releases as mutable (`immutable: false`), so RLA no longer claims native GitHub release immutability.
- Keep the stronger property that CI actually enforces: a version tag is locked to one validated main SHA, and reusing that version for a different SHA fails the release job.
- Preserve verified ZIP/checksum release assets and provenance while keeping repository-admin release mutability explicit.
- Confirm there are no open pull requests at this release boundary; owner/admin follow-up is tracked separately and first-party runtime code remains free of TODO/FIXME/HACK/XXX development markers.

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
