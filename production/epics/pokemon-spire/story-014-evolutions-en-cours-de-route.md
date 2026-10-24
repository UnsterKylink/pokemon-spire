# Story 014: Évolutions en cours de route

> **Epic**: Pokémon Spire
> **Status**: In Progress
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

- [ ] Les Pokémon de l'équipe évoluent à des moments définis en données (ex. certains badges), jusqu'au 3e stade (ex. Salamèche → Reptincel → Dracaufeu).
- [ ] Les données d'évolution couvrent les 3 stades pour tous les Pokémon de départ et les Pokémon capturables ; un Pokémon sans évolution suivante reçoit un bonus en données.
- [ ] Chaque évolution montre l'écran d'évolution (avant/après, bonus de PV) puis un choix de 1 carte parmi 3 de la nouvelle forme.
- [ ] Les cartes déjà portées par le Pokémon passent à sa forme évoluée ; la règle est la même pour tous les Pokémon (aucun code par Pokémon).

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

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 013
- Unlocks: Story 015
