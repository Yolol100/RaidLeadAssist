# Audit source register

Review date: 2026-08-18. Changing platform/provider facts must be rechecked before a release claim.

## Blizzard / WoW

- Blizzard UI Add-On Development Policy: https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534/1
- Blizzard, Combat Philosophy and Addon Disarmament in Midnight: https://worldofwarcraft.blizzard.com/en-us/news/24246290/combat-philosophy-and-addon-disarmament-in-midnight
- Blizzard current content/update notes: https://worldofwarcraft.blizzard.com/en-us/news
- WoW API / 12.1 interface and Encounter Timeline reference: https://warcraft.wiki.gg/wiki/Patch_12.1.0/API_changes and https://warcraft.wiki.gg/wiki/Category:API_namespaces/C_EncounterTimeline

Audit implications: addon code stays readable/free of advertising/premium behavior, avoids real-time combat-decision automation, treats secret values fail-closed, validates the Retail interface/API surface and uses the Blizzard timeline only as presentation timing.

## GitHub / supply chain

- Secure use reference: https://docs.github.com/en/actions/reference/security/secure-use
- Repository rulesets: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets
- Protected branches: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches
- Dependency review: https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/about-dependency-review
- Secret scanning / push protection: https://docs.github.com/en/code-security/secret-scanning/introduction/about-secret-scanning
- Artifact attestations: https://docs.github.com/en/actions/security-for-github-actions/using-artifact-attestations

Audit implications: least-privilege workflow permissions, actions pinned to full SHAs, no unsafe PR-event interpolation, dependency monitoring, secret hygiene, protected `main` as an owner/admin action, deterministic artifacts, checksum and provenance.

## Bossmod contracts

- DBM repository/releases: https://github.com/DeadlyBossMods/DeadlyBossMods
- BigWigs repository/releases: https://github.com/BigWigsMods/BigWigs

The machine-readable exact reviewed commits/file fingerprints live in `UPSTREAM_BASELINES.json`; current stable release pins at this review remain DBM `12.1.3` and BigWigs `v419.2`.

On 2026-08-18 the tracked BigWigs `Core/BossPrototype.lua` master fingerprint changed again after the earlier audit. RLA re-verified the current `BigWigs_Timer`, `BigWigs_CastTimer` and `BigWigs_StartBar` argument shapes, including the final timeline event-ID slot used as one-shot metadata. The provider contract remains compatible; the new reviewed fingerprint is recorded in `UPSTREAM_BASELINES.json`.

The boss-specific watch list now also pins current DBM and BigWigs Twin Fangs and Coiled Altar modules. This catches encounter-level timer/key drift that could otherwise leave a provider contract technically valid while a raid call silently stops matching the intended mechanic.

## Encounter strategy

Encounter-facing copy is checked against current Encounter Journal/PTR/live evidence and reputable current raid guides, then remains marked live-pending until reproduced in Retail. Source disagreement never authorizes silently enabling timing or hard-coding volatile thresholds.

The 2026-08-18 follow-up review additionally used the user-provided Ready Check Pull recap screenshots for The Twin Fangs and The Coiled Altar and cross-checked them against the current Wowhead strategy/Journal plus current DBM/BigWigs source.

Twin Fangs conclusions from that cross-check:

- Normal Ravenous Feast does not require the Heroic three-group assignment. The raid stack soaks all three hits together on Normal; Heroic/Mythic retain three fresh 3+ teams because Feasted makes repeats unsafe.
- Stone Breaker remains tank/bossmod-owned as a live role mechanic, but the briefing now states the practical set execution: handle all three marked impacts in order and swap tanks after the set; never leave an impact empty.
- The shared 100-energy movement remains one RLA call anchored only to Sanguine Storm, while the briefing explicitly moves the raid toward Ithraz and calls out Vexhul's rotating flood plus Sanguine Storm.
- Ready Check Pull's recap mentions a 10-stack Heroic Eternal Venom threshold, while the current Wowhead page contains conflicting 9/10/11-stack wording across guide and Journal sections. RLA therefore keeps the lethal threshold qualitative instead of hard-coding a volatile number.

Coiled Altar conclusions from that cross-check:

- Pre-pull setup now explicitly uses world markers at both platform ends, 2-3 mobile Orb Collectors, two Heroic Guillotine teams and 2-3 Heroic/Mythic Wail interrupt owners.
- Phase 1 includes controlled orb destruction through Sever, the stacking Heroic Venom Rupture cost, the leftover-orb transition risk and the Guillotine soak-then-range movement.
- Phase 2 includes breaking Dreadmarch before the edge, steering/stopping fixate ghosts at the Soul Sever mark, reclaiming Soul Fragments, breaking/interruption of Eternal Nightfall and Soulcoiler/Wail priority.
- The supplied Ready Check Pull tactic uses Bloodlust during Soulbinding while Zul'jan takes 100% increased damage; the current Wowhead strategy header instead recommends Phase 3. Bloodlust timing is a raid-strategy choice rather than a mechanic invariant. For this RLA plan the supplied Ready Check Pull intermission tactic is selected and the source disagreement is recorded explicitly.
- Phase 3 retains synchronized boss health/death, shared frontals/orb/ghost setup, Defilement healing-absorb awareness and Heroic Guillotine end-to-end movement.

The broader follow-up also corrected three prior assumptions using current strategy evidence:

- Entombed Sentinels: raid groups remain on their physical sides after Stasis while tanks taunt-swap the bosses across them. RLA therefore says `GROUPS HOLD SIDES > BOSSES SWAP` instead of telling the raid groups to cross the room.
- Vashnik the Malignant: the current guide lists no fixed key assignments. Malignant Catalyst remains a shared raid call to soak every green impact, but no permanent Bile roster is required.
- Sszorak: the current guide lists three Cyst Poppers as the key assignment. RLA now exposes three distinct required poppers and names all three in the Maelstrom coordination call.

Boss 7/8 review on 2026-08-18 also retains the earlier Ula'tek evidence boundary: Blizzard did not make the final boss available for public PTR testing, so every Ula'tek call remains manual until Retail evidence proves exact stable timing identity and cadence.
