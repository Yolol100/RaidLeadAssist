# Phase 4 timing guidance — 2026-09-14

Phase 4 hardens the existing DBM/BigWigs/Blizzard timing stack instead of replacing it. Raid Lead Assist remains a manual Raid Warning tool: timing selects and colors the relevant button, but only the raid leader's click sends the warning.

## Stable identity boundary

Automatic guidance now requires the timer's numeric mechanic identity to match one of the selected call's reviewed `spellIDs`.

- DBM direct timers can guide when their public SpellID is reviewed and exact.
- BigWigs direct/cast timers can guide when their public key is a reviewed numeric SpellID and the timer is exact.
- Blizzard native timers can guide when the Encounter Timeline event exposes a reviewed SpellID and native timing is usable.
- Localized timer text is never sufficient for Phase 4 automatic guidance.
- BigWigs' nil-module Blizzard Timeline bridge has no mechanic SpellID. It therefore remains non-actionable/preview-only rather than being matched by localized bar text.
- Approximate, faded, malformed, unknown or unreviewed timers fail closed.

The existing provider authority, precision, encounter-scope, duplicate-occurrence and acknowledgement logic remains in `TimelineService`; Phase 4 adds a stricter guidance boundary above it.

## One current mechanic

The new `Services.TimingGuidance` layer normalizes all currently verified timer representations into one current mechanic:

- call key and call definition;
- provider/source identity;
- occurrence identity;
- timer precision;
- signed remaining time;
- one guidance state.

Only that mechanic's button is emphasized. Other timed buttons remain neutral unless they are showing short `CALLED` feedback after a manual click. This prevents two nearby bossmod bars from asking the raid leader to press multiple Raid Warning buttons at once.

For duplicate representations of the same occurrence, provider authority remains deterministic: DBM, then BigWigs, then Blizzard.

## Guidance states

The state model is:

1. `WAIT` — verified mechanic is next but outside the lead window.
2. `SOON` — internal `PREPARE` state; yellow/amber preparation window.
3. `PRESS NOW` — green manual-click window.
4. `LATE` — red bounded missed-click feedback for at most the existing timer-expiry grace.
5. `CALLED` — short feedback after the user manually sends the Raid Warning.

`GetCallState()` remains unchanged for compatibility. `GetGuidanceState()` owns the new WAIT/LATE behavior.

A removed bossmod bar can still show `LATE` for the bounded grace if it was the last verified mechanic and its expected deadline has just passed. The state never persists beyond that grace and never sends automatically.

## Fail-closed presentation

If a profile has timed calls but no stable, exact/native actionable mechanic is available, the timeline shows `NO VERIFIED TIMER` and no mechanic button is promoted. Manual buttons remain usable.

If automatic timing is disabled, the existing `AUTO TIMING OFF` behavior remains. Manual-only profiles keep `MANUAL CALLS ONLY`.

## Validation boundary

Static/CI validation can prove:

- stable-ID-only guidance selection;
- provider-order selection for duplicate occurrences;
- WAIT → SOON → PRESS NOW → LATE state transitions;
- bounded late expiry;
- single emphasized mechanic;
- one-shot PREPARE/PRESS audio;
- manual click ownership;
- fail-closed behavior for name-only and approximate timers.

CI cannot prove actual Retail callback timing, live bar identity, visibility under combat load, or that the chosen lead windows feel correct to the raid leader. Those remain Phase 5 `PASS-LIVE` gates.
