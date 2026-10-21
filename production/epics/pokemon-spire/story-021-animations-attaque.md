# Story 021: Animations d'attaque et de combat

> **Epic**: Pokémon Spire
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief feuille de route, étape 5` (« Après le MVP », 2026-10-21)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (section « Après le MVP — feuille de route », étape 5), scoped to this story:*

- [ ] Jouer une carte d'attaque lance une animation de l'attaquant et un effet selon le type de l'attaque (feu, eau, électrik…), en données.
- [ ] Les dégâts, protections, statuts, switch de Pokémon, K.O. et évolutions ont un retour visuel animé (secousse, clignotement, nombres flottants…).
- [ ] Les animations ne bloquent pas la partie plus longtemps qu'un délai défini en données ; une option permet de les accélérer.
- [ ] Aucune animation ne change le résultat du combat.

---

## Implementation Notes

- Valeurs de gameplay en données (`assets/data/`), aucun code spécifique à un Pokémon.
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 022 : son

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`: at `qa.level: minimal` tests are **waived** (advisory, never "must exist and pass"), but a Visual/Feel or UI story's retained screenshot is not.*

**Story Type**: Visual/Feel
**Required evidence**:
- Visual/Feel : a retained screenshot in `production/qa/evidence/` + sign-off in `production/qa/evidence/[story-slug]-evidence.md`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 020
- Unlocks: Story 022
