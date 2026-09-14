# Bosses 1–4 tactic alignment — 2026-09-14

This pass aligns the first four Venomous Abyss encounter surfaces with the existing reviewed strategy contract in `docs/AUDIT_SOURCES.md`. It is a wording/assignment consistency pass, not a new source review and not live Retail proof.

## Nek'zali

- Normal Pyre now states the full execution split in the raidleader call: melee soak, ranged stay out.
- Heroic/Mythic Pyre calls render the assigned soak group and explicitly keep everyone else out.
- The Phase 2 call keeps the chosen Bloodlust strategy but adds the existing burn-before-full-energy condition.
- Assignment ownership is unchanged: Heroic/Mythic require the Pyre group; Mythic additionally requires two distinct rotating Well groups.

## Entombed Sentinels

- Stasis now says to pair toxins to exactly four.
- The normal plan explicitly retains healing the weaker boss during Stasis.
- The post-Stasis call now combines the fixed physical side assignment with the tank boss swap, so the raid does not interpret “hold sides” as “hold bosses.”
- Assignment ownership is unchanged: two required, non-overlapping physical side groups on every difficulty.

## The Lost Explorers

- Normal/Heroic crate calls now use “break” consistently with the player plan.
- Final Ascension now explicitly says to feed Nama, then Iku, then Gebbo rather than only naming the order.
- Mythic keeps the controlled crate-breaker rotation and the 15+ yard clear-before-break boundary.
- Normal/Heroic remain assignment-free; Mythic retains two required breakers plus an optional third rotation slot.

## Vashnik the Malignant

- The Siphoning Infection call now names the visible Blood circle and tells several teammates to stack for healing.
- The fixed fountain route, Heroic Skull-then-Cross add order, Catalyst soaks and Mythic Tumor/Froth handling remain unchanged.
- No fixed player assignment is added; Blood-circle help remains shared raid execution rather than a permanent roster.

## Validation boundary

These changes preserve the existing provider identities, timing flags and encounter call keys. CI can prove syntax, static-analysis, registry/assignment contracts and deterministic release output. Real Retail timing, readability under combat load, player comprehension and encounter correctness remain `PASS-LIVE` gates.
