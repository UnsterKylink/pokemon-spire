# Story 020: Style graphique, fonds de combat et cartes

> **Epic**: Pokémon Spire
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Visual/Feel
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-28

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

- [x] Une bible artistique définit le style (palette, typographie, cadres, icônes) et est appliquée à tous les écrans.
- [x] Chaque zone a un fond de combat propre (selon le type de l'arène / l'environnement).
- [x] Les cartes sont redessinées : cadre selon le type et la rareté, illustration du Pokémon porteur, lisibilité conservée.
- [x] La carte d'avancement (map) est plus belle : décor de zone, icônes de salles, chemin parcouru visible.
- [x] Tous les écrans gardent 1280×720 sans coupure ni chevauchement.

---

## Implementation Notes

- Valeurs de gameplay en données (`assets/data/`), aucun code spécifique à un Pokémon.
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.
- **Question de design à trancher avec le joueur au début de `/dev-story`** (voir le brief : « à décider avant de coder »).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 021 : animations
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

**Status**: [x] Captures et validation dans `production/qa/evidence/story-020-style-graphique/` + `story-020-style-graphique-evidence.md`

---

## Dependencies

- Depends on: Story 019
- Unlocks: Story 021

## Completion Notes
**Completed**: 2026-10-28
**Criteria**: 5/5 passing (validé par le joueur en jeu ; captures 01–06, 1x-, 2x- conservées)
**Deviations**: Advisory only — le style a été retouché ensuite en story 020b (polices Pokémon, carte de région illustrée, décors peints fournis par le joueur) ; liseré de la carte sélectionnée en combat et écran du choix du starter encore en sprites pixelisés
**Test Evidence**: Visual/Feel — captures dans `production/qa/evidence/story-020-style-graphique/` ; validation joueur dans `production/qa/evidence/story-020-style-graphique-evidence.md`
**Code Review**: Skipped — Solo mode
