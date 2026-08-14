# Raid Lead Assist

Raid Lead Assist is a raid-leader callout panel for The Venomous Abyss with separate Normal, Heroic, and Mythic strategy profiles.

The main panel has three difficulty tabs. Each tab can define its own pre-pull raid plan, combat call buttons, Raid Warning text, timer identities, and optional per-call PREPARE/PRESS windows. Outside combat the raid leader can switch freely. When a supported encounter starts, the panel automatically selects and locks to the actual Normal, Heroic, or Mythic difficulty so calls cannot accidentally come from the wrong profile. Manual difficulty changes are blocked for the entire active encounter, including re-selecting the currently active difficulty, so a slash command cannot reset live timer state. Manual boss changes are also blocked while the current encounter is known; automatic encounter selection remains allowed.

Settings edits are bound to the currently selected difficulty. While Settings is open, manual difficulty changes are blocked so an in-progress Raid Warning draft cannot silently move between Normal, Heroic, and Mythic. Encounter-start difficulty selection is still allowed and closes/discards an open draft through the existing encounter safety path.

Existing custom Raid Warning text from the previous Heroic-only schema migrates into the Heroic profile. Normal and Mythic customizations are stored separately.

## Timer sources

Raid Lead Assist listens to BigWigs, DBM, and Blizzard's Encounter Timeline. Exact bossmod bars and native Blizzard events can drive PREPARE/PRESS states. BigWigs bars explicitly marked approximate are retained as timeline previews but do not trigger exact button states or TTS prompts unless an exact/native timer source is also available for that occurrence.

Cross-provider timers for the same call are clustered by native event identity when possible and otherwise by a bounded end-time tolerance. A manual call acknowledges the clustered occurrence and keeps a short acknowledgement memory so a late second provider cannot immediately re-arm the same mechanic. Provider timer updates keep the original occurrence identity, so DBM timer corrections cannot replay PREPARE/PRESS audio as if a new mechanic had appeared.

The provider adapters and TimelineService fail closed on Midnight secret values. Secret timer durations, update values, identities, metadata, and pause state are not retained or used for call decisions.

Ula'tek remains manual-timing only until the final boss has been validated in the live Retail client. Its current difficulty plans are Journal-derived and intentionally do not claim a dedicated public Mythic PTR test.

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

GitHub Actions compile every Lua file with Lua 5.1, verify the active TOC inventory, and run focused behavioral regressions for saved-variable schema safety, difficulty-profile isolation, Settings difficulty locking, active-encounter boss/difficulty locking, confirmation-dialog cancellation, Midnight secret-value handling at both adapter and service boundaries, Blizzard Encounter Timeline invalid-event races, real BigWigs/DBM callback shapes, provider precision, stable timer occurrence identity across provider updates, multi-provider timer selection/deduplication, late-provider acknowledgement, per-call timing boundaries, raid-warning pre-pull cancellation, and the 24 Normal/Heroic/Mythic encounter plans. CI then builds and byte-verifies the exact clean release ZIP inventory before retaining the verified main-branch artifact.

These automated checks are source and controlled-runtime evidence. They do not replace live Retail raid tests with Blizzard timelines, current BigWigs, and current DBM present.
