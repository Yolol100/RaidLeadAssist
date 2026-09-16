# Raid Lead Assist

Raid Lead Assist is a World of Warcraft Retail add-on focused on boss-specific raid-leader macros with encounter-aware action-bar timing guidance.

## What it does

- Preloads boss profiles from the bundled encounter definitions.
- Lets you create, rename and delete boss profiles and macros.
- Uses Blizzard-style macro configuration and icon selection.
- Creates managed character macros that can be picked up and placed on action bars.
- Matches supported DBM, BigWigs or Blizzard encounter timers to linked boss abilities.
- Adds a full-button timing overlay to managed action-bar macros: white progress/countdown, amber prepare state, and red press/late state.
- Defers macro create/edit/delete work until combat ends when required by WoW's protected-action rules.

## Requirements

- World of Warcraft Retail
- DBM or BigWigs is optional; Blizzard native encounter timers are used as a fallback when available.

## Installation

1. Place the `RaidLeadAssist` folder in `World of Warcraft/_retail_/Interface/AddOns/`.
2. Make sure `RaidLeadAssist.toc` is directly inside that folder.
3. Enable **Raid Lead Assist** in the WoW AddOns menu.

## Usage

Use `/rla` to open the Boss Macro Manager.

Available commands:

- `/rla` or `/rla toggle` — open or close the Boss Macro Manager
- `/rla show` — show it
- `/rla hide` — hide it
- `/rla status` — show the selected boss, macro count and timer-provider status
- `/rla provider` — show detected timer providers
- `/rla resetpos` — reset the manager position

The AddOn Compartment entry also opens the Boss Macro Manager.

## Boss Macro Manager

Each boss has a grid of macros. A macro can contain normal WoW macro commands and can optionally be linked to a bundled boss ability or to an advanced timer match.

The manager stores a small internal marker in managed WoW character macros so Raid Lead Assist can identify the macro after it has been placed on an action bar. That marker counts toward WoW's macro-length limit; the editor includes it in the displayed character count and blocks an over-limit save.

Creating or editing a Raid Lead Assist entry does not require the macro to already be on an action bar. Use **To Action Bar** or drag the selected macro to pick up the managed WoW macro and place it normally.

## Timing overlay

When a macro is linked to a supported timer and the current timer is exact/actionable, Raid Lead Assist overlays the complete action button:

- **white progress/countdown** — the mechanic is approaching;
- **amber border/countdown** — prepare window;
- **red full-button veil and border** — press-now window;
- **red NOW state** — the short late/grace window immediately after the deadline.

Approximate, faded, unmatched or unsupported timer data is not promoted to exact automatic guidance.

## Combat safety

WoW restricts macro and action-bar changes during combat. Raid Lead Assist therefore:

- does not create, edit, delete or pick up managed macros while `InCombatLockdown()` is active;
- queues managed macro synchronization/deletion and retries it after `PLAYER_REGEN_ENABLED`;
- keeps the timing overlay presentation separate from protected action-button behavior.

## Repository structure

The repository intentionally keeps only the runtime code required by the add-on plus this README.

- `Core/` — database, events, constants, bootstrap controller and AddOn Compartment
- `Encounters/` — bundled boss definitions and matching registry
- `Services/Providers/` — DBM, BigWigs and Blizzard timer adapters
- `Services/TimelineService.lua` — canonical timer state and deduplication
- `Services/EncounterService.lua` — encounter/difficulty detection and reload recovery
- `Services/BossMacroService.lua` — boss/macro state, ability linkage and timer matching
- `Services/ManagedMacroService.lua` — managed WoW macro lifecycle and combat queue
- `Services/ActionBarOverlayService.lua` — action-button timing presentation
- `UI/` — Boss Macro Manager and icon picker
- `RaidLeadAssist.toc` — WoW add-on manifest

## Validation boundary

Repository/source validation can verify manifest closure, syntax, module ordering, timer/provider contracts and controlled-runtime behavior. Final acceptance of protected-action behavior, taint, drag/drop and real DBM/BigWigs/Blizzard action-bar timing still requires an in-game World of Warcraft test.
