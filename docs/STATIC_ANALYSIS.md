# Static analysis policy

Raid Lead Assist uses Luacheck in CI as a source-quality gate in addition to Lua 5.1 parsing, repository/runtime audits and behavioral regressions.

The runtime is checked with the repository `.luacheckrc`. WoW API globals are intentionally excluded from global-variable diagnostics because the live client supplies them, while Luacheck continues to detect local-variable and redefinition problems that the parser alone cannot catch.

The exception list is intentionally tiny and named. `Services/Providers/BigWigsProvider.lua` has one reviewed callback-shape secondary-variable exception. `Core/App.lua` has two reviewed local shadowing warnings (`settingsEnabled`/`settingsReason`) created by separate initialization and encounter-end scopes. Any additional warning fails CI unless it is first reviewed and explicitly added here/configured by name.

Static analysis is supporting evidence only. It does not replace behavioral tests or live Retail validation for taint, protected APIs, secret values, performance, provider callbacks, accessibility or encounter correctness.
