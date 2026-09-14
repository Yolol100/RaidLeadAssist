# Raid Lead Assist

> **Portfolio status:** Flagship · active development · WoW raid-lead addon

## At a glance

Raid Lead Assist is a fail-closed raid-leader callout and assignment panel for The Venomous Abyss. It supports separate Heroic and Mythic strategy profiles while leaving protected combat decisions to players.

| Area | Evidence |
| --- | --- |
| Audience | Raid leaders who need repeatable pre-pull plans and bounded manual callouts |
| Stack | Lua, WoW Retail APIs and GitHub Actions validation |
| Coverage | Eight encounters and 16 Heroic/Mythic profiles |
| Safety | Unknown encounters, unsupported difficulties and stale or malformed state disable automatic guidance |
| Quality | Validation workflow plus upstream-drift monitoring |

## Quick start

1. Download a validated addon package from GitHub Releases when available.
2. Extract it into the WoW Retail `Interface/AddOns` directory.
3. Enable Raid Lead Assist and configure assignments outside combat.
4. Drag the main header to move the panel; use Ctrl+mouse wheel on the header to scale it from 70–110%.
5. Use preview and preset tools before announcing a plan to raid chat.

## Runtime model

```text
encounter + difficulty context -> validated strategy profile
                               -> pre-pull assignments / manual callouts
                               -> optional verified timing guidance
unknown or invalid state       -> automatic guidance disabled
```

Raid Lead Assist (RLA) is a raid-leader callout panel for **The Venomous Abyss** with separate Heroic and Mythic strategy profiles. It provides pre-pull plans, boss-specific assignments, manual Raid Warning buttons and optional timing/audio guidance.

Automatic guidance is deliberately narrow. A timer must resolve to a stable numeric spell identity owned by the selected call and must already be exact/native and actionable. RLA then exposes one normalized current mechanic at a time using `WAIT -> SOON -> PRESS NOW -> LATE`. `LATE` is bounded to a one-second grace window. Localized/name-only matches, wrong IDs, approximate bars, faded bars, stale state and malformed input do not become actionable guidance.

The actual Raid Warning remains manual. RLA can highlight which button matters and when, but the raid leader must click the button to send the warning. No timing provider can send a Raid Warning automatically.

RLA is fail-closed: uncertain encounter identity, unsupported difficulty, malformed/secret timing values, stale cross-encounter state or incomplete provider data disable automatic behavior rather than reuse an old profile. It is not a DBM/BigWigs replacement and does not automate protected combat decisions.

## Encounter, calls and assignments

RLA supports eight encounters and 16 Heroic/Mythic profiles. During a supported encounter WoW's encounter/difficulty context locks the active profile. Unknown encounters and unsupported difficulties disable calls/timing. Pre-pull plans cannot be sent during an active encounter.

Assignments are configured before combat through `ASSIGN`, Settings or `/rla assignments`. PLAYER/GROUP, ROTATION, RULE and SEQUENCE fields are validated per boss/difficulty. Duplicate/overlapping players and hard group-size constraints are rejected where the tactic requires it. Rotation advances only after the matching manual Raid Warning succeeds.

The assignment window also owns local planning tools. `PREVIEW` validates the current unsaved draft and prints the exact assignment plan locally without saving it or sending anything to raid chat. `PRESETS` stores up to eight validated plans per boss/difficulty and `MY TASKS` prints the current player's direct, rotation and raid-group duties. Preview and announce share one bounded plan renderer, so the local inspection path cannot drift from the actual pre-pull assignment announcement. None of these tools add addon networking or live combat scanning; slash equivalents remain available for power users where applicable.

## Timer sources and guidance

RLA consumes public **DBM**, **BigWigs** and Blizzard Encounter Timeline timing. Among equally precise usable representations of the same occurrence it prefers DBM, then BigWigs, then Blizzard. Exact/native sources may produce `WAIT`, `SOON`, `PRESS NOW` and bounded `LATE` guidance; approximate representations remain non-actionable.

Only one verified current mechanic is emphasized. When two distinct verified mechanics have the same deadline, the encounter profile call order is the deterministic raid-leader priority. A successful manual call acknowledges the represented occurrence, and cross-provider occurrence reconciliation prevents another provider from immediately re-arming the same mechanic.

Provider payloads are untrusted runtime input. Secret, malformed, stale or cross-encounter data is rejected/downgraded. Direct bossmod timers must resolve to the verified active encounter. A bossmod timer cancelled well before its deadline cannot later reappear as a phantom `LATE` call; the short late snapshot is retained only when the mechanic was actually observed inside the final grace window.

The current **source-reviewed** stable provider contracts are **DBM 12.1.9** and **BigWigs v424.8**. `docs/UPSTREAM_BASELINES.json` pins those releases plus the exact watched current-`master` files re-reviewed on **2026-09-14**, while Blizzard's live generated Encounter Timeline contract remains unchanged. RLA continues to consume resolved public timer durations rather than copying private bossmod schedules; see `docs/PROVIDER_REVIEW_2026-09-14.md`. The earlier `docs/PROVIDER_REVIEW_2026-09-13.md` remains historical evidence.

Source review is separate from **live-tested** evidence. The runtime doctor/live matrix still records **DBM 12.1.6** and **BigWigs v424.1** as the last live-tested contracts until fresh Retail evidence is collected. A newer source-reviewed pin therefore means “contract inspected and CI-compatible”, not “proved in a real raid client”. When a bossmod cannot provide a usable matching timer, RLA may use Blizzard Encounter Timeline data for supported calls when the normal precision and authority gates pass. Manual calls remain available independently of bossmod timing.

## Final two bosses

The tactic/runtime review for **The Coiled Altar** and **Ula'tek** is recorded in `docs/FINAL_BOSSES_REVIEW_2026-09-13.md`.

For The Coiled Altar, Heroic Guillotine follows Blizzard's live **3-player minimum** with alternating assigned teams. Mythic remains on fresh 5+ groups because the 3-player hotfix does not include Mythic. The intermission call keeps the current progression strategy of using Bloodlust during Soulbinding's Zul'jan damage window and staggering fragment interceptions.

Ula'tek is no longer globally manual-only. RLA permits fail-closed exact/native provider timing for a deliberately limited set of stable public DBM/BigWigs identities: Caustic Waves, Spectral Coils, Rage of the Shackled, Call of the Serpent, Serpent's Bite, Circling Prey and Mythic Toxic Incubation. Approximate provider data remains non-actionable; Doomscale Warden, egg choices, Grasping Fangs execution and the generic Phase 3 transition remain manual raid-leader calls.

Provider timer identity stays separate from display spell identity. Mythic Toxic Incubation, for example, matches reviewed provider timer key `1299757` while the UI can retain display spell `1299759`. Current bossmod source identifies `1301510` as the Circling Prey/platform-break timing identity.

The **0.9.0-beta.68** candidate combines the beta67 encounter review with the Phase 4 timing-guidance layer and Phase 5 source QA hardening. It is technically source/CI-testable but is not yet PASS-LIVE; the exact package must still be exercised in Retail according to `docs/LIVE_TEST_MATRIX.md`.

## Operational controls

The main raid-control panel is draggable directly by its header and stores its position. Ctrl+mouse wheel on the header changes its persisted 70–110% scale. Settings and assignment surfaces use bounded/dynamic sizing to avoid the previous overlap and excessive-empty-space behavior.

The main panel shows a themed `READY`/`CHECK` control next to Settings. It opens the same read-only doctor diagnostics used by `/rla doctor` rather than creating a second readiness state.

Settings owns the default timing-lead editor beside `AUTO`. Defaults are SOON at 5s and PRESS NOW at 3s, with bounded 2–30s and 1–10s ranges and the SOON lead greater than PRESS NOW. Encounter-specific call windows remain authoritative. Timing preferences cannot be changed during an active encounter or combat; the slash fallback follows the same boundary.

- `/rla timing on|off`: automatic timing toggle, pre-pull only.
- `/rla timing lead <prepare> <press>` / `/rla timing reset`: default lead-window fallbacks, pre-pull only.
- `/rla assignments`: pre-pull assignment editor, including local `PREVIEW` before `ANNOUNCE`.
- `/rla preset list|save|load|delete <name>`: local preset fallback for the active boss/difficulty.
- `/rla my`: local personal-assignment fallback.
- `/rla provider`: read-only provider/timer diagnostics.
- `/rla doctor`: read-only readiness diagnostics.
- `AUTO TIMING OFF`: user disabled automatic timing.
- `MANUAL CALLS ONLY`: selected profile intentionally has no automatic timing.
- `NO VERIFIED TIMER`: timed profile is active but no safe stable-ID actionable timer exists.

## SavedVariables and privacy

`RaidLeadAssistDB` schema **7** stores local settings, bounded timing leads, custom warning text, assignments, assignment presets, frame position and UI scale. Migration is defensive and a newer unknown schema is preserved rather than blindly downgraded. RLA has no addon networking, telemetry or external storage; see `PRIVACY.md`.

## Architecture and audit evidence

- `docs/ARCHITECTURE.md`: what each layer owns, when it runs, for whom and why.
- `docs/TEN_OF_TEN_ACCEPTANCE.md`: the master source/behavior audit.
- `docs/LIVE_TEST_MATRIX.md`: evidence that can only be collected in the real Retail client.
- `docs/PROVIDER_REVIEW_2026-09-14.md`: current Midnight/DBM/BigWigs provider-drift review.
- `docs/PROVIDER_REVIEW_2026-09-13.md`: preserved historical provider review preceding the bounded Ula'tek timing decision.
- `docs/FINAL_BOSSES_REVIEW_2026-09-13.md`: live-hotfix, bossmod, guide/video and RWF review for The Coiled Altar and Ula'tek.
- `docs/AUDIT_SOURCES.md`: source register through its recorded review date.
- `docs/RELEASE_PROCESS.md`: release-versus-repository-only change classification and publication flow.
- `scripts/audit_runtime.py`: TOC/runtime/copy/policy hygiene.
- `scripts/audit_repository.py`: repository paths/encoding/secrets/module order/combat API/workflow/supply-chain governance.

The repository audit blocks combat-log decision processing, aura/health/power/cast/position decision APIs, protected action automation, secure-action automation, dynamic code execution and addon networking from the shipped runtime. Approved App extension surfaces are CI-locked. Assignment preview/announce behavior stays under `Core/AssignmentIntegration.lua` and the shared `Services/AssignmentPlanService.lua`.

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

Normal `main` pushes receive full source/reproducibility validation but do **not** publish a release automatically. Release publication is deliberate. From `main`, manually dispatch **Validate source** only after the TOC version, changelog and versioned release notes represent the intended immutable release. The workflow then verifies reproducibility, creates provenance/SBOM attestations, verifies them and creates or verifies the version-locked prerelease/tag.

## PASS-CI versus PASS-LIVE

A source/release can be **PASS-CI / technically green** when every applicable automated gate passes on the exact SHA. A full product claim additionally requires the live-only checks in `docs/LIVE_TEST_MATRIX.md`: real raid pulls, DBM/BigWigs combinations, `/reload` recovery, wipe/repull lifecycle, taint, CPU/frame-time, memory soak, UI scaling/accessibility/locales and post-hotfix tactic/timer accuracy.

CI, source review and simulated provider tests must never be recorded as `PASS-LIVE`. Missing real-client evidence remains `MANUAL TEST NEEDED`.

## Project status, roadmap and support

Raid Lead Assist is actively maintained against its documented encounter and difficulty contracts. New encounters or automation paths require explicit validation and fail-closed fallback behavior. Report reproducible defects through GitHub Issues without character, account or private raid data.

## License

This repository currently has no open-source license. Reuse, redistribution and derivative works are not permitted without explicit permission from the copyright holder.
