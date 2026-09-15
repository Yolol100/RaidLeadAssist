# Raid Lead Assist

Raid Lead Assist is a World of Warcraft Retail boss macro manager designed to feel like Blizzard's own Macro UI.

Choose a boss, select or create a macro, link it to a boss ability, adjust the name/icon/text if needed, and place the managed macro on a normal Blizzard action bar. During the encounter the entire action button becomes the timer: a translucent white full-button progress layer counts down, the button enters an amber prepare state, and the whole button turns red when it is time to press it.

## Main workflow

1. Open Raid Lead Assist with `/rla` or the AddOn Compartment.
2. Choose a boss from the dropdown.
3. Select one of the preinstalled boss macros or press **New**.
4. Choose the boss ability, macro text and icon.
5. Press **Save**.
6. Use **To Action Bar** or drag the macro icon to pick up the managed WoW macro.
7. During the encounter, press the action-bar macro when its full-button timing overlay turns red.

The addon never presses the macro for you. The player remains responsible for the actual action-bar input.

## Preinstalled boss macros

The supported Venomous Abyss encounters are seeded automatically from Raid Lead Assist's encounter definitions. Existing ability spell IDs, timer aliases, warning text and timing windows are reused.

Where an ability has a known spell ID, Raid Lead Assist asks the WoW client for the current official spell texture instead of bundling copied icon files.

You can still:

- add, rename or remove bosses;
- add, edit or remove macros;
- change the macro name and icon;
- select another linked boss ability;
- enter custom macro commands;
- configure advanced Spell ID/timer matching when necessary.

## Blizzard-style interface

The configuration flow deliberately follows Blizzard's Macro UI conventions:

- Blizzard `ButtonFrameTemplate` framing;
- boss dropdown above the macro grid;
- six-column icon grid;
- selected macro editor;
- Blizzard-style buttons, fonts, borders and input controls;
- a separate Change Name/Icon window backed by Blizzard's current macro icon provider.

## Action-bar timing overlay

A linked, actionable boss timer is displayed over the entire managed macro button.

- **Countdown** — translucent white progress covers the full icon and shrinks toward zero, with a thin moving white edge and central countdown.
- **Prepare** — the full-button timer remains visible and gains an amber border.
- **Press** — the whole button receives a transparent red veil, red border and urgent pulse.
- **Late** — the urgent red state remains briefly visible within the bounded late window.
- **Acknowledged** — pressing the managed macro acknowledges that occurrence and clears the urgent state until the next occurrence.

Raid Lead Assist uses its existing timer engine rather than running a second independent timer system.

## Timer sources

Automatic timing supports the existing provider stack:

- DBM;
- BigWigs;
- Blizzard's native encounter timeline where available.

Reliable spell/call identity is preferred. If a custom macro cannot be matched reliably, it remains usable as a normal manual macro without inventing a countdown.

## Combat safety

WoW macro creation, editing, deletion and pickup are treated as out-of-combat operations.

If a saved managed macro needs to change during combat, Raid Lead Assist queues the write and processes it after `PLAYER_REGEN_ENABLED`. The action-bar overlay is visual only; it does not replace or mutate the protected action carried by the Blizzard action button.

## Commands

- `/rla` — toggle the Boss Macro Manager
- `/rla show` — show it
- `/rla hide` — hide it
- `/rla status` — show selected boss/macro and provider status
- `/rla provider` — show timer-provider diagnostics
- `/rla resetpos` — reset the manager position

## Installation

1. Place the `RaidLeadAssist` folder in `World of Warcraft/_retail_/Interface/AddOns/`.
2. Ensure `RaidLeadAssist.toc` is directly inside the folder.
3. Enable **Raid Lead Assist** from the WoW AddOns screen.
4. DBM and BigWigs are optional timer providers.

## Repository structure

The repository intentionally keeps only the runtime required by the Boss Macro Manager plus this README.

- `Core/` — bootstrap state, database migration, app wiring and AddOn Compartment integration
- `Encounters/` — supported boss/ability definitions
- `Services/Providers/` — DBM, BigWigs and Blizzard timer adapters
- `Services/TimelineService.lua` — timer normalization and provider authority
- `Services/BossMacroService.lua` — boss/macro model and timer matching
- `Services/ManagedMacroService.lua` — real WoW character macro lifecycle
- `Services/ActionBarOverlayService.lua` — full-button countdown/prepare/press visual layer
- `UI/` — Blizzard-style macro manager and icon picker
- `RaidLeadAssist.toc` — runtime manifest
