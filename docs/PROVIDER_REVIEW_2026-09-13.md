# Provider and Midnight raid review — 2026-09-13

This is a source/provider maintenance review for Raid Lead Assist (RLA). It does not replace live Retail acceptance evidence and does not by itself promote any timer or encounter to `PASS-LIVE`.

## Reviewed upstream state

- DBM stable release reviewed: `12.1.9` (`f2aa0876ef91a6c80d48bde620bed58402bd8878`).
- BigWigs stable release reviewed: `v424.8` (`8177bf9d06f2f1b6c51b54bf8da330a39e4c3651`).
- Blizzard's generated live `C_EncounterTimeline` contract remains at the previously reviewed blob and still exposes the event list/info/state/remaining/elapsed APIs used by RLA.
- Current DBM and BigWigs Venomous Abyss encounter files were re-fingerprinted in `UPSTREAM_BASELINES.json`.

## Compatibility conclusion

No RLA timer-provider rewrite is justified by the reviewed drift. RLA should continue consuming resolved public DBM/BigWigs/Blizzard timer durations dynamically instead of copying private bossmod cooldown tables or stage schedules.

DBM's public timer stream remains compatible with RLA's fail-closed precision model. BigWigs' public timer/bar callbacks remain compatible with RLA's current provider boundary. Uncertain, approximate, stale, malformed or cross-encounter data must continue to downgrade or be rejected rather than becoming actionable PREPARE/PRESS/TTS timing.

## Encounter-specific regression priorities

1. **Lost Explorers** — re-test Mythic/stage routing, Throw Junk (`1291933`), Final Ascension (`1292779`) and Mighty Thud (`1296092`). DBM has continued stage/routing fixes after the previous review, and the September 10 hotfix changed Final Ascension escalation reset behavior after an interrupt.
2. **Entombed Sentinels** — re-test timer identity and ordering around same-duration timeline rows. Current DBM uses boss-caster evidence to disambiguate observed race conditions.
3. **The Coiled Altar** — explicitly test wipe during/near intermission followed by immediate repull. Current DBM contains additional recovery protection against wipe-time Blizzard timeline resends poisoning next-pull routing.
4. **Sszorak** — re-test Mythic Venomous Surge repeat timing. BigWigs v424.8 includes a Mythic duration special case intended to preserve repeating-route correctness.
5. **Vashnik the Malignant** — re-test Plague Froth and provider lifecycle. Current DBM changed its personal-warning source because Blizzard does not reliably emit the expected encounter warning; RLA must remain independent from that private warning path.
6. **Ula'tek** — keep all RLA calls manual-only. Current provider availability or timing data is not sufficient evidence to enable automatic timing.

Nek'zali and Twin Fangs remain part of the normal provider/source matrix, but the reviewed public contracts do not require a new RLA timing architecture.

## Midnight hotfix implications

The post-raid-release Blizzard hotfix chain was reviewed for RLA-relevant changes. The material themes are encounter routing/recovery fixes, target/indicator corrections, cast/tuning changes and transition fixes across Twin Fangs, Nek'zali, Vashnik, Lost Explorers, Coiled Altar, Ula'tek, Sszorak and Entombed Sentinels. These changes justify renewed live regression coverage, but they do not justify hard-coding new cooldown tables in RLA.

## 12.1.5 readiness

Current DBM Midnight source already contains `UnbindingofKithix/Kithix.lua`. RLA remains intentionally scoped to The Venomous Abyss. The Unbinding of Kith'ix requires a separate product/readiness gate before RLA adds encounter IDs, spell identities, strategy, assignments or automatic timing.

## Repository cleanup

The files `scripts/native_ats_prospecting.py` and `tests/test_native_ats_prospecting.py` are unrelated Webactueel ATS/lead-prospecting code and do not belong in the WoW addon repository. They are removed from the active tree in this maintenance change. Rollback remains available in Git history through commits `6ec40d757cfbded060e3beaaaf38e51325586482` and `1b3850025833193ed41f5822b9ad26355d36bacf`; history is not rewritten.

## Release classification

This review changes repository maintenance data/documentation and removes unrelated non-runtime files only. It does not change `RaidLeadAssist.toc` or a Lua file loaded by that TOC, so the addon version is not bumped. Source/CI compatibility must still pass on the exact PR head, and current live-tested provider versions remain whatever is recorded in `LIVE_TEST_MATRIX.md` until new Retail evidence is collected.
