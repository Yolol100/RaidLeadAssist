# Raid Lead Assist

Raid Lead Assist (RLA) is a raid-leader callout panel for **The Venomous Abyss** with separate Normal, Heroic, and Mythic strategy profiles. It provides pre-pull plans, boss-specific assignments, manual Raid Warning buttons, optional PREPARE/PRESS timing state, and TTS/sound feedback.

The addon is intentionally fail-closed: uncertain encounter identity, unsupported difficulty, malformed or secret timing values, stale cross-encounter state, or incomplete provider data must disable automatic decisions rather than reuse an old profile.

## Encounter and difficulty safety

RLA supports eight Venomous Abyss encounters and 24 Normal/Heroic/Mythic profiles. During a supported live encounter, the actual encounter and difficulty select and lock the active profile. Manual boss/difficulty changes are blocked until the encounter ends.

Unknown encounters, unsupported difficulties, or stale/mismatched selected state idle automatic timing and disable combat-call controls. The pre-pull plan cannot be sent during an active encounter.

A `/reload` during a pull remains fail-closed until WoW independently confirms that an encounter is active in The Venomous Abyss. DBM/BigWigs may provide a recovery hint, but a bossmod hint alone cannot select or unlock a profile.

## Boss assignments

Assignments are configured before combat through `ASSIGN`, Settings, or `/rla assignments`. Layouts are boss- and difficulty-specific and use typed fields:

- **PLAYER/GROUP** — fixed players or teams, with current-roster selection.
- **ROTATION** — ordered players/teams that advance only after the matching successful manual call.
- **RULE** — pre-pull movement/position logic for mechanics with dynamic live targets.
- **SEQUENCE** — tactic order that is not a roster selection.

Saved values are isolated per boss and difficulty. Roster fields reject duplicate names case-insensitively. Required simultaneous/rotating slots reject invalid overlap. Hard tactic constraints are validated before save/announce, including four-player Helical Toxin groups, 5+ Mutilate/Guillotine soak teams, and 3+ players per Ravenous Feast hit.

`CLEAR DRAFT` changes only the unsaved draft. `ANNOUNCE` stays disabled until the complete draft is valid. Combat-call assignment text is all-or-nothing: if the base call plus assignment would exceed the warning limit, RLA sends the intact base call instead of a misleading partial assignment.

## Timer sources

RLA can consume **DBM**, **BigWigs**, and Blizzard's Encounter Timeline. Among equally precise usable representations it prefers:

1. DBM
2. BigWigs
3. Blizzard

Exact/native sources may drive PREPARE/PRESS/TTS. Approximate BigWigs bars remain previews and are not silently promoted to actionable exact timers.

Provider data is treated as untrusted runtime input. RLA rejects or downgrades secret/malformed durations, identities, metadata, precision and authority state. Explicit encounter identity from a direct bossmod source must match the verified active RLA encounter.

### DBM

RLA consumes public DBM timer begin/update/stop/pause/resume/fade callbacks, resolves module identity to encounter identity, rejects disabled/variable timers, preserves occurrence identity through timer corrections, and respects DBM's explicit Blizzard-timeline authority handoff. A faded timer becomes non-actionable without becoming a new occurrence when it returns.

The release-contract baseline remains **DBM 12.1.3**. Upstream source fingerprints are separately tracked so post-release `master` changes are not mistaken for the tested release contract.

### BigWigs

RLA handles direct `BigWigs_Timer`/`BigWigs_CastTimer` boss bars separately from the nil-module Blizzard Timeline bridge. Test/statistics/keystone/non-boss timers cannot become encounter calls. Direct event/counter metadata is used only when its public shape is valid and encounter-scoped.

The release-contract baseline remains **BigWigs v419.2**. Current `master` source is fingerprinted independently.

### Cross-provider occurrence handling

Representations are clustered by native event identity when possible and otherwise by bounded end-time tolerance. Explicit conflicting occurrence counts prevent accidental merges. A successful manual call acknowledges the clustered occurrence so a late second provider cannot immediately re-arm it. Updates preserve the original occurrence identity to prevent duplicate PREPARE/PRESS audio.

## Ula'tek status

Ula'tek is deliberately **manual-only** on every supported difficulty. All Ula'tek calls keep `timing=false` until public provider coverage is complete, stable, and observed in the live Retail encounter.

The source review was refreshed on **2026-08-17** after DBM added Ula'tek drycode. The current DBM module now contains timeline mappings and more mechanic coverage, but it still includes TODO/placeholder work and does not constitute a live-validated exact schedule. Current BigWigs source still uses Blizzard Timeline-backed backup bars for unmatched Ula'tek events. Neither change is sufficient to enable automatic RLA timing.

RLA also keeps provider timer identity separate from display spell identity. Current DBM drycode uses `1299757` as its Toxic Incubation timer/warning key; the RLA Toxic Incubation display spell identity remains `1299759`. Regression coverage prevents a provider-specific key from silently replacing the UI mechanic identity.

The Ula'tek plans remain pre-release and do not claim live raid validation. Heroic does not inherit Mythic-only Soul Constrictor/Mass Gestation handling; Mythic retains its dedicated Coil/egg/incubation assignment logic pending live confirmation.

## Operational controls

- `/rla timing on|off` or Settings `AUTO ON/OFF` toggles automatic timing without disabling manual plans/calls/assignments.
- `AUTO TIMING OFF` means the user disabled automatic timing.
- `MANUAL CALLS ONLY` means the selected profile intentionally has no automatic call timing.
- `/rla doctor` is a read-only readiness diagnostic for SavedVariables, encounter/difficulty state, Raid Warning permission, timing state, TTS fallback, provider/core-pack status and strategy evidence.
- `/rla provider` shows provider diagnostics and active timer paths.

## SavedVariables

`RaidLeadAssistDB` currently uses schema 5. Existing Heroic-only custom messages migrate into the Heroic profile; Normal/Mythic remain isolated. Assignment data is stored separately per boss/difficulty. Invalid types and invalid frame positions are normalized defensively. A database claiming a newer schema is preserved rather than blindly downgraded.

## Release package

Build locally with:

```bash
python3 scripts/build_release.py
```

The builder creates `dist/RaidLeadAssist.zip` with one `RaidLeadAssist/` root containing only the TOC, TOC runtime files and this README. It rejects unsafe/duplicate/unexpected paths, reopens the ZIP, compares packaged bytes to source and prints SHA-256.

CI additionally builds the ZIP **twice** and requires byte-identical output. Successful `main` pushes retain the verified ZIP/checksum artifact for **90 days**. A separate least-privilege provenance job downloads that exact artifact and generates a signed GitHub/Sigstore build-provenance attestation for the ZIP.

## Upstream drift control

`docs/UPSTREAM_BASELINES.json` records the reviewed DBM/BigWigs release commits plus fingerprints for callback-critical and Ula'tek source files. `scripts/check_upstream_drift.py` validates the schema in normal CI. The scheduled `Check upstream drift` workflow compares the recorded baselines against current upstream GitHub state and fails when a watched release or source file changes.

A drift failure is a **review trigger**, not permission to copy new upstream IDs/timers into RLA automatically. Re-review the affected provider contract/encounter data, update regressions, then deliberately advance the baseline.

## Validation and release gate

Every push/PR runs:

- baseline/tooling validation;
- Lua 5.1 compile checks for every Lua file;
- TOC source inventory validation;
- every `tests/test_*.lua` behavioral/adversarial regression;
- deterministic double-build release-ZIP verification;
- SHA-256 generation.

`main` pushes additionally upload the verified artifact and, after the validation job succeeds, create provenance using a separate job with only the permissions needed for attestation.

The full audit is maintained in [`docs/TEN_OF_TEN_ACCEPTANCE.md`](docs/TEN_OF_TEN_ACCEPTANCE.md). It covers 58 platform, encounter-data, provider, state, chat/audio, SavedVariables, UI/accessibility, taint/performance, packaging, security and governance checks.

Automated source/controlled-runtime evidence does **not** prove live WoW behavior. Final product acceptance still requires real Retail-client tests for raid pulls, provider combinations, `/reload` recovery, taint, CPU/frame-time, memory stability, UI scaling/accessibility and post-hotfix tactic/timer accuracy. Until those rows have matching live evidence, RLA must not claim a full live 10/10.
