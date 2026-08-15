# Raid Lead Assist

Raid Lead Assist is a raid-leader callout panel for The Venomous Abyss with separate Normal, Heroic, and Mythic strategy profiles.

The main panel has three difficulty tabs. Each tab can define its own pre-pull raid plan, combat call buttons, Raid Warning text, timer identities, optional per-call PREPARE/PRESS windows, and boss-specific assignments. Outside combat the raid leader can switch freely. When a supported encounter starts, the panel automatically selects and locks to the actual Normal, Heroic, or Mythic difficulty so calls cannot accidentally come from the wrong profile. Manual difficulty and boss changes are blocked during the active encounter; automatic encounter selection remains allowed.

## Boss assignments

Assignments are configured before combat through the `ASSIGN` launcher on the main panel, the `ASSIGNMENTS` button in Settings, or `/rla assignments`. The editor is intentionally encounter-specific: each boss and difficulty shows only the blocks its tactic needs.

Assignment fields have tactic semantics instead of one generic input model:

- **PLAYER/GROUP** selects fixed players or teams and exposes the current-roster picker.
- **ROTATION** selects ordered players/teams and advances only when the matching manual call succeeds.
- **RULE** stores a pre-pull movement/position rule for mechanics whose live target is dynamic.
- **SEQUENCE** stores tactic order such as Vashnik's Blood/Shadow/Flame fountain combinations and does not expose a roster picker.

The roster picker reads the current party or raid roster and lets the raid leader select individual names or quickly toggle a complete current raid subgroup with G1-G8. Saved values are isolated by boss and difficulty. Roster-like fields reject duplicate names case-insensitively, and mechanics that require distinct simultaneous or rotating coverage reject overlap between their configured slots. Hard group-size requirements are validated before saving: Helical Toxin groups require exactly four unique players, Mutilate and Guillotine soak teams require at least five, and every Ravenous Feast hit requires at least three.

`CLEAR DRAFT` only clears the visible draft; nothing is deleted until the raid leader explicitly saves. Closing the editor or switching boss/difficulty with unsaved work uses the same Save / Discard / Cancel recovery pattern as Settings. `ANNOUNCE` remains disabled until required fields are complete and the whole draft passes size, duplicate, overlap, and tactic validation.

`ANNOUNCE` sends the filled assignment plan as pre-pull Raid Warnings. During combat, manual call buttons remain raid-leader controlled; when a call has a configured fixed assignment or rotation, Raid Lead Assist appends the relevant player/group text only if the complete combined Raid Warning fits. If assignment detail would exceed the warning limit, RLA sends the complete base call instead of a misleading partial assignment and tells the raid leader to use the pre-pull announcement for the full plan. Rotation counters reset between pulls and when the selected boss or difficulty changes. Raid Lead Assist does not inspect protected combat state to choose a player or alter the pre-pull plan.

Assignment editing is blocked during an active encounter and during combat. The assignment window scales down on smaller UI canvases while keeping its internal layout stable, Tab / Shift-Tab moves between assignment fields, invalid fields receive an error border, and RULE/SEQUENCE helper text is available as an input tooltip.

Settings edits are bound to the currently selected difficulty. While Settings is open, manual difficulty changes are blocked so an in-progress Raid Warning draft cannot silently move between Normal, Heroic, and Mythic. Encounter-start difficulty selection is still allowed and closes/discards an open draft through the existing encounter safety path.

Existing custom Raid Warning text from the previous Heroic-only schema migrates into the Heroic profile. Normal and Mythic customizations are stored separately. Schema 4 adds isolated assignment storage without changing existing message overrides.

## Timer sources

Raid Lead Assist listens to BigWigs, DBM, and Blizzard's Encounter Timeline. Exact bossmod bars and native Blizzard events can drive PREPARE/PRESS states. BigWigs bars explicitly marked approximate are retained as timeline previews but do not trigger exact button states or TTS prompts unless an exact/native timer source is also available for that occurrence.

Cross-provider timers for the same call are clustered by native event identity when possible and otherwise by a bounded end-time tolerance. A manual call acknowledges the clustered occurrence and keeps a short acknowledgement memory so a late second provider cannot immediately re-arm the same mechanic. Provider timer updates keep the original occurrence identity, so DBM timer corrections cannot replay PREPARE/PRESS audio as if a new mechanic had appeared.

The provider adapters and TimelineService fail closed on Midnight secret values. Secret timer durations, update values, identities, metadata, and pause state are not retained or used for call decisions.

Ula'tek remains manual-timing only until the final boss has been validated in the live Retail client. Its current difficulty plans are Journal-derived and intentionally do not claim live raid validation.

## Encounter-data policy

Encounter strategy text is sourced from current Patch 12.1 PTR/Encounter Journal material and remains subject to live tuning. Raid Lead Assist avoids hard-coding volatile PTR tuning thresholds when current source surfaces disagree; assignments focus on stable mechanic contracts such as minimum soak counts, mutually exclusive repeat-debuff groups, interrupt ownership, and pre-pull positioning rules. Live Retail validation remains the final oracle after the raid opens.

## Release package

Build the distribution ZIP with:

```bash
python3 scripts/build_release.py
```

This creates `dist/RaidLeadAssist.zip` with one `RaidLeadAssist/` root containing only the TOC, every runtime file referenced by the TOC, and this README. The builder immediately reopens the ZIP, rejects unsafe/duplicate/unexpected paths, compares every packaged file byte-for-byte with the tested source, and prints the final SHA-256. Tests, `.github`, scripts, caches, and other development-only files are not part of the package.

An existing package can be rechecked with:

```bash
python3 scripts/build_release.py --output dist/RaidLeadAssist.zip --verify-only
```

On successful pushes to `main`, GitHub Actions retains the byte-verified `RaidLeadAssist.zip` together with a `RaidLeadAssist.zip.sha256` checksum as an immutable workflow artifact for 14 days. This keeps the downloadable package tied to the exact commit that passed validation rather than requiring a separate unverified local build.

## Validation

GitHub Actions compile every Lua file with Lua 5.1, verify the active TOC inventory, and run focused behavioral regressions for saved-variable schema safety, difficulty-profile isolation, boss-specific typed assignment layouts, duplicate/overlap and hard group-size validation, all-or-nothing assignment call composition, assignment rotation reset, assignment-to-encounter call bindings, Settings difficulty locking, active-encounter boss/difficulty locking, confirmation-dialog cancellation, Midnight secret-value handling at both adapter and service boundaries, Blizzard Encounter Timeline invalid-event races, real BigWigs/DBM callback shapes, provider precision, stable timer occurrence identity across provider updates, multi-provider timer selection/deduplication, late-provider acknowledgement, per-call timing boundaries, raid-warning pre-pull cancellation, and the 24 Normal/Heroic/Mythic encounter plans. CI then builds and byte-verifies the exact clean release ZIP inventory before retaining the verified main-branch artifact.

These automated checks are source and controlled-runtime evidence. They do not replace a live Retail raid-leader usability pass, keyboard/gamepad verification in the WoW client, or live combat tests with current Blizzard timelines, BigWigs, and DBM present.
