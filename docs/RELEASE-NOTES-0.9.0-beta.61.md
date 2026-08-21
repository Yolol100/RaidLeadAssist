# Raid Lead Assist 0.9.0-beta.61

Beta.61 adds one focused raid-planning workflow selected from the Method Raid Tools comparison: a safe local preview of the current assignment draft before it is saved or announced.

## Assignment preview

- `PREVIEW` now sits directly beside `ANNOUNCE` in the existing pre-pull Boss Assignments footer.
- Preview uses the values currently visible in the assignment editor, including unsaved changes.
- The draft passes through the existing authoritative assignment validation and required-field checks before any preview is shown.
- Preview output uses the same 200-character Raid Warning line budget and 12-line plan budget as the existing assignment system.
- Valid output is printed locally only. It does not save the draft and does not send anything to raid, party or addon channels.
- Preview is blocked during an active encounter or combat, preserving the existing pre-pull planning boundary.

## Method Raid Tools comparison boundary

The public Method Raid Tools workflow remains useful as a product reference because it makes reusable raid planning, notes and timeline-oriented preparation easy to inspect before execution. Raid Lead Assist adopts only the core workflow principle that improves its own narrow purpose: validate and inspect a raid-leader plan before broadcasting it.

No Method Raid Tools source, assets, strings or implementation details are copied. Beta.61 does not add MRT's broad combat logging, loot, attendance, inspection, automarking, invite management or addon-network synchronization scope.

## Architecture and safety

- `Services/AssignmentPreviewService.lua` owns bounded preview rendering while delegating validity and required-assignment decisions to `Services.AssignmentService`.
- `UI/AssignmentPreview.lua` owns the themed button and tooltip and receives a bounded callback from `Core/ProductivityIntegration.lua`.
- The preview path introduces no combat-log listener, unit scanning, protected actions, target/focus manipulation, raid-marker automation or addon messaging.
- New regressions cover validation, normalization, required assignments, length/line budgets, module ordering, current-draft ownership and the local-only API boundary.

Beta.61 still requires the existing real-Retail live matrix for visual scaling, taint, frame-time and real-pull acceptance; source/CI validation does not replace live WoW testing.
