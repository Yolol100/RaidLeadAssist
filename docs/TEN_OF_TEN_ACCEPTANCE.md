# Raid Lead Assist — master acceptance audit

A 10/10 claim is allowed only for the scope that has matching evidence. Source/CI evidence can prove code and packaging properties; it cannot replace a live Retail client, raid pulls, accessibility hardware, or real provider behavior.

## Current release boundary

- Retail interface baseline: `120100`.
- DBM release-contract baseline: `12.1.3`.
- BigWigs release-contract baseline: `v419.2`.
- Upstream source fingerprints are stored in `docs/UPSTREAM_BASELINES.json` and checked by the scheduled `Check upstream drift` workflow.
- The Venomous Abyss Normal/Heroic/Mythic opens with the European weekly reset on 2026-08-19. Untested live rows stay `MANUAL TEST NEEDED`.
- Ula'tek remains `MANUAL CALLS ONLY` until exact public timer coverage is stable and observed live.

## Evidence classes

Use exactly one of these states per audit item:

- `PASS-CI` — deterministic source/controlled-runtime evidence exists on the exact release SHA.
- `PASS-LIVE` — reproduced in the current Retail client with recorded environment/provider evidence.
- `MANUAL TEST NEEDED` — cannot be proven by CI alone.
- `DRIFT REVIEW` — an upstream/platform source changed and the affected contract must be re-reviewed.
- `N/A` — demonstrably not applicable, with a reason.
- `FAIL` — confirmed defect; release is blocked for the affected scope.

## Master audit — 58 checks

### Platform and loading

1. TOC `Interface` matches the intended Retail build.
2. TOC runtime paths exist, are unique, safe, and load in dependency order.
3. Optional DBM/BigWigs absence never prevents addon load.
4. Every runtime Lua file parses under Lua 5.1 and passes the repository's blocking `luacheck` policy.
5. Login, `/reload`, logout/login, zoning, instance enter/leave and UI reload keep state valid.
6. Unsupported raid/difficulty state fails closed instead of retaining a prior encounter.

### Encounter and strategy data

7. All eight encounter IDs match current Retail.
8. Encounter-name aliases are fallback-only; numeric encounter identity remains authoritative.
9. Normal/Heroic/Mythic IDs map to the correct profile and lock during pulls.
10. Every pre-pull plan is checked per boss and difficulty against current Journal/live behavior.
11. Every visible combat call maps to a real raid-leader action and correct difficulty.
12. Every mechanic spell/icon/event identity is validated independently; timer keys are not assumed to equal display spell IDs.
13. Volatile tuning values are not hard-coded when sources disagree.
14. Strategy status text states its actual evidence date and never implies live validation prematurely.
15. Ula'tek Heroic does not inherit Mythic-only mechanics without live evidence.
16. Ula'tek remains manual-only until complete stable live timer coverage is proven.

### DBM, BigWigs and Blizzard timelines

17. DBM `TimerBegin` argument shape matches the pinned/current contract.
18. DBM update/stop/pause/resume/fade lifecycle preserves occurrence identity.
19. DBM module ID resolves to the actual encounter before accepting a direct timer.
20. DBM disabled/variable timers cannot drive exact RLA calls.
21. DBM Blizzard-authority handoff honors `IgnoreBlizzAPI`, bar-disable settings and resume state.
22. BigWigs `Timer` argument shape matches the pinned/current contract.
23. BigWigs `CastTimer` argument shape matches the pinned/current contract.
24. BigWigs `StartBar` bridge and direct-bar metadata are distinguished correctly.
25. Non-boss/test/statistics/keystone BigWigs timers cannot become RLA encounter calls.
26. BigWigs approximate/disabled bars never silently become exact/actionable.
27. Blizzard Encounter Timeline accepts only live encounter-source events.
28. Blizzard timeline add/change/remove/pause/cancel races fail closed on malformed/secret data.
29. Provider combinations are tested: Blizzard only, DBM only, BigWigs only, every pair, all three.
30. Provider startup/failover follows deterministic DBM > BigWigs > Blizzard priority among equally precise usable sources.
31. Cross-provider deduplication prevents duplicate calls/TTS for one occurrence.
32. Late provider arrival cannot re-arm an already acknowledged occurrence.
33. Timer correction, pause, fade and reused IDs cannot replay stale PREPARE/PRESS state.
34. `/reload` mid-pull recovery requires independent native encounter confirmation.
35. Current upstream release tags and watched contract/raid files match `UPSTREAM_BASELINES.json` or trigger `DRIFT REVIEW`.

### Calls, assignments, chat and audio

36. Raid Warning requires current leader/assistant permission.
37. Multi-line pre-pull briefing stops if combat starts, permission disappears or a send fails.
38. Briefing/call throttling does not cause spam, duplicate sends or client throttling under real raid conditions.
39. Required assignment fields, unique-player rules, overlap constraints and hard group sizes are enforced.
40. Rotation state resets on wipe/end/boss/difficulty change and advances only after a successful bound call.
41. Roster changes, realm-qualified names, offline players and subgroup moves do not corrupt saved assignments.
42. Combined base-call + assignment text is all-or-nothing; no misleading truncation.
43. TTS handles missing voice APIs and falls back safely to raid-warning sound.
44. PREPARE/PRESS audio fires once per actionable occurrence and remains off for manual-only profiles.

### SavedVariables and state recovery

45. Fresh install defaults are valid.
46. Historical schemas migrate without cross-difficulty message/assignment leakage.
47. Corrupt types, NaN/infinite positions and malformed tables recover safely.
48. A database from a newer schema is preserved/fail-safe rather than destructively downgraded.
49. Upgrade testing includes representative real SavedVariables snapshots from older releases.

### UI, accessibility, taint and performance

50. Main/settings/assignment UI works at representative 1080p, 1440p, 4K, ultrawide and WoW UI scales.
51. Keyboard focus/Tab/Shift-Tab, gamepad interaction where applicable, contrast and non-color-only state cues are usable.
52. Long names/text and supported client locales do not overflow critical controls or change mechanic identity semantics.
53. No `ADDON_ACTION_BLOCKED`/taint is caused during combat transitions and secure UI interaction.
54. CPU/frame-time during provider event storms and 20–30 player pulls stays acceptably low.
55. Memory/frame/timer/callback counts remain stable across repeated pull/wipe/reload soak tests.

### Release, security and operations

56. Release ZIP is deterministic across two clean builds, contains only intended runtime files, matches source byte-for-byte and has SHA-256 output.
57. The exact main-branch artifact has GitHub build-provenance attestation, a versioned prerelease/tag on the same SHA, durable ZIP/checksum release assets, and a previous verified release available for rollback.
58. Repository/release governance is reviewed: CI permissions least-privilege, Actions pinned by full SHA, security-reporting policy present, CODEOWNERS present, upstream drift monitored, protected-branch/ruleset policy evaluated, and license choice explicitly owned by the repository owner.

## Per-boss live execution matrix

For every boss × difficulty that is claimed live-ready, record:

- Retail build/interface and region/date.
- Boss/difficulty and pull count.
- Provider set and exact DBM/BigWigs versions.
- Encounter selection/difficulty lock result.
- Plan/call/assignment correctness.
- Every actionable timer identity/precision/provider observed.
- Dedup/failover behavior.
- `/reload` recovery where safe to test.
- wipe/end cleanup.
- `/rla doctor` and `/rla provider` output accuracy.
- taint/errors plus CPU/memory observations.

A single successful pull does not establish stability. Reproduce important timer/provider paths and at least one wipe/re-pull lifecycle before marking `PASS-LIVE`.

## Ula'tek gate

The 2026-08-17 source review found new DBM master drycode plus BigWigs timeline-backed coverage. This is useful evidence, not a live timing oracle. Specifically verify live:

- Spectral Coils and Soul Constrictor difficulty behavior.
- Doomscale/Hardened Eggs and Mass Gestation difficulty behavior.
- Grasping Fangs and Blight Vein behavior.
- Serpent's Bite, Volatile Purge and Mythic Caustic Waves interaction.
- Toxic Incubation mechanic/display identity versus provider timer keys.
- exact DBM, BigWigs and Blizzard timeline identities, repetitions and cancellation behavior.

Do not enable Ula'tek automatic timing merely because an upstream module contains placeholder/drycode timers or timeline mappings.

## Release gate

A release is `TECHNICALLY GREEN` only when the exact SHA has:

- Lua 5.1 compile PASS;
- blocking `luacheck` PASS;
- TOC inventory/metadata PASS;
- all `tests/test_*.lua` PASS;
- baseline schema PASS;
- reproducible release ZIP PASS;
- SHA-256 PASS;
- GitHub build-provenance attestation PASS;
- uploaded Actions artifact PASS;
- matching versioned prerelease/tag PASS;
- durable ZIP/checksum release assets PASS.

A full product `10/10` additionally requires every relevant live-only item above to be `PASS-LIVE`. Unavailable live evidence is never converted into a source-only pass.
