# Raid Lead Assist

Raid Lead Assist is a raid-leader callout panel for The Venomous Abyss with separate Normal, Heroic, and Mythic strategy profiles.

The main panel has three difficulty tabs. Each tab can define its own pre-pull raid plan, combat call buttons, Raid Warning text, and timer identities. Outside combat the raid leader can switch freely. When a supported encounter starts, the panel automatically selects and locks to the actual Normal, Heroic, or Mythic difficulty so calls cannot accidentally come from the wrong profile.

Existing custom Raid Warning text from the previous Heroic-only schema migrates into the Heroic profile. Normal and Mythic customizations are stored separately.

Ula'tek remains manual-timing only until the final boss has been validated in the live Retail client. Its current difficulty plans are Journal-derived and intentionally do not claim public PTR raid validation.

## Validation

GitHub Actions compile every Lua file with Lua 5.1, verify the active TOC inventory, and run focused behavioral regressions for saved-variable schema safety, difficulty-profile isolation, Midnight secret-value handling, Blizzard Encounter Timeline invalid-event races, multi-provider timer selection/deduplication, acknowledgement, raid-warning pre-pull cancellation, and the 24 Normal/Heroic/Mythic encounter plans.

These automated checks are controlled-runtime evidence. They do not replace live Retail raid tests with Blizzard timelines, BigWigs and DBM present.
