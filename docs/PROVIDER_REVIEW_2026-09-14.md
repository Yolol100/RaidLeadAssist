# Provider Review — 2026-09-14

## Scope

This review closes the upstream-drift alerts raised on 2026-09-14 for current BigWigs `master`: the Coiled Altar and Ula'tek encounter modules plus the later `Core/BossPrototype.lua` change. Stable release pins remain DBM `12.1.9` and BigWigs `v424.8`; only current-`master` watched-file fingerprints are refreshed.

## BigWigs core

Current BigWigs `Core/BossPrototype.lua` blob: `511af2ec3a91608cfa9e476e2d4fe1b1cbbe10ca`.

Commit `fecae11b6d2547e7387456edc6427379e241c1c0` adds an optional unit argument to BigWigs `SecretMessage` so the secret-safe message can include the current spell target. Raid Lead Assist does not consume BigWigs message text or `SecretMessage` as a timing contract. Its provider integration remains based on the public timer/bar lifecycle and explicitly preserves approximation metadata, so this core change does not widen RLA's provider authority or timing allowlist.

## The Coiled Altar

Current BigWigs blob: `8ffd6d755d0781b3fc6d888138039bf184bcb9b9`.

Reviewed upstream changes include the 2026-09-14 warning/target-routing rework and later option tweaks. BigWigs now routes more Blizzard encounter warnings into personal warnings and adjusts private Dreadmarch/Gloombomb handling. Raid Lead Assist does not consume those private warning helpers. Its provider boundary remains the public BigWigs bar lifecycle plus encounter-scoped stable mechanic identities, so no RLA call identity or permission boundary is widened by this change.

Blizzard's September 9-10 hotfixes also changed Coiled Altar tuning and corrected several phase-3/Sever behaviors. None requires adding a new protected action or health-based decision engine to RLA; volatile numeric tuning remains deliberately outside its raid-leader plan contract.

## Ula'tek

Current BigWigs blob: `6c873faefbc1b76c2f20b8ea79a450cfeb3868d5`.

Two upstream changes are material to the provider audit:

- BigWigs now stops the `Rage of the Shackled` bar when the channel ends early. RLA already consumes public BigWigs stop events and keeps occurrence identity/reset handling in `TimelineService`, so an early stop correctly makes that occurrence non-actionable instead of leaving a stale countdown.
- BigWigs added Doomscale Warden and Blightscale Wretch (`Warden/Wretch`) tracking bars. These bars are not automatically promoted by RLA. The Ula'tek profile still permits automatic guidance only for its explicit reviewed stable-ID exact/native allowlist; Warden/egg/Grasping Fangs and other strategy milestones remain manual.

Blizzard's September 9-10 hotfixes reinforce the current strategy boundaries, including the 40% Spectral Coils floor, three Grasping Fangs targets per side on Heroic, Warden timing fixes and other Ula'tek corrections. They do not justify broadening RLA's timing allowlist without a separate product review.

## Decision

- Refresh the three reviewed BigWigs current-`master` fingerprints in `docs/UPSTREAM_BASELINES.json`.
- Keep DBM `12.1.9` and BigWigs `v424.8` as the stable source-reviewed release pins.
- Keep the last live-tested runtime contracts in `/rla doctor` unchanged until new Retail evidence exists.
- Make the online upstream-drift check part of the required aggregate `validation` gate and therefore part of the release/provenance dependency chain.
- Keep `PASS-LIVE` pending. Repository/source review cannot prove in-client timer precision, taint behavior, UI layout or raid-visible delivery.

## Sources

- BigWigs current master: `Core/BossPrototype.lua`, `TheVenomousAbyss/CoiledAltar.lua` and `TheVenomousAbyss/Ulatek.lua`.
- BigWigs commits reviewed: `fecae11b6d2547e7387456edc6427379e241c1c0`, `3ee110feee0f8e476ee2c3c9e8bbf34fb2edddbe`, `f38a2ba610597569ffbac13ec4ef1a86f2b9e12f`, `f1156021f0c912e02c501afb15afe5022e0a8352`, `690d5951a90f41fea31cc90759263c853cbeacf2`, `488c17a0b6a46afc9c9be943f331e3ef3ac3af1d`.
- Blizzard Hotfixes: September 9, 2026 and September 10, 2026.
