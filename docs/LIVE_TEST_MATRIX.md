# Live Retail acceptance matrix

Source/CI checks cannot fill these rows. Record evidence on the exact installed addon SHA/version and current Retail build. Repository-only commits may advance `main` without changing a published package; live evidence therefore names the installed addon version/SHA rather than assuming that `main` equals a release tag.

## Tonight source/runtime candidate — 0.9.0-beta.64 — 2026-08-21

The current source/runtime candidate on `main` is `0.9.0-beta.64`. The previously published `0.9.0-beta.63` remains the last separately evidenced prerelease baseline. During the 2026-08-21 re-audit, a `0.9.0-beta.64` Git ref did not resolve, so do not describe beta64 as a published/tagged release unless that changes and is independently verified.

`PASS-CI` means source/build validation only. `PASS-LIVE` requires the exact installed beta64 candidate to pass the applicable rows below in a real Retail client. Do not convert any row to `PASS-LIVE` from guides, source code, screenshots from another build, upstream source review or CI alone.

Current provider baselines for tonight:

- DBM stable: **12.1.5**, release commit `9a3ab9e404312b2515f0143a67a1d8392e9ad6a2`. RLA's 2026-08-21 source review confirms the public DBM Timer callback file used by the provider remained byte-identical to the prior reviewed contract, while DBM's shared Encounter Timeline batching and all eight Venomous Abyss encounter modules changed since 12.1.4. Those changed routes therefore require focused live provider checks below.
- DBM current `master` is also watched separately because it can advance after the stable release. The exact watched file hashes are stored in `docs/UPSTREAM_BASELINES.json`; do not substitute an unrecorded upstream state for the stable baseline without updating the evidence.
- BigWigs stable: **v421.6**, release commit `113c7f2169e14f5959cd2d45c0d4fc22d6a739ce`. The public `BigWigs_Timer`, `BigWigs_CastTimer` and normal `BigWigs_StartBar` message contracts remain byte-identical to the previous reviewed RLA contract.
- Current BigWigs `master` is watched separately. After v421.6 the reviewed relevant change is Coiled Altar intermission handling plus a difficulty-specific Spiritcackle display rename. RLA matches numeric spell IDs before timer names, so that rename is not a source-level call-selection dependency; intermission/lifecycle behavior remains a live gate.
- Current DBM Venomous Abyss modules can switch between hardcoded Encounter Timeline routing and fail-closed Blizzard fallback. RLA treats DBM timing as exact only while DBM has asserted `DBM_IgnoreBlizzAPI` authority and can actually supply enabled boss timers. After `DBM_ResumeBlizzAPI`, the DBM copy must not remain actionable merely because its provider name is DBM.
- BigWigs direct timers preserve the upstream `isApproximate` signal. A BigWigs nil-module `StartBar` produced by the Blizzard bridge does not expose that signal and is therefore preview-only in RLA.
- Blizzard Encounter Timeline events explicitly marked `isApproximate=true` are preview-only. They must never become actionable PREPARE/PRESS/TTS timing merely because their source is Blizzard or because a bossmod re-emits the event.
- Ula'tek remains manual-only in RLA even though current DBM/BigWigs contain more encounter timing. Provider availability alone must not promote any Ula'tek call to automatic PREPARE/PRESS/TTS.
- Season 2/The Venomous Abyss is live by region. Source review can prove contract compatibility, not real pull cadence or encounter correctness; those remain `PASS-LIVE`-pending until reproduced in Retail.

Before using beta64 for a raid tonight, complete at least the short **Tonight smoke gate** plus the relevant boss/provider rows for the encounters you intend to run. Before promoting beyond beta, complete the broader matrix and record at minimum one clean supported pull/wipe lifecycle per claimed boss/difficulty.

## Tonight smoke gate — minimum before raid use

Record one evidence line per item with date/time, Retail build, installed RLA SHA/version and provider versions.

- [ ] Launch Retail 12.1.x with the exact beta64 candidate and confirm RLA loads without Lua error.
- [ ] `/reload` once and confirm SavedVariables/UI/provider state reconstructs without error.
- [ ] Open RLA through its normal UI and AddOn Compartment path; left-click toggles raid controls and right-click opens settings.
- [ ] With no bossmod active, select one supported encounter and verify manual calls remain usable and no provider failure creates an actionable phantom timer.
- [ ] With **DBM 12.1.5**, start one supported Normal/Heroic encounter or reproducible provider test path and verify encounter identity, one timer occurrence, PREPARE/PRESS ordering and wipe/reset cleanup.
- [ ] With **BigWigs v421.6**, repeat the same minimal lifecycle and verify exact/approximate semantics are respected.
- [ ] With both bossmods enabled where practical, verify duplicate representations collapse to one mechanic occurrence and provider priority does not create double PREPARE/PRESS/TTS.
- [ ] Verify one Blizzard `isApproximate=true` timeline item cannot drive actionable PREPARE/PRESS/TTS.
- [ ] Wipe/restart once and confirm no stale timer, call acknowledgement, assignment or provider authority survives into the next pull.
- [ ] Capture Lua/taint output for the smoke run; any `ADDON_ACTION_BLOCKED`, Lua error, duplicate actionable call or stale next-pull timer is a tonight **NO-GO** until reproduced and fixed.

If the raid tonight includes Nek'zali or Coiled Altar, also execute their current-provider focused rows below because both upstream providers changed live routing around those encounters during the current release window.

## Environment matrix

For each relevant scenario record: date/region, WoW build/interface, resolution, UI scale, language, raid size, RLA version/SHA, DBM version, BigWigs version, and enabled addon set.

Test at minimum:

- 1920x1080, 2560x1440, 3840x2160 and an ultrawide resolution at representative UI scales.
- English plus at least one non-English client to prove mechanic identity is ID-driven rather than localized-string driven.
- no bossmod; DBM **12.1.5** only; current DBM source where practical; BigWigs **v421.6** only; current BigWigs source where practical; DBM+BigWigs; Blizzard timeline available with each relevant combination.
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
- **DBM 12.1.5 shared batching regression:** reproduce two legitimate overlapping timeline timers with the same rounded duration where practical and verify the current DBM batching change does not cause RLA to drop the surviving legitimate occurrence or emit duplicate PREPARE/PRESS for a superseded event.
- **Nek'zali / DBM 12.1.5:** verify current live Normal/Heroic routing for Restless Amani, Hungering Pyre, Invoke and Grasping Depths against RLA's registered spell identities. If DBM hits an unmatched state and resumes Blizzard, RLA exactness must drop immediately rather than remaining exact by provider name.
- **Nek'zali / BigWigs v421.6:** verify the current direct timer identities/counters are mapped to the intended RLA calls and repeated Phase 1/2 occurrences do not leave stale or duplicate timers.
- **Coiled Altar / DBM 12.1.5:** exercise current Normal/Heroic routing and at least one phase/intermission transition. Confirm `ResumeBlizzardAPI` removes DBM exact authority and no stale exact timer survives into the fallback representation.
- **Coiled Altar / BigWigs v421.6:** verify current stable timer lifecycle. If testing post-v421.6 `master`, specifically exercise the updated intermission handling and Spiritcackle display rename; numeric spell-key mapping must continue to select the same RLA mechanic and wipe/reset must clear the bar.
- Vashnik current DBM source: exercise reviewed live routing and, if reproducible, an unmatched/bad-state timeline transition. Verify duplicate handling does not leave two RLA timers and that `ResumeBlizzardAPI` changes DBM timing to preview-only.
- Lost Explorers with current DBM source: verify direct supported timers map to the correct mechanic and any Blizzard fallback remains preview-only unless independently exact. Repeat around phase/lifecycle transitions because the 12.1.5 module routing changed materially.
- DBM current Sentinels: verify Stasis/Miasma/Protovenom identities and an authority release cannot leave stale exact bars.
- BigWigs current Sentinels: verify intermission end/reset does not leave a stale Stasis or backup bridge bar in RLA.
- DBM current Sszorak: verify claimed Normal/Heroic/Mythic calls against actual current routing; do not convert a difficulty to `PASS-LIVE` from upstream comments or source alone.
- DBM/BigWigs current Twin Fangs: verify Submerge lifecycle changes do not duplicate or orphan Ravenous Feast/shared movement timing; DBM fallback precision must follow authority state.
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

Current bossmod source provides materially more Ula'tek timer/event coverage, but do not change `timing=false` from source availability alone. Require live evidence for each difficulty, stable exact public timer identities/cadence, lifecycle behavior across repeated pulls, and a separate product review of which shared raid-leader calls genuinely benefit from automation. Until then, exact bossmod traffic is diagnostic/provider input only and RLA stays manual-only.
