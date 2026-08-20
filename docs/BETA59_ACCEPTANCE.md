# Raid Lead Assist beta.59 additive acceptance

These are four unique controls added on top of the 172-point `TEN_OF_TEN_ACCEPTANCE.md` contract. They are not permutations of existing assignment/provider checks, so the combined controlled audit universe is 176 unique controls.

173. The Assignments footer exposes one local `PREVIEW` action through the existing `UI.ActionButton` component and existing AssignmentFrame ownership; it must not create a parallel theme, state owner or settings surface.
174. Preview validates the current unsaved assignment draft, including required fields and the existing Raid Warning line/plan budgets, without saving the draft or advancing runtime assignment rotations.
175. Preview is observation-only: it may print bounded local feedback but must never call `RaidWarning`, `SendChatMessage`, addon messaging or any other raid/network broadcast surface.
176. Current BigWigs Lost Explorers `Fling Fish` (1295817) must remain distinct from RLA's fish-order `Final Ascension` (1292779) call on Normal/Heroic/Mythic, while `Throw Junk` (1291933) remains mapped to the crates call.

The corresponding regression oracles are `tests/test_assignment_preview.lua` and `tests/test_explorers_fling_fish_isolation.lua`. Live visual spacing, UI scale, taint and real raid behavior remain governed by `LIVE_TEST_MATRIX.md` and are not replaced by these source tests.
