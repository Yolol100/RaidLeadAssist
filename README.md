# Raid Lead Assist

Raid Lead Assist (RLA) is a raid-leader callout panel for **The Venomous Abyss** with separate Normal, Heroic and Mythic strategy profiles. It provides pre-pull plans, boss-specific assignments, manual Raid Warning buttons, optional PREPARE/PRESS timing state and TTS/sound feedback.

RLA is deliberately fail-closed: uncertain encounter identity, unsupported difficulty, malformed/secret timing values, stale cross-encounter state or incomplete provider data disable automatic behavior rather than reuse an old profile. It is not a DBM/BigWigs replacement and does not automate protected combat decisions.

## Encounter, calls and assignments

RLA supports eight encounters and 24 Normal/Heroic/Mythic profiles. During a supported encounter WoW's encounter/difficulty context locks the active profile. Unknown encounters and unsupported difficulties disable calls/timing. Pre-pull plans cannot be sent during an active encounter.

Assignments are configured before combat through `ASSIGN`, Settings or `/rla assignments`. PLAYER/GROUP, ROTATION, RULE and SEQUENCE fields are validated per boss/difficulty. Duplicate/overlapping players and hard group-size constraints are rejected where the tactic requires it. Rotation advances only after the matching manual Raid Warning succeeds.

## Timer sources

RLA consumes public **DBM**, **BigWigs** and Blizzard Encounter Timeline timing. Among equally precise usable representations it prefers DBM, then BigWigs, then Blizzard. Exact/native sources may drive PREPARE/PRESS/TTS; approximate bars remain non-actionable previews.

Provider payloads are untrusted runtime input. Secret, malformed, stale or cross-encounter data is rejected/downgraded. Direct bossmod timers must resolve to the verified active encounter. Cross-provider occurrence reconciliation prevents duplicate calls/audio and a successful manual call acknowledges the occurrence so a late provider cannot immediately re-arm it.

The reviewed stable release-contract baselines remain **DBM 12.1.3** and **BigWigs v419.2**. Exact watched upstream commits/files are stored in `docs/UPSTREAM_BASELINES.json` and checked for drift.

## Ula'tek

Ula'tek remains deliberately **manual-only** on every difficulty. Current DBM source has drycode/timeline mappings and BigWigs has timeline-backed coverage, but neither constitutes stable live-validated exact scheduling. RLA therefore keeps every Ula'tek call `timing=false` pending live Retail proof.

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
- `docs/TEN_OF_TEN_ACCEPTANCE.md`: the **160-check** maximum master audit.
- `docs/LIVE_TEST_MATRIX.md`: evidence that can only be collected in the real Retail client.
- `docs/AUDIT_SOURCES.md`: current Blizzard, GitHub, DBM/BigWigs and API source register.
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
- two independent release-ZIP builds that must be byte-identical;
- SHA-256 generation.

A successful `main` push additionally uploads the verified ZIP/checksum for 90 days, creates GitHub/Sigstore build provenance and publishes one version-locked prerelease/tag on the exact validated SHA with durable ZIP/checksum assets. Reusing the same version for another SHA fails.

GitHub currently still reports `main` as unprotected and no repository ruleset is installed; license selection is also an explicit owner/legal choice. Those owner/admin actions are tracked in issue #14 rather than being falsely marked fixed by CI.

## 10/10 boundary

A source/release can be **TECHNICALLY GREEN** only when every automated gate passes on the exact released SHA. A full product **10/10** additionally requires the applicable live-only checks — real raid pulls, provider combinations, `/reload` recovery, taint, CPU/frame-time, memory soak, UI scaling/accessibility/locales and post-hotfix tactic/timer accuracy — to be recorded as `PASS-LIVE`. Missing live evidence remains `MANUAL TEST NEEDED`.
