# Story 017: Capture avec Poké Balls

> **Epic**: Pokémon Spire
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-25

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief feuille de route, étape 3` (« Après le MVP », 2026-10-21)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (section « Après le MVP — feuille de route », étape 3), scoped to this story:*

- [x] Des Poké Balls (consommables, en données) s'obtiennent au Mart, en récompense ou en événement.
- [x] En combat sauvage, utiliser une Poké Ball sur un ennemi tente de le capturer ; la chance dépend de ses PV restants, de son statut et de la Ball (formule en données).
- [x] Un Pokémon capturé rejoint l'équipe : ses cartes (1–2) sont ajoutées au deck, portées par lui, et il peut entrer sur le terrain comme les autres.
- [x] On ne peut pas capturer les Pokémon de Dresseurs, de Champions, du Conseil ni Éthernatos.
- [x] L'équipe capturée est visible (liste ou écran d'équipe).

---

## Implementation Notes

- Valeurs de gameplay en données (`assets/data/`), aucun code spécifique à un Pokémon.
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.
- **Question de design à trancher avec le joueur au début de `/dev-story`** (voir le brief : « à décider avant de coder »).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 018 : rival et événements

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`: at `qa.level: minimal` tests are **waived** (advisory, never "must exist and pass"), but a Visual/Feel or UI story's retained screenshot is not.*

**Story Type**: Integration
**Required evidence**:
- Integration : `tests/integration/run/capture_test.gd` OR playtest doc — advisory at `qa.level: minimal`, plus a retained screenshot in `production/qa/evidence/` when the story changes what the player sees.

**Status**: [x] Retained screenshots in `production/qa/evidence/story-017-capture/`

---

## Dependencies

- Depends on: Story 016 (done), 019 (done: balance first, simulator to re-run after this story)
- Unlocks: Story 018

---

## Completion Notes
**Completed**: 2026-10-25
**Criteria**: 5/5 passing (confirmed by the user in play; 8 screenshots retained)
**Deviations**: Advisory only — only the best status bonus counts (not multiplied); a Pokémon with no `teaches` card is not capturable (none today except the boss); a captured Pokémon starts counting toward team evolution from the next won battle; the auto-player policy never throws balls, so the 36.2 % simulator result (600 runs, design/balance/report-post017.md) does not measure capture's effect — re-check balance with a capturing policy later; shot 05's ball loot chip and the Mart states were partly staged for the screenshots; QA hooks ship in the build
**Design decisions (with the user)**: chance = ball base × (1 − HP ratio × k) × best status bonus (data in balls.json); captured Pokémon brings all its teaches cards and joins the team; balls from Mart, loot and events, max 5, 1 energy per throw; wild fights only
**Test Evidence**: Integration — tests waived at qa.level minimal; scratch t3–t23 pass; screenshots at `production/qa/evidence/story-017-capture/`
**Code Review**: Skipped — Solo mode
