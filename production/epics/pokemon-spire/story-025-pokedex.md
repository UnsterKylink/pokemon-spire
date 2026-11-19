# Story 025: Pokédex

> **Epic**: Pokémon Spire
> **Status**: Complete
> **Layer**: Feature
> **Type**: UI
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-19

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief feuille de route, étape 7` (« Après le MVP », 2026-10-21)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (section « Après le MVP — feuille de route », étape 7), scoped to this story:*

- [x] Le Pokédex liste tous les Pokémon du jeu, avec ceux rencontrés et capturés marqués, conservés d'une partie à l'autre.
- [x] Chaque fiche montre sprite, nom, types et cartes enseignées ; un Pokémon jamais rencontré apparaît en silhouette.
- [x] Le Pokédex est accessible depuis le menu principal et affiche un compteur (vus / capturés / total).
- [x] **Choix du joueur (2026-11-19)** : grille par génération (onglets 1–9) avec filtres (type, vus / capturés), silhouette si jamais vu, fiche détaillée au clic (illustration officielle, types, cartes enseignées, nombre de fois vu / capturé) ; **paliers de récompenses** permanents légers selon le nombre de Pokémon capturés (en données), affichés dans le Pokédex et annoncés quand on les débloque.

---

## Implementation Notes

- Valeurs de gameplay en données (`assets/data/`), aucun code spécifique à un Pokémon.
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 026 : difficultés

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`: at `qa.level: minimal` tests are **waived** (advisory, never "must exist and pass"), but a Visual/Feel or UI story's retained screenshot is not.*

**Story Type**: UI
**Required evidence**:
- UI : a retained screenshot of each screen touched, in `production/qa/evidence/`

**Status**: [x] 10 captures dans `production/qa/evidence/story-025-pokedex/`, `tests/scratch/t25b_pokedex.gd`

---

## Dependencies

- Depends on: Story 024
- Unlocks: Story 026

## Completion Notes
**Completed**: 2026-11-19
**Criteria**: 4/4 (validé par le joueur ; t25b_pokedex 53/0, t9, t11, t18, t19, t23_menus, t24, t25, t32 OK, simulateur 100 parties OK ; 10 captures)
**Deviations**: Advisory only — le palier 150 améliore une carte de départ au début de la partie (au lieu d'une amélioration gratuite au premier Centre : cela aurait demandé de modifier l'écran du Centre) ; « vu » compte +1 par combat et par ennemi présent (pas par Pokémon individuel) et les 4 starters proposés ne sont pas marqués vus (seul le starter choisi l'est) ; total = 893 espèces (173 absentes du roster décrites dans `assets/data/pokedex_species.json`, généré par `tools/pokedex/generate_species.py`) ; la fiche de Salamèche montre les cartes portées par `salameche` (le starter n'a pas de liste `teaches`) ; pas d'entrée Pokédex dans le menu pause ; la bannière de palier recouvre l'en-tête de la carte pendant 4 s ; le Pokédex est inactif dans les tests et le simulateur sauf `qa_set_pokedex_path`
**Test Evidence**: Integration — `tests/scratch/t25b_pokedex.gd` ; captures `production/qa/evidence/story-025-pokedex/`
**Code Review**: Skipped — Solo mode
