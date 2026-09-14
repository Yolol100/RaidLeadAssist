# Retail Raid Warning delivery gate

This checklist supplements `docs/LIVE_TEST_MATRIX.md`. It defines what counts as evidence for every matrix row that says a manual call or assignment briefing was sent. Source review, CI, a successful Lua return value, or local button feedback do **not** prove that Retail actually delivered the message.

## PASS-LIVE acceptance

Use the exact installed Raid Lead Assist version/SHA being evaluated and record the current Retail build, raid size, difficulty, player permission state, and enabled bossmods.

A manual call or briefing is `PASS-LIVE` only when all applicable points below are observed in a real Retail raid:

- Start a supported encounter and test while the encounter is active, not only before pull.
- Test once as raid leader and once as raid assistant when practical.
- Trigger a manual Raid Lead Assist call whose final rendered text includes the expected assignment detail.
- Confirm the exact rendered message is visibly delivered through `RAID_WARNING`/raid chat to at least one other raid member or independently observed client. Local UI state alone is insufficient.
- Confirm there is no `ADDON_ACTION_BLOCKED`, Lua error, chat-lockdown rejection, silent truncation, or other protected-action failure associated with the send.
- Confirm Raid Lead Assist marks the call as sent/acknowledged only when the chat send path succeeds according to its runtime contract.
- Remove or lose raid-warning permission and repeat the action. The addon must fail safely; it must not present missing chat delivery as successful raid communication.
- Repeat after `/reload` and after a wipe/repull so a stale permission, encounter, assignment, or provider state cannot create a false positive.
- For a long assignment call, verify the visible message is complete. The source/CI 200-character guard remains necessary, but only Retail observation proves end-to-end delivery.

## Evidence rule

Record the observed chat text plus date/time, Retail build, installed RLA SHA/version, permission state, encounter/difficulty, and provider combination. A successful API call without visible remote delivery is **not** `PASS-LIVE` evidence.

If any active-encounter send is blocked, missing, truncated, or only appears locally, mark the applicable `docs/LIVE_TEST_MATRIX.md` manual-call row **NO-GO** until the behavior is reproduced and fixed.
