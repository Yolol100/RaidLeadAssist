# Live Retail acceptance matrix

Source/CI checks cannot fill these rows. Record evidence on the exact addon SHA/version and current Retail build.

## 0.9.0-beta.54 release-candidate status — 2026-08-19

The source/release path may be marked `PASS-CI` only after the final beta.54 head passes the full workflow and the online upstream-drift check against the latest 2026-08-19 post-unlock provider baselines.

The release remains a **prerelease/beta**, not a live-proven stable release. Do not convert any row below to `PASS-LIVE` from guides, source code, screenshots or CI alone.

Known release boundaries:

- DBM 12.1.4 remains the reviewed stable DBM release contract. Current `master` has moved materially beyond that tag after raid unlock: Sentinels gained confirmed Normal routing, Lost Explorers was rebuilt from fresh Normal evidence while Heroic/Mythic deliberately reverted to Blizzard fallback, Sszorak gained confirmed Normal/Heroic routing with explicitly extrapolated Mythic routing, and Twin Fangs received additional Submerge safety/lifecycle coverage. RLA pins the reviewed source fingerprints without requiring unreleased DBM.
- BigWigs v419.2 remains the reviewed stable release baseline and still predates finalized live-launch coverage for parts of The Venomous Abyss. Current `master` now also contains a Sentinels intermission/reset fix and additional Twin Fangs Submerge capture; these files are pinned after semantic review.
- Direct BigWigs timers preserve the upstream `isApproximate` signal. A BigWigs nil-module `StartBar` produced by the Blizzard bridge does not carry that metadata and is therefore preview-only in RLA.
- DBM Lost Explorers timing is preview-only whenever DBM has not asserted `DBM_IgnoreBlizzAPI` authority. This prevents current Heroic/Mythic Blizzard fallback from being promoted to exact merely because it arrives through a DBM callback. If DBM later gains hardcoded authority, upstream drift must be re-reviewed before the policy is changed.
- Blizzard Encounter Timeline events explicitly marked `isApproximate=true` are preview-only. They must never become actionable PREPARE/PRESS/TTS timing merely because their source is Blizzard or because a bossmod re-emits the event.
- Ula'tek stays manual-only on every difficulty until real Retail pulls prove stable exact timer identities and cadence.
- Season 2/The Venomous Abyss is open by region; source review can track post-unlock upstream changes, but encounter plans remain `PASS-LIVE`-pending until reproduced in the raid.

Before promoting beyond beta, record at minimum one clean supported pull/wipe lifecycle per boss on the intended release difficulty, plus the provider/failure combinations below.

## Environment matrix

For each relevant scenario record: date/region, WoW build/interface, resolution, UI scale, language, raid size, RLA version/SHA, DBM version, BigWigs version, and enabled addon set.

Test at minimum:

- 1920x1080, 2560x1440, 3840x2160 and an ultrawide resolution at representative UI scales.
- English plus at least one non-English client to prove mechanic identity is ID-driven rather than localized-string driven.
- no bossmod; DBM stable only; current DBM source where practical; BigWigs stable only; current BigWigs source where practical; DBM+BigWigs; Blizzard timeline available with each relevant combination.
- clean SavedVariables, upgraded historical SavedVariables and intentionally malformed recoverable SavedVariables.
- raid leader, raid assistant and ordinary member permissions.

## Per boss/difficulty

For every one of 8 bosses x Normal/Heroic/Mythic that is claimed live-ready, verify plan text, assignment layout, call buttons, mechanic/difficulty correctness, visible English copy, provider identities, timing precision, PREPARE/PRESS behavior, deduplication, audio, manual call send, wipe cleanup and next-pull reset.

For every timed mechanic reproduce the occurrence more than once when practical. One successful pull is not enough to prove lifecycle stability.

## Recovery, precision and provider scenarios

- `/reload` before pull, during a supported pull and after wipe.
- disconnect/reconnect where practical.
- bossmod loaded late or disabled.
- provider timer update, pause/resume, cancel/fade and duplicate second-provider arrival.
- A Blizzard Encounter Timeline event with `isApproximate=false`: verify it can remain native/actionable when all normal encounter and authority checks pass.
- A Blizzard Encounter Timeline event with `isApproximate=true`: verify it can appear as preview timing but cannot drive actionable PREPARE/PRESS/TTS state.
- Malformed/secret approximation metadata or invalid timeline event state: verify the event fails closed and creates no actionable timer.
- BigWigs direct `BigWigs_Timer` with `isApproximate=false`: verify direct boss-module timing may remain exact.
- BigWigs direct `BigWigs_Timer` with `isApproximate=true`: verify it remains preview-only.
- BigWigs Blizzard-bridge `BigWigs_StartBar` with nil module/key and a native event ID: verify it is preview-only even if the underlying event happens to be exact, because the bridge callback does not expose `isApproximate`. The direct Blizzard provider may still supply an actionable copy when Blizzard itself proves the event exact.
- DBM Lost Explorers Normal with hardcoded timeline authority (`DBM_IgnoreBlizzAPI` active): verify reviewed direct timers may remain exact and Blizzard duplicates are suppressed only for covered calls.
- DBM Lost Explorers Heroic/Mythic on current `master`: verify DBM's deliberate Blizzard fallback is preview-only in RLA and cannot trigger PREPARE/PRESS/TTS merely because the callback provider is DBM.
- Disable DBM hardcoded timers on Lost Explorers Normal: verify precision falls back to preview-only until an exact native/direct source is independently available.
- Re-enable/restore DBM hardcoded authority or wipe/reload: verify the authority transition does not leave stale exact/preview timers behind.
- DBM current Sentinels: verify Normal routing plus Stasis/Miasma/Protovenom identities remain correct after the post-unlock routing update.
- BigWigs current Sentinels: verify intermission end/reset does not leave a stale Stasis or backup bridge bar in RLA.
- DBM current Sszorak: verify Normal/Heroic calls against confirmed routing and keep Mythic `PASS-LIVE`-pending where upstream itself labels routing extrapolated.
- DBM/BigWigs current Twin Fangs: verify Submerge lifecycle changes do not duplicate or orphan Ravenous Feast/shared movement timing.
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
