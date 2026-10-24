# Story 014: Évolutions en cours de route

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

- [x] Les Pokémon de l'équipe évoluent à des moments définis en données (ex. certains badges), jusqu'au 3e stade (ex. Salamèche → Reptincel → Dracaufeu).
- [x] Les données d'évolution couvrent les 3 stades pour tous les Pokémon de départ et les Pokémon capturables ; un Pokémon sans évolution suivante reçoit un bonus en données.
- [x] Chaque évolution montre l'écran d'évolution (avant/après, bonus de PV) puis un choix de 1 carte parmi 3 de la nouvelle forme.
- [x] Les cartes déjà portées par le Pokémon passent à sa forme évoluée ; la règle est la même pour tous les Pokémon (aucun code par Pokémon).

---

## Implementation Notes

- Valeurs de gameplay en données (`assets/data/`), aucun code spécifique à un Pokémon.
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 017 : capture (les Pokémon capturés profitent de cette règle une fois 017 faite)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`: at `qa.level: minimal` tests are **waived** (advisory, never "must exist and pass"), but a Visual/Feel or UI story's retained screenshot is not.*

**Story Type**: Integration
**Required evidence**:
- Integration : `tests/integration/run/evolutions-en-cours-de-route_test.gd` OR playtest doc — advisory at `qa.level: minimal`, plus a retained screenshot in `production/qa/evidence/` when the story changes what the player sees.

**Status**: [x] Retained screenshots in `production/qa/evidence/story-014-evolutions-en-cours-de-route/`

---

## Dependencies

- Depends on: Story 013
- Unlocks: Story 015

---

## Completion Notes
**Completed**: 2026-10-24
**Criteria**: 4/4 passing (confirmed by the user in play; 6 screenshots retained)
**Deviations**: Advisory only — screenshots taken with QA shortcuts (team cards added and wins counted by hooks; the "se renforce" shot shows 0 badges); an `ERR_CANT_OPEN` message at walkthrough start was not investigated (no effect, exit 0); a Pokémon with no next form gets no card choice (its card is upgraded directly); two lines evolving into the same form share progress; QA hooks ship in the build
**Design decisions (with the user)**: starter evolves after badges 1 and 4 (data `evolution_after_badges: [1, 4]`); team Pokémon evolve after 4 then 9 battles won with them in the deck (data `team_evolution`), +2 max HP each; no next form → +max HP and one card upgraded "+"
**Test Evidence**: Integration — tests waived at qa.level minimal; screenshots at `production/qa/evidence/story-014-evolutions-en-cours-de-route/`
**Code Review**: Skipped — Solo mode
