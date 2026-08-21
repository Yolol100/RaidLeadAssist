# Raid Lead Assist

Raid Lead Assist (RLA) is a raid-leader callout panel for **The Venomous Abyss** with separate Normal, Heroic and Mythic strategy profiles. It provides pre-pull plans, boss-specific assignments, manual Raid Warning buttons, optional PREPARE/PRESS timing state and TTS/sound feedback.

RLA is deliberately fail-closed: uncertain encounter identity, unsupported difficulty, malformed/secret timing values, stale cross-encounter state or incomplete provider data disable automatic behavior rather than reuse an old profile. It is not a DBM/BigWigs replacement and does not automate protected combat decisions.

## Encounter, calls and assignments

RLA supports eight encounters and 24 Normal/Heroic/Mythic profiles. During a supported encounter WoW's encounter/difficulty context locks the active profile. Unknown encounters and unsupported difficulties disable calls/timing. Pre-pull plans cannot be sent during an active encounter.

Assignments are configured before combat through `ASSIGN`, Settings or `/rla assignments`. PLAYER/GROUP, ROTATION, RULE and SEQUENCE fields are validated per boss/difficulty. Duplicate/overlapping players and hard group-size constraints are rejected where the tactic requires it. Rotation advances only after the matching manual Raid Warning succeeds.

The assignment window also owns local planning tools. `PREVIEW` validates the current unsaved draft and prints the exact assignment plan locally without saving it or sending anything to raid chat. `PRESETS` stores up to eight validated plans per boss/difficulty and `MY TASKS` prints the current player's direct, rotation and raid-group duties. Preview and announce share one bounded plan renderer, so the local inspection path cannot drift from the actual pre-pull assignment announcement. None of these tools add addon networking or live combat scanning; slash equivalents remain available for power users where applicable.

## Timer sources

RLA consumes public **DBM**, **BigWigs** and Blizzard Encounter Timeline timing. Among equally precise usable representations it prefers DBM, then BigWigs, then Blizzard. Exact/native sources may drive PREPARE/PRESS/TTS; approximate bars remain non-actionable previews.

Provider payloads are untrusted runtime input. Secret, malformed, stale or cross-encounter data is rejected/downgraded. Direct bossmod timers must resolve to the verified active encounter. Cross-provider occurrence reconciliation prevents duplicate calls/audio and a successful manual call acknowledges the occurrence so a late provider cannot immediately re-arm it.

The stable compatibility floor remains **DBM 12.1.4** and **BigWigs v419.2**; those published releases are kept separate from current-source evidence. `docs/UPSTREAM_BASELINES.json` independently pins the exact watched DBM/BigWigs `master` files that were semantically re-reviewed on 2026-08-20. The evening re-review includes DBM's expanded Normal Coiled Altar Stage 3 routing and BigWigs' newer Vashnik, Twin Fangs, Coiled Altar and Lost Explorers mappings. DBM's watched Timer/BossMod contracts and BigWigs' watched BossPrototype timer contracts remain byte-identical, while changed boss files retain the encounter/spell identities RLA consumes.

BigWigs `v419.2` predates the finalized Coiled Altar boss module, so RLA does not assume that a loaded stable BigWigs build can supply every live Venomous Abyss bar. When a bossmod cannot provide a usable matching timer, RLA intentionally falls back to Blizzard Encounter Timeline data for supported calls. Users do not need unreleased bossmod source for RLA to load or for manual calls to remain available.

## Ula'tek

Ula'tek remains deliberately **manual-only** on every difficulty. Current DBM source has drycode/timeline mappings and BigWigs has timeline-backed coverage. BigWigs' 2026-08-20 source additionally fixes Phase 3 initial-timer handling and related custom-bar details, but this still does not constitute stable live-validated exact scheduling for RLA. Every Ula'tek call therefore remains `timing=false` pending live Retail proof.

Provider timer identity is kept separate from display spell identity; for example the current DBM drycode key used for Toxic Incubation cannot silently replace RLA's UI mechanic identity.

## Operational controls

The main raid-control panel shows a themed `READY`/`CHECK` control next to Settings. It opens the same read-only doctor diagnostics used by `/rla doctor` rather than creating a second readiness state.

Settings owns the default timing-lead editor beside `AUTO`. Defaults are PREPARE 5s / PRESS 3s, with bounded 2-30s and 1-10s ranges and PREPARE greater than PRESS. Encounter-specific call windows remain authoritative. Timing preferences cannot be changed during an active encounter or combat; the slash fallback follows the same boundary.

- `/rla timing on|off`: automatic timing toggle, pre-pull only.
- `/rla timing lead <prepare> <press>` / `/rla timing reset`: default lead-window fallbacks, pre-pull only.
- `/rla assignments`: pre-pull assignment editor, including local `PREVIEW` before `ANNOUNCE`.
- `/rla preset list|save|load|delete <name>`: local preset fallback for the active boss/difficulty.
- `/rla my`: local personal-assignment fallback.
- `/rla provider`: read-only provider/timer diagnostics.
- `/rla doctor`: read-only readiness diagnostics.
- `AUTO TIMING OFF`: user disabled automatic timing.
- `MANUAL CALLS ONLY`: selected profile intentionally has no automatic timing.

## SavedVariables and privacy

`RaidLeadAssistDB` schema 6 stores local settings, bounded timing leads, custom warning text, assignments, assignment presets and frame position. Migration is defensive and a newer unknown schema is preserved rather than blindly downgraded. RLA has no addon networking, telemetry or external storage; see `PRIVACY.md`.

## Architecture and audit evidence

- `docs/ARCHITECTURE.md`: what each layer owns, when it runs, for whom and why.
- `docs/TEN_OF_TEN_ACCEPTANCE.md`: the **172-check** master audit, supplemented by focused post-audit release regressions.
- `docs/LIVE_TEST_MATRIX.md`: evidence that can only be collected in the real Retail client.
- `docs/AUDIT_SOURCES.md`: current Blizzard, GitHub, DBM/BigWigs and encounter source register.
- `docs/RELEASE_PROCESS.md`: release-versus-repository-only change classification and the deliberate publication flow.
- `scripts/audit_runtime.py`: TOC/runtime/copy/policy hygiene.
- `scripts/audit_repository.py`: repository paths/encoding/secrets/module order/combat API/workflow/supply-chain governance.

The repository audit explicitly blocks combat-log decision processing, aura/health/power/cast/position decision APIs, protected action automation, secure-action automation, dynamic code execution and addon networking from the shipped runtime. Approved App extension surfaces are explicitly documented and their exact patched method sets are CI-locked. Assignment preview/announce behavior stays under `Core/AssignmentIntegration.lua` and the shared `Services/AssignmentPlanService.lua`; productivity UI uses bounded callbacks instead of adding another App monkey patch.

## Validation and release

Every push and pull request runs:

- upstream-baseline schema validation;
- runtime and repository master audits;
- `git diff --check` source hygiene;
- Lua 5.1 compile checks;
- blocking Luacheck for every TOC runtime file;
- TOC inventory/metadata checks;
- every `tests/test_*.lua` behavioral/adversarial regression;
- two independent runtime-only ZIP and SPDX-SBOM builds that must be byte-identical;
- SHA-256 generation for the validated artifact.

Pull-request validation uses workflow concurrency so a superseded PR run is cancelled when a newer commit for the same PR starts. Normal `main` pushes still receive full source/reproducibility validation but do **not** publish a release automatically.

The distributable ZIP is runtime-only: `RaidLeadAssist.toc` plus exactly the Lua files listed by that TOC. Repository documentation, tests, audit scripts and maintenance files are deliberately excluded from the addon package. Repository-only changes can therefore advance `main` without inventing a new addon version when the runtime package is unchanged.

Release publication is deliberate. From the `main` branch, manually dispatch the **Validate source** workflow only after the TOC version, top changelog entry and optional versioned release notes represent a new immutable addon release. That dispatch rebuilds the exact source, verifies reproducibility, creates GitHub/Sigstore provenance plus the SPDX SBOM attestation, verifies both attestations and creates or verifies the version-locked prerelease/tag. Reusing an existing version for a different SHA fails closed. See `docs/RELEASE_PROCESS.md`.

All third-party Actions are pinned to full commit SHAs and workflows use explicit least-privilege permissions. GitHub-native branch protection/rulesets, required CODEOWNER approval, secret scanning/push protection, Actions policy enforcement and Private Vulnerability Reporting remain repository-admin evidence rather than source-code claims. License selection is also an explicit owner/legal choice. These settings are not reported as enabled until the GitHub repository itself proves them.

## 10/10 boundary

A source/release can be **TECHNICALLY GREEN** only when every applicable automated gate passes on the exact source or released SHA. A full product **10/10** additionally requires the applicable live-only checks — real raid pulls, provider combinations, `/reload` recovery, taint, CPU/frame-time, memory soak, UI scaling/accessibility/locales and post-hotfix tactic/timer accuracy — to be recorded as `PASS-LIVE`. Missing live evidence remains `MANUAL TEST NEEDED`.
