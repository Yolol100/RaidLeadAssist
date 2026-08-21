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
- Every addon release change must update the TOC version and top changelog entry together; add versioned release notes when release-specific context is useful.
- Repository-only documentation, governance, issue-template or CI-orchestration changes do not require an addon version bump when the runtime package is unchanged.

## Pull requests

Use the pull request template. Classify the change as runtime/release or repository-only, name the affected boss/provider where applicable, record the automated checks, and state which live checks remain necessary. Do not mark source or CI evidence as `PASS-LIVE`.

Open changes on a feature branch and keep `main` as the integration branch. A repository ruleset or branch-protection policy should require the `Validate source` checks before merge; that GitHub-native enforcement is an owner/admin setting and must be verified separately.

## Required checks

A change is source-ready only after `scripts/audit_runtime.py`, `scripts/audit_repository.py`, Lua 5.1 parsing, Luacheck, all behavioral tests, reproducible packaging and checksum generation pass.

Normal pushes and pull requests never publish a release. For a new addon release, first merge a versioned source change to `main`, then manually dispatch **Validate source** from `main`. The manual run rebuilds and verifies the exact main SHA, creates and verifies provenance/SBOM attestations, and creates or verifies the immutable prerelease/tag. An existing version may never be reused for a different SHA. See `docs/RELEASE_PROCESS.md`.

Source/CI evidence never substitutes for the live checks in `docs/LIVE_TEST_MATRIX.md`.
