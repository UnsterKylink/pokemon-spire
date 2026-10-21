# Story 022: Musique et effets sonores

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

- [ ] Musiques différentes pour la carte, les combats sauvages, les Dresseurs / Champions, le Conseil 4, Éthernatos, la victoire et la défaite.
- [ ] Effets sonores pour les cartes jouées, les coups (selon l'efficacité), les menus, les achats, la capture et l'évolution.
- [ ] Volumes musique / effets réglables et mémorisés.
- [ ] Sons libres de droits ou créés pour le projet, listés avec leur source.

---

## Implementation Notes

- Valeurs de gameplay en données (`assets/data/`), aucun code spécifique à un Pokémon.
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 023 : menu et options

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

- Depends on: Story 021
- Unlocks: Story 023
