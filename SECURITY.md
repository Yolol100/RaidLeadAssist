# Security policy

## Reporting a vulnerability

Do not publish exploit details, malicious payloads, or private player data in a public issue before the maintainer has had a reasonable chance to review them.

For security-sensitive reports, contact the repository owner through the private contact channel associated with the GitHub account. Include:

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
- pin GitHub Actions by immutable commit SHA.

A source/CI pass does not prove absence of WoW taint or runtime performance problems. Those remain explicit live acceptance checks.
