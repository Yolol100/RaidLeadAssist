# Raid Lead Assist

> **Portfolio status:** Flagship · active development · WoW raid-lead addon

## At a glance

Raid Lead Assist is a fail-closed raid-leader callout and assignment panel for The Venomous Abyss. It supports separate Normal, Heroic and Mythic strategy profiles while leaving protected combat decisions to players.

| Area | Evidence |
| --- | --- |
| Audience | Raid leaders who need repeatable pre-pull plans and bounded manual callouts |
| Stack | Lua, WoW Retail APIs and GitHub Actions validation |
| Coverage | Eight encounters and 24 difficulty-specific profiles |
| Safety | Unknown encounters, unsupported difficulties and stale or malformed state disable automation |
| Quality | Validation workflow plus upstream-drift monitoring |

## Quick start

1. Download a validated addon package from GitHub Releases when available.
2. Extract it into the WoW Retail `Interface/AddOns` directory.
3. Enable Raid Lead Assist and configure assignments outside combat.
4. Use preview and preset tools before announcing a plan to raid chat.

## Runtime model

```text
encounter + difficulty context → validated strategy profile
                               → pre-pull assignments / manual callouts
                               → optional bounded timing feedback
unknown or invalid state       → automatic behavior disabled
```

Raid Lead Assist (RLA) is a raid-leader callout panel for **The Venomous Abyss** with separate Normal, Heroic and Mythic strategy profiles. It provides pre-pull plans, boss-specific assignments, manual Raid Warning buttons, optional PREPARE/PRESS timing state and TTS/sound feedback.

RLA is deliberately fail-closed: uncertain encounter identity, unsupported difficulty, malformed/secret timing values, stale cross-encounter state or incomplete provider data disable automatic behavior rather than reuse an old profile. It is not a DBM/BigWigs replacement and does not automate protected combat decisions.

## Encounter, calls and assignments

RLA supports eight encounters and 24 Normal/Heroic/Mythic profiles. During a supported encounter WoW's encounter/difficulty context locks the active profile. Unknown encounters and unsupported difficulties disable calls/timing. Pre-pull plans cannot be sent during an active encounter.

Assignments are configured before combat through `ASSIGN`, Settings or `/rla assignments`. PLAYER/GROUP, ROTATION, RULE and SEQUENCE fields are validated per boss/difficulty. Duplicate/overlapping players and hard group-size constraints are rejected where the tactic requires it. Rotation advances only after the matching manual Raid Warning succeeds.

The assignment window also owns local planning tools. `PREVIEW` validates the current unsaved draft and prints the exact assignment plan locally without saving it or sending anything to raid chat. `PRESETS` stores up to eight validated plans per boss/difficulty and `MY TASKS` prints the current player's direct, rotation and raid-group duties. Preview and announce share one bounded plan renderer, so the local inspection path cannot drift from the actual pre-pull assignment announcement. None of these tools add addon networking or live combat scanning; slash equivalents remain available for power users where applicable.

## Timer sources

RLA consumes public **DBM**, **BigWigs** and Blizzard Encounter Timeline timing. Among equally precise usable representations it prefers DBM, then BigWigs, then Blizzard. Exact/native sources may drive PREPARE/PRESS/TTS; approximate bars remain non-actionable previews.

Provider payloads are untrusted runtime input. Secret, malformed, stale or cross-encounter data is rejected/downgraded. Direct bossmod timers must resolve to the verified active encounter. Cross-provider occurrence reconciliation prevents duplicate calls/audio and a successful manual call acknowledges the occurrence so a late provider cannot immediately re-arm it.

The current **source-reviewed** stable provider contracts are **DBM 12.1.9** and **BigWigs v424.8**. `docs/UPSTREAM_BASELINES.json` pins those releases plus the exact watched current-`master` files re-reviewed on **2026-09-13**, while Blizzard's live generated Encounter Timeline contract remains unchanged. DBM's recent Venomous Abyss changes concentrate on Lost Explorers routing, Sentinels/Coiled Altar recovery and Vashnik warning handling; BigWigs v424.8 includes Venomous Abyss aura updates and a Mythic Sszorak Venomous Surge special case. RLA continues to consume resolved public timer durations rather than copying private bossmod schedules; see `docs/PROVIDER_REVIEW_2026-09-13.md`.

Source review is deliberately separate from **live-tested** evidence. The current runtime doctor/live matrix still records DBM 12.1.6 and BigWigs v424.1 as the last live-tested contracts until fresh Retail evidence is collected. A newer source-reviewed pin therefore means “contract inspected and CI-compatible”, not “proved in a real raid client”. When a bossmod cannot provide a usable matching timer, RLA intentionally falls back to Blizzard Encounter Timeline data for supported calls. Manual calls remain available independently of bossmod timing.

## Final two bosses

The current tactic/runtime review for **The Coiled Altar** and **Ula'tek** is recorded in `docs/FINAL_BOSSES_REVIEW_2026-09-13.md`.

For The Coiled Altar, Normal/Heroic Guillotine now follows Blizzard's live **3-player minimum** while Heroic keeps alternating assigned teams. Mythic remains on fresh 5+ groups because the 3-player hotfix does not include Mythic. The intermission call keeps the current progression strategy of using Bloodlust during Soulbinding's Zul'jan damage window and staggering fragment interceptions.

Ula'tek is no longer globally manual-only. RLA now permits fail-closed exact/native provider timing for a deliberately limited set of stable public DBM/BigWigs identities: Caustic Waves, Spectral Coils, Rage of the Shackled, Call of the Serpent, Serpent's Bite, Circling Prey and Mythic Toxic Incubation. Approximate provider data remains preview-only; Doomscale Warden, egg choices, Grasping Fangs execution and the generic Phase 3 transition remain manual raid-leader calls.

Provider timer identity stays separate from display spell identity. Mythic Toxic Incubation, for example, matches the reviewed provider timer key `1299757` while the UI can retain display spell `1299759`. Current bossmod source identifies `1301510` as the Circling Prey/platform-break timing identity; the stale Demolish assumption is regression-blocked.

This beta.67 change is **source/CI reviewable but not yet PASS-LIVE**. Real Retail pulls are still required to prove exact Ula'tek lead windows, Coiled Altar repull recovery, taint, performance and current post-hotfix raid execution.

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
- `docs/PROVIDER_REVIEW_2026-09-13.md`: current Midnight/DBM/BigWigs provider-drift review, cleanup decision and targeted live-regression gates.
- `docs/FINAL_BOSSES_REVIEW_2026-09-13.md`: live-hotfix, bossmod, guide/video and RWF review for The Coiled Altar and Ula'tek plus the beta.67 tactic/timing decisions.
- `docs/AUDIT_SOURCES.md`: source register through its recorded review date; newer provider drift is tracked in the dated provider review above.
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

## Project status, roadmap and support

Raid Lead Assist is actively maintained against its documented encounter and difficulty contracts. New encounters or automation paths require explicit validation and fail-closed fallback behavior. Report reproducible defects through [GitHub Issues](https://github.com/Yolol100/RaidLeadAssist/issues) without character, account or private raid data.

## License

This repository currently has no open-source license. Reuse, redistribution and derivative works are not permitted without explicit permission from the copyright holder.
