# Raid Lead Assist 0.9.0-beta.62

Beta.62 is a narrow code-hygiene follow-up to beta.61. It does not change the PREVIEW UI or assignment behavior.

- Remove the obsolete `AssignmentService:GetPlanLines()` implementation after PREVIEW and ANNOUNCE were unified on `Services/AssignmentPlanService.lua`.
- Keep `AssignmentPlanService` as the single assignment-plan formatting path used by the current preview/announce workflow.
- Add a regression that fails if the legacy renderer is reintroduced.
- Preserve beta.61 placement, theme, full-width footer feedback, pre-pull/combat/schema safety and local-only preview behavior unchanged.

The normal live Retail acceptance boundary still applies for UI scaling, long names, taint, frame-time and accessibility checks.
