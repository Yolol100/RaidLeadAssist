# Changelog

## 0.9.0-beta.68 — 2026-09-14

- Add the stable-ID-only single-mechanic timing guidance path introduced in Phase 4: `WAIT` -> `SOON` -> `PRESS NOW` -> bounded `LATE`, while keeping every Raid Warning action on an explicit raid-leader click.
- Keep localized/name-only, wrong-ID, faded, malformed and approximate timer representations fail-closed for automatic guidance; exact/native duplicate representations still resolve through DBM, then BigWigs, then Blizzard authority.
- Harden the final guidance edge cases so an early-cancelled or removed paused timer cannot resurface later as a phantom `LATE` call at its former deadline.
- Make simultaneous verified mechanics deterministic by using the encounter profile call order as the explicit raid-leader priority tie-break instead of Lua table iteration order.
- Refresh the QA/release documentation for the beta68 candidate and keep source/CI evidence separate from real Retail `PASS-LIVE` evidence.
- Preserve the current DBM 12.1.6 and BigWigs v424.1 live-tested baselines while the newer source-reviewed provider contracts remain CI/source evidence only.

## 0.9.0-beta.67 — 2026-09-13

- Re-audit the final two Venomous Abyss encounters against live Blizzard hotfixes, current DBM `12.1.9`, BigWigs `v424.8`, current written guides, video guides and Race to World First evidence.
- Update The Coiled Altar Normal/Heroic Guillotine contract to Blizzard's live 3-player minimum while preserving fresh 5+ Mythic groups and the existing intermission Bloodlust / coordinated final-kill plan.
- Refresh Ula'tek tactics for the live 40% Spectral Coils requirement, Heroic three-target-per-side Grasping Fangs, current Serpent's Bite leech/Purge handling, Caustic Waves, Heart burn windows and Circling Prey platform breaks.
- Add the current raid-leader assignment model for Ula'tek: Normal keeps one raid-wide Coil soak; Heroic/Mythic use two alternating near-equal Coil teams; all difficulties preassign left/right egg carriers plus melee/ranged/healer Bite helper sectors; Mythic additionally keeps the 4+ Toxic Incubation group.
- Enforce the Heroic/Mythic Coil minimum dynamically against the current roster: every configured team must contain at least `ceil(raid size × 40%)` unique players when live roster data is available. Saved subgroup plans are preserved across `/reload`/roster-context changes but fail closed at call readiness if the current raid no longer satisfies the requirement.
- Keep the generic Ula'tek Phase 3 burn call strategy-owned rather than hardcoding Bloodlust because current strategy sources differ on the preferred lust window.
- Enable fail-closed automatic timing only for selected Ula'tek mechanics with stable public DBM/BigWigs spell identities; approximate provider data stays preview-only and manual milestones remain manual.
- Correct spell `1301510` to the current bossmod `Circling Prey` platform-break identity and retain Toxic Incubation provider identity `1299757` separately from display spell `1299759`.
- Add focused regressions for final-boss tactics, static and roster-relative assignment minima, raid-size changes, saved-plan normalization, rotation reset, missing/overlapping Ula'tek groups, provider identity resolution, approximate/cross-encounter rejection, setup markers and manual milestone boundaries. Real Retail pulls remain required for `PASS-LIVE` acceptance.

## 0.9.0-beta.66 — 2026-09-03

- Re-review the current DBM `12.1.8` release plus post-release Midnight raid master changes and BigWigs `v424.5` against Raid Lead Assist's public timer-provider boundaries.
- Confirm DBM's new Mythic Lost Explorers routing keeps encounter `3497` and the RLA spell-ID identities for Throw Junk (`1291933`), Final Ascension (`1292779`) and Mighty Thud (`1296092`) compatible with the existing encounter-scoped timeline model.
- Refresh the DBM master fingerprints for the Midnight raid TOC and Lost Explorers, and move the BigWigs release baseline from `v424.3` to `v424.5`; Blizzard EncounterTimeline remains unchanged.
- Add focused Lost Explorers regression assertions for the current provider-review date, Mythic DBM review status, encounter identity and the three raid-leader timer identities.
- Keep provider behavior fail-closed and avoid duplicating DBM's private stage scheduling or BigWigs profile internals; live Retail provider precision remains a separate acceptance gate.

## 0.9.0-beta.65 — 2026-08-31

- Refresh `/rla doctor` so its tested bossmod-contract line matches the semantically reviewed DBM `12.1.6` and BigWigs `v424.1` baselines.
- Synchronize the living README, audit-source register and Retail live-test matrix with the 2026-08-31 provider review while preserving dated historical review/release documents.
- Keep Ula'tek manual-only and retain the existing fail-closed DBM/BigWigs/Blizzard provider boundaries; no new combat automation or provider authority is introduced.
- Add regression coverage that prevents the runtime provider diagnostic and current operational documentation from silently falling behind the audited provider baseline again.

## 0.9.0-beta.64 — 2026-08-21

- Add a native WoW AddOn Compartment entry: left-click shows/hides the existing raid-control panel and right-click opens the existing guarded Settings surface.
- Add Blizzard's official localized `Dungeons & Raids` category metadata for the modern AddOns list.
- Keep the compartment integration isolated in `Core/AddonCompartment.lua`; it adds no combat scanning, addon networking, protected actions, automatic raid warnings or another App extension surface.
- Review DBM, BigWigs, WeakAuras, oRA3, Northern Sky Raid Tools and Method Raid Tools and adopt only discoverability/metadata patterns that fit RLA's manual raid-leader scope.
- Add focused regression coverage for canonical MainFrame/SettingsFrame routing, localized category metadata and the no-chat/no-network boundary.
- Preserve the full beta.63-and-earlier changelog byte-for-byte in `docs/CHANGELOG-HISTORY-THROUGH-0.9.0-beta.63.md`.

## Historical releases

The complete `0.9.0-beta.63` and earlier release history is preserved in `docs/CHANGELOG-HISTORY-THROUGH-0.9.0-beta.63.md`.
