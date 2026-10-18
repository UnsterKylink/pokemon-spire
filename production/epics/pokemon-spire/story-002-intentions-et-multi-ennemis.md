# Story 002: Intentions des ennemis et combats à plusieurs

> **Epic**: Pokémon Spire
> **Status**: In Progress
> **Layer**: Core
> **Type**: Logic
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-18

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature 2`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (the **Player goal & fail state** field + MVP feature 2), scoped to this story:*

- [ ] Chaque ennemi affiche au-dessus de lui son intention pour le prochain tour (attaque + valeur, protection, bonus).
- [ ] L'action exécutée en fin de tour correspond exactement à l'intention affichée.
- [ ] Le comportement de chaque ennemi est défini dans ses données (séquence fixe ou aléatoire pondéré), sans code spécifique par Pokémon.
- [ ] Un combat peut contenir de 1 à 3 ennemis ; le joueur choisit la cible des cartes à cible unique.
- [ ] Le combat est gagné quand tous les ennemis sont K.O. ; un ennemi K.O. n'agit plus et n'est plus ciblable.
- [ ] Au moins 5 Pokémon ennemis différents sont définis dans les données.

---

## Implementation Notes

- L'aléatoire passe par un générateur injecté (graine fixe possible pour les tests).
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 003 : types
- 007 : comportement spécial du boss

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/combat/intentions-et-multi-ennemis_test.gd` — advisory at `qa.level: minimal` (tests waived), plus a retained screenshot in `production/qa/evidence/` because the story changes what the player sees.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 must be DONE
- Unlocks: Story 003
