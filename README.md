# Raid Lead Assist

Raid Lead Assist (RLA) is a raid-leader callout panel for **The Venomous Abyss** with separate Normal, Heroic and Mythic strategy profiles. It provides pre-pull plans, boss-specific assignments, manual Raid Warning buttons, optional PREPARE/PRESS timing state and TTS/sound feedback.

RLA is deliberately fail-closed: uncertain encounter identity, unsupported difficulty, malformed/secret timing values, stale cross-encounter state or incomplete provider data disable automatic behavior rather than reuse an old profile. It is not a DBM/BigWigs replacement and does not automate protected combat decisions.

## Encounter, calls and assignments

RLA supports eight encounters and 24 Normal/Heroic/Mythic profiles. During a supported encounter WoW's encounter/difficulty context locks the active profile. Unknown encounters and unsupported difficulties disable calls/timing. Pre-pull plans cannot be sent during an active encounter.

Assignments are configured before combat through `ASSIGN`, Settings or `/rla assignments`. PLAYER/GROUP, ROTATION, RULE and SEQUENCE fields are validated per boss/difficulty. Duplicate/overlapping players and hard group-size constraints are rejected where the tactic requires it. Rotation advances only after the matching manual Raid Warning succeeds.

The assignment footer also provides a local-only `PREVIEW` action. It validates the current unsaved draft with the same required-field and Raid Warning size budgets, then prints exactly what would be announced to the local chat frame without saving, advancing rotations or sending anything to raid chat. The preview uses the existing RLA `ActionButton`, theme and AssignmentFrame rather than introducing a parallel UI/state system.

## Timer sources

RLA consumes public **DBM**, **BigWigs** and Blizzard Encounter Timeline timing. Among equally precise usable representations it prefers DBM, then BigWigs, then Blizzard. Exact/native sources may drive PREPARE/PRESS/TTS; approximate bars remain non-actionable previews.

Provider payloads are untrusted runtime input. Secret, malformed, stale or cross-encounter data is rejected/downgraded. Direct bossmod timers must resolve to the verified active encounter. Cross-provider occurrence reconciliation prevents duplicate calls/audio and a successful manual call acknowledges the occurrence so a late provider cannot immediately re-arm it.

The stable release-contract baselines are **DBM 12.1.4** and **BigWigs v419.2**. DBM 12.1.4 remains the stable release pin while current DBM master has only advanced its displayed alpha identity without changing the watched timer/BossMod contracts. Venomous Abyss DBM and BigWigs `master` watch paths were re-reviewed on 2026-08-20; exact core, raid-TOC and per-boss fingerprints live in `docs/UPSTREAM_BASELINES.json`.

Current BigWigs master additionally introduced a dedicated Lost Explorers `Fling Fish` bar and central count resets plus unrelated aura metadata accessors in `Core/BossPrototype.lua`. RLA keeps `Fling Fish` (1295817) separate from its fish-order `Final Ascension` (1292779) call and keeps `Throw Junk` (1291933) mapped to crates; beta.59 adds a regression for that exact provider boundary.

BigWigs `v419.2` predates the finalized Coiled Altar boss module, so RLA does not assume that a loaded stable BigWigs build can supply every live Venomous Abyss bar. When a bossmod cannot provide a usable matching timer, RLA intentionally falls back to Blizzard Encounter Timeline data for supported calls. Users do not need unreleased bossmod source for RLA to load or for manual calls to remain available.

## Ula'tek

Ula'tek remains deliberately **manual-only** on every difficulty. Current DBM source has drycode/timeline mappings and BigWigs has timeline-backed coverage. BigWigs' 2026-08-20 source additionally fixes Phase 3 initial-timer handling and related custom-bar details, but this still does not constitute stable live-validated exact scheduling for RLA. Every Ula'tek call therefore remains `timing=false` pending live Retail proof.

Provider timer identity is kept separate from display spell identity; for example the current DBM drycode key used for Toxic Incubation cannot silently replace RLA's UI mechanic identity.

## Operational controls

- `/rla timing on|off`: automatic timing toggle.
- `/rla assignments`: pre-pull assignment editor.
- `/rla provider`: read-only provider/timer diagnostics.
- `/rla doctor`: read-only readiness diagnostics.
- `AUTO TIMING OFF`: user disabled automatic timing.
- `MANUAL CALLS ONLY`: selected profile intentionally has no automatic timing.

## SavedVariables and privacy

`RaidLeadAssistDB` schema 5 stores local settings, custom warning text, assignments and frame position. Migration is defensive and a newer unknown schema is preserved rather than blindly downgraded. RLA has no addon networking, telemetry or external storage; see `PRIVACY.md`.

## Architecture and audit evidence

- `docs/ARCHITECTURE.md`: what each layer owns, when it runs, for whom and why.
- `docs/TEN_OF_TEN_ACCEPTANCE.md`: the **172-check** master audit after beta.58 distribution/supply-chain expansion.
- `docs/BETA59_ACCEPTANCE.md`: four additional unique beta.59 controls for preview ownership/safety and current BigWigs Fling Fish isolation, bringing the controlled audit universe to **176 unique controls**.
- `docs/LIVE_TEST_MATRIX.md`: evidence that can only be collected in the real Retail client.
- `docs/AUDIT_SOURCES.md`: current Blizzard, GitHub, DBM/BigWigs and encounter source register.
- `scripts/audit_runtime.py`: TOC/runtime/copy/policy hygiene.
- `scripts/audit_repository.py`: repository paths/encoding/secrets/module order/combat API/workflow/supply-chain governance.

The repository audit explicitly blocks combat-log decision processing, aura/health/power/cast/position decision APIs, protected action automation, secure-action automation, dynamic code execution and addon networking from the shipped runtime. The single existing `AssignmentIntegration` App extension surface is explicitly documented and its exact patched method set is CI-locked; additional monkey patches fail validation.

## Validation and release

Every push/PR runs:

- upstream-baseline schema validation;
- runtime and repository master audits;
- `git diff --check` source hygiene;
- Lua 5.1 compile checks;
- blocking Luacheck for every TOC runtime file;
- TOC inventory/metadata checks;
- every `tests/test_*.lua` behavioral/adversarial regression;
- two independent release-ZIP and SPDX-SBOM builds that must be byte-identical;
- SHA-256 generation and separate SLSA/SBOM attestation verification for the release ZIP.

The distributable ZIP is runtime-only: `RaidLeadAssist.toc` plus exactly the Lua files listed by that TOC. Repository documentation, tests, audit scripts and maintenance files are deliberately excluded from the addon package, so release cleanup does not require deleting useful verification source from Git.

A successful `main` push additionally uploads the verified ZIP/checksum/SBOM, creates GitHub/Sigstore build provenance and publishes one version-locked prerelease/tag on the exact validated SHA with durable assets. Reusing the same version for another SHA fails.

GitHub-native branch protection/rulesets, required CODEOWNER approval, secret scanning/push protection and Private Vulnerability Reporting remain repository-admin evidence rather than source-code claims. License selection is also an explicit owner/legal choice. These owner/admin actions remain external release gates rather than being falsely marked fixed by CI.

## 10/10 boundary

A source/release can be **TECHNICALLY GREEN** only when every automated gate passes on the exact released SHA. A full product **10/10** additionally requires the applicable live-only checks — real raid pulls, provider combinations, `/reload` recovery, taint, CPU/frame-time, memory soak, UI scaling/accessibility/locales and post-hotfix tactic/timer accuracy — to be recorded as `PASS-LIVE`. Missing live evidence remains `MANUAL TEST NEEDED`.
