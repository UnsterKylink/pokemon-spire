# Story 024: Version .exe Windows et optimisation

> **Epic**: Pokémon Spire
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief feuille de route, étape 6` (« Après le MVP », 2026-10-21)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (section « Après le MVP — feuille de route », étape 6), scoped to this story:*

- [ ] Un export Windows (.exe) se lance sans l'éditeur Godot, avec icône et nom du jeu.
- [ ] Les raccourcis et outils de test (QA) ne sont pas actifs dans la version exportée.
- [ ] Le jeu tient 60 images/s en combat avec animations sur une machine moyenne, et le chargement initial dure moins de 5 s (budgets en données de project.yaml).
- [ ] Les images et sons sont importés aux bons formats (taille du jeu raisonnable) ; aucune erreur dans la console au lancement.
- [ ] La procédure d'export est notée pour pouvoir la refaire.

---

## Implementation Notes

- Valeurs de gameplay en données (`assets/data/`), aucun code spécifique à un Pokémon.
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 025 : Pokédex

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`: at `qa.level: minimal` tests are **waived** (advisory, never "must exist and pass"), but a Visual/Feel or UI story's retained screenshot is not.*

**Story Type**: Integration
**Required evidence**:
- Integration : `tests/integration/run/export-et-optimisation_test.gd` OR playtest doc — advisory at `qa.level: minimal`, plus a retained screenshot in `production/qa/evidence/` when the story changes what the player sees.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 023
- Unlocks: Story 025
