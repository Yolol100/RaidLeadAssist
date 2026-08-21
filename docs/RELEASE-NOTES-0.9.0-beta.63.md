# Raid Lead Assist 0.9.0-beta.63

Beta.63 is a cleanup-only follow-up. It preserves the beta.62 assignment-preview behavior while tightening UI ownership and repository naming.

## Assignment UI ownership

- `UI/AssignmentFrame.lua` now owns the full-width status and required-assignment footer layout it creates.
- `UI/AssignmentPreview.lua` is reduced to its actual responsibility: create the themed `PREVIEW` button, read the current draft through the existing callback boundary and show its tooltip/status result.
- PREVIEW remains immediately beside ANNOUNCE and continues to inspect unsaved draft values locally without saving or broadcasting them.

## Repository cleanup

- Rename `tests/test_assignment_preview_service.lua` to `tests/test_assignment_plan_service.lua` so the regression path matches the canonical `Services/AssignmentPlanService.lua` service.
- Strengthen the static UI regression so the preview extension cannot silently start moving AssignmentFrame-owned footer elements again.
- Keep the shared PREVIEW/ANNOUNCE renderer, assignment validation, line budgets and pre-pull/combat/schema safety boundaries unchanged.

## Validation boundary

Automated CI covers repository/runtime audits, Lua 5.1 compilation, Luacheck, all behavioral regressions, TOC/version parity and reproducible ZIP/SBOM output. Real Retail UI scaling, long-name rendering, taint, frame-time and accessibility still require live-client acceptance.
