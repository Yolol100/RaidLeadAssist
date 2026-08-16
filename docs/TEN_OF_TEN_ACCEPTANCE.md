# Raid Lead Assist — 10/10 acceptance plan

A 10/10 claim is allowed only for the scope that has matching evidence. Source/CI evidence can prove code quality; it cannot replace live Retail encounter validation.

## Execution prompt

Use this prompt for each live validation session:

> Validate Raid Lead Assist against the current Retail build for The Venomous Abyss. For each supported boss and the live difficulty, verify encounter identity, automatic difficulty lock, pre-pull plan accuracy, every visible raid-leader call, assignment relevance, DBM/BigWigs/Blizzard provider behavior, timer precision/fallback, reload recovery, encounter end cleanup, and /rla doctor diagnostics. Do not enable automatic timing for a mechanic unless an exact public provider/native signal is observed and stable. Record PASS/FAIL with the observed mechanic/provider evidence. Fix confirmed defects only, add a regression for each fix, run the full release workflow twice, and never claim live validation for untested boss/difficulty combinations.

## Acceptance matrix

For every one of the 8 encounters and each tested difficulty:

1. **Encounter/difficulty** — WoW selects the correct RLA boss and locks the live difficulty.
2. **Pre-pull plan** — no missing, wrong-difficulty, obsolete, or misleading tactic statement.
3. **Calls** — each visible call maps to a real raid-leader action; no duplicate bossmod warning functionality.
4. **Assignments** — every fixed assignment is actually pre-plannable; dynamic targets remain rules rather than fake preselected players.
5. **DBM only** — actionable timers fire once, update/stop/pause correctly, and stale timers do not re-arm calls.
6. **BigWigs only** — same checks, including Blizzard timeline bridge/fallback bars.
7. **Blizzard only** — native Encounter Timeline input remains safe and exactness is preserved.
8. **Combined providers** — DBM > BigWigs > Blizzard priority and occurrence deduplication remain correct.
9. **Failure paths** — provider loss, unsupported encounter/difficulty, malformed/secret values and reload mid-pull fail closed.
10. **Diagnostics** — `/rla doctor`, `/rla provider` and `/rla status` explain the observed state accurately.

## Ula'tek gate

Ula'tek remains `MANUAL CALLS ONLY` until live evidence and current public provider/native signals are sufficient. Specifically verify:

- Spectral Coils and whether Soul Constrictor changes Heroic/Mythic assignment requirements.
- Doomscale Eggs and whether Mass Gestation is Heroic or Mythic in the live build.
- Grasping Fangs and Blight Vein behavior by difficulty.
- Serpent's Bite, Volatile Purge spread, and Mythic Caustic Waves interaction.
- Any exact DBM, BigWigs or Blizzard timeline identity that could safely support automatic timing.

Only after these are live-confirmed should the temporary Ula'tek compatibility policy be consolidated into the canonical assignment registry.

## Release gate

A release may be called technically green when:

- every Lua file compiles under Lua 5.1;
- the TOC inventory is complete;
- every `tests/test_*.lua` regression passes;
- the release ZIP is built and byte-verified;
- the exact `main` SHA produces a successful GitHub Actions run and artifact.

A full product 10/10 additionally requires the relevant rows in the live acceptance matrix to be PASS. Untested live rows stay `manual test needed`, never implied as proven.
