# Raid Lead Assist

Raid Lead Assist is a raid-leader callout panel for The Venomous Abyss with separate Normal, Heroic, and Mythic strategy profiles.

The main panel has three difficulty tabs. Each tab can define its own pre-pull raid plan, combat call buttons, Raid Warning text, timer identities, and optional per-call PREPARE/PRESS windows. Outside combat the raid leader can switch freely. When a supported encounter starts, the panel automatically selects and locks to the actual Normal, Heroic, or Mythic difficulty so calls cannot accidentally come from the wrong profile.

Existing custom Raid Warning text from the previous Heroic-only schema migrates into the Heroic profile. Normal and Mythic customizations are stored separately.

## Timer sources

Raid Lead Assist listens to BigWigs, DBM, and Blizzard's Encounter Timeline. Exact bossmod bars and native Blizzard events can drive PREPARE/PRESS states. BigWigs bars explicitly marked approximate are retained as timeline previews but do not trigger exact button states or TTS prompts unless an exact/native timer source is also available for that occurrence.

Cross-provider timers for the same call are clustered by native event identity when possible and otherwise by a bounded end-time tolerance. A manual call acknowledges the clustered occurrence and keeps a short acknowledgement memory so a late second provider cannot immediately re-arm the same mechanic.

Ula'tek remains manual-timing only until the final boss has been validated in the live Retail client. Its current difficulty plans are Journal-derived and intentionally do not claim a dedicated public Mythic PTR test.

## Validation

GitHub Actions compile every Lua file with Lua 5.1, verify the active TOC inventory, and run focused behavioral regressions for saved-variable schema safety, difficulty-profile isolation, Midnight secret-value handling, Blizzard Encounter Timeline invalid-event races, real BigWigs/DBM callback shapes, provider precision, multi-provider timer selection/deduplication, late-provider acknowledgement, per-call timing boundaries, raid-warning pre-pull cancellation, and the 24 Normal/Heroic/Mythic encounter plans.

These automated checks are controlled-runtime evidence. They do not replace live Retail raid tests with Blizzard timelines, current BigWigs, and current DBM present.
