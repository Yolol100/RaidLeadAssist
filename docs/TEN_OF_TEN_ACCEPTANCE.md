# Raid Lead Assist — maximum master acceptance audit

A 10/10 claim is valid only for the scope with matching evidence. Source/CI cannot replace a live Retail client, raid pulls, assistive testing or real provider behavior.

Evidence states: `PASS-CI`, `PASS-LIVE`, `MANUAL TEST NEEDED`, `DRIFT REVIEW`, `N/A`, `FAIL`.

## Product contract and scope

1. The addon has one documented primary user: raid leader/assistant.
2. The normal workflow is boss -> difficulty -> plan/assignments -> combat calls.
3. RLA does not claim to replace DBM or BigWigs.
4. RLA does not select targets, players or protected combat actions dynamically.
5. RLA does not create an independent combat-log decision engine.
6. Automatic timing changes when a predefined human call is relevant, not what action should be chosen.
7. Unsupported/uncertain state fails closed rather than reusing stale context.
8. Product documentation distinguishes source validation from live validation.

## Repository, files and load order

9. Every tracked source file is UTF-8 text with LF endings and final newline.
10. Tracked paths are portable, normalized and free of case collisions.
11. No temp/editor/build/cache artifacts are committed.
12. No symlinks or unexpected binary payloads are committed.
13. Tracked source files stay below the repository size guardrail.
14. Required governance/audit/release files exist.
15. TOC paths are safe, unique and exist.
16. Every runtime Lua file appears exactly once in the TOC.
17. No unrelated Lua runtime exists outside the TOC inventory.
18. Every registered module name is unique.
19. Every `GetModule` dependency has an earlier TOC provider.
20. The approved App extension surface cannot silently gain another monkey patch.
21. `AssignmentIntegration` loads after `Core/App.lua` and its exact patch set is CI-locked.
22. Provider recovery remains event-driven and bounded rather than patching App methods.
23. Runtime filenames follow the canonical naming policy.
24. TOC metadata, version and changelog top entry agree.

## WoW platform and Midnight compliance

25. TOC `Interface` matches the intended Retail build (`120100` at this audit).
26. Optional DBM/BigWigs absence does not prevent addon load.
27. Every runtime Lua file parses under Lua 5.1.
28. Every runtime Lua file passes the blocking Luacheck policy.
29. Runtime contains no combat-log event processing used for decisions.
30. Runtime contains no live aura scanning used for decisions.
31. Runtime contains no unit health/power scanning used for decisions.
32. Runtime contains no live unit cast/channel scanning used for decisions.
33. Runtime contains no player/unit positioning or radar decision engine.
34. Runtime contains no protected spell/action/target automation.
35. Runtime contains no secure-action/state-driver automation.
36. Runtime contains no dynamic code loading or execution.
37. Runtime contains no addon networking/broadcast protocol.
38. Secret values are rejected before arithmetic, comparison, identity matching or persistence.
39. Malformed/NaN/infinite public values fail closed.
40. Missing/changed public APIs fail safely instead of crashing the addon.

## Encounter identity, difficulty and tactics

41. Exactly eight intended Venomous Abyss encounter identities are registered.
42. Numeric encounter identity is authoritative over localized display text.
43. Normal/Heroic/Mythic map to the correct supported difficulty IDs.
44. Boss and difficulty are locked to native encounter context during a pull.
45. Unsupported difficulty cannot retain a prior supported profile.
46. Unsupported encounter cannot retain a prior supported boss.
47. All 24 boss/difficulty profiles exist.
48. Every profile has non-empty pre-pull plan copy.
49. Every profile has a valid call set and unique stable call keys.
50. Every visible call maps to a real raid-leader coordination action.
51. Every plan is reviewed separately for Normal/Heroic/Mythic.
52. Difficulty-only mechanics never leak into a lower difficulty without evidence.
53. Spell, aura, cast, icon, timer and timeline IDs are not assumed interchangeable.
54. Provider-specific timer keys cannot silently replace UI mechanic identity.
55. Volatile tuning thresholds are omitted when authoritative sources may change.
56. Strategy status includes evidence/currentness and does not overclaim live proof.
57. Lost Explorers uses health balancing/joint finish rather than the obsolete fixed kill order.
58. Twin Fangs explicitly coordinates a joint finish.
59. Stable soak-count constraints match current encounter evidence.
60. Ula'tek remains manual-only until the dedicated live gate is satisfied.
61. Ula'tek Heroic does not inherit unconfirmed Mythic-only handling.
62. Post-hotfix tactic changes trigger a targeted strategy re-review.

## DBM provider

63. DBM availability detection is optional and safe.
64. DBM timer callback argument contracts match the reviewed baseline/current source.
65. Direct DBM timers resolve to a real supported encounter module.
66. Unknown/global/non-boss timers cannot create encounter calls.
67. Secret/malformed durations or IDs are rejected.
68. Disabled timers are not promoted to actionable calls.
69. Variable/approximate semantics are not treated as exact.
70. Begin/update/stop lifecycle preserves occurrence identity.
71. Pause/resume preserves timer identity and state.
72. Fade makes a timer non-actionable without inventing a new occurrence.
73. Reused DBM IDs cannot replay stale PREPARE/PRESS state.
74. DBM Blizzard-authority handoff is respected only when DBM can actually supply the relevant bars.

## BigWigs provider

75. BigWigs availability detection is optional and safe.
76. `BigWigs_Timer` contract matches the reviewed baseline/current source.
77. `BigWigs_CastTimer` contract matches the reviewed baseline/current source.
78. Direct bars require a real boss module/encounter ID.
79. Test/statistics/keystone/plugin timers cannot become encounter calls.
80. `BigWigs_StartBar` direct metadata is not duplicated as a second direct timer.
81. The nil-module Blizzard timeline bridge is distinguished from boss-module bars.
82. Pending timeline event IDs are one-shot and bounded.
83. Approximate bars remain non-actionable previews.
84. Disabled bars remain non-actionable.
85. Secret/malformed BigWigs metadata is rejected.
86. BigWigs event/count metadata cannot cross encounter scope.

## Blizzard Encounter Timeline and reconciliation

87. Blizzard provider requires the expected public Encounter Timeline APIs.
88. Only encounter-source timeline events are consumed.
89. Added events validate ID, duration, source and secret boundaries.
90. Existing active events can be seeded safely after provider startup.
91. Paused events cannot drive actionable countdown progress.
92. Resume restores the same occurrence rather than creating another.
93. Finished/canceled/removed events stop their timer representation.
94. Remaining/elapsed fallback calculations reject secret/non-finite values.
95. TimelineService scopes every usable timer to the verified encounter.
96. Provider priority is deterministic among equally precise representations.
97. Native/exact precision is required for actionable PREPARE/PRESS state.
98. Same-occurrence DBM/BigWigs/Blizzard representations are deduplicated.
99. Explicit conflicting occurrence counts prevent unsafe merges.
100. Late provider arrival cannot re-arm an acknowledged occurrence.
101. Timer corrections preserve occurrence identity.
102. Timer pause/fade/stop races do not replay audio/call states.
103. Provider reset/encounter switch clears stale timers.
104. Manual-only profiles bypass automatic provider lookup/action state.

## Assignments, roster, chat and audio

105. Assignment layouts exist for all 24 profiles.
106. Required player/group/rotation/rule/sequence field types validate before save.
107. Duplicate player names are rejected case-insensitively where uniqueness is required.
108. Simultaneous assignment groups cannot overlap when the mechanic forbids overlap.
109. Hard group-size constraints are enforced before announce.
110. Saved assignments are isolated per boss and difficulty.
111. Rotation state resets on encounter/boss/difficulty lifecycle boundaries.
112. Rotation advances only after a successful bound manual call.
113. Roster picker reads only current group/raid data needed for assignments.
114. Realm-qualified/long names and roster changes do not corrupt stored assignments.
115. Raid Warning send requires current raid leader/assistant permission.
116. Pre-pull plan/assignment briefing is blocked once an encounter is active.
117. Scheduled briefing stops on combat, permission loss, cancellation or send failure.
118. Briefing click lock and line delay prevent accidental burst spam.
119. Base call plus assignment detail is all-or-nothing at chat-size limits.
120. TTS unavailable state falls back safely to normal warning audio behavior.
121. PREPARE/PRESS audio fires once per actionable occurrence.
122. Manual-only profiles never produce automatic PREPARE/PRESS audio.

## SavedVariables, UI, security, release and live operations

123. Fresh SavedVariables defaults are valid and schema-tagged.
124. Historical schema migration prevents cross-difficulty message/assignment leakage.
125. Corrupt types and invalid/NaN/infinite positions normalize safely.
126. Newer unknown schema is preserved/fail-safe rather than destructively downgraded.
127. Runtime/front-end and WoW-visible metadata contain only intended English user copy.
128. UI states are not color-only: critical call state also has text labels.
129. Main/settings/assignment controls do not expose provider/debug internals as normal raid workflow.
130. Long text/names and representative 1080p/1440p/4K/ultrawide UI scales pass live layout testing.
131. Keyboard/focus/gamepad behavior where applicable passes live usability testing.
132. Non-English clients do not change mechanic identity semantics.
133. Live combat produces no addon-caused taint/`ADDON_ACTION_BLOCKED` errors.
134. CPU/frame-time remains acceptable during provider event bursts and raid pulls.
135. Memory/timer/frame/callback counts remain stable across repeated wipe/re-pull soak tests.
136. Tracked repository text contains no recognized credential/private-key patterns.
137. Runtime contains no advertising, premium unlock or donation prompt behavior.
138. SECURITY, PRIVACY, CONTRIBUTING and CODEOWNERS policies exist and match actual behavior.
139. GitHub Actions declare explicit permissions and privileged jobs are main-only.
140. Every external GitHub Action is pinned to a full 40-character commit SHA.
141. High-risk `pull_request_target`, `workflow_run` and `repository_dispatch` triggers are absent unless explicitly re-audited.
142. Workflows do not interpolate untrusted PR metadata into shell execution.
143. Download-to-shell workflow patterns are absent.
144. Dependabot monitors GitHub Actions dependency updates.
145. Upstream DBM/BigWigs release/file drift is machine-monitored.
146. Release ZIP is built twice and must be byte-identical.
147. Release ZIP inventory is limited to `RaidLeadAssist.toc` plus exactly the Lua runtime files listed by the TOC, with no repository-only documentation, tests, audit scripts or maintenance files, and every packaged byte matches the tested source.
148. Release ZIP has SHA-256 output and a retained Actions artifact.
149. Exact release ZIP receives GitHub/Sigstore build-provenance attestation.
150. Versioned prerelease/tag must target the exact validated main SHA.
151. Reusing a version for a different SHA is rejected.
152. Durable release ZIP/checksum assets provide rollback to previous verified builds.
153. `main` protection/ruleset status is explicitly audited; unprotected `main` remains an owner/admin blocker.
154. Repository license choice is explicit; no automation silently selects legal terms.
155. Secret-scanning/push-protection availability is checked by an owner/admin when connector permissions cannot prove it.
156. Current DBM/BigWigs stable release baselines are rechecked before release closure.
157. The online audit source register is reviewed for platform/source drift.
158. `/rla doctor` accurately distinguishes READY/CHECK based on real runtime prerequisites.
159. `/rla provider` diagnostics match observed provider traffic without changing behavior.
160. Every claimed live-ready boss/difficulty/provider combination has evidence in `LIVE_TEST_MATRIX.md`.

## Release gate

`TECHNICALLY GREEN` requires the exact SHA to pass runtime audit, repository audit, Lua 5.1 compile, Luacheck, all `tests/test_*.lua`, baseline validation, deterministic package comparison, SHA-256, artifact upload, provenance and matching versioned release assets.

A full product `10/10` additionally requires every applicable live-only row above to be `PASS-LIVE`. Missing live evidence stays `MANUAL TEST NEEDED`; upstream changes become `DRIFT REVIEW`; confirmed defects are `FAIL`.
