# Live Retail acceptance matrix

Source/CI checks cannot fill these rows. Record evidence on the exact addon SHA/version and current Retail build.

## 0.9.0-beta.52 release-candidate status — 2026-08-19

The source/release path may be marked `PASS-CI` only after the final beta.52 head passes the full workflow and the online upstream-drift check against the 2026-08-19 launch-day provider baselines.

The release remains a **prerelease/beta**, not a live-proven stable release. Do not convert any row below to `PASS-LIVE` from guides, source code, screenshots or CI alone.

Known release boundaries:

- DBM 12.1.4 is the reviewed stable DBM contract baseline; its current Venomous Abyss encounter files match the reviewed launch-day source.
- BigWigs v419.2 is the reviewed stable callback/release baseline, but it predates the finalized Coiled Altar module. Missing stable BigWigs boss bars must therefore degrade to Blizzard timeline/manual behavior without disabling RLA.
- Current BigWigs live-launch `master` modules, core callback contract and raid TOC were source-reviewed on 2026-08-19 and are pinned for drift detection; users are not expected to install unreleased source.
- Ula'tek stays manual-only on every difficulty until real Retail pulls prove stable exact timer identities and cadence.
- Season 2/The Venomous Abyss is in its launch window by region; source review can now track live-launch upstream changes, but encounter plans remain `PASS-LIVE`-pending until reproduced in the raid.

Before promoting beyond beta, record at minimum one clean supported pull/wipe lifecycle per boss on the intended release difficulty, plus the provider/failure combinations below.

## Environment matrix

For each relevant scenario record: date/region, WoW build/interface, resolution, UI scale, language, raid size, RLA version/SHA, DBM version, BigWigs version, and enabled addon set.

Test at minimum:

- 1920x1080, 2560x1440, 3840x2160 and an ultrawide resolution at representative UI scales.
- English plus at least one non-English client to prove mechanic identity is ID-driven rather than localized-string driven.
- no bossmod; DBM only; BigWigs only; DBM+BigWigs; Blizzard timeline available with each relevant combination.
- clean SavedVariables, upgraded historical SavedVariables and intentionally malformed recoverable SavedVariables.
- raid leader, raid assistant and ordinary member permissions.

## Per boss/difficulty

For every one of 8 bosses x Normal/Heroic/Mythic that is claimed live-ready, verify plan text, assignment layout, call buttons, mechanic/difficulty correctness, visible English copy, provider identities, timing precision, PREPARE/PRESS behavior, deduplication, audio, manual call send, wipe cleanup and next-pull reset.

For every timed mechanic reproduce the occurrence more than once when practical. One successful pull is not enough to prove lifecycle stability.

## Recovery and failure scenarios

- `/reload` before pull, during a supported pull and after wipe.
- disconnect/reconnect where practical.
- bossmod loaded late or disabled.
- provider timer update, pause/resume, cancel/fade and duplicate second-provider arrival.
- BigWigs v419.2 with Coiled Altar/finalized-module coverage absent: verify Blizzard/manual fallback remains usable and no stale bossmod authority suppresses the call.
- permission loss during a scheduled pre-pull briefing.
- combat starts during briefing.
- unsupported encounter, Raid Finder/Story/other unsupported difficulty and unknown context.
- no TTS voice/API available.
- full/long assignment text near Raid Warning limits.

## Taint/performance/accessibility

Capture `ADDON_ACTION_BLOCKED`/taint errors, Lua errors, CPU/frame-time and memory before pull, during event bursts and after repeated wipes. Run at least a 20-pull/wipe soak sequence for a representative timed encounter and verify no sustained timer/frame/callback/memory growth.

Verify text remains legible, controls do not overlap, PREPARE/PRESS/CALLED are distinguishable without color, long names do not destroy layout, keyboard focus where supported is usable, and critical actions remain understandable under raid time pressure.

## Ula'tek gate

Do not change `timing=false` until live evidence confirms the difficulty split and stable exact public timing identities for the mechanics RLA would consume. Provider drycode or generic Blizzard timeline fallback alone is not sufficient.
