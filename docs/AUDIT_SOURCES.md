# Audit source register

Review date: 2026-08-21. Changing platform/provider facts must be rechecked before a release or same-day readiness claim.

## Blizzard / WoW

- Blizzard UI Add-On Development Policy: https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534/1
- Blizzard, Combat Philosophy and Addon Disarmament in Midnight: https://worldofwarcraft.blizzard.com/en-us/news/24246290/combat-philosophy-and-addon-disarmament-in-midnight
- Blizzard current content/update notes: https://worldofwarcraft.blizzard.com/en-us/news
- WoW API / 12.1 interface and Encounter Timeline reference: https://warcraft.wiki.gg/wiki/Patch_12.1.0/API_changes and https://warcraft.wiki.gg/wiki/Category:API_namespaces/C_EncounterTimeline

Audit implications: addon code stays readable/free of in-game advertising, premium behavior or donation solicitation, avoids real-time combat-decision automation, treats secret values fail-closed, validates the Retail interface/API surface and uses the Blizzard timeline only as presentation timing. Blizzard's published policy also names excessive chat, unnecessary disk loading and slow frame rates as examples of negative impact, so live performance/soak remains a release gate rather than a source-only claim.

The 2026-08-21 review reconfirmed Retail interface `120100` / Patch 12.1 as the current target. Patch-level secret/restricted-value rules remain a fail-closed input constraint; source compatibility never authorizes combat-decision scanning that Blizzard has restricted.

Post-unlock review confirmed the regional Season 2/Venomous Abyss unlock schedule. No undocumented encounter tuning is encoded merely because a community/datamine source changes; encounter or timing changes require a current authoritative source or reproducible live evidence.

## GitHub / supply chain

- Secure use reference: https://docs.github.com/en/actions/reference/security/secure-use
- Repository rulesets: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets
- Protected branches: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches
- Dependency review: https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/about-dependency-review
- Secret scanning / push protection: https://docs.github.com/en/code-security/secret-scanning/introduction/about-secret-scanning
- Artifact attestations: https://docs.github.com/en/actions/security-for-github-actions/using-artifact-attestations

Audit implications: least-privilege workflow permissions, actions pinned to full SHAs, no unsafe PR-event interpolation, dependency monitoring, secret hygiene, protected `main` as an owner/admin action, deterministic artifacts, checksum and provenance.

## Bossmod contracts — refreshed 2026-08-21

- DBM repository/releases: https://github.com/DeadlyBossMods/DeadlyBossMods
- BigWigs repository/releases: https://github.com/BigWigsMods/BigWigs

The machine-readable exact reviewed releases and current-master file fingerprints live in `UPSTREAM_BASELINES.json`. The stable release-contract pins for the 2026-08-21 evening audit are DBM `12.1.5` (`9a3ab9e404312b2515f0143a67a1d8392e9ad6a2`) and BigWigs `v421.6` (`113c7f2169e14f5959cd2d45c0d4fc22d6a739ce`). Current upstream `master` is monitored separately because it can advance after a stable release.

DBM `12.1.5` changed shared Encounter Timeline batching/resolver behavior and all eight Venomous Abyss encounter modules relative to the prior 12.1.4 review. The watched `DBM-Core/modules/objects/Timer.lua` file remains byte-identical, so RLA's public `DBM_TimerBegin`/Stop/Update/Pause/Resume/FadeUpdate callback field contract did not drift. RLA does not call DBM's private timeline batching helpers; nevertheless, route/overlap/fallback behavior changed enough that duplicate-timer and authority-release scenarios remain explicit live gates for tonight.

Current DBM Nek'zali source retains the encounter ID and the RLA-consumed Restless Amani, Hungering Pyre and Grasping Depths spell identities while replacing earlier routing with live Normal/Heroic logic. Unmatched states can still return authority to Blizzard. RLA therefore continues to require DBM encounter identity plus active hardcoded authority before treating the DBM representation as exact; provider name alone is insufficient.

BigWigs `v421.6` is the current stable review baseline. The watched `Core/BossPrototype.lua` remains byte-identical to the previous RLA review: `BigWigs_Timer` still exposes `isApproximate`, `BigWigs_CastTimer` retains its reviewed shape, and normal `BigWigs_StartBar` retains the optional timeline event ID in the final message slot. Post-v421.6 `master` changed Coiled Altar intermission handling and corrected a difficulty-specific Spiritcackle display rename without changing that public core message contract. RLA matches numeric spell IDs before timer names, so the display rename cannot by itself select a different registered call when the numeric key is present; live intermission/lifecycle behavior remains a separate gate.

Ula'tek remains deliberately manual-only even though current DBM/BigWigs contain materially more timer/event coverage. Source availability is not evidence that those timings are stable, strategically useful or safe to promote to automatic PREPARE/PRESS/TTS.

The scheduled upstream-drift workflow checks the machine-readable current-master fingerprints twice daily. Baseline changes now also run the same online comparison in pull requests, so a newly reviewed provider baseline cannot be merged without checking it against the actual upstream refs at that moment.

## Method Raid Tools comparison

- Current Method Raid Tools CurseForge project, reviewed 2026-08-20: https://www.curseforge.com/wow/addons/method-raid-tools
- Current gallery: https://www.curseforge.com/wow/addons/method-raid-tools/gallery
- Public v5040 release notes documenting the Reminder assignments page: https://www.curseforge.com/wow/addons/method-raid-tools/files/5870341

Method Raid Tools is used only as a public product/workflow reference. Its current public description includes Notes, Reminders, Raid Check, Timers, Marks Bar, Invite Tools, Raid Attendance, Raid Groups Saver and other broad raid-management modules; Reminder supports timeline/assignment setup, and the gallery exposes a Ready Check window and Marks Bar. Its CurseForge license is All Rights Reserved. RLA therefore copies no MRT source, assets, strings or protected implementation details.

Useful pattern-level lessons retained for RLA are deliberately narrow: readiness belongs with raid control, reminder timing belongs with timing/settings, reusable assignments belong with assignment planning, and a personal assignment projection should be discoverable next to the plan it summarizes. RLA implements those patterns with its own Theme/ActionButton controls and existing service contracts.

Deliberately not adopted: network-synchronized live assignment collaboration, generic raid combat logging, loot/invite/attendance suites, broad raid-inspection/consumable scanning, automarking/protected-action behavior or a generic cooldown suite. Those would materially expand RLA's networking, combat-information, privacy/performance and maintenance surface and are not required for the raid-leader callout product contract.

## Encounter strategy

Encounter-facing copy is checked against current Encounter Journal/live evidence and reputable current raid guides, then remains marked live-pending until reproduced in Retail. Source disagreement never authorizes silently enabling timing or hard-coding volatile thresholds.

The release review uses current Wowhead encounter guides/Journal data, current Raidstrats strategy guidance where useful, current DBM/BigWigs source, Method guides as an additional strategy comparison, and the user-provided Ready Check Pull recap evidence where it was previously supplied. On 2026-08-21 the high-risk public claims were rechecked against currently indexed Patch 12.1 guidance. No source-only review converts an encounter to `PASS-LIVE`.

A useful volatility example is Twin Fangs `Eternal Venom`: current public guides disagree on the exact lethal-stack presentation, while the Adventure Journal consistently exposes the three-hit Ravenous Feast behavior and the penalty when fewer than three players are struck. RLA therefore deliberately avoids a fixed Eternal Venom threshold in player copy and retains the stable Feast instruction instead.

### Nek'zali

- Keep the Soulcoil Well clear and stop Amani before they reach it.
- Heroic/Mythic Cremation handling uses persistent Amani corpses; the player with the fire expiration handles the corpse rather than requiring a separate fixed Cremation roster.
- Mythic Grasping Depths retains fresh Well groups because Soul Exhaustion makes immediate repeat entry unsafe.
- Current source continues to show the 50% transition/intermission and Phase 2 burn window; exact live cadence remains provider/live evidence, not hard-coded strategy truth.

### Entombed Sentinels

- The raid stays split on fixed physical sides while tanks swap bosses after Stasis.
- Bosses remain separated, the weaker boss is healed during Stasis, and Helical Toxins must resolve at exactly four applications.
- Current Patch 12.1 guidance still requires the bosses to remain widely separated and confirms the `1+3` / `2+2` exact-four intermission logic.
- Heroic return-path venom and Blood pools plus Mythic Protovenom remain difficulty deltas rather than base-plan noise.

### Lost Explorers

- The selected fixed fish order is Nama, then Iku, then Gebbo. It is an RLA strategy choice, not a universal mechanic invariant.
- Mighty Thud uses three fixed Star/Circle/Diamond soak points.
- The supplied recap explicitly pairs Fire/Frost circles, drops them beside each other, then has players enter the opposite elemental patch; the Boss Plan mirrors that sequence instead of compressing it into an ambiguous one-line instruction.
- Normal/Heroic do not need a fixed crate roster. Mythic alone uses a controlled breaker rotation so everyone else can clear 15+ yards before the break.
- Current public guidance still describes the three-target/fish/Final Ascension encounter structure; the fixed fish order remains clearly labeled as strategy rather than mechanic law.

### Vashnik

- The selected fixed fountain route is Flame+Shadow, Shadow+Blood, then Blood+Flame; the encounter mechanic itself only requires controlling the two closest fountains at Imbibe.
- No permanent player roster is required for Catalyst impacts.
- The Blood infection instruction names the visible circle and explicitly tells several teammates to stack in it so the affected player can receive the required healing; this matches both the supplied recap and current strategy guidance.
- Heroic/Mythic Fire adds remain staggered Skull then Cross to avoid overlapping the stacking on-death damage-over-time effect.
- Current Method/Raidstrats/Wowhead guidance continues to describe Vashnik as a repeating one-phase fountain/add-control encounter; the chosen fountain order remains an RLA strategy choice.

### Sszorak

- The current strategy retains three Cyst Poppers and two separate 5+ Mutilate teams.
- Current Raidstrats Heroic guidance still supports pairing a Crosswinds player shoulder-to-shoulder with the opposite knockback direction.
- Dig In remains a shared damage-cooldown call because it creates the encounter's major fixed damage window.

### Twin Fangs

- Ravenous Feast hits three times. Every hit requires at least 3 players; after soaking one hit, Feasted prevents that player from safely serving as the fresh soak for the next hit of the same cast. Normal resolves fresh eligible soakers dynamically, while Heroic/Mythic use configured groups.
- Stone Breaker remains tank/bossmod-owned rather than adding another raidleader button.
- The shared 100-energy movement remains one RLA call anchored to the current movement mechanic rather than duplicating each personal hazard.
- Current sources disagree on the exact lethal Eternal Venom threshold. RLA therefore keeps the threshold qualitative instead of hard-coding a volatile number.

### Coiled Altar

- Pre-pull setup uses world markers at both platform ends plus assigned mobile Orb Collectors and Wail interrupt ownership.
- The player plan cues orb handling from the actual spawn event: only assigned collectors touch the green poison orbs and carry them to Triangle. It does not imply that an orb initially appears on a player.
- Normal Guillotine only needs any 5+ soakers; Heroic adds rotating groups; Mythic uses fresh groups because the repeat-hit restriction is stronger.
- Dreadmarch/ghost routing, Nightfall shield+interrupt, Soulcoilers/Wail, intermission fragment control and synchronized final boss deaths remain the raid-lead essentials.
- The selected Bloodlust timing is during Soulbinding/intermission from the supplied Ready Check Pull tactic. This is recorded as strategy rather than presented as a universal mechanic invariant.
- Current public guidance continues to describe the three-phase/intermission/final-linked-boss structure. Same-day DBM/BigWigs route changes are treated as timing-provider evidence and do not silently rewrite the strategy plan.

### Ula'tek

- Ula'tek remains the lowest-confidence encounter for automation. Public Patch 12.1 guides now describe the encounter, but the absence of prior public PTR live validation and the rapidly evolving bossmod timing still make source-only automatic timing unjustified.
- Normal/Heroic Spectral Coils stays a full-raid Square stack; Mythic alone introduces the assigned Coil rotation and additional egg/incubation ownership in the current plan.
- Every Ula'tek call remains manual (`timing=false`) until live Retail evidence confirms stable exact public timer identity/cadence. Provider drycode, current guide availability or generic Blizzard timeline coverage alone is insufficient.
