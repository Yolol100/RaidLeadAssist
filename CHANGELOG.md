# Changelog

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
