## Scope

- [ ] Runtime/release change
- [ ] Repository-only change

Affected boss/difficulty/provider, if applicable:

## What changed

Describe the smallest intended change and why it is needed.

## Safety boundaries

- [ ] No new combat-decision automation, protected actions, addon networking or dynamic code loading.
- [ ] Provider/Blizzard inputs remain untrusted and fail closed where applicable.
- [ ] Player-facing runtime copy remains English.
- [ ] No credentials, private player data or sensitive diagnostics are included.

## Validation

- [ ] `Validate source` passes on the final PR head.
- [ ] Full diff reviewed; no unrelated files.
- [ ] Behavior changes have focused `tests/test_*.lua` coverage.
- [ ] Live-only checks are listed below and are not represented as CI evidence.

Live checks required or performed:

## Release intent

- [ ] No addon release required; runtime package is unchanged.
- [ ] New release required; TOC version and top changelog entry match and the version has never been published.

Do not manually publish from a PR branch. Runtime releases are dispatched from `main` after merge according to `docs/RELEASE_PROCESS.md`.
