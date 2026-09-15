# Raid Lead Assist

Raid Lead Assist is a World of Warcraft raid-leader add-on for tactical callouts, raid warnings, assignments and encounter timing support.

## Features

- Manual raid-leader callouts and raid warnings
- Heroic and Mythic encounter profiles
- Encounter-specific assignments and setup support
- Automatic timing support from DBM, BigWigs and Blizzard encounter timelines
- Audio cues and visual call states
- Provider diagnostics and readiness checks
- In-game settings and movable/scalable UI

## Installation

1. Download or clone this repository.
2. Place the add-on folder in:
   `World of Warcraft/_retail_/Interface/AddOns/`
3. Make sure the folder is named `RaidLeadAssist` and contains `RaidLeadAssist.toc` directly inside it.
4. Restart World of Warcraft or reload the UI.
5. Enable **Raid Lead Assist** in the AddOns menu.

## Optional dependencies

Raid Lead Assist can integrate with:

- DBM (`DBM-Core`)
- BigWigs

The add-on also supports Blizzard's native encounter timeline where available.

## Commands

Use `/rla` in game.

- `/rla show` — show the window
- `/rla hide` — hide the window
- `/rla toggle` — toggle the window
- `/rla settings` — open settings
- `/rla difficulty heroic|mythic` — select a profile outside an active encounter
- `/rla resetpos` — reset the window position
- `/rla audio on|off` — enable or disable audio
- `/rla timing on|off` — enable or disable automatic timing
- `/rla provider` — show timer-provider diagnostics
- `/rla doctor` — run the readiness check
- `/rla status` — show current add-on status

## Repository structure

Only files required for the add-on runtime are kept in this repository, plus this README.

- `Core/` — application state and integrations
- `Encounters/` — encounter profiles, assignments and layouts
- `Services/` — timing, providers, warnings, roster and assignments
- `UI/` — in-game interface
- `Bootstrap.lua` — module bootstrap
- `RaidLeadAssist.toc` — World of Warcraft add-on manifest
