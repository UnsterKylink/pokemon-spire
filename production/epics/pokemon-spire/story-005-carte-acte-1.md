# Story 005: Carte de l'acte 1

> **Epic**: Pokémon Spire
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature 5`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (the **Player goal & fail state** field + MVP feature 5), scoped to this story:*

- [ ] Une carte de l'acte est générée au début de la partie : ~15 étages, plusieurs chemins qui se croisent, et le boss au dernier étage.
- [ ] Types de salles : combat sauvage, Dresseur élite, Centre Pokémon, Poké Mart, événement, boss Champion ; proportions définies en données.
- [ ] Le joueur ne peut choisir qu'une salle reliée à sa salle actuelle ; les salles visitées sont marquées.
- [ ] Entrer dans une salle de combat lance le combat correspondant (ennemis tirés d'une liste par type de salle) ; la victoire ramène à la carte.
- [ ] Les élites sont plus difficiles que les combats normaux et donnent une meilleure récompense.
- [ ] Au moins 1 événement simple à choix (texte + 2 options avec conséquences).

---

## Implementation Notes

- Génération de carte avec un générateur aléatoire injecté et une graine affichable.
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 006 : contenu du Centre Pokémon et du Poké Mart
- 007 : le boss

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/run/carte-acte-1_test.gd` OR playtest doc — advisory at `qa.level: minimal`, plus a retained screenshot in `production/qa/evidence/` because the story changes what the player sees.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 004 must be DONE
- Unlocks: Story 006
