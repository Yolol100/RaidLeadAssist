# Security policy

## Reporting a vulnerability

Do not publish exploit details, malicious payloads, credentials, or private player data in a public issue before the maintainer has had a reasonable chance to review them.

When GitHub Private Vulnerability Reporting is enabled for this repository, use that private reporting flow for security-sensitive reports. Until the repository setting is independently verified, contact the repository owner through the private contact channel associated with the GitHub account rather than assuming that a public issue is private.

Include:

- affected Raid Lead Assist version/commit;
- WoW Retail build and provider versions;
- reproduction steps;
- impact and whether combat, chat, SavedVariables, taint, or external addon interoperability is involved;
- the smallest safe proof needed to reproduce the problem.

Normal correctness bugs, strategy-data errors, timer mismatches and UI defects can use regular GitHub issues when they do not expose sensitive information.

## Security boundaries

Raid Lead Assist must:

- treat bossmod/Blizzard callback data as untrusted runtime input;
- fail closed on secret, malformed, stale, cross-encounter or unsupported timing data;
- never require obfuscated code, external executables, credentials, network calls, advertisements, or paid unlocks in the distributed addon;
- never derive protected combat actions from hidden/secret values;
- keep release ZIP contents limited to `RaidLeadAssist.toc` plus the audited runtime files referenced by that TOC;
- pin every third-party GitHub Action to an immutable full commit SHA;
- declare least-privilege `GITHUB_TOKEN` permissions and keep release write permissions scoped to the release job;
- avoid `pull_request_target`, `repository_dispatch`, `workflow_run` and untrusted pull-request metadata interpolation in privileged workflows;
- keep `CODEOWNERS` explicit for workflow, release/audit and timer-provider trust boundaries;
- keep GitHub Actions dependencies monitored through weekly Dependabot version updates.

Dependabot version updates and GitHub Dependency Review are different controls. This repository must not claim Dependency Review is enabled merely because `.github/dependabot.yml` exists.

Release publication is a deliberate `workflow_dispatch` from `main`; ordinary pushes and pull requests validate source and reproducibility without receiving release credentials or creating tags/releases.

Repository-native branch protection/rulesets, required CODEOWNER approval, secret scanning/push protection, Actions policy enforcement and Private Vulnerability Reporting are GitHub settings and must be verified independently; source files must not claim those controls are enabled merely because the repository documents them.

A source/CI pass does not prove absence of WoW taint or runtime performance problems. Those remain explicit live acceptance checks.
