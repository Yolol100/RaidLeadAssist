# Changelog

## 0.9.0-beta.47 — 2026-08-18

- Re-audit bosses 1-6 against current Patch 12.1 encounter strategy evidence and current DBM/BigWigs source contracts, including raid-size scaling, failure conditions, provider gaps, duplicate timer arming, assignments and UI/plan consistency.
- Merge the completed boss 5/6 raidleader audit into `main`, including flex-safe Sszorak 5+ Mutilate teams, flex-safe Twin Fangs 3+ Feast teams and the single Sanguine Storm anchor for the shared 100-energy movement call.
- Make Entombed Sentinels flex-safe by replacing fixed 20-player `Groups 1+2` / `Groups 3+4` assumptions with required Green/Red team selectors used consistently by the raid plan, live warnings and the special two-column UI.
- Preserve bossmod ownership for personal debuffs, dodges, role warnings and personal timers while keeping RLA responsible for shared teams, markers, soaks, target priority and coordinated raid movement across bosses 1-6.
- Add call-scoped Blizzard timeline fallback under DBM authority so a required RLA mechanic with no direct bossmod timer, notably Lost Explorers `Final Ascension`, remains available without reopening unrelated native events or aliasing the separate `Fling Fish` timer.
- Re-verify current BigWigs master `Timer`, `CastTimer` and `StartBar` callback shapes after upstream fingerprint drift and refresh the exact reviewed provider baseline.
- Expand regressions for Sentinels flex selectors, live assignment fragments, provider authority gaps and the Lost Explorers Final Ascension/Fling Fish separation.

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
- Keep all current runtime modules because the TOC/module-order audit confirms they are part of the active load graph; no runtime file is deleted merely to reduce repository size.
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
