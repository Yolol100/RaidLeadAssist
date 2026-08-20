# Raid Lead Assist 0.9.0-beta.60

Beta.60 is a placement, discoverability and pre-pull safety follow-up to beta.59. It keeps the beta.59 productivity services and provider semantics, but puts their visible controls in the canonical Raid Lead Assist UI layer and closes a slash-command path that could change timing preferences during an active encounter.

## UI and workflow corrections

- READY/CHECK is owned by `UI/ProductivityPanel.lua` and remains beside the existing Settings control on the main raid-control panel.
- Default PREPARE/PRESS lead windows now have a themed `LEADS` control beside `AUTO` in Settings. The popover uses the existing Theme/ActionButton language and makes the bounded values discoverable without requiring a slash command.
- Assignment presets now have a themed `PRESETS` control in the existing pre-pull Boss Assignments window. Save/load/delete uses the boss and difficulty currently open in that window and reuses the existing draft validation and unsaved-change confirmation flow.
- `MY TASKS` now sits beside presets in the assignment header and uses that window's current boss/difficulty instead of assuming the main panel selection.
- Slash commands remain as power-user fallbacks rather than being the only way to use the beta.59 productivity features.

## Safety and architecture

- Timing lead changes and legacy `/rla timing on|off` changes are blocked during an active encounter, in combat or when SavedVariables came from a newer schema. This prevents a hidden slash path from changing PREPARE/PRESS behavior mid-pull while the normal Settings surface is locked.
- Assignment preset and personal-assignment state remains owned by the existing bounded Services modules. The new UI receives callbacks and does not add another App monkey patch.
- The productivity UI adds no addon networking, combat-log processing, aura/health/power/cast/position scanning, protected actions, target/focus/marker automation or dynamic code loading.
- TOC ordering loads assignment/personal state owners before the productivity UI, loads MainFrame/SettingsFrame/AssignmentFrame before the productivity UI extends them, and loads the callback integration after `Core/App.lua`.

## Method Raid Tools comparison boundary

The workflow direction was cross-checked against the public Method Raid Tools feature set: readiness belongs with raid-control, configurable reminders belong with reminder/settings surfaces, and reusable assignments belong with assignment planning. Raid Lead Assist implements those general workflow patterns independently in its existing visual language. No Method Raid Tools source, assets, strings or protected implementation details are copied.

RLA deliberately does not expand into MRT's broader live collaboration, combat logging, loot/invite/attendance, generic raid-inspection or automarking scope. Those features would materially enlarge RLA's networking, combat-information, privacy and maintenance surface without being required for its raid-leader callout purpose.

## Evidence boundary

Beta.60 still requires the documented real-Retail live matrix before a full `PASS-LIVE`/10-of-10 product claim. Source/CI can prove module order, fail-closed behavior, release reproducibility, provider contracts and UI ownership, but it cannot substitute for real WoW visual scaling, taint, frame-time, accessibility/locales or real-pull provider acceptance.
