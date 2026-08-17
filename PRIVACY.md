# Privacy and data flow

Raid Lead Assist does not use network APIs, addon-to-addon chat messages, external executables, telemetry, analytics, advertising identifiers or remote storage.

The addon reads only the WoW state needed for its stated role: encounter/difficulty context, public boss/timeline provider data, raid leadership permission and the current group roster used by the pre-pull assignment editor. Saved configuration, custom Raid Warning text, assignments and frame position are stored locally in `RaidLeadAssistDB` through WoW SavedVariables.

Raid Warning output is sent only when the user explicitly presses a plan/call/announce action and has raid leader/assistant permission. RLA does not silently broadcast the stored assignment database.

Roster names can be persisted when a user assigns players. Users should treat SavedVariables backups as local gameplay data and remove/reset assignments before sharing diagnostic files if they do not want character names included.
