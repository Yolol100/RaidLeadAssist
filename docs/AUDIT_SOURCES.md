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

The machine-readable exact reviewed commits/file fingerprints live in `UPSTREAM_BASELINES.json`; current stable releases at this review are DBM `12.1.3` and BigWigs `v419.2`.

On 2026-08-18 the tracked BigWigs `Core/BossPrototype.lua` master fingerprint changed. RLA re-verified the current `BigWigs_Timer`, `BigWigs_CastTimer` and `BigWigs_StartBar` argument shapes, including the final timeline event-ID slot used as one-shot metadata. The provider contract remains compatible; the new reviewed fingerprint is recorded in `UPSTREAM_BASELINES.json`.

## Encounter strategy

Encounter-facing copy is checked against current Encounter Journal/PTR/live evidence and reputable current raid guides, then remains marked pre-release/live-pending until reproduced in Retail. Source disagreement never authorizes silently enabling timing or hard-coding volatile thresholds.

Boss 7/8 review on 2026-08-18 additionally used:

- The current The Coiled Altar strategy/Encounter Journal guide, which identifies Orb Collectors, Heroic alternating Guillotine groups, Zul'jan double-damage intermission priority, Phase 3 Bloodlust and the synchronized-kill failure condition.
- Blizzard's official Venomous Abyss PTR raid-testing schedule, which explicitly states that the final boss was not available for testing while The Coiled Altar received Heroic/Mythic test windows.
- The current Ula'tek strategy/Encounter Journal guide, including Heroic+ Soul Constrictor Coil alternation, Doomscale Warden egg protection, Mythic 3-yard Noxious Shell separation, four-impact Toxic Incubation, Circling Prey space loss and Phase 3 Bloodlust.
- Current DBM and BigWigs encounter modules for both bosses. Coiled Altar's proven bossmod identities may drive RLA's shared timed calls; Ula'tek remains manual-only until Retail evidence proves exact stable timing identity and cadence.
