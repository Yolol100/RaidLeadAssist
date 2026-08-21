# Raid Lead Assist architecture and execution map

## Product contract

RLA serves the raid leader or raid assistant. Before a pull it prepares strategy, assignments and Raid Warning copy. During a supported pull it locks boss/difficulty context, exposes manual calls, and may show PREPARE/PRESS state only from sufficiently precise public DBM, BigWigs or Blizzard timeline data. It never selects combat targets or actions for players.

## Load order and ownership

1. `Bootstrap.lua` creates the addon namespace/module registry.
2. `Core/*` utilities/database/event bus establish shared primitives.
3. `Encounters/*` owns all boss/difficulty plans, calls and assignment definitions.
4. `Services/*` owns Raid Warning, messages, audio, roster, assignments, canonical assignment-plan rendering, local assignment presets/personal-assignment projection, provider adapters, timeline reconciliation and encounter context. `Services/AssignmentPlanService.lua` validates and renders the exact bounded lines shared by local PREVIEW and Raid Warning ANNOUNCE.
5. `UI/*` owns presentation and editing widgets. `UI/AssignmentPreview.lua` extends the existing assignment footer with the themed PREVIEW control; `UI/ProductivityPanel.lua` owns the visible READY/CHECK, timing-lead, preset and My Tasks controls while delegating state changes through callbacks.
6. `Core/App.lua` owns application lifecycle, selection, timing state, slash commands and primary event coordination.
7. `Core/AssignmentIntegration.lua` owns assignment initialization, preview/announce wiring, call-context safety and assignment-aware send behavior. PREVIEW and ANNOUNCE both call the same `AssignmentPlanService` renderer. CI locks its exact App patch surface.
8. `Core/ReadinessIntegration.lua` owns readiness aggregation/doctor extension. CI locks its exact App patch surface.
9. `Core/ProductivityIntegration.lua` owns the bounded callback bridge for READY/CHECK, timing leads, presets and My Tasks plus equivalent slash fallbacks. It does not own assignment preview behavior, creates no visual controls and adds no App monkey patch.
10. `Core/ProviderRecoveryIntegration.lua` is event-driven rather than a monkey patch. It performs bounded post-reload encounter recovery probes and cannot create encounter context without WoW already reporting an active encounter.

The module graph is validated in CI: every `GetModule` provider must exist and be loaded earlier in the TOC; module registration names must be unique. Service state owners load before their UI consumers. The assignment plan renderer loads after authoritative assignment validation, the preview UI loads after the assignment frame it extends, and assignment integration wires the preview only after both exist.

## Runtime lifecycle

### Addon load

Database migration/default normalization runs first. Registry state is selected, services/providers initialize, UI initializes, assignment integration initializes the assignment editor and attaches PREVIEW, productivity callbacks attach after the canonical App initialization, event handlers are registered and the main frame is shown only when forced or in the intended raid context.

### Pre-pull

The user selects boss/difficulty, edits optional custom warning copy and assignments, validates the assignment draft and may locally PREVIEW the current unsaved assignment plan before saving or announcing it. PREVIEW never saves or sends. ANNOUNCE reads the saved values after the editor's normal save path and passes them through the same canonical assignment-plan renderer, preventing preview/send formatting drift. Local assignment presets are scoped to the boss/difficulty currently open in the assignment window, not to stale main-frame selection. Default timing leads are edited in Settings and are used only when an encounter call has no specific lead override. Raid Warning permission is checked at send time. Multi-line briefings are cancellable and stop when combat/encounter state or permissions change.

### Encounter start

WoW encounter identity and difficulty become authoritative. Manual boss/difficulty changes are locked. Unknown encounter or unsupported difficulty disables calls/timing fail-closed. Assignment runtime rotations reset. Settings/assignment editors close for combat. Timing preference changes are also blocked through slash fallbacks so PREPARE/PRESS thresholds cannot be changed mid-pull.

### Timed call state

Provider adapters sanitize public inputs and pass them to `TimelineService`. TimelineService scopes timers to the verified encounter, preserves provider/source/precision identity, reconciles occurrences, deduplicates providers and exposes only exact/native timers as actionable. `App:UpdateTiming` maps those to IDLE/PREPARE/PRESS/CALLED and audio. Manual-only profiles bypass provider lookup.

### Manual call

The raid leader presses a configured call button. Active encounter/difficulty context is revalidated, message text is retrieved, assignment detail is appended only when it fits intact, Raid Warning permission is checked, the occurrence is acknowledged and any bound assignment rotation advances only after a successful send.

### Wipe/end/reload

Transient audio/call/timer/assignment state is reset. A reload during a pull stays fail-closed until WoW reports an active encounter and a bounded DBM/BigWigs hint confirms a supported boss. Provider hints alone cannot start a context.

## Security and Midnight boundaries

Runtime code must not use combat-log decision processing, live aura/health/power/cast/position scanning, protected action APIs, secure-action automation, dynamic code loading or addon networking. `scripts/audit_repository.py` blocks those API classes from the shipped runtime. Secret values and malformed provider values are rejected or downgraded instead of coerced into decisions.

Assignment planning stays local: PREVIEW is a read-only projection of the current editor draft, presets are bounded SavedVariables data and My Tasks is a read-only projection of the existing assignment plan. Readiness reuses existing diagnostics and timing defaults are bounded preferences. These features do not add network synchronization, combat logging, live target selection, protected marking or another data provider.

## Data ownership

- Encounter strategy/calls: `Encounters/VenomousAbyss/*.lua`.
- Assignment schemas/layouts: `Encounters/AssignmentRegistry.lua`.
- Assignment validation/storage/runtime rotations: `Services/AssignmentService.lua`.
- Shared PREVIEW/ANNOUNCE line rendering: `Services/AssignmentPlanService.lua`.
- Assignment preview/announce lifecycle and safety: `Core/AssignmentIntegration.lua`.
- Local user data: `RaidLeadAssistDB` / `Core/Database.lua`.
- Assignment preset validation/storage: `Services/AssignmentPresetService.lua`.
- Personal assignment projection: `Services/PersonalAssignmentService.lua`.
- Provider parsing: `Services/Providers/*.lua`.
- Cross-provider state: `Services/TimelineService.lua`.
- Visible assignment preview control: `UI/AssignmentPreview.lua`.
- Visible productivity controls: `UI/ProductivityPanel.lua`.
- Other visible UI: `UI/*.lua`.
- Release/audit controls: `scripts/*`, `.github/workflows/*`, `docs/*`.
