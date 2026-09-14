# Final Two Bosses Review — 2026-09-13

This review follows the earlier provider-only review from 2026-09-13 with a product/tactic pass over the final two Venomous Abyss encounters. The earlier provider review intentionally kept Ula'tek manual-only because provider-source availability by itself was not enough evidence to change encounter behavior. This follow-up adds live Blizzard hotfixes, current encounter guides, video guides and Race to World First evidence, then applies only the changes that remain compatible with RLA's fail-closed provider model.

## Scope and evidence boundary

- Encounter scope: The Coiled Altar (boss 7) and Ula'tek (boss 8/final boss).
- Runtime candidate after this review: `0.9.0-beta.67`.
- Stable provider releases rechecked: DBM `12.1.9`, BigWigs `v424.8`.
- No private DBM/BigWigs cooldown table is copied into RLA. RLA still consumes public provider durations dynamically.
- Source review and CI can prove identities, matching rules, assignment contracts and fail-closed behavior. They cannot prove real Retail timing quality, taint, performance or pull-to-pull encounter behavior. Those remain `PASS-LIVE` gates.

## Primary/current sources reviewed

### Blizzard

- Live hotfix register: https://worldofwarcraft.blizzard.com/en-us/news/24296142
- September 1 hotfix snapshot: https://worldofwarcraft.blizzard.com/en-us/news/24296142/hotfixes-september-1-2026

Material changes:

- The Coiled Altar: the minimum players needed in Guillotine / Grim Guillotine to avoid failure damage is now **3** on Raid Finder, Normal and Heroic. This hotfix does not state a Mythic reduction.
- Ula'tek: Spectral Coils requires **40% of the raid** to reduce damage to its minimum value; Heroic timing was made more consistent.
- Ula'tek: Grasping Fangs targets **three players per side** on Heroic regardless of raid size.
- Ula'tek: Caustic Waves can no longer be avoided by swimming underneath them.
- Ula'tek: Serpent's Bite minimum-player requirements were reduced across raid sizes; failed Bite handling is especially dangerous on Heroic/Mythic because Calcified Corpse radiates raid damage.

### DBM 12.1.9

Current reviewed files remain those pinned in `docs/UPSTREAM_BASELINES.json`.

Ula'tek public timer identities used by this change:

- Caustic Waves — `1292188`
- Rage of the Shackled — `1286860`
- Spectral Coils — `1300530`
- Call of the Serpent — `1300751`
- Serpent's Bite — `1295905`
- Circling Prey / platform break — `1301510`
- Toxic Incubation provider timer — `1299757`

The Coiled Altar public timer identities remain compatible with the existing RLA encounter implementation. No provider-adapter rewrite is required.

### BigWigs v424.8

Current reviewed files remain those pinned in `docs/UPSTREAM_BASELINES.json`.

BigWigs independently exposes the encounter-level timing surfaces needed by the selected Ula'tek calls. RLA continues to accept only encounter-scoped provider traffic and only exact/native precision for actionable PREPARE/PRESS state.

### Strategy / video / progression cross-checks

- Wowhead Ula'tek: https://www.wowhead.com/guide/midnight/raids/venomous-abyss-ulatek-boss-strategy-abilities
- Icy Veins Ula'tek: https://www.icy-veins.com/wow/ulatek-raid-guide/
- Method Heroic Ula'tek: https://www.method.gg/guides/the-venomous-abyss/ulatek-heroic
- Mythic Trap Ula'tek: https://www.mythictrap.com/en/venomous-abyss/ulatek/heroic
- Viserio Ula'tek assignment reference: https://www.viserio.com/raid/venomous-abyss/ulatek
- Method Race to World First progression: https://www.method.gg/raidprogress
- Wowhead The Coiled Altar: https://www.wowhead.com/guide/midnight/raids/venomous-abyss-coiled-altar-boss-strategy-abilities
- Method Heroic The Coiled Altar: https://www.method.gg/guides/the-venomous-abyss/the-coiled-altar-heroic
- Mythic Trap The Coiled Altar: https://www.mythictrap.com/en/venomous-abyss/the-coiled-altar/heroic

Community sources are used for raid-leader execution patterns, not to override Blizzard mechanic contracts or public bossmod identities.

## The Coiled Altar decision

### Heroic Guillotine (RLA runtime; Normal source context only)

Blizzard's live September 1 hotfix lowers the failure-avoidance minimum to 3 players on Normal/Heroic.

RLA now:

- does not expose a Normal runtime profile;
- validates two different Heroic Guillotine teams at `minPlayers = 3`;
- preserves alternating Heroic groups because the repeat-hit debuff still makes immediate reuse unsafe;
- keeps Mythic at fresh `5+` groups because the 3-player hotfix does not include Mythic and the permanent Guillotined contract remains a separate execution model.

### Intermission / Phase 3

Current progression sources support using the Soulbinding damage-amplification intermission as a major burn window while intercepting only enough fragments to avoid healing the bosses without overwhelming the raid. Some guides differ on the preferred Bloodlust window, so RLA keeps the existing Coiled Altar intermission plan but does not generalize that preference to Ula'tek.

Phase 3 remains a combined-mechanics execution: preserve space, keep both bosses close in health and finish together.

## Ula'tek decision

### Selected provider-timed calls

The earlier provider review did not enable Ula'tek timing. This follow-up has enough independent evidence to expose a **bounded selected set** to the existing exact/native provider pipeline:

- `waves` — Caustic Waves `1292188`
- `coils` — Spectral Coils `1300530`
- `heart` — Rage of the Shackled `1286860`
- `serpents` — Call of the Serpent `1300751`
- `bite` — Serpent's Bite `1295905`
- `circling` — Circling Prey `1301510`
- Mythic only: `incubation` — provider key `1299757`, display icon `1299759`

This does **not** add hardcoded boss cooldown schedules. It only lets an exact/native, encounter-matched DBM/BigWigs/Blizzard representation drive the existing timing state. Approximate bars remain non-actionable previews. Cross-encounter traffic remains rejected.

### Calls intentionally kept manual

These remain manual because a stable timer identity is not the same as a useful raid-leader execution boundary or because player/phase decisions remain strategy-owned:

- Doomscale Warden
- Doomscale Eggs / chosen egg side
- Grasping Fangs execution
- generic Phase 3 transition

The generic Phase 3 call intentionally says to execute the raid's final burn plan instead of hardcoding Bloodlust. Current strategy sources do not all place Bloodlust in the same window.

### Spectral Coils

- Heroic: alternating Coil teams must still meet the live **40%+** floor on every impact.
- Heroic: current Icy Veins, Method, Mythic Trap and assignment references converge on pre-splitting the raid into two near-equal teams and alternating Coils. RLA therefore assigns `coil_a` / `coil_b` and renders the currently called team into the Coil warning.
- Mythic: keeps the same alternating-team model and the stricter Soul Constrictor execution.

This is an assignment strategy layer, not a replacement for the underlying Blizzard 40% mechanic. Real Retail validation still has to prove that each configured team actually meets the requirement for the raid size being used.

### Phase 2 sides and Doomscale eggs

All supported difficulties now preassign one mobile egg carrier per side:

- `egg_left` maps to the Triangle / left side;
- `egg_right` maps to the Cross / right side.

Heroic/Mythic Coil teams map cleanly to the same left/right split so the raid does not need to relearn a second partition during the phase change.

### Grasping Fangs

Heroic text reflects the live three-targets-per-side contract. Tethers are broken sequentially so Blight Vein applications do not chain uncontrollably.

### Serpent's Bite / Volatile Purge

Current Icy Veins, Method and Mythic Trap strategy converges on three practical helper sectors for Phase 3:

- melee helpers;
- ranged helpers;
- healer-target helpers, supplemented by nearby ranged/short-range DPS rather than healers alone.

RLA therefore exposes three required, mutually exclusive assignment groups: `bite_melee`, `bite_ranged` and `bite_healer` on Heroic and Mythic. The mechanic remains a leech handoff: each Bite is fully cleared through its matching helper sector, then the Purge carrier moves **7+ yards** away. Mythic additionally warns that Purge emits Caustic Waves and those waves must be aimed safely.

### Circling Prey identity correction

Current DBM/BigWigs source identifies spell `1301510` as the platform-break/Circling Prey timing identity. The stale RLA assumption that treated `1301510` as `Demolish` remains removed and regression-tested.

## Regression and release gates added/updated

- The Coiled Altar Heroic 3-player Guillotine floor is guarded; Mythic 5+ remains guarded separately.
- Ula'tek selected timed call spell identities are guarded.
- Ula'tek manual milestones remain explicitly manual.
- Heroic/Mythic require two non-overlapping alternating Coil teams.
- All difficulties require distinct left/right egg carriers and three non-overlapping Bite helper sectors.
- Assignment overlap, missing required call assignments and stale setup-marker expectations are explicit negative tests.
- Approximate Ula'tek provider data is preview-only and cross-encounter provider traffic is rejected.
- Toxic Incubation provider identity remains separate from its display identity.
- Circling Prey `1301510` is guarded and the stale Demolish call key is forbidden.

## Required live follow-up before full acceptance

`0.9.0-beta.67` can be technically green in source/CI, but it is not a full product `PASS-LIVE` until real Retail evidence covers at least:

1. Heroic The Coiled Altar Guillotine with the live 3-player minimum and alternating Heroic groups.
2. Coiled Altar wipe during/near intermission, then repull, verifying no stale/duplicate PREPARE/PRESS state.
3. Ula'tek Heroic/Mythic exact Caustic Waves, Spectral Coils, Heart, Call of the Serpent, Serpent's Bite and Circling Prey timers from DBM and BigWigs.
4. Ula'tek Heroic/Mythic side carriers plus melee/ranged/healer Bite groups.
5. Ula'tek Heroic alternating Coil-team calls, left/right side mapping, egg carriers and Bite groups under a real raid size.
6. Ula'tek Mythic Toxic Incubation, alternating Coils, Bite groups and safe Purge-wave directions.
7. Ula'tek approximate-provider fallback proving it never becomes actionable.
8. Ula'tek `/reload`, wipe/repull and provider-switch recovery.
9. Real-player confirmation that call lead windows are useful and not early/late after current hotfix timing.
10. Taint, frame-time/CPU, memory and UI-scale/accessibility checks from the live matrix.

Until those are collected, documentation must say **source/CI reviewed, PASS-LIVE pending** rather than “perfect” or “fully live-tested”.
