# Story 003: Types et multiplicateurs

> **Epic**: Pokémon Spire
> **Status**: In Progress
> **Layer**: Core
> **Type**: Logic
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-18

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature 3`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (the **Player goal & fail state** field + MVP feature 3), scoped to this story:*

- [ ] Chaque carte d'attaque et chaque Pokémon ont un type (au minimum : Feu, Eau, Plante, Normal, Électrik, Vol, Insecte, Roche, Sol, Poison).
- [ ] Une table des types en données définit les multiplicateurs : super efficace ×1,5, pas très efficace ×0,5, neutre ×1.
- [ ] Les dégâts finaux = dégâts de base × multiplicateur de type, arrondis à l'entier inférieur, appliqués avant la protection.
- [ ] Les attaques des ennemis utilisent aussi les types contre Salamèche (type Feu, puis Feu après évolution).
- [ ] Un texte « Super efficace ! » ou « Ce n'est pas très efficace… » s'affiche brièvement quand le multiplicateur n'est pas ×1.
- [ ] Le type de chaque carte et de chaque ennemi est visible à l'écran (couleur ou icône).

---

## Implementation Notes

- Formule de dégâts centralisée dans une seule fonction testable.
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 006 : objets qui modifient les dégâts

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/combat/types_test.gd` — advisory at `qa.level: minimal` (tests waived), plus a retained screenshot in `production/qa/evidence/` because the story changes what the player sees.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 must be DONE
- Unlocks: Story 004
