# Story 016: Statuts : brûlure, poison, paralysie, sommeil, gel

> **Epic**: Pokémon Spire
> **Status**: In Progress
> **Layer**: Core
> **Type**: Logic
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-24

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

- [ ] 5 statuts définis en données, avec effets, durées et affichage : brûlure (dégâts par tour, attaques affaiblies), poison (dégâts croissants), paralysie (chance de rater), sommeil (passe des tours), gel (bloqué jusqu'à dégel).
- [ ] Des cartes du joueur et des actions ennemies infligent des statuts ; les types immunisés comme dans les jeux (ex. Feu ne brûle pas, Électrik pas paralysé, Glace pas gelé, Poison/Acier pas empoisonnés).
- [ ] Les statuts s'appliquent aux ennemis et au Pokémon actif du joueur ; leur icône et leur durée sont visibles en combat.
- [ ] Des potions ou objets soignent les statuts (au moins un de chaque, en données).
- [ ] L'intention affichée d'un ennemi tient compte de son statut (ex. endormi → « dort »).

---

## Implementation Notes

- Valeurs de gameplay en données (`assets/data/`), aucun code spécifique à un Pokémon.
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.
- **Question de design à trancher avec le joueur au début de `/dev-story`** (voir le brief : « à décider avant de coder »).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 017 : capture

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`: at `qa.level: minimal` tests are **waived** (advisory, never "must exist and pass"), but a Visual/Feel or UI story's retained screenshot is not.*

**Story Type**: Logic
**Required evidence**:
- Logic : `tests/unit/run/statuts_test.gd` — waived at `qa.level: minimal`, plus a retained screenshot in `production/qa/evidence/` because the story changes what the player sees.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 015
- Unlocks: Story 017
