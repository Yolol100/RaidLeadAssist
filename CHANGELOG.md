# Changelog

## 0.9.0-beta.62 — 2026-08-21

- Remove the obsolete `AssignmentService:GetPlanLines()` implementation now that both PREVIEW and ANNOUNCE use `Services/AssignmentPlanService.lua` as their canonical assignment-plan renderer.
- Keep beta.61 behavior, UI placement, safety boundaries and output unchanged; this cleanup removes the final duplicate formatting path rather than introducing another feature.
- Add a regression that prevents the legacy duplicate renderer from returning while preserving the existing preview/announce ownership contract.

## 0.9.0-beta.61 — 2026-08-21

- Add a themed `PREVIEW` control beside `ANNOUNCE` in the pre-pull Boss Assignments footer so the raid leader can validate and inspect the current unsaved assignment draft locally before saving or broadcasting it.
- Move preview ownership out of `Core/ProductivityIntegration.lua` and into the canonical assignment domain: `Core/AssignmentIntegration.lua` now owns preview/announce wiring and `Services/AssignmentPlanService.lua` owns their shared bounded line rendering.
- Make PREVIEW and ANNOUNCE use the same validation, required-field checks, 200-character Raid Warning line budget and 12-line plan budget, eliminating formatting drift between local inspection and the actual assignment briefing.
- Keep preview local-only and fail-closed: it never saves the draft or sends chat, and the existing pre-pull/combat/newer-schema assignment boundary remains authoritative.
- Reflow assignment footer feedback above the action row at full width so PREVIEW does not squeeze validation/status text beside the buttons; keep the control on the existing `UI.ActionButton` theme, sizing and spacing system.
- Extend regression coverage for module order, assignment-domain ownership, shared PREVIEW/ANNOUNCE rendering, local-only safety and the full-width footer layout.
- Preserve the existing scope boundary: no addon networking, combat-log decision processing, unit-state scanning, protected actions, automarking, loot/invite/attendance features or Method Raid Tools source/assets are introduced.

## 0.9.0-beta.60 — 2026-08-20

- Move beta.59 productivity controls into the canonical themed UI layer: READY/CHECK beside Settings, LEADS beside AUTO, and PRESETS/MY TASKS in the pre-pull Boss Assignments surface.
- Keep assignment preset and personal-assignment state in their existing Services owners; the UI receives bounded callbacks and does not add another App monkey patch.
- Make preset and personal-assignment UI follow the boss/difficulty actually open in the Assignment window rather than assuming the main-panel selection.
- Block timing-lead changes and legacy `/rla timing on|off` changes during an active encounter, in combat or under a newer SavedVariables schema so slash commands cannot alter PREPARE/PRESS behavior mid-pull.
- Add placement/load-order regressions that require the productivity UI to reuse `UI.Theme`/`UI.ActionButton`, stay clamped/in-context and add no combat/network automation API surface.
- Keep the public Method Raid Tools comparison at the workflow-pattern level only; no MRT source, assets, strings or protected implementation details are copied, and RLA does not expand into MRT's broader collaboration/logging/loot/inspection/automarking scope.
- Recheck the current DBM/BigWigs watch points used by beta.59; the reviewed fingerprints remain current at the beta.60 audit snapshot, so no provider mapping change is required.

## 0.9.0-beta.59 — 2026-08-20

- Add bounded configurable PREPARE/PRESS lead windows while preserving encounter-specific timing overrides and fail-closed handling for secret, malformed, non-finite or inverted saved values.
- Add up to eight validated local assignment presets per boss/difficulty plus a compact READY/CHECK control backed by the existing doctor state.
- Add `/rla my`, a local read-only personal assignment summary that filters the active plan to direct player, rotation and raid-subgroup duties without addon networking or combat-state scanning.
- Refresh the watched provider evidence after BigWigs added aura metadata accessors to `BossPrototype.lua` and DBM corrected Lost Explorers to register its UNIT_FLAGS handler only in combat; neither change alters RLA's consumed timer-authority contract.
- Keep Ula'tek manual-only despite current bossmod timer coverage; provider bars still cannot promote PREPARE/PRESS/TTS without separate live evidence.
- Select the workflow improvements after a public Method Raid Tools feature comparison, but implement them independently; no MRT source, assets, strings or protected implementation details are copied.

## 0.9.0-beta.58 — 2026-08-20

- Add a deterministic SPDX 2.3 SBOM for the exact runtime-only release ZIP, including per-file hashes, package verification code and the ZIP SHA-256 digest.
- Build the SBOM independently alongside both release builds and require byte-identical ZIP, checksum and SBOM results before provenance can advance.
- Bind the verified ZIP to the SPDX document with a dedicated GitHub/Sigstore SBOM attestation in addition to the existing SLSA build-provenance attestation.
- Verify both attestation predicate types before creating the version-locked prerelease and publish the SBOM as a release asset.
- Keep the repository license field `NOASSERTION` in the SBOM because choosing a project license remains an explicit owner/legal decision rather than an automated code change.
- Recheck DBM and BigWigs master on 2026-08-20; both remain at the provider source heads reviewed for beta.57, so no encounter/runtime mapping change is required.

## 0.9.0-beta.57 — 2026-08-19

- Re-review the post-beta.56 BigWigs Ula'tek implementation after upstream added substantial Normal/Heroic/Mythic Encounter Timeline handlers and custom bars on live-launch day.
- Keep all Ula'tek Raid Lead Assist calls explicitly manual-only instead of promoting newly available bossmod bars before real Retail pull evidence establishes stable timing identities and cadence.
- Add a controlled-runtime regression that presents an exact BigWigs-style provider timer and proves Normal/Heroic/Mythic Ula'tek still performs zero automatic timer queries, emits no PREPARE/PRESS audio and remains `MANUAL CALLS ONLY`.
- Pin the new BigWigs Ula'tek source fingerprint and assign the review a new immutable prerelease identity because beta.56 already exists as a versioned tag.

## 0.9.0-beta.56 — 2026-08-19

- Re-review another late Season 2 day-one upstream movement after beta.55: DBM Coiled Altar now enables preliminary Normal hardcoded timelines in addition to Heroic, while unknown rows still fail closed through `ResumeBlizzardAPI`.
- Refresh the DBM Coiled Altar fingerprint after confirming beta.55's encounter-wide authority rule already keeps exactness bound to active hardcoded DBM authority rather than provider name.
- Refresh BigWigs Nek'zali after the non-Mythic Phase 2 Possession Barrage 28-second timeline routing fix; RLA does not consume Possession Barrage as a raidleader call identity, so no encounter call mapping changes.
- Keep beta.56 prerelease/live-pending and assign the refreshed source evidence a new immutable version rather than mutating the already published beta.55 identity.

## 0.9.0-beta.55 — 2026-08-19

- Generalize DBM timing provenance across all eight current Venomous Abyss modules: a DBM callback is exact only while DBM has asserted hardcoded Encounter Timeline authority; after `ResumeBlizzardAPI` the DBM copy is preview-only until another direct source independently proves exact timing.
- Add regression coverage for every reviewed Venomous Abyss encounter ID so provider priority cannot launder Blizzard fallback timing into actionable PREPARE/PRESS/TTS state.
- Refresh late day-one DBM drift for Vashnik, Nek'zali and the shared `TLBatchTrackLatest` batch-routing helper; add the shared BossMod timeline helper to the automated upstream drift oracle.
- Refresh BigWigs Nek'zali after its Phase 1 Essence Rend duplicate/cancel routing fix; RLA does not consume Essence Rend directly, so raidleader call identities remain unchanged while the new source fingerprint is pinned.
- Expand live Retail acceptance for authority-release transitions, Vashnik/Nek'zali hardcoded-to-Blizzard fallback, duplicate timeline batches and current BigWigs Nek'zali. Beta.55 remains prerelease/live-pending.

## 0.9.0-beta.54 — 2026-08-19

- Preserve timing provenance across bossmod fallback paths: BigWigs' Blizzard bridge is preview-only when it does not expose `isApproximate`, and current DBM Lost Explorers fallback is preview-only unless DBM explicitly asserts hardcoded timeline authority.
- Add regression coverage for bossmod-versus-Blizzard precision escalation and lock the central `TimelineService.ProviderTimerStarted` precision policy as an approved audited extension surface.
- Refresh the second post-unlock DBM/BigWigs review for Entombed Sentinels, The Lost Explorers, Sszorak and The Twin Fangs, pinning the newly reviewed source fingerprints without requiring unreleased bossmod builds.
- Expand the live Retail matrix for Lost Explorers Normal versus Heroic/Mythic authority, BigWigs direct-versus-bridge precision, Sentinels intermission reset, Sszorak Mythic extrapolation and Twin Fangs Submerge lifecycle. Beta.54 remains prerelease/live-pending.

## 0.9.0-beta.53 — 2026-08-19

- Respect Blizzard Encounter Timeline `isApproximate` metadata: approximate native events remain preview-only and can no longer become actionable PREPARE/PRESS/TTS timing; secret or malformed approximation metadata fails closed.
- Add regression coverage for exact, approximate and secret Blizzard timeline precision and extend the live Retail matrix with the same provider boundary.
- Remove temporary branch deletion from the privileged release job so release credentials are limited to release work rather than unrelated ref cleanup.
- Preserve the version-locked prerelease contract by assigning these audited source changes a new beta version instead of mutating the existing beta.52 release identity.

## 0.9.0-beta.52 — 2026-08-19

- Refresh the release candidate after Season 2 launch-day review and give it a new version so the previously built beta.51 artifact cannot be confused with this final audited source.
- Update the reviewed stable DBM contract from `12.1.3` to `12.1.4`; recheck the Timer callback surface plus all eight Venomous Abyss encounter modules and confirm the current stable encounter files match the reviewed live source.
- Re-review the latest BigWigs Coiled Altar source change: encounter-timeline callbacks now reject non-encounter sources and wipe-state events while the RLA-consumed timer/key identities remain compatible.
- Expand upstream drift monitoring to include the DBM Midnight raid TOC and BigWigs Venomous Abyss raid TOC so interface/module-inventory changes are detected in addition to core and per-boss source drift.
- Recheck Blizzard's launch schedule and current official hotfix publication state; no verified launch-day Venomous Abyss mechanic/timer hotfix requires a tactic change, so no speculative tuning is encoded into RLA.
- Keep the runtime-only package boundary and all existing fail-closed behavior; no active runtime file is removed merely to reduce file count, while repository-only tests/docs/audit tooling remain excluded from the shipped ZIP.

## 0.9.0-beta.51 — 2026-08-19

- Add a first-class, difficulty-aware pre-pull setup registry for world markers, target markers and raidleader preparation without turning marker placement into combat automation.
- Add a compact `PRE-PULL SETUP` card between the timeline and Boss Plan that uses the existing Raid Lead Assist theme, shows CHECK/READY state and separates `Markers` from concise `Raid Leader Prep` steps in its tooltip.
- Rewrite all eight Boss Plans as player-facing cue-to-action briefings: Normal contains the complete base strategy, Heroic contains only changes from Normal, and Mythic contains only changes from Heroic.
- Audit every boss/difficulty so settings exist only for real raidleader choices: remove unnecessary fixed fish/fountain/crate ownership fields, keep fixed strategy directly visible in the plan/setup, and render configured groups/players into the actual call where assignments are required.
- Refresh encounter copy against current Wowhead/Encounter Journal evidence, Raidstrats guidance, current DBM/BigWigs source and the supplied Ready Check Pull recap images; clarify Vashnik's Blood-circle stack and Coiled Altar collector-first orb handling.
- Correct Twin Fangs Normal Ravenous Feast so every hit requires fresh eligible 3+ soakers; Heroic/Mythic retain explicit preassigned three-group rotations while volatile Eternal Venom lethal thresholds remain qualitative.
- Add/retain source-backed raidleader coordination only: Sszorak Cyst Poppers/Mutilate groups plus Dig In cooldown call, Sentinels fixed physical sides, Lost Explorers fixed Thud markers/fish order, Coiled Altar collector/Wail/Guillotine ownership and Mythic-only Ula'tek rotations.
- Re-review live-launch provider drift on 2026-08-19: DBM watched modules remain unchanged; changed BigWigs Venomous Abyss master modules are re-pinned after semantic review while the core callback contract remains compatible.
- Document that BigWigs v419.2 predates the finalized Coiled Altar boss module and keep Blizzard Encounter Timeline/manual fallback as the expected safe behavior when a stable bossmod lacks a usable bar.
- Keep Ula'tek manual-only and preserve the live-evidence boundary: source/CI can make beta.51 technically green, but Retail pull, taint, performance, provider and UI acceptance still require live evidence.
- Keep setup confirmation session-scoped and pre-pull-only so `/rla doctor` cannot report stale marker/prep readiness after a reload; add `CHECK SETUP` plus marker/prep counts and regression coverage.
- Re-verify the runtime-only release boundary: the distributable ZIP contains only `RaidLeadAssist.toc` plus the 53 audited runtime Lua files; repository docs/tests/audit scripts stay in source control and out of the addon package.

## 0.9.0-beta.50 — 2026-08-18

- Harden Entombed Sentinels so boss health is display-only, boss identity is resolved from locale-independent NPC GUIDs, and raid leaders get three explicit manual balance calls instead of an automatic STOP/RESUME recommendation.
- Refresh and expand provider-drift baselines to boss-specific DBM and BigWigs modules for all eight Venomous Abyss encounters, including the reviewed Coiled Altar BigWigs baseline.
- Replace chained assignment-layout monkey patches with a canonical registry API and add roster-aware pre-pull assignment warnings without blocking future-roster planning.
- Track custom Raid Warning text against deterministic default fingerprints so preserved customizations can be marked for review when upstream defaults change.
- Expand `/rla doctor` readiness reporting with assignment, roster, custom-text and provider-coverage states, including READY TIMED and READY MANUAL outcomes.
- Compact adjacent assignment Raid Warning lines within the chat-size limit to reduce worst-case pre-pull message bursts without dropping assignment content.
- Generalize the repository extension-surface audit, strengthen release reproducibility with independent jobs, and verify the exact release ZIP attestation before publishing.
- Align the documented release artifact boundary with the runtime-only build contract and add regression coverage for the complete audit-hardening set.

## 0.9.0-beta.49 — 2026-08-18

- Integrate the user-provided Ready Check Pull recap sheets for The Twin Fangs and The Coiled Altar and cross-check both against the current Patch 12.1 strategy/Journal evidence plus current DBM/BigWigs encounter modules.
- Correct Twin Fangs by difficulty: Normal Ravenous Feast is a full-raid three-hit soak with no forced three-team roster, while Heroic/Mythic retain three fresh 3+ teams; document the three-hit Stone Breaker tank set, Ithraz regroup movement and keep the volatile Eternal Venom lethal thresholds qualitative.
- Expand The Coiled Altar pre-pull and phase plan with both-end world markers, required 2+ Orb Collectors, Heroic/Mythic Wail coverage, controlled Guillotine movement, ghost/Soul Fragment handling, the selected Ready Check Pull intermission Bloodlust tactic and the synchronized Phase 3 kill.
- Correct Entombed Sentinels so raid groups hold their physical sides after Stasis while tanks taunt-swap the bosses; RLA now calls `GROUPS HOLD SIDES > BOSSES SWAP` instead of telling raid groups to cross the arena.
- Remove Vashnik's fixed Bile roster because the current strategy lists no key assignments; keep Malignant Catalyst as the shared `SOAK EVERY GREEN CIRCLE` call and leave dynamic impacts/personal infection execution to bossmods.
- Add Sszorak's source-backed three Cyst Popper assignment and include all three owners in the Howling Maelstrom call while preserving the two distinct 5+ Mutilate teams.
- Refresh the BigWigs provider fingerprint after another compatible upstream drift, add boss-specific DBM/BigWigs watches for Twin Fangs and Coiled Altar, and expand regression coverage for every corrected assignment/call boundary.

## 0.9.0-beta.48 — 2026-08-18

- Re-audit The Coiled Altar and Ula'tek across Normal, Heroic and Mythic against the current Patch 12.1 Encounter Journal/strategy evidence and current DBM/BigWigs source contracts, using the same raidleader-only ownership model as bosses 1-6.
- Make The Coiled Altar explicitly raidleader-driven: add required Coalesced Venom Orb Collectors, keep Guillotine 5+ soak rotations and Wail interrupt ownership, add the Zul'jan-focused Soulbinding intermission call and Phase 3 Bloodlust/synchronized-kill call, and remove the tank-only Sever button plus personal Normal/Heroic Gloombomb buttons.
- Keep Mythic Coiled Altar Gloombomb as a shared call only because it is used to strip Spirit Shield from Soulcoilers before the raid can kill them; personal bomb positioning and Gravebound recovery remain bossmod-owned.
- Rebuild Ula'tek around shared coordination only: add Doomscale Warden/egg ownership, Heroic+ alternating Spectral Coil groups, Heroic+ one-at-a-time Fang breaks, Venomous Heart target priority, Phase 3 Bloodlust and Circling Prey shared movement while removing personal Bite, Sting and generic dodge buttons.
- Correct Mythic Toxic Incubation planning from one rotating interceptor per cast to one required 4+ player intercept team, matching the four sequential impacts in a single Incubation while avoiding unnecessary Toxic Burn stacking.
- Keep every Ula'tek call manual (`timing=false`) because Blizzard explicitly excluded the final boss from public PTR raid testing and current bossmod modules still lack live-proven stable timing identity/cadence for RLA PREPARE/PRESS automation.
- Extend the common DBM/BigWigs-vs-RLA ownership contract to all eight bosses and add boss 7/8 assignment, call-scope and pre-live timing regressions.

## 0.9.0-beta.47 — 2026-08-18

- Re-audit bosses 1-6 against current Patch 12.1 encounter strategy evidence and current DBM/BigWigs source contracts, including raid-size scaling, failure conditions, provider gaps, duplicate timer arming, assignments and UI/plan consistency.
- Merge the completed boss 5/6 raidleader audit into `main`, including flex-safe Sszorak 5+ Mutilate teams, flex-safe Twin Fangs 3+ Feast teams and the single Sanguine Storm anchor for the shared 100-energy movement call.
- Make Entombed Sentinels flex-safe and rotation-safe: Team A/B configure only the starting split, the live boss-mechanic calls stay `BREATH SIDE` / `BLOOD SIDE`, and the explicit side-swap call reminds the raid which roster is Team A/B after every Stasis.
- Preserve bossmod ownership for personal debuffs, dodges, role warnings and personal timers while keeping RLA responsible for shared teams, markers, soaks, target priority and coordinated raid movement across bosses 1-6.
- Add call-scoped Blizzard timeline fallback under DBM authority so a required RLA mechanic with no direct bossmod timer, notably Lost Explorers `Final Ascension`, remains available without reopening unrelated native events or aliasing the separate `Fling Fish` timer.
- Re-verify current BigWigs master `Timer`, `CastTimer` and `StartBar` callback shapes after upstream fingerprint drift and refresh the exact reviewed provider baseline.
- Expand regressions for Sentinels flex/start-team selectors, post-Stasis boss-side calls, provider authority gaps and the Lost Explorers Final Ascension/Fling Fish separation.

## 0.9.0-beta.46 — 2026-08-18

- Audit the existing Nek'zali, Entombed Sentinels and Vashnik implementations for purpose, audience, tactic/button consistency, UI behavior, assignments, timer behavior and release safety without adding new encounter features.
- Normalize Nek'zali's existing add action label to `Kill adds` while preserving the established `KILL ADS` raid warning and all difficulty tactics.
- Keep the Entombed Sentinels balance button stable when the calculated recommendation has not changed, so a manual `CALLED` state is not reset by the 10 Hz health refresh; also clear stale boss-token mappings before each rescan.
- Align Vashnik's existing Fountain Sequence assignment helper with the active `FLAME > SHADOW > SHADOW > BLOOD > BLOOD > FLAME` raid plan and lock that agreement with regressions.
- Preserve all existing Normal/Heroic/Mythic mechanics, layouts, assignments, secret-value boundaries and DBM/BigWigs/Blizzard timer behavior outside these targeted consistency fixes.

## 0.9.0-beta.45 — 2026-08-17

- Rebuild Vashnik around the raid-lead essentials: `KILL ADDS`, staggered Fire add deaths, Shadow swirlies, Siphon stacking, Froth positioning and difficulty-specific Bile/Tumor handling.
- Remove all Vashnik tank calls and keep the pre-pull plan focused on player actions.
- Lock the requested `FLAME > SHADOW > SHADOW > BLOOD > BLOOD > FLAME` route while stating that every Imbibe actually draws from the two nearest fountains.
- Correct the source boundary for Exploding Infection: `BIG CIRCLE > MOVE FAR OUT` remains present on Normal, Heroic and Mythic; `SOAK BILE` remains Heroic/Mythic-only.
- Preserve DBM/BigWigs/Blizzard timing for Imbibe, Plague Froth and Malignant Catalyst; fountain/add-state calls without a reliable timer identity remain manual-only.
- On Mythic, replace the generic Froth call with `FROTH > AIM AT TUMORS` and add `KILL TUMORS` after Plague Waves remove their protection.

## 0.9.0-beta.44 — 2026-08-17

- Rebuild Entombed Sentinels around the raid split: groups 1+2 on green/Breath and groups 3+4 on red/Blood, with difficulty-specific Normal, Heroic and Mythic briefing text.
- Add a native two-column encounter panel with Breath and Blood health bars, side-specific action buttons, shared Stasis/side-swap/tank calls, and the existing timer-state styling.
- Keep boss-health handling Midnight-safe: secret health values may feed StatusBars directly but are never compared in Lua; the automatic `STOP DPS` boss choice is enabled only when both percentages are accessible and otherwise fails closed to a neutral manual balance call.
- Simplify Breath calls to `KILL ADD`, `RUN OVER GREEN DROPLETS` and Heroic+ `DODGE VENOM`; simplify Blood calls to `SOAK CIRCLE`, `DISPEL DOTS` and Heroic+ `GO TO CORNER`.
- Add `MATCH TO EXACTLY 4` and `SWAP BOSS SIDES` shared calls, plus Mythic `PROTOVENOM > MARKED + MARKED`, and lock the UI/secret-health contract with permanent regressions.

## 0.9.0-beta.43 — 2026-08-17

- Confirm from current Encounter Journal data that Cremation and persistent Amani corpses are Heroic/Mythic mechanics, not Normal mechanics.
- Replace fixed Normal/Heroic group numbers with role-based Nek'zali calls: `MELEE SOAK`, `RANGED SPREAD OUT` on Normal and `RANGED BURN ADS` on Heroic.
- Keep Mythic group-based Pyre/Cremation assignments and Mythic-only Grasping Depths/Invoke calls unchanged.
- Add regressions that prevent Normal from claiming Cremation and require Heroic to retain the corpse-burn plan.

## 0.9.0-beta.42 — 2026-08-17

- Recheck Nek'zali Normal, Heroic and Mythic against the current 12.1 Encounter Journal and current raid strategy evidence.
- Use Bloodlust when Nek'zali becomes active in phase 2 and burn before full energy.
- Standardize shared direct calls to `GO TO THE EDGE`, `KILL ADS` and `GROUP 1 + 2 SOAK` on all three difficulties.
- Use `GROUP 3 + 4 SPREAD OUT` on Normal and `GROUP 3 + 4 BURN ADS` on Heroic/Mythic for the Slithering Flame/Cremation strategy.
- Keep Mythic-only Grasping Depths and Invoke calls separate, including fresh Well teams, Soulcoiler's Curse interrupts and stop-casting guidance.

## 0.9.0-beta.41 — 2026-08-17

- Re-audit all eight Venomous Abyss bosses across Normal, Heroic and Mythic against the current 12.1 Encounter Journal and current community/PTR strategy evidence.
- Rewrite mechanic buttons to be action-first and concise while keeping the pre-pull Raid Warning briefing responsible for the full strategy, assignments and failure conditions.
- Add Nek'zali Mythic Soulcoiler's Curse interrupt guidance, Entombed Sentinels tank-swap guidance, Sszorak opposite-gust Crosswinds pairing, and safer Twin Fangs Mythic Bulwark stop wording.
- Add Vashnik Adaptive Infection responses for blood, fire and shadow infusions and keep Ula'tek explicitly journal-based/live-validation-required because the final boss was not publicly PTR-tested.
- Add a regression contract that caps each briefing line at 250 bytes and keeps per-mechanic action/warning copy bounded.

## 0.9.0-beta.40 — 2026-08-17

- Keep all release-ready source changes on `main` and remove leftover temporary implementation branches after the validated release is created.
- Extend the post-release cleanup to delete `release-fix-beta39-temp` and the accidental cleanup-sentinel branches created during repository verification.
- Preserve the existing validation, provenance, version-lock and runtime-only packaging gates unchanged.

## 0.9.0-beta.39 — 2026-08-17

- Align the 160-point acceptance audit with the beta.38+ runtime-only distribution contract.
- Define the release ZIP inventory as `RaidLeadAssist.toc` plus exactly the Lua runtime files listed by the TOC; repository-only README/docs/tests/audit scripts/maintenance files must stay out of the distributable addon package.
- Preserve the existing source/CI/live evidence boundary: automated technical gates can pass before Retail-only raid, taint, performance, accessibility and provider validation is available.

## 0.9.0-beta.38 — 2026-08-17

- Make the distributable addon ZIP strictly runtime-only: `RaidLeadAssist.toc` plus the exact Lua files listed by the TOC.
- Remove `README.md` from the shipped addon package; documentation, tests, audit scripts and GitHub maintenance files remain source-repository assets only.
- Keep all current runtime modules because the TOC/module-order audit confirms they are part of the active load graph; no runtime file is deleted merely to reduce file count.
- Preserve the full CI/audit/test suite in source control so release cleanup does not weaken verification or future maintenance.

## 0.9.0-beta.37 — 2026-08-17

- Expand the permanent acceptance model from 58 to 160 checks covering product scope, repository structure, module/load-order integrity, Midnight combat boundaries, tactics, providers, reconciliation, assignments, UI/accessibility, data recovery, security, privacy, supply chain, release and live operations.
- Add a blocking repository audit for path portability, UTF-8/LF hygiene, committed-secret signatures, module dependency order, approved App patch surface, forbidden combat-automation APIs, workflow trigger/injection risks, full-SHA action pinning and behavioral-test inventory.
- Add `ARCHITECTURE.md`, `AUDIT_SOURCES.md`, `LIVE_TEST_MATRIX.md`, `PRIVACY.md` and `CONTRIBUTING.md` so every subsystem has documented ownership, lifecycle, purpose, evidence boundary and current source provenance.
- Add `.editorconfig` and `.gitattributes` to keep future source encoding/line endings deterministic across platforms; the new gate found and normalized the pre-existing missing final newline in `Core/App.lua`.
- Keep Luacheck exceptions narrowly named and documented: one BigWigs callback-shape secondary variable plus the two existing App settings-scope shadowings; every other runtime warning remains blocking.
- Recheck current stable bossmod releases: DBM remains `12.1.3` and BigWigs remains `v419.2` at this audit.
- Keep the single `AssignmentIntegration` App extension explicit and machine-locked instead of allowing additional runtime monkey patches to appear silently.
- Correct the beta.36 historical wording: there are no open pull requests, while owner/admin governance work is tracked in issue #14; no claim is made that the repository has zero open issues.
