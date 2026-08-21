# Changelog

## 0.9.0-beta.64 — 2026-08-21

- Add a native WoW AddOn Compartment entry: left-click shows/hides the existing raid-control panel and right-click opens the existing guarded Settings surface.
- Add Blizzard's official localized `Dungeons & Raids` category metadata for the modern AddOns list.
- Keep the compartment integration isolated in `Core/AddonCompartment.lua`; it adds no combat scanning, addon networking, protected actions, automatic raid warnings or another App extension surface.
- Review DBM, BigWigs, WeakAuras, oRA3, Northern Sky Raid Tools and Method Raid Tools and adopt only discoverability/metadata patterns that fit RLA's manual raid-leader scope.
- Add focused regression coverage for canonical MainFrame/SettingsFrame routing, localized category metadata and the no-chat/no-network boundary.
- Preserve the full beta.63-and-earlier changelog byte-for-byte in `docs/CHANGELOG-HISTORY-THROUGH-0.9.0-beta.63.md`.

## Historical releases

The complete `0.9.0-beta.63` and earlier release history is preserved in `docs/CHANGELOG-HISTORY-THROUGH-0.9.0-beta.63.md`.
