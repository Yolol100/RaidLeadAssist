# Raid Lead Assist 0.9.0-beta.64

## Native WoW discoverability

- Add an AddOn Compartment entry for Raid Lead Assist. Left-click shows/hides the existing raid-control panel; right-click opens the existing guarded Settings surface.
- Add Blizzard's official localized `Dungeons & Raids` category metadata for the modern AddOns list.
- Keep the integration isolated in `Core/AddonCompartment.lua`; it does not add combat scanning, addon networking, protected actions, automatic raid warnings or another App extension surface.

## Comparable-addon review

- Review DBM, BigWigs, WeakAuras, oRA3, Northern Sky Raid Tools and Method Raid Tools for relevant raid-leader UX/architecture patterns.
- Adopt only native discoverability/metadata improvements. RLA remains a manual raid-leader control surface and does not expand into boss-mod combat automation, raid networking, loot/attendance/inspection or automarking.
- Preserve the complete beta.63-and-earlier changelog as historical evidence in `docs/CHANGELOG-HISTORY-THROUGH-0.9.0-beta.63.md`.

## Validation boundary

This beta still requires the live Retail acceptance matrix before a full product 10/10 claim. The source package remains subject to repository/runtime audits, Lua 5.1 parsing, Luacheck, focused regressions and deterministic ZIP/SPDX verification.
