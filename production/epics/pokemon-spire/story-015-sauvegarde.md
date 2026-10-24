# Story 015: Sauvegarde en cours de partie

> **Epic**: Pokémon Spire
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-24

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief feuille de route, étape 2` (« Après le MVP », 2026-10-21)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (section « Après le MVP — feuille de route », étape 2), scoped to this story:*

- [x] La partie est sauvegardée automatiquement à chaque retour sur la carte (après combat, salle ou événement).
- [x] Relancer le jeu propose de reprendre la partie en cours : même zone, carte, deck (cartes améliorées comprises), PV, argent, objets, potions, badges et équipe.
- [x] La reprise est déterministe : les mêmes choix donnent les mêmes résultats qu'avant la sauvegarde.
- [x] Une sauvegarde absente, corrompue ou d'une version incompatible est signalée sans planter ; on peut alors lancer une nouvelle partie.
- [x] La victoire finale ou la défaite efface la sauvegarde en cours.

---

## Implementation Notes

- Valeurs de gameplay en données (`assets/data/`), aucun code spécifique à un Pokémon.
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 023 : menu principal (cette story peut proposer la reprise par un écran simple)

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`: at `qa.level: minimal` tests are **waived** (advisory, never "must exist and pass"), but a Visual/Feel or UI story's retained screenshot is not.*

**Story Type**: Integration
**Required evidence**:
- Integration : `tests/integration/run/sauvegarde_test.gd` OR playtest doc — advisory at `qa.level: minimal`, plus a retained screenshot in `production/qa/evidence/` when the story changes what the player sees.

**Status**: [x] Retained screenshots in `production/qa/evidence/story-015-sauvegarde/`

---

## Dependencies

- Depends on: Story 014
- Unlocks: Story 016

---

## Completion Notes
**Completed**: 2026-10-24
**Criteria**: 5/5 passing (confirmed by the user in play; 5 screenshots retained)
**Deviations**: Advisory only — single save slot (`user://savegame.json`, version 1); saves only at safe points (map / league intermission), so quitting mid-room or on a badge/evolution screen resumes before that room (same result thanks to restored RNG states); save deleted as soon as a battle is lost; unreadable saves are moved to `.bak` when detected; the resume screen is a stand-in until the main menu (story 023); league resume and deletion on victory verified by scratch test t19, not by screenshot; autosave disabled for scripted/CLI runs (--seed/--starter/--encounter); QA hooks ship in the build
**Test Evidence**: Integration — tests waived at qa.level minimal; screenshots at `production/qa/evidence/story-015-sauvegarde/`
**Code Review**: Skipped — Solo mode
