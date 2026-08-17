# Contributing to Raid Lead Assist

Raid Lead Assist is deliberately narrow: it presents raid-leader strategy and public boss/timeline timing; it must not become a combat-decision engine or a replacement for DBM/BigWigs.

## Change rules

- Keep all player-facing runtime copy in English.
- Keep encounter and difficulty behavior fail-closed when identity, precision or provider data is uncertain.
- Do not add combat-log, aura/health/power/position scanning, protected-action automation, addon networking, dynamic code loading, ads, premium unlocks or donation prompts.
- Treat DBM, BigWigs and Blizzard callback payloads as untrusted input and preserve source/precision identity.
- Do not enable Ula'tek automatic timing without stable public provider coverage plus live Retail evidence.
- Keep volatile tuning numbers out of tactic copy unless current authoritative evidence requires them.
- Every behavior change needs a focused `tests/test_*.lua` regression.
- Every release change must update the TOC version and top changelog entry together.

## Required checks

A change is source-ready only after `scripts/audit_runtime.py`, `scripts/audit_repository.py`, Lua 5.1 parsing, Luacheck, all behavioral tests, reproducible packaging and checksum generation pass. `main` release publication additionally requires provenance and a matching version-locked prerelease/tag.

Source/CI evidence never substitutes for the live checks in `docs/LIVE_TEST_MATRIX.md`.
