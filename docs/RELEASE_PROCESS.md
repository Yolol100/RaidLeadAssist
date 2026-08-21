# Release process

Raid Lead Assist separates ordinary repository maintenance from addon release publication. This prevents documentation, governance or CI-only changes from creating meaningless addon versions while keeping releases immutable and reproducible.

## 1. Classify the change

### Repository-only

Examples: README/docs corrections, issue/PR templates, CODEOWNERS, Dependabot configuration and CI orchestration that does not change the runtime package.

- Do not bump `RaidLeadAssist.toc` solely for the repository change.
- Do not create a new addon release solely because `main` advanced.
- The normal push/PR workflow still runs the complete source audit, Lua validation and two independent deterministic package/SBOM builds.
- The latest published addon tag may legitimately remain behind `main` when the intervening commits cannot change the runtime ZIP.

### Runtime/release

Any change to `RaidLeadAssist.toc` or a Lua file listed by the TOC is release-affecting. Changes to release packaging semantics may also require a new release even when runtime Lua is unchanged.

Before merge:

1. Choose a new immutable version matching `0.9.0-beta.N`.
2. Update `## Version:` in `RaidLeadAssist.toc`.
3. Put the same version at the top of `CHANGELOG.md`.
4. Add `docs/RELEASE-NOTES-<version>.md` when a dedicated release note is useful.
5. Run the normal pull-request validation and review the full diff.

Never reuse an existing version for another SHA.

## 2. Source validation

Every push and pull request runs `Validate source` with read-only repository permissions by default. It performs:

- audit-tool and upstream-baseline validation;
- Lua 5.1 parsing and blocking Luacheck;
- all focused behavioral/adversarial regressions;
- deterministic runtime-only ZIP generation;
- deterministic SPDX 2.3 SBOM generation;
- an independent second build;
- byte-for-byte ZIP/checksum/SBOM comparison.

Superseded pull-request runs are cancelled through workflow concurrency. Main and manual release runs are not cancelled merely because another run starts.

## 3. Merge

Merge only after the intended PR head SHA has passed the required source checks and the final diff contains no unrelated files.

A GitHub ruleset or branch-protection policy should enforce PR-based changes and required `Validate source` status checks on `main`. That is a repository setting, not something source files can prove or enable by themselves.

## 4. Publish a release

After a runtime/release change has landed on `main`, manually dispatch **Validate source** from the `main` branch.

The manual dispatch rebuilds the exact main SHA. Only that explicit release run receives the additional job-scoped permissions needed to:

1. create GitHub/Sigstore build provenance for the verified ZIP;
2. create an SPDX SBOM attestation for the same ZIP;
3. verify both attestations with GitHub CLI;
4. create the prerelease/tag and upload ZIP, SHA-256 and SBOM assets, or verify an existing release already points to the same SHA.

If the version already points at another commit, publication fails and the source must receive a new version before another release attempt.

## 5. Live acceptance

A green release workflow proves source, packaging and supply-chain properties only. Promotion beyond beta requires the applicable rows in `docs/LIVE_TEST_MATRIX.md` to be recorded against the exact installed addon version/SHA as `PASS-LIVE`.

Do not infer live rendering, taint safety, frame-time, memory stability, provider cadence or encounter correctness from CI.

## 6. Repository-admin controls

Before describing repository governance as fully hardened, independently verify the GitHub settings tracked in issue #14:

- ruleset/branch protection covers `main` and requires the intended checks;
- force pushes and unsafe direct changes are blocked;
- GitHub Actions policy requires full-SHA-pinned actions where supported;
- secret scanning and push protection are enabled where supported;
- Private Vulnerability Reporting is configured if desired;
- automatic deletion of merged branches is enabled if desired;
- the repository LICENSE reflects the owner's intentional legal choice.
