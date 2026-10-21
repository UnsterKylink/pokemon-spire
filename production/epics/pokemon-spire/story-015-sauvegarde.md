# Story 015: Sauvegarde en cours de partie

> **Epic**: Pokémon Spire
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

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

- [ ] La partie est sauvegardée automatiquement à chaque retour sur la carte (après combat, salle ou événement).
- [ ] Relancer le jeu propose de reprendre la partie en cours : même zone, carte, deck (cartes améliorées comprises), PV, argent, objets, potions, badges et équipe.
- [ ] La reprise est déterministe : les mêmes choix donnent les mêmes résultats qu'avant la sauvegarde.
- [ ] Une sauvegarde absente, corrompue ou d'une version incompatible est signalée sans planter ; on peut alors lancer une nouvelle partie.
- [ ] La victoire finale ou la défaite efface la sauvegarde en cours.

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

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 014
- Unlocks: Story 016
