# Raid Lead Assist 0.9.0-beta.59

Beta.59 keeps the existing provider-safety and encounter tactics intact while making pre-pull preparation faster for raid leaders.

## Raid-leader workflow

- Adds bounded configurable lead windows with `/rla timing lead <prepare> <press>` and `/rla timing reset`. Defaults remain PREPARE 5 seconds and PRESS 3 seconds. Encounter-specific call windows continue to override the user default.
- Adds local assignment presets per boss and difficulty: `/rla preset save <name>`, `load <name>`, `delete <name>` and `list`. Names are bounded, plans are revalidated before storage and before load, and each profile is capped at eight presets.
- Adds a compact READY/CHECK control next to Settings. It exposes the existing doctor state for missing required assignments, current-roster mismatches, setup confirmation, custom-text review and provider coverage. Clicking it prints the complete doctor report.
- SavedVariables advance to schema 6. Malformed, inverted, non-finite or otherwise invalid timing windows fall back to the proven 5/3-second defaults; preset storage is normalized separately by the assignment-preset service.

## Reference-addon review

The workflow improvements were selected after comparing Raid Lead Assist with the publicly documented Method Raid Tools feature set, especially Reminders timing controls, Raid Check visibility and saved raid-group/assignment workflows. They are independent Raid Lead Assist implementations. No Method Raid Tools source code, assets or protected implementation details are included; Method Raid Tools is distributed as All Rights Reserved.

Large MRT modules that do not match Raid Lead Assist's focused product contract were deliberately not copied: loot history, attendance, generic raid inspect, invite automation, WeakAura inspection, generic cooldown tracking and network-synchronized notes. Buff/aura scanning was also not added because Raid Lead Assist's Midnight safety model intentionally avoids expanding into combat-state automation/data surfaces.

## Provider currentness

- DBM stable release evidence remains 12.1.4; the current master display version has moved to 12.1.5 alpha without changing the reviewed timer callback contract in the latest inspected commit.
- BigWigs Ula'tek was re-reviewed against the 2026-08-20 phase-3 initial-timer fix and current source blob. Raid Lead Assist continues to keep every Ula'tek call manual-only, so provider bars cannot promote PREPARE/PRESS/TTS for that encounter without separate live evidence and a reviewed product decision.

## Evidence boundary

Beta.59 can only advance to source/package/controlled-runtime 10/10 after the exact final head passes the full repository audit, Lua compilation, Luacheck, all behavioral/adversarial regressions, two independent deterministic ZIP+SPDX-SBOM builds and the required second stable CI round. Real Retail raid pulls, taint/performance/UI-scale checks, CurseForge project settings, repository branch protection and the unresolved project-license decision remain separate release gates and are not claimed by CI.
