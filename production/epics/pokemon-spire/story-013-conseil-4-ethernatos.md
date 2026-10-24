# Story 013: Conseil 4 et Éthernatos

> **Epic**: Pokémon Spire
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-24

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief feuille de route, étape 2` (« Après le MVP », 2026-10-21)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (section « Après le MVP — feuille de route », étape 2), scoped to this story:*

- [x] Après le 8e badge, le Conseil 4 : 4 Dresseurs d'élite puis le Maître, avec équipes définies en données ; les règles d'enchaînement (soin ou non entre les combats) sont définies en données.
- [x] Éthernatos est le boss final, avec un comportement spécial défini en données (ex. plusieurs phases, intentions propres), plus difficile que le Maître.
- [x] Battre Éthernatos mène à l'écran de victoire finale, qui résume toute la partie (badges, Conseil, deck final).
- [x] Perdre à n'importe quel combat du Conseil ou contre Éthernatos mène à l'écran de défaite.

---

## Implementation Notes

- Valeurs de gameplay en données (`assets/data/`), aucun code spécifique à un Pokémon.
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.
- **Question de design à trancher avec le joueur au début de `/dev-story`** (voir le brief : « à décider avant de coder »).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 014 : évolutions

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`: at `qa.level: minimal` tests are **waived** (advisory, never "must exist and pass"), but a Visual/Feel or UI story's retained screenshot is not.*

**Story Type**: Integration
**Required evidence**:
- Integration : `tests/integration/run/conseil-4-ethernatos_test.gd` OR playtest doc — advisory at `qa.level: minimal`, plus a retained screenshot in `production/qa/evidence/` when the story changes what the player sees.

**Status**: [x] Retained screenshots in `production/qa/evidence/story-013-conseil-4-ethernatos/`

---

## Dependencies

- Depends on: Story 012
- Unlocks: Story 014

---

## Completion Notes
**Completed**: 2026-10-24
**Criteria**: 4/4 passing (confirmed by the user in play; 8 screenshots retained)
**Deviations**: Advisory only — league teams have 3 Pokémon (Battle.MAX_ENEMIES = 3); no money/loot during the league (no shop after badge 8); Éthernatos is one solo fight with a long action sequence, no phases (user's choice); league balance not playtested; the gym-type fallback for member types is coded but never triggered by the shipped data; defeat screenshot taken via QA skip (0 badges shown); QA hooks ship in the build
**Design decisions (with the user)**: 25 % heal + 1-of-3 card between the 5 league fights; 4 member types drawn among Spectre/Glace/Combat/Psy/Ténèbres/Acier excluding the run's gym types; Maître Peter (Dragon); Éthernatos solo
**Test Evidence**: Integration — tests waived at qa.level minimal; screenshots at `production/qa/evidence/story-013-conseil-4-ethernatos/`
**Code Review**: Skipped — Solo mode
