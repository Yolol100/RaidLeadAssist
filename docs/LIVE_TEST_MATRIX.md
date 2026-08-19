# Live Retail acceptance matrix

Source/CI checks cannot fill these rows. Record evidence on the exact addon SHA/version and current Retail build.

## 0.9.0-beta.56 release-candidate status — 2026-08-19

The source/release path may be marked `PASS-CI` only after the final beta.56 head passes the full workflow and the online upstream-drift check against the latest 2026-08-19 day-one provider baselines.

The release remains a **prerelease/beta**, not a live-proven stable release. Do not convert any row below to `PASS-LIVE` from guides, source code, screenshots or CI alone.

Known release boundaries:

- DBM 12.1.4 remains the reviewed stable DBM release contract. Current `master` has continued to move after raid unlock. RLA pins the reviewed source fingerprints without requiring unreleased DBM.
- Current DBM Venomous Abyss modules can switch between reviewed hardcoded Encounter Timeline routing and fail-closed Blizzard fallback. Beta.56 therefore treats DBM timing for all eight raid encounter IDs as exact only while DBM has asserted `DBM_IgnoreBlizzAPI` authority. Once DBM resumes Blizzard, the DBM copy is preview-only until an independently exact direct source is available.
- Late day-one DBM Coiled Altar now enables preliminary Normal hardcoded timelines in addition to Heroic. Unknown/unmapped timeline rows still call `ResumeBlizzardAPI`, so RLA exactness must continue to follow DBM authority rather than the provider name.
- DBM's shared `TLBatchTrackLatest` Encounter Timeline de-duplication helper is part of the upstream drift oracle because it can change which public boss bar RLA observes without changing a boss-module call identity.
- BigWigs v419.2 remains the reviewed stable release baseline and still predates finalized live-launch coverage for parts of The Venomous Abyss. Current `master` contains additional live fixes. The latest Nek'zali change adds non-Mythic Phase 2 Possession Barrage routing; that mechanic is not a direct RLA raidleader identity but the source fingerprint is pinned for provider-currentness.
- Direct BigWigs timers preserve the upstream `isApproximate` signal. A BigWigs nil-module `StartBar` produced by the Blizzard bridge does not carry that metadata and is therefore preview-only in RLA.
- Blizzard Encounter Timeline events explicitly marked `isApproximate=true` are preview-only. They must never become actionable PREPARE/PRESS/TTS timing merely because their source is Blizzard or because a bossmod re-emits the event.
- Ula'tek stays manual-only on every difficulty until real Retail pulls prove stable exact timer identities and cadence. Provider authority hardening does not promote the encounter to timed support.
- Season 2/The Venomous Abyss is open by region; source review can track day-one upstream changes, but encounter plans remain `PASS-LIVE`-pending until reproduced in the raid.

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
- For every Venomous Abyss DBM module on current reviewed source, disable hardcoded timers or otherwise reach a state where DBM has resumed Blizzard. Verify the DBM copy becomes preview-only and cannot trigger PREPARE/PRESS/TTS solely because the callback provider is DBM.
- For every supported Venomous Abyss DBM module while `DBM_IgnoreBlizzAPI` authority is active, verify reviewed direct DBM timers may remain exact and Blizzard duplicates are suppressed only for covered calls.
- Transition from DBM hardcoded authority to Blizzard fallback during the same pull where upstream supports that recovery. Verify no stale exact timer survives the authority release and no replacement/fallback bar is precision-escalated.
- Vashnik current DBM source: exercise the new Normal hardcoded route and, if reproducible, an unmatched/bad-state timeline transition. Verify the shared `TLBatchTrackLatest` duplicate handling does not leave two RLA timers and that `ResumeBlizzardAPI` changes DBM timing to preview-only.
- Nek'zali current DBM source: verify Normal hardcoded routing and a fallback/authority release if reproducible; exactness must follow DBM authority rather than provider name.
- Coiled Altar current DBM source: exercise both the newly added Normal hardcoded route and Heroic hardcoded route, then reproduce an unmapped/bad-state fallback where practical. Confirm DBM exactness disappears immediately after `ResumeBlizzardAPI` and no stale exact timer survives into Blizzard fallback.
- Lost Explorers Normal with hardcoded timeline authority: verify reviewed direct timers may remain exact. Heroic/Mythic/current fallback and Normal with hardcoded timers disabled must remain preview-only until an independent exact source is available.
- DBM current Sentinels: verify Normal routing plus Stasis/Miasma/Protovenom identities remain correct and an authority release cannot leave stale exact bars.
- BigWigs current Sentinels: verify intermission end/reset does not leave a stale Stasis or backup bridge bar in RLA.
- DBM current Sszorak: verify Normal/Heroic calls against confirmed routing, keep Mythic `PASS-LIVE`-pending where upstream itself labels routing extrapolated, and verify fallback precision is preview-only after DBM resumes Blizzard.
- DBM/BigWigs current Twin Fangs: verify Submerge lifecycle changes do not duplicate or orphan Ravenous Feast/shared movement timing; DBM fallback precision must follow authority state.
- BigWigs current Nek'zali: repeat Phase 1 rows around the earlier Essence Rend correction and non-Mythic Phase 2 rows around the new 28-second Possession Barrage routing. Neither change may leave duplicate/stale RLA timing or create a new RLA call identity that is not explicitly registered.
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
