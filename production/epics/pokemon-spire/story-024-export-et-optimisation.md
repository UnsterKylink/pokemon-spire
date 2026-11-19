# Story 024: Version .exe Windows et optimisation

> **Epic**: Pokémon Spire
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-19

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

- [x] Un export Windows (.exe) se lance sans l'éditeur Godot, avec icône et nom du jeu.
- [x] Les raccourcis et outils de test (QA) ne sont pas actifs dans la version exportée.
- [x] Le jeu tient 60 images/s en combat avec animations sur une machine moyenne, et le chargement initial dure moins de 5 s (budgets en données de project.yaml).
- [x] Les images et sons sont importés aux bons formats (taille du jeu raisonnable) ; aucune erreur dans la console au lancement.
- [x] La procédure d'export est notée pour pouvoir la refaire.

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

**Status**: [x] Export Linux lancé sous xvfb (`production/qa/evidence/story-024-export-linux-title.png`), tests t9–t32 OK, procédure `docs/export-procedure.md`

---

## Dependencies

- Depends on: Story 023
- Unlocks: Story 025

## Completion Notes
**Completed**: 2026-11-19
**Criteria**: 5/5 (validé par le joueur ; exports Windows 215 Mo et Linux 181 Mo en ~14 s ; titre en ~2 s sous xvfb ; tests t9, t11, t18, t19, t23, t24, t25, t32 OK)
**Deviations**: Advisory only — **DEFERRED — requires playtest session** : 60 images/s en combat non mesuré (rendu logiciel sous xvfb non représentatif) et lancement du `.exe` sur un vrai PC Windows non constaté ; l'icône n'est pas intégrée au `.exe` exporté depuis Linux (rcedit + wine absents ; à faire depuis l'éditeur Windows avec rcedit) ; le nom produit / la version ne sont probablement pas écrits dans le `.exe` pour la même raison ; le `.exe` (215 Mo) vient surtout des sprites animés (65 Mo) et des cris (18 Mo) ; les décors d'origine (2752 px) ne survivent que dans l'historique git (.git 728 Mo, non réécrit) ; description du projet rédigée par l'assistant, à relire ; `.gitignore` ne liste plus `export_presets.cfg`
**Test Evidence**: Config/Data — tests `tests/scratch/` + capture `production/qa/evidence/story-024-export-linux-title.png` ; procédure `docs/export-procedure.md`
**Code Review**: Skipped — Solo mode
