# Final Two Bosses Review — 2026-09-13

This review follows the earlier provider-only review from 2026-09-13 with a product/tactic pass over the final two Venomous Abyss encounters. The earlier provider review intentionally kept Ula'tek manual-only because provider-source availability by itself was not enough evidence to change encounter behavior. This follow-up adds live Blizzard hotfixes, current encounter guides, video guides and Race to World First evidence, then applies only the changes that remain compatible with RLA's fail-closed provider model.

## Scope and evidence boundary

- Encounter scope: The Coiled Altar (boss 7) and Ula'tek (boss 8/final boss).
- Runtime candidate after this review: `0.9.0-beta.67`.
- Stable provider releases rechecked: DBM `12.1.9`, BigWigs `v424.8`.
- No private DBM/BigWigs cooldown table is copied into RLA. RLA still consumes public provider durations dynamically.
- Source review and CI can prove identities, matching rules and fail-closed behavior. They cannot prove real Retail timing quality, taint, performance or pull-to-pull encounter behavior. Those remain `PASS-LIVE` gates.

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

BigWigs independently exposes the same encounter-level timing surfaces needed by the selected Ula'tek calls. RLA continues to accept only encounter-scoped provider traffic and only exact/native precision for actionable PREPARE/PRESS state.

### Strategy / video / progression cross-checks

- Wowhead Ula'tek: https://www.wowhead.com/guide/midnight/raids/venomous-abyss-ulatek-boss-strategy-abilities
- Icy Veins Ula'tek: https://www.icy-veins.com/wow/ulatek-raid-guide/
- Method Heroic Ula'tek: https://www.method.gg/guides/the-venomous-abyss/ulatek-heroic
- Method Race to World First progression: https://www.method.gg/raidprogress
- Ula'tek Normal/Heroic video guide (BrettStefani): https://www.youtube.com/watch?v=zqMvD1oy2d0
- The Coiled Altar Normal/Heroic video coverage (Tactyks): https://www.youtube.com/watch?v=L__7PvkXaoc
- Wowhead The Coiled Altar: https://www.wowhead.com/guide/midnight/raids/venomous-abyss-coiled-altar-boss-strategy-abilities
- Method Heroic The Coiled Altar: https://www.method.gg/guides/the-venomous-abyss/the-coiled-altar-heroic
- Mythic Trap The Coiled Altar: https://www.mythictrap.com/en/venomous-abyss/the-coiled-altar/heroic
- Ready Check Pull Coiled Altar strategy notes: https://www.patreon.com/readycheckpull/posts/early-access-166803547

Community sources are used here for raid-leader execution patterns, not to override Blizzard mechanic contracts or public bossmod identities.

## The Coiled Altar decision

### Normal / Heroic Guillotine

The old RLA contract required 5+ soakers. Blizzard's live September 1 hotfix lowers the failure-avoidance minimum to 3 players on Normal/Heroic.

RLA now:

- says `3+` on Normal;
- allows two different Heroic Guillotine teams with a `minPlayers = 3` validation floor;
- preserves alternating Heroic groups because the repeat-hit debuff still makes immediate reuse unsafe;
- keeps Mythic at fresh `5+` groups because the 3-player hotfix does not include Mythic and the permanent Guillotined contract remains a separate execution model.

### Intermission / Phase 3

Current progression sources consistently support using the Soulbinding damage-amplification intermission to burn Zul'jan, commonly with Bloodlust, while intercepting only enough fragments to avoid healing the bosses without overwhelming the raid. RLA keeps that existing raid-leader call.

Phase 3 remains a combined-mechanics execution: line up orbs/ghosts for tank frontals where applicable, preserve space, keep both bosses close in health and finish together.

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

This does **not** add hardcoded boss cooldown schedules. It only lets an exact/native, encounter-matched DBM/BigWigs/Blizzard representation drive the already-existing timing state. Approximate bars remain non-actionable previews. Cross-encounter traffic remains rejected.

### Calls intentionally kept manual

These remain manual because a stable timer identity is not the same as a useful raid-leader execution boundary or because player/phase decisions remain strategy-owned:

- Doomscale Warden
- Doomscale Eggs / chosen egg side
- Grasping Fangs execution
- generic Phase 3 / Bloodlust transition

### Spectral Coils

- Normal/Heroic: raid-leader text now says to put at least 40% of the raid into the active Coil.
- Heroic does **not** invent Mythic Soul Constrictor rotation assignments.
- Mythic retains the two assigned Coil groups because Soul Constrictor prevents immediate reuse.

### Grasping Fangs

Heroic text now reflects the live three-targets-per-side contract. Tethers are broken sequentially so Blight Vein applications do not chain uncontrollably.

### Serpent's Bite / Volatile Purge

The prior draft idea of fixed three soak groups was rejected during this audit. The encounter mechanic is a leech handoff:

1. Bite targets meet nearby helpers before Surging Fang expires.
2. A helper leeches the poison.
3. The helper receives Volatile Purge and moves at least 7 yards from other players before expiration.
4. On Mythic, the Purge also emits Caustic Waves, so the call explicitly warns about the follow-up waves.

No fixed Normal/Heroic Bite roster group is added.

### Circling Prey identity correction

Current DBM/BigWigs source identifies spell `1301510` as the platform-break/Circling Prey timing identity. The stale RLA assumption that treated `1301510` as `Demolish` is removed and regression-tested.

## Regression and release gates added/updated

- The Coiled Altar Normal/Heroic 3-player Guillotine floor is guarded; Mythic 5+ remains guarded separately.
- Ula'tek selected timed call spell identities are guarded.
- Ula'tek manual milestones remain explicitly manual.
- Approximate Ula'tek provider data is preview-only.
- Cross-encounter provider traffic is rejected.
- Toxic Incubation provider identity remains separate from its display identity.
- Circling Prey `1301510` is guarded and the stale Demolish call key is forbidden.

## Required live follow-up before full acceptance

`0.9.0-beta.67` can be technically green in source/CI, but it is not a full product `PASS-LIVE` until real Retail evidence covers at least:

1. Normal/Heroic The Coiled Altar Guillotine with 3-player minimum assignments and alternating Heroic groups.
2. Coiled Altar wipe during/near intermission, then repull, verifying no stale/duplicate PREPARE/PRESS state.
3. Ula'tek Normal/Heroic exact Caustic Waves, Spectral Coils, Heart, Call of the Serpent, Serpent's Bite and Circling Prey timers from DBM and BigWigs.
4. Ula'tek Mythic Toxic Incubation and Spectral Coils rotations.
5. Ula'tek approximate-provider fallback proving it never becomes actionable.
6. Ula'tek `/reload`, wipe/repull and provider-switch recovery.
7. Real-player confirmation that call lead windows are useful and not early/late after current hotfix timing.
8. Taint, frame-time/CPU, memory and UI-scale/accessibility checks from the existing live matrix.

Until those are collected, documentation must say **source/CI reviewed, PASS-LIVE pending** rather than “perfect” or “fully live-tested”.
