# Live Retail acceptance matrix

Source/CI checks cannot fill these rows. Record evidence on the exact installed addon SHA/version and current Retail build. Repository-only commits may advance `main` without changing a published package; live evidence therefore names the installed addon version/SHA rather than assuming that `main` equals a release tag.

## Current source/runtime candidate — 0.9.0-beta.67 — 2026-09-13

The current source/runtime candidate is `0.9.0-beta.67`. The published `0.9.0-beta.63` remains the last separately evidenced prerelease baseline unless a newer GitHub release/tag is independently verified. Do not describe beta67 as a published/tagged release from source state alone.

`PASS-CI` means source/build validation only. `PASS-LIVE` requires the exact installed beta67 candidate to pass the applicable rows below in a real Retail client. Do not convert any row to `PASS-LIVE` from guides, source code, screenshots from another build, upstream source review or CI alone.

Current provider baselines for live evidence remain those actually exercised on 2026-08-31:

- DBM live-tested stable is **12.1.6**, release commit `c08dbfd91a006bad45352ea0d3d1a0cc1bc8367e`. The current source-reviewed stable is **12.1.9**; source review does not replace live evidence.
- The watched DBM Venomous Abyss encounter files retain the reviewed numeric mechanic identities consumed by RLA. Nek'zali's dual Hungering Pyre identities `1305421`/`1290679` remain intentionally mapped to the same RLA call.
- BigWigs live-tested stable is **v424.1**, release commit `2f04791c4ac04a13f96757298e407014682d6d12`. The current source-reviewed stable is **v424.8**; source review does not replace live evidence.
- Exact current source-reviewed releases and current-master fingerprints are stored in `docs/UPSTREAM_BASELINES.json` and are checked online in PRs plus twice daily. An unrecorded upstream state is a new `DRIFT REVIEW`, not automatic evidence of compatibility.
- Current DBM Venomous Abyss modules can switch between hardcoded Encounter Timeline routing and fail-closed Blizzard fallback. RLA treats DBM timing as exact only while DBM has asserted `DBM_IgnoreBlizzAPI` authority and can actually supply enabled boss timers. After `DBM_ResumeBlizzAPI`, the DBM copy must not remain actionable merely because its provider name is DBM.
- BigWigs direct timers preserve the upstream `isApproximate` signal. A BigWigs nil-module `StartBar` produced by the Blizzard bridge does not expose that signal and is therefore preview-only in RLA.
- Blizzard Encounter Timeline events explicitly marked `isApproximate=true` are preview-only. They must never become actionable PREPARE/PRESS/TTS timing merely because their source is Blizzard or because a bossmod re-emits the event.
- Beta67 introduces a bounded Ula'tek timing set from stable public spell identities plus explicit raid-leader assignment layouts. This is **source/CI reviewed only** until the exact beta67 package is exercised in Retail. Approximate provider data must remain preview-only and manual milestones must remain manual.
- Season 2/The Venomous Abyss is live by region. Source review can prove contract compatibility, not real pull cadence or encounter correctness; those remain `PASS-LIVE`-pending until reproduced in Retail.

Before using beta67 for a raid, complete at least the short **Tonight smoke gate** plus the relevant boss/provider rows for the encounters you intend to run. Before promoting beyond beta, complete the broader matrix and record at minimum one clean supported pull/wipe lifecycle per claimed boss/difficulty.

## Tonight smoke gate — minimum before raid use

Record one evidence line per item with date/time, Retail build, installed RLA SHA/version and provider versions.

- [ ] Launch Retail 12.1.x with the exact beta67 candidate and confirm RLA loads without Lua error.
- [ ] `/reload` once and confirm SavedVariables/UI/provider state reconstructs without error.
- [ ] Open RLA through its normal UI and AddOn Compartment path; left-click toggles raid controls and right-click opens settings.
- [ ] With no bossmod active, select one supported encounter and verify manual calls remain usable and no provider failure creates an actionable phantom timer.
- [ ] With **DBM 12.1.6**, start one supported Normal/Heroic encounter or reproducible provider test path and verify encounter identity, one timer occurrence, PREPARE/PRESS ordering and wipe/reset cleanup.
- [ ] With **BigWigs v424.1**, repeat the same minimal lifecycle and verify exact/approximate semantics are respected.
- [ ] With both bossmods enabled where practical, verify duplicate representations collapse to one mechanic occurrence and provider priority does not create double PREPARE/PRESS/TTS.
- [ ] Verify one Blizzard `isApproximate=true` timeline item cannot drive actionable PREPARE/PRESS/TTS.
- [ ] Wipe/restart once and confirm no stale timer, call acknowledgement, assignment or provider authority survives into the next pull.
- [ ] Capture Lua/taint output for the smoke run; any `ADDON_ACTION_BLOCKED`, Lua error, duplicate actionable call or stale next-pull timer is a **NO-GO** until reproduced and fixed.

If the raid includes Nek'zali, Twin Fangs, Coiled Altar, Lost Explorers or Ula'tek, also execute their current-provider focused rows below because reviewed provider routing, live hotfixes or precision behavior changed around those encounters during the current release window. If testing current/unreleased bossmod source, record that exact source SHA and include the current-master checks below.

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
- **Coiled Altar / beta67 Normal/Heroic:** verify a 3-player Guillotine assignment passes RLA validation and is accepted by the live mechanic without the minimum-player failure penalty. Also verify the Heroic second Guillotine advances to the other assigned group.
- **Coiled Altar / beta67 Mythic:** verify RLA still requires fresh 5+ groups and does not apply the Normal/Heroic 3-player hotfix to Mythic.
- **Coiled Altar / beta67 recovery:** wipe during or immediately around Soulbinding/intermission, repull, and verify no stale Guillotine, Dreadmarch, Nightfall, assignment rotation or PREPARE/PRESS state carries into the next attempt.
- Vashnik current DBM source: verify the reviewed numeric identities remain bound to the same RLA calls and an authority release cannot leave a stale exact bar.
- **Lost Explorers / current DBM source:** verify encounter `3497`, Throw Junk `1291933`, Final Ascension `1292779` and Mighty Thud `1296092` map to the intended RLA mechanics under the new Mythic routing; verify fallback and repeated-stage transitions create no duplicate actionable occurrence.
- DBM current Sentinels: verify Stasis/Miasma/Protovenom numeric identities remain correct and an authority release cannot leave stale exact bars.
- BigWigs current Sentinels: verify intermission end/reset does not leave a stale Stasis or backup bridge bar in RLA.
- DBM current Sszorak: verify Venomous Surge/Raging Crosswinds numeric IDs `1305959`/`1285425` continue to select the intended RLA calls.
- **Twin Fangs / DBM 12.1.6 + BigWigs v424.1:** verify Ravenous Feast and shared movement timing remain one occurrence across providers and fallback precision follows authority state.
- **Twin Fangs / current BigWigs source:** exercise the new Mythic submerge timeline route and verify it does not duplicate or misidentify RLA's existing shared movement/call occurrences.
- **BigWigs current master core:** confirm the observed `BigWigs_Timer`/`BigWigs_CastTimer`/`BigWigs_StartBar` callback shapes remain compatible when testing current source; source-reviewed v424.8 changes do not widen RLA's timer boundary.
- **Ula'tek / beta67 Normal with current DBM:** verify exact provider timers for Caustic Waves `1292188`, Spectral Coils `1300530`, Rage of the Shackled `1286860`, Call of the Serpent `1300751`, Serpent's Bite `1295905` and Circling Prey `1301510` select the intended RLA call exactly once per occurrence. Confirm the raid-wide Coil soak still meets 40%+, left/right egg carriers are shown and all three Bite helper sectors are present.
- **Ula'tek / beta67 Heroic with current DBM:** repeat the selected timer checks; confirm two near-equal Coil teams alternate correctly, each called soak meets 40%+, the same split maps cleanly to left/right Phase 2, left/right egg carriers are clear, three Grasping Fangs targets per side are handled sequentially and all three Bite helper sectors are used before Purge moves 7+ yards out.
- **Ula'tek / beta67 with current BigWigs:** repeat Normal/Heroic selected-timer checks and verify direct approximate bars stay preview-only, exact bars may become actionable, and Blizzard-bridge copies do not create duplicate PREPARE/PRESS/TTS.
- **Ula'tek / beta67 Mythic:** verify Toxic Incubation provider key `1299757` resolves to the Incubation call while display spell `1299759` remains UI-only; verify alternating Coil teams, left/right egg carriers, all three Bite helper sectors, the 4+ Incubation team and safe Purge-wave directions remain intact.
- **Ula'tek / beta67 manual boundaries:** Doomscale Warden, Doomscale Eggs, Grasping Fangs and generic Phase 3 remain manual and never become automatically timed just because a bossmod exposes related traffic. Confirm the generic Phase 3 call does not force a specific Bloodlust window.
- **Ula'tek / beta67 assignment safety:** remove one required Heroic Coil team, duplicate a player across Coil teams, duplicate the same egg carrier on both sides and overlap two Bite helper sectors. Each invalid setup must fail closed and must not silently become raid-ready.
- **Ula'tek / beta67 Serpent's Bite:** verify melee, ranged and healer-target helper sectors are understandable under combat pressure, Bite targets have enough time to reach helpers, the handoff fully clears, Purge carriers move 7+ yards out, and on Mythic the follow-up Purge waves are aimed safely without making the call materially early/late.
- **Ula'tek / beta67 Caustic Waves:** confirm the live no-swim-under behavior and that the raid-leader call consistently points players toward the safe gap without encouraging an invalid route.
- **Ula'tek / beta67 lifecycle:** exercise phase changes, custom Encounter Timeline additions, `/reload`, provider switch/fallback, wipe and repull. No timer, acknowledgement, assignment rotation or audio state may carry into the next pull.
- permission loss during a scheduled pre-pull briefing.
- combat starts during briefing.
- unsupported encounter, Raid Finder/Story/other unsupported difficulty and unknown context.
- no TTS voice/API available.
- full/long assignment text near Raid Warning limits.

## Taint/performance/accessibility

Capture `ADDON_ACTION_BLOCKED`/taint errors, Lua errors, CPU/frame-time and memory before pull, during event bursts and after repeated wipes. Run at least a 20-pull/wipe soak sequence for a representative timed encounter and verify no sustained timer/frame/callback/memory growth.

Verify text remains legible, controls do not overlap, PREPARE/PRESS/CALLED are distinguishable without color, long names do not destroy layout, keyboard focus where supported is usable, and critical actions remain understandable under raid time pressure. Include a short-height/UI-scale pass that forces the combat-call list to scroll, because Ula'tek Mythic has one of the largest call sets.

## Ula'tek beta67 acceptance gate

The product/tactic review in `docs/FINAL_BOSSES_REVIEW_2026-09-13.md` allows a bounded set of source/CI-reviewed Ula'tek calls to use exact/native public provider timing and adds explicit raid-leader assignment layouts. That is not a `PASS-LIVE` claim.

For each claimed difficulty require real Retail evidence of:

- stable exact public identities and useful cadence for every selected timed call;
- no approximate-to-actionable precision escalation;
- no cross-encounter or stale-pull match;
- repeated occurrence deduplication with DBM, BigWigs and practical combined-provider scenarios;
- correct difficulty-specific assignments: Normal raid-wide Coils, Heroic/Mythic alternating Coil teams, left/right egg carriers, three Bite helper sectors, plus Mythic Incubation;
- correct fail-closed behavior when required assignments are missing or overlapping;
- correct manual-only behavior for Warden, Eggs, Fangs and generic Phase 3 calls;
- wipe/repull, `/reload` and provider recovery;
- current post-hotfix tactic text matching what players actually execute;
- no taint, Lua errors or material frame-time/memory regression.

Until those rows are recorded against the exact installed beta67 SHA, describe Ula'tek as **selected timing and assignment strategy enabled in source/CI; PASS-LIVE pending**.
