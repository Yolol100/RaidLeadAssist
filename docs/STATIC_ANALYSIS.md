# Static analysis policy

Raid Lead Assist uses Luacheck in CI as a source-quality gate in addition to Lua 5.1 parsing and behavioral regressions.

The runtime is checked with the repository `.luacheckrc`. WoW API globals are intentionally excluded from global-variable diagnostics because the live client supplies them, while Luacheck continues to detect local-variable and redefinition problems that the parser alone cannot catch.

Static analysis is supporting evidence only. It does not replace behavioral tests or live Retail validation for taint, protected APIs, secret values, performance, provider callbacks, accessibility, or encounter correctness.
