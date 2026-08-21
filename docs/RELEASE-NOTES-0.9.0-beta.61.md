# Raid Lead Assist 0.9.0-beta.61

Beta.61 finishes the assignment-preview integration and gives it a new immutable prerelease identity instead of reusing the already published beta.60 tag.

## Assignment preview

- `PREVIEW` sits directly beside `ANNOUNCE` in the existing pre-pull Boss Assignments footer and uses the same themed `ActionButton` component, height, font size and spacing as the surrounding controls.
- Preview reads the values currently visible in the editor, including unsaved changes, validates them and prints the resulting assignment plan locally only.
- Preview never saves the draft and never sends raid, party or addon traffic.
- Status and required-assignment feedback now use the full footer width above the action row, preventing the added button from squeezing long validation text into a narrow column.

## Shared preview and announce rendering

- `Services/AssignmentPlanService.lua` is the single bounded renderer used by both local PREVIEW and Raid Warning ANNOUNCE.
- Both paths therefore share the same assignment validation, required-field checks, 200-character Raid Warning line limit and 12-line plan limit.
- `Core/AssignmentIntegration.lua` owns both preview and announce wiring. `Core/ProductivityIntegration.lua` returns to READY/CHECK, timing leads, presets and My Tasks only.

## Safety and scope

- The existing pre-pull, combat and newer-schema boundaries remain authoritative.
- No combat-log listener, live unit-state scanning, protected action, target/focus manipulation, raid-marker automation, addon networking, loot, attendance or invite-management scope is added.
- The workflow idea was implemented independently; no Method Raid Tools source, assets or strings are copied.

## Validation boundary

Automated CI covers Lua compilation, static analysis, module order, preview/announce ownership, shared rendering, runtime-policy safety, release reproducibility and SBOM/provenance inputs. Real Retail UI scaling, long-name rendering, taint, frame-time and accessibility remain live acceptance checks and are not claimed from source inspection alone.
