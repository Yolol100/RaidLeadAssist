# Comparable Add-on Audit — 2026-08-21

This checklist records workflow and UX patterns reviewed from comparable raid tools. No third-party implementation code or assets are copied.

## Compared projects

1. **Deadly Boss Mods** — role-focused actionable information, modular encounter packages, recovery/diagnostics and configurable attention cues.
2. **BigWigs** — modular lightweight core/plugins, localized AddOns metadata, native category/icon conventions and focused encounter modules.
3. **WeakAuras** — conditional loading, grouping, configuration discoverability and explicit CPU-efficiency emphasis.
4. **oRA3** — small raid-utility modules, ready/consumable/durability/latency utilities and localized addon metadata.
5. **Northern Sky Raid Tools** — profiles/setup management, separate configuration surface, localized Dungeons & Raids metadata, ready checks and encounter-specific raid-leader tooling.
6. **Method Raid Tools** — used as an additional workflow comparison for notes/reminders/assignments; its broader combat/collaboration scope is intentionally not adopted.

## Adoption checklist

- [x] Preserve RLA's existing role as a raid-leader control surface rather than becoming another boss mod.
- [x] Preserve fail-closed encounter/difficulty/provider validation and the manual-only Ula'tek boundary.
- [x] Preserve local assignment preview, presets, personal tasks and READY/CHECK diagnostics.
- [x] Add WoW's native AddOn Compartment entry: left-click toggles raid controls; right-click opens settings through the same existing guarded settings surface.
- [x] Add Blizzard's official localized **Dungeons & Raids** category metadata so RLA is grouped consistently in the modern AddOns list.
- [x] Keep the compartment feature isolated in its own tiny module; no new App monkey patch, combat scanning, networking or protected action surface is introduced.
- [ ] Do **not** copy DBM/BigWigs combat-event automation. RLA consumes verified provider timing and keeps manual raid-leader decisions authoritative.
- [ ] Do **not** copy MRT/NSRT raid networking, loot, attendance, inspection or automarking scope.
- [ ] Do **not** split the full options UI into another load-on-demand addon yet. RLA is still small enough that the extra package/lifecycle complexity is not justified without measured load-time/memory evidence.

## Result

The comparison supports a native discoverability upgrade rather than broader automation. The new AddOn Compartment/category integration makes RLA easier to find and operate while preserving the existing security, timing and raid-leader authority boundaries.
