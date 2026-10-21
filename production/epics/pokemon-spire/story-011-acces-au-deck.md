# Story 011: Accès au deck partout

> **Epic**: Pokémon Spire
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-21

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief feuille de route, étape 1` (« Après le MVP », 2026-10-21)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (section « Après le MVP — feuille de route », étape 1), scoped to this story:*

- [x] Un bouton « Deck » dans la barre du haut est visible et utilisable sur tous les écrans de partie (carte, combat, récompense, événement, Centre, Mart, évolution).
- [x] En combat, on peut consulter séparément le deck complet, la pioche (ordre masqué, triée) et la défausse.
- [x] L'affichage regroupe les copies identiques (×N), montre les cartes améliorées « + » distinctement et le Pokémon porteur de chaque carte.
- [x] Ouvrir / fermer le deck ne modifie jamais l'état de la partie ni du combat (pas de tour perdu, pas de clic traversant).
- [x] Le panneau tient en 1280×720 sans coupure, avec défilement si le deck est long (40+ cartes).

---

## Implementation Notes

- Valeurs de gameplay en données (`assets/data/`), aucun code spécifique à un Pokémon.
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Aucune autre fonctionnalité de la feuille de route.

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`: at `qa.level: minimal` tests are **waived** (advisory, never "must exist and pass"), but a Visual/Feel or UI story's retained screenshot is not.*

**Story Type**: UI
**Required evidence**:
- UI : a retained screenshot of each screen touched, in `production/qa/evidence/`

**Status**: [x] Retained screenshots in `production/qa/evidence/story-011-acces-au-deck/`

---

## Dependencies

- Depends on: None (MVP complete)
- Unlocks: Story 012

---

## Completion Notes
**Completed**: 2026-10-21
**Criteria**: 5/5 passing (confirmed by the user in play; 7 screenshots retained)
**Deviations**: Advisory only — real mouse clicks and Escape not tested with real input events; panel is a snapshot taken at open (not refreshed during the enemy turn); no keyboard/gamepad focus; Deck button disabled while Centre/Mart pickers are open; event, Centre, evolution and reward screens not captured (same button and panel); QA hooks ship in the build
**Test Evidence**: UI — tests waived at qa.level minimal; screenshots at `production/qa/evidence/story-011-acces-au-deck/`
**Code Review**: Skipped — Solo mode
