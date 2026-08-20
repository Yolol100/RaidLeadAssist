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
- pin GitHub Actions by immutable commit SHA;
- keep `CODEOWNERS` explicit for workflow, release/audit and timer-provider trust boundaries;
- keep GitHub Actions dependency review enabled through weekly Dependabot updates.

Repository-native branch protection/rulesets, required CODEOWNER approval, secret scanning/push protection and Private Vulnerability Reporting are GitHub settings and must be verified independently; source files must not claim those controls are enabled merely because the repository documents them.

A source/CI pass does not prove absence of WoW taint or runtime performance problems. Those remain explicit live acceptance checks.
