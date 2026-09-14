# Live Retail acceptance matrix

Source/CI checks cannot fill these rows. Record evidence on the exact installed addon SHA/version and current Retail build. Repository-only commits may advance `main` without changing a published package; live evidence therefore names the installed addon version/SHA rather than assuming that `main` equals a release tag.

## Current source/runtime candidate — 0.9.0-beta.68 — 2026-09-14

The current source/runtime candidate is `0.9.0-beta.68`. It inherits the beta67 encounter/tactic review and adds the Phase 4 stable-ID timing-guidance layer plus Phase 5 cancellation/order hardening. Do not describe beta68 as published/tagged until a GitHub release/tag is independently verified.

`PASS-CI` means source/build validation only. `PASS-LIVE` requires the exact installed beta68 candidate to pass the applicable rows below in a real Retail client. Do not convert any row to `PASS-LIVE` from guides, source code, simulated provider callbacks, screenshots from another build, upstream source review or CI alone.

Current provider baselines for live evidence remain those actually exercised on 2026-08-31:

- DBM live-tested stable is **12.1.6**, release commit `c08dbfd91a006bad45352ea0d3d1a0cc1bc8367e`. The current source-reviewed stable is **12.1.9**; source review does not replace live evidence.
- BigWigs live-tested stable is **v424.1**, release commit `2f04791c4ac04a13f96757298e407014682d6d12`. The current source-reviewed stable is **v424.8**; source review does not replace live evidence.
- Exact source-reviewed release/current-master fingerprints are stored in `docs/UPSTREAM_BASELINES.json`. An unrecorded upstream state is a new `DRIFT REVIEW`, not automatic compatibility evidence.
- DBM timing is actionable only while its reviewed hardcoded authority is valid. After DBM resumes Blizzard fallback, a DBM-labelled copy must not stay actionable merely because its provider name is DBM.
- BigWigs direct timers preserve the upstream approximation signal. A BigWigs nil-module Blizzard bridge bar is preview-only because that callback does not prove the native approximation flag.
- Blizzard Encounter Timeline events marked approximate are non-actionable.
- Timing guidance is stable-ID-only. Localized/name-only or wrong-ID matches must never drive `SOON`, `PRESS NOW` or timing audio.
- Only one verified mechanic is emphasized at a time. Distinct verified mechanics with exactly the same deadline must resolve deterministically by encounter profile call order.
- A provider timer cancelled well before its former deadline must never resurface later as phantom `LATE`. A timer that survives into the final one-second grace window may retain bounded `LATE` feedback when the bar disappears at the mechanic.
- The Raid Warning action boundary is always manual. Guidance may change button/timeline state but may never send a Raid Warning without the raid leader clicking.

Before using beta68 for a raid, complete at least the short smoke gate plus the relevant boss/provider rows for the encounters you intend to run. Before claiming full live readiness, complete the broader matrix and record at minimum one clean supported pull/wipe lifecycle per claimed boss/difficulty.

## Tonight smoke gate — minimum before raid use

Record one evidence line per item with date/time, region, Retail build, installed RLA SHA/version, provider versions, resolution/UI scale, language and raid size.

- [ ] Launch Retail 12.1.x with the exact beta68 candidate and confirm RLA loads without Lua error.
- [ ] `/reload` once and confirm SavedVariables/UI/provider state reconstructs without error.
- [ ] Confirm the main panel can be dragged directly by the header and Ctrl+mouse wheel scales it through the supported 70–110% range without overlap or clipping.
- [ ] Open RLA through the normal UI and AddOn Compartment path; left-click toggles raid controls and right-click opens settings.
- [ ] With no bossmod active, select one supported encounter and verify manual calls remain usable and no provider failure creates actionable phantom timing.
- [ ] With **DBM 12.1.6**, start one supported Heroic/Mythic encounter or reproducible provider path and verify encounter identity, one mechanic occurrence, `WAIT -> SOON -> PRESS NOW` ordering and wipe/reset cleanup.
- [ ] With **BigWigs v424.1**, repeat the lifecycle and verify exact/approximate semantics are respected.
- [ ] With DBM+BigWigs where practical, verify duplicate representations collapse to one occurrence and provider priority does not create double guidance/audio.
- [ ] Verify one Blizzard `isApproximate=true` event cannot drive actionable `SOON`/`PRESS NOW`/TTS.
- [ ] Cancel or stop an exact timer several seconds before its old deadline and verify it never becomes `LATE` at that old deadline.
- [ ] Let a verified timer reach the mechanic, allow its bar to disappear at/near zero and verify `LATE` lasts no longer than the one-second grace window.
- [ ] Reproduce two different verified mechanics with the same/near-identical deadline where practical; verify the selected call remains deterministic and matches profile/UI call order.
- [ ] Click one guided Raid Warning manually and verify acknowledgement suppresses duplicate provider representations without suppressing a later genuine occurrence.
- [ ] Wipe/restart once and confirm no stale timer, `LATE` snapshot, call acknowledgement, assignment, audio state or provider authority survives into the next pull.
- [ ] Capture Lua/taint output. Any `ADDON_ACTION_BLOCKED`, Lua error, duplicate actionable call, automatic Raid Warning, phantom `LATE` or stale next-pull timer is a **NO-GO** until reproduced and fixed.

## Environment matrix

Test at minimum:

- 1920x1080, 2560x1440, 3840x2160 and one ultrawide resolution at representative UI scales, including 70% and 110% RLA scale.
- English plus at least one non-English client to prove automatic guidance is stable-ID-driven rather than localized-string-driven.
- no bossmod; DBM 12.1.6 only; current DBM source where practical; BigWigs v424.1 only; current BigWigs source where practical; DBM+BigWigs; Blizzard timeline available with each relevant combination.
- clean SavedVariables, upgraded schema history and intentionally malformed-but-recoverable SavedVariables.
- raid leader, raid assistant and ordinary member permissions.
- short-height UI conditions that force the combat-call list to scroll.

## Per boss/difficulty

For every one of 8 bosses x Heroic/Mythic that is claimed live-ready, verify:

- plan text and current tactic correctness;
- assignment layout/readiness and difficulty-specific constraints;
- visible English call copy and manual Raid Warning send;
- provider identity and precision;
- one-mechanic guidance order and state labels;
- cross-provider occurrence deduplication;
- acknowledgement behavior after manual click;
- audio once per occurrence/state;
- wipe cleanup and next-pull reset.

For every timed mechanic reproduce the occurrence more than once when practical. One successful pull is not enough to prove lifecycle stability.

## Timing-guidance acceptance

For representative timed calls on at least two bosses and both primary bossmods, record each of these boundaries:

- [ ] Far-away exact/native timer displays `WAIT` on only the selected mechanic.
- [ ] Entering the configured prepare window changes that same mechanic to `SOON` exactly once for audio.
- [ ] Entering the press window changes it to `PRESS NOW` exactly once for audio.
- [ ] The addon does not send `/rw` on either transition.
- [ ] Manual click sends the intended warning and marks the occurrence called/acknowledged.
- [ ] A second provider for the same occurrence cannot re-arm the acknowledged mechanic.
- [ ] A later genuine occurrence of the same call can arm normally.
- [ ] Approximate, faded, malformed, secret, name-only and wrong-ID representations never become actionable guidance.
- [ ] Cross-encounter timers never map to the selected call.
- [ ] Early stop/cancel cannot produce delayed phantom `LATE`.
- [ ] Near-zero disappearance may show `LATE` only inside the one-second grace window.
- [ ] Equal-deadline distinct mechanics choose encounter profile order consistently across repeated pulls/reloads.
- [ ] No more than one call button is in `WAIT`/`SOON`/`PRESS NOW`/`LATE` guidance at a time.

## Recovery, precision and provider scenarios

- `/reload` before pull, during a supported pull and after wipe.
- disconnect/reconnect where practical.
- bossmod loaded late or disabled.
- provider timer update, pause/resume, cancel/fade and duplicate second-provider arrival.
- Blizzard exact/native event: may be actionable only when normal encounter/authority/identity checks pass.
- Blizzard approximate event: preview/non-actionable only.
- malformed/secret approximation metadata or invalid timeline event state: fail closed.
- BigWigs direct exact timer: may become actionable when the stable-ID and encounter checks pass.
- BigWigs direct approximate timer: non-actionable.
- BigWigs Blizzard bridge with nil module/key: non-actionable bridge copy; direct Blizzard may separately prove an actionable representation.
- DBM hardcoded authority -> Blizzard fallback transition: no stale exact DBM guidance survives authority release and no replacement is precision-escalated.
- DBM pause/resume: same occurrence identity is retained; a removed paused timer cannot later synthesize `LATE`.
- DBM/BigWigs fade/unfade: presentation/actionability changes do not replay `SOON`/`PRESS NOW` audio for the same occurrence.

## Focused encounter rows

### Nek'zali

- [ ] Heroic has no unnecessary fixed assignment UI.
- [ ] DBM current/live routing for Restless Amani, Hungering Pyre, Invoke and Grasping Depths maps to the intended stable identities.
- [ ] Hungering Pyre IDs `1305421` and `1290679` select the same intended RLA call without duplicate/re-arm behavior.
- [ ] BigWigs repeated Phase 1/2 occurrences do not leave stale or duplicate timers.

### Entombed Sentinels

- [ ] Existing populated raid subgroups are balanced as whole groups between left/right; layouts never assume groups that are not present.
- [ ] DBM Stasis/Miasma/Protovenom identities stay correct and authority release leaves no stale exact guidance.
- [ ] BigWigs intermission end/reset leaves no stale Stasis or bridge representation.
- [ ] Wipe/repull resets side/assignment presentation cleanly.

### The Lost Explorers

- [ ] Encounter `3497`, Throw Junk `1291933`, Final Ascension `1292779` and Mighty Thud `1296092` map to the intended mechanics.
- [ ] Current empowered-explorer/ultimate presentation does not encourage tunnelling the wrong explorer.
- [ ] Fish and final death-order raid-leader copy remains understandable under combat pressure.
- [ ] Repeated stage/fallback transitions do not create duplicate actionable occurrences.

### Vashnik the Malignant

- [ ] Heroic simple profile keeps the raid between Shadow/Purple and Fire/Orange and does not surface Blood/red strategy calls.
- [ ] Purple-first/Orange-after strategy copy matches what the raid is intentionally executing.
- [ ] Current DBM numeric identities remain bound to the intended calls and authority release leaves no stale exact guidance.

### Sszorak

- [ ] Venomous Surge/Raging Crosswinds IDs `1305959`/`1285425` continue to select the intended calls.

### The Twin Fangs

- [ ] DBM 12.1.6 + BigWigs v424.1 Ravenous Feast/shared movement timing remains one occurrence across providers.
- [ ] Current BigWigs Mythic submerge route does not duplicate or misidentify existing shared movement calls.

### The Coiled Altar

- [ ] Heroic 3-player Guillotine assignment passes RLA validation and the live mechanic minimum.
- [ ] Heroic second Guillotine advances to the other assigned group.
- [ ] Mythic still requires fresh 5+ groups and does not inherit the Heroic 3-player rule.
- [ ] DBM/BigWigs phase/intermission transitions do not create stale or duplicate guidance.
- [ ] Wipe around Soulbinding/intermission leaves no stale Guillotine, Dreadmarch, Nightfall, assignment rotation or timing state.

### Ula'tek

The beta67 tactic review remains the source for the bounded Ula'tek timing/assignment strategy; beta68 adds the new guidance presentation and QA hardening. For each claimed difficulty require real Retail evidence of:

- stable exact public identities and useful cadence for selected timed calls;
- Caustic Waves `1292188`, Spectral Coils `1300530`, Rage of the Shackled `1286860`, Call of the Serpent `1300751`, Serpent's Bite `1295905` and Circling Prey `1301510` selecting the intended call exactly once per occurrence;
- Mythic Toxic Incubation provider key `1299757` resolving to Incubation while display spell `1299759` remains UI-only;
- no approximate-to-actionable precision escalation;
- Heroic/Mythic alternating Coil teams, left/right egg carriers, three Bite helper sectors, plus Mythic Incubation;
- missing/overlapping required assignments failing closed;
- Doomscale Warden, Doomscale Eggs, Grasping Fangs and generic Phase 3 remaining manual;
- provider switch/fallback, `/reload`, wipe and repull carrying no timer, acknowledgement, assignment rotation, `LATE` snapshot or audio state into the next pull;
- current post-hotfix tactic text matching what players actually execute.

## Taint, performance and accessibility

Capture `ADDON_ACTION_BLOCKED`/taint errors, Lua errors, CPU/frame-time and memory before pull, during event bursts and after repeated wipes. Run at least a 20-pull/wipe soak sequence for one representative timed encounter and verify no sustained timer/frame/callback/memory growth.

Verify text remains legible, controls do not overlap, `WAIT`/`SOON`/`PRESS NOW`/`LATE`/`CALLED` are distinguishable without relying only on color, long names do not destroy layout, and critical actions remain understandable under raid time pressure. Include the smallest and largest supported RLA scale plus a short-height pass that forces the call list to scroll.

## Phase 5 acceptance boundary

Phase 5 source QA may be marked complete when the exact beta68 SHA passes repository audits, Lua compile/Luacheck, all behavioral regressions, deterministic release/SBOM reproduction and the focused cancellation/order tests. That is `PASS-CI`, not `PASS-LIVE`.

`PASS-LIVE` requires the exact beta68 package to be installed in Retail and the applicable smoke/provider/boss/recovery/taint/performance rows above to be recorded from real execution. Until then describe beta68 as **source/CI green candidate; Retail PASS-LIVE pending**.
