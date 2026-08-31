# Live Retail acceptance matrix

Source/CI checks cannot fill these rows. Record evidence on the exact installed addon SHA/version and current Retail build. Repository-only commits may advance `main` without changing a published package; live evidence therefore names the installed addon version/SHA rather than assuming that `main` equals a release tag.

## Tonight source/runtime candidate — 0.9.0-beta.65 — 2026-08-31

The current source/runtime candidate is `0.9.0-beta.65`. The published `0.9.0-beta.63` remains the last separately evidenced prerelease baseline. Do not describe beta65 as a published/tagged release unless that state is independently verified.

`PASS-CI` means source/build validation only. `PASS-LIVE` requires the exact installed beta65 candidate to pass the applicable rows below in a real Retail client. Do not convert any row to `PASS-LIVE` from guides, source code, screenshots from another build, upstream source review or CI alone.

Current provider baselines for tonight:

- DBM stable is **12.1.6**, release commit `c08dbfd91a006bad45352ea0d3d1a0cc1bc8367e`. Current reviewed `master` changed the watched Timer implementation so DBM itself distinguishes exact `next*` timers from approximate cooldown-style timers with the full timer type; RLA now applies the same distinction to external callbacks.
- The watched DBM Venomous Abyss encounter files retain the reviewed numeric mechanic identities consumed by RLA. Nek'zali's dual Hungering Pyre identities `1305421`/`1290679` remain intentionally mapped to the same RLA call.
- BigWigs stable is **v424.1**, release commit `2f04791c4ac04a13f96757298e407014682d6d12`. Current reviewed `master` changes in `Core/BossPrototype.lua` add non-timer helpers/sorting, Twin Fangs adds Mythic submerge routing, and Coiled Altar fixes a Phase 2 state-transition race. The timer callback shapes RLA consumes remain compatible.
- Exact current-master fingerprints are stored in `docs/UPSTREAM_BASELINES.json` and are checked online in PRs plus twice daily. An unrecorded upstream state is a new `DRIFT REVIEW`, not automatic evidence of compatibility.
- Current DBM Venomous Abyss modules can switch between hardcoded Encounter Timeline routing and fail-closed Blizzard fallback. RLA treats DBM timing as exact only while DBM has asserted `DBM_IgnoreBlizzAPI` authority and can actually supply enabled boss timers. After `DBM_ResumeBlizzAPI`, the DBM copy must not remain actionable merely because its provider name is DBM.
- BigWigs direct timers preserve the upstream `isApproximate` signal. A BigWigs nil-module `StartBar` produced by the Blizzard bridge does not expose that signal and is therefore preview-only in RLA.
- Blizzard Encounter Timeline events explicitly marked `isApproximate=true` are preview-only. They must never become actionable PREPARE/PRESS/TTS timing merely because their source is Blizzard or because a bossmod re-emits the event.
- Ula'tek remains manual-only in RLA even though current DBM/BigWigs contain encounter timing. Provider availability alone must not promote any Ula'tek call to automatic PREPARE/PRESS/TTS.
- Season 2/The Venomous Abyss is live by region. Source review can prove contract compatibility, not real pull cadence or encounter correctness; those remain `PASS-LIVE`-pending until reproduced in Retail.

Before using beta65 for a raid, complete at least the short **Tonight smoke gate** plus the relevant boss/provider rows for the encounters you intend to run. Before promoting beyond beta, complete the broader matrix and record at minimum one clean supported pull/wipe lifecycle per claimed boss/difficulty.

## Tonight smoke gate — minimum before raid use

Record one evidence line per item with date/time, Retail build, installed RLA SHA/version and provider versions.

- [ ] Launch Retail 12.1.x with the exact beta65 candidate and confirm RLA loads without Lua error.
- [ ] `/reload` once and confirm SavedVariables/UI/provider state reconstructs without error.
- [ ] Open RLA through its normal UI and AddOn Compartment path; left-click toggles raid controls and right-click opens settings.
- [ ] With no bossmod active, select one supported encounter and verify manual calls remain usable and no provider failure creates an actionable phantom timer.
- [ ] With **DBM 12.1.6**, start one supported Normal/Heroic encounter or reproducible provider test path and verify encounter identity, one timer occurrence, PREPARE/PRESS ordering and wipe/reset cleanup.
- [ ] With **BigWigs v424.1**, repeat the same minimal lifecycle and verify exact/approximate semantics are respected.
- [ ] With both bossmods enabled where practical, verify duplicate representations collapse to one mechanic occurrence and provider priority does not create double PREPARE/PRESS/TTS.
- [ ] Verify one Blizzard `isApproximate=true` timeline item cannot drive actionable PREPARE/PRESS/TTS.
- [ ] Wipe/restart once and confirm no stale timer, call acknowledgement, assignment or provider authority survives into the next pull.
- [ ] Capture Lua/taint output for the smoke run; any `ADDON_ACTION_BLOCKED`, Lua error, duplicate actionable call or stale next-pull timer is a **NO-GO** until reproduced and fixed.

If the raid includes Nek'zali, Twin Fangs or Coiled Altar, also execute their current-provider focused rows below because reviewed provider routing or precision behavior changed around those encounters during the current release window. If testing current/unreleased bossmod source, record that exact source SHA and include the current-master checks below.

## Environment matrix

For each relevant scenario record: date/region, WoW build/interface, resolution, UI scale, language, raid size, RLA version/SHA, DBM version, BigWigs version, and enabled addon set.

Test at minimum:

- 1920x1080, 2560x1440, 3840x2160 and an ultrawide resolution at representative UI scales.
- English plus at least one non-English client to prove mechanic identity is ID-driven rather than localized-string driven.
- no bossmod; DBM **12.1.6** only; current DBM source where practical; BigWigs **v424.1** only; current BigWigs source where practical; DBM+BigWigs; Blizzard timeline available with each relevant combination.
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
- For every Venomous Abyss DBM module on the current reviewed source, disable hardcoded timers or otherwise reach a state where DBM has resumed Blizzard. Verify the DBM copy becomes preview-only and cannot trigger PREPARE/PRESS/TTS solely because the callback provider is DBM.
- For every supported Venomous Abyss DBM module while `DBM_IgnoreBlizzAPI` authority is active, verify reviewed direct DBM timers may remain exact and Blizzard duplicates are suppressed only for covered calls.
- Transition from DBM hardcoded authority to Blizzard fallback during the same pull where upstream supports that recovery. Verify no stale exact timer survives the authority release and no replacement/fallback bar is precision-escalated.
- **DBM 12.1.6 timer precision:** reproduce one exact `next`/`nextcount` style timer and one approximate cooldown/variance timer that both arrive with simplified cooldown-style callback metadata. Verify RLA keeps the full-type exact timer actionable and the approximate timer preview-only; malformed/secret full-type metadata must downgrade rather than escalate precision.
- **DBM 12.1.6 shared batching regression:** reproduce two legitimate overlapping timeline timers with the same rounded duration where practical and verify batching does not cause RLA to drop the surviving legitimate occurrence or emit duplicate PREPARE/PRESS for a superseded event.
- **Nek'zali / DBM 12.1.6:** verify current live Normal/Heroic routing for Restless Amani, Hungering Pyre, Invoke and Grasping Depths against RLA's registered spell identities. If DBM hits an unmatched state and resumes Blizzard, RLA exactness must drop immediately rather than remaining exact by provider name.
- **Nek'zali / current DBM source:** verify Hungering Pyre timer ID `1305421` selects the same RLA Pyre call as legacy/release identity `1290679`; repeated Pyres must not duplicate or re-arm the same occurrence.
- **Nek'zali / BigWigs v424.1:** verify the current direct timer identities/counters are mapped to the intended RLA calls and repeated Phase 1/2 occurrences do not leave stale or duplicate timers.
- **Coiled Altar / DBM 12.1.6:** exercise current Normal/Heroic routing and at least one phase/intermission transition. Confirm `ResumeBlizzardAPI` removes DBM exact authority and no stale exact timer survives into the fallback representation.
- **Coiled Altar / current DBM source:** verify watched mechanic identities remain stable and current routing does not create duplicate bars across phase/intermission transitions.
- **Coiled Altar / BigWigs v424.1:** exercise phase/intermission handling; numeric spell-key mapping must continue to select the same RLA mechanic and wipe/reset must clear the bar.
- **Coiled Altar / current BigWigs source:** specifically exercise the Phase 2 transition affected by the upstream next-frame state-3 race fix and verify RLA receives one coherent occurrence without stale or duplicate timer state.
- Vashnik current DBM source: verify the reviewed numeric identities remain bound to the same RLA calls and an authority release cannot leave a stale exact bar.
- Lost Explorers with current DBM source: verify direct supported timers map to the correct mechanic and any Blizzard fallback remains preview-only unless independently exact.
- DBM current Sentinels: verify Stasis/Miasma/Protovenom numeric identities remain correct and an authority release cannot leave stale exact bars.
- BigWigs current Sentinels: verify intermission end/reset does not leave a stale Stasis or backup bridge bar in RLA.
- DBM current Sszorak: verify Venomous Surge/Raging Crosswinds numeric IDs `1305959`/`1285425` continue to select the intended RLA calls.
- **Twin Fangs / DBM 12.1.6 + BigWigs v424.1:** verify Ravenous Feast and shared movement timing remain one occurrence across providers and fallback precision follows authority state.
- **Twin Fangs / current BigWigs source:** exercise the new Mythic submerge timeline route and verify it does not duplicate or misidentify RLA's existing shared movement/call occurrences.
- **BigWigs current master core:** because post-v424.1 `BossPrototype.lua` changes are non-timer aura/sorting/difficulty helpers, confirm the observed `BigWigs_Timer`/`BigWigs_CastTimer`/`BigWigs_StartBar` callback shapes remain compatible when testing master rather than v424.1.
- **Current DBM Ula'tek:** provider traffic may be visible in diagnostics, but all RLA Ula'tek calls must remain `MANUAL CALLS ONLY`; no automatic timeline state, PREPARE/PRESS audio or automatic call acknowledgement may occur even while DBM hardcoded authority is active.
- BigWigs current Ula'tek on Normal, Heroic and Mythic: provider traffic may appear in diagnostics, but the Ula'tek profile must remain `MANUAL CALLS ONLY`; no automatic timeline state, PREPARE/PRESS audio or automatic call acknowledgement may occur.
- BigWigs current Ula'tek: exercise phase changes, custom Encounter Timeline additions and repeat/wipe lifecycle. Provider timer churn must not silently turn any `timing=false` Ula'tek call into a timed call or carry stale timer state into the next pull.
- permission loss during a scheduled pre-pull briefing.
- combat starts during briefing.
- unsupported encounter, Raid Finder/Story/other unsupported difficulty and unknown context.
- no TTS voice/API available.
- full/long assignment text near Raid Warning limits.

## Taint/performance/accessibility

Capture `ADDON_ACTION_BLOCKED`/taint errors, Lua errors, CPU/frame-time and memory before pull, during event bursts and after repeated wipes. Run at least a 20-pull/wipe soak sequence for a representative timed encounter and verify no sustained timer/frame/callback/memory growth.

Verify text remains legible, controls do not overlap, PREPARE/PRESS/CALLED are distinguishable without color, long names do not destroy layout, keyboard focus where supported is usable, and critical actions remain understandable under raid time pressure.

## Ula'tek gate

Current bossmod source provides Ula'tek timer/event coverage, but do not change `timing=false` from source availability alone. Require live evidence for each difficulty, stable exact public timer identities/cadence, lifecycle behavior across repeated pulls, and a separate product review of which shared raid-leader calls genuinely benefit from automation. Until then, exact bossmod traffic is diagnostic/provider input only and RLA stays manual-only.
