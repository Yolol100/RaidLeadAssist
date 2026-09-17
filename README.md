# Raid Lead Assist

Raid Lead Assist is a World of Warcraft Retail add-on for boss-specific raid-leader macros, per-difficulty tactics, and encounter-aware action-bar timing guidance.

Current add-on version: **1.1.13**.

## What it does

- Preloads boss profiles from the bundled encounter definitions.
- Keeps **Heroic** and **Mythic** macros, ordering, ability links, timing settings and tactics separate per boss.
- Lets you create, rename, edit, delete and reorder macros per boss and difficulty.
- Provides editable boss tactics and generates a dedicated **Pull Tactics** raid-warning macro from that text.
- Stores managed Raid Lead Assist macros in WoW **General Macros** so they are account-wide rather than character-specific.
- Lets every macro tile, the large selected-macro icon, and the **To Action Bar** button pick up the managed General Macro for placement on an action bar.
- Matches supported DBM, BigWigs or Blizzard encounter timers to linked boss abilities.
- Adds a full-button timing overlay to managed action-bar macros: progress/countdown, prepare state, press-now state and a short late state.
- Defers protected macro changes until combat ends when required by WoW.

## Requirements

- World of Warcraft Retail.
- DBM or BigWigs is optional. Blizzard native encounter timers are used as a fallback when available.

## Installation

1. Extract the release ZIP.
2. Place the `RaidLeadAssist` folder in `World of Warcraft/_retail_/Interface/AddOns/`.
3. Confirm `RaidLeadAssist.toc` is directly inside that folder.
4. Enable **Raid Lead Assist** in the WoW AddOns menu.

The generated GitHub Actions ZIP contains only the TOC and the runtime files listed by the TOC. Repository-only files such as this README and `.github/` are not included in the installable add-on package.

## Usage

Use `/rla` to open the Boss Macro Manager.

Available commands:

- `/rla` or `/rla toggle` — open or close the Boss Macro Manager
- `/rla show` — show it
- `/rla hide` — hide it
- `/rla status` — show the selected boss, difficulty, macro count, managed General Macro count and timer-provider status
- `/rla provider` — show detected timer providers
- `/rla resetpos` — reset the manager position

The AddOn Compartment entry also opens the Boss Macro Manager.

## Heroic and Mythic profiles

Choose **Heroic** or **Mythic** in the Boss Macro Manager. Changing difficulty changes the visible macro and tactics profile immediately. Encounter start/recovery also selects the supported difficulty from the live encounter when WoW supplies it.

Existing older SavedVariables are migrated to the difficulty-aware structure. Existing IDs are preserved where possible. A linked encounter macro that belongs to both difficulties receives an independent managed-macro ID in the other difficulty so action-bar markers stay unambiguous.

## General Macros and action-bar placement

Raid Lead Assist appends a small internal `/run RLA_P(...)` marker to every managed WoW macro. The marker lets the add-on identify an action-bar macro and acknowledge its timer occurrence after it is pressed. The marker counts toward WoW's macro-length limit, so the editor includes that overhead in its character counter.

Managed macros live in WoW **General Macros**. Older Raid Lead Assist character-specific macros are migrated to General Macros outside combat; the old character copy is removed only after the General Macro has been created successfully.

To place a macro on an action bar, use any of these methods outside combat:

- drag a macro tile from the grid;
- drag the large selected-macro icon below the grid;
- click **To Action Bar** and then place the macro.

Macro ordering inside Raid Lead Assist is changed with the `<` and `>` buttons. Dragging a macro tile is reserved for action-bar placement.

## Boss tactics

Use **Boss Tactics** for the selected boss/difficulty. Bundled bosses start with their included strategy text; **Reset Default** restores that text.

When tactics contain text, Raid Lead Assist maintains a **Pull Tactics** macro containing as many `/rw` lines as fit safely within WoW's macro-length limit. Saving or resetting tactics updates the managed General Macro. Clearing the tactics text removes the generated Pull Tactics entry and its managed WoW macro instead of leaving stale tactics behind.

Pull Tactics is intentionally not linked to a boss timer, so it does not receive the automatic timer overlay.

## Timing overlay

When a macro belongs to the active difficulty, is linked to a supported timer, and the current timer is exact/actionable, Raid Lead Assist overlays the action button:

- normal progress/countdown while the mechanic approaches;
- amber prepare state;
- red press-now state;
- red `NOW` state during the short late/grace window.

Approximate, faded, unmatched, unsupported, wrong-boss or wrong-difficulty timer data is not promoted to automatic press guidance.

Provider priority is DBM, then BigWigs, then Blizzard. The timeline service deduplicates matching occurrences and retains Blizzard-native timing as a fallback when a boss-mod timer is not precise enough for automatic guidance.

## Combat safety

WoW restricts macro and action-bar changes during combat. Raid Lead Assist therefore does not create, edit, delete or pick up managed macros while `InCombatLockdown()` is active. Required synchronization/deletion is queued and retried after `PLAYER_REGEN_ENABLED`. The visual timing overlay remains separate from protected action-button behavior.

## Bundled raid data

The repository currently includes Heroic/Mythic profiles for all eight bosses in **The Venomous Abyss**. Provider integration has been source-checked against the current DBM and BigWigs timer callback/message contracts used by those raid modules.

## Repository structure

- `Core/` — database, events, constants, application controller and AddOn Compartment
- `Encounters/` — bundled boss definitions, Heroic/Mythic profiles and tactics source text
- `Services/Providers/` — DBM, BigWigs and Blizzard timer adapters
- `Services/TimelineService.lua` — canonical timer state, precision handling and deduplication
- `Services/EncounterService.lua` — encounter/difficulty detection and reload recovery
- `Services/BossMacroService.lua` — boss/difficulty macro state, tactics, ordering, ability linkage and timer matching
- `Services/TacticsMacroService.lua` — generated Pull Tactics macro lifecycle
- `Services/ManagedMacroService.lua` — General Macro lifecycle, migration and combat queue
- `Services/ActionBarOverlayService.lua` — action-button timing presentation
- `UI/` — Boss Macro Manager, layout polish and icon picker
- `RaidLeadAssist.toc` — WoW add-on manifest and runtime load order
- `.github/workflows/validation.yml` — source checks, Lua parse and minimal runtime ZIP build

## Validation boundary

CI verifies repository hygiene, TOC closure/load list, Lua 5.1 syntax, key General Macro and action-bar contracts, final UI anchors, encounter-data invariants, timer-provider safeguards and package contents. The package is built from the TOC so repository-only files cannot accidentally ship with the add-on.

Final acceptance of protected-action behavior, taint, real drag/drop rendering, UI-scale clipping and live DBM/BigWigs/Blizzard timing still requires an in-game World of Warcraft test. Source/CI validation cannot prove those runtime behaviors by itself.
