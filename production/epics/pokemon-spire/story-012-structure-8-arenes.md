# Story 012: Structure : 8 arènes, zones et badges

> **Epic**: Pokémon Spire
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-21

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

- [x] La partie enchaîne 8 zones, chacune avec sa carte, ses salles et une arène finale ; le découpage (nombre d'étages par zone, regroupement en actes) est défini en données et tranché avec le joueur au début de la story.
- [x] Chaque zone a un type d'arène, un Champion (équipe définie en données, difficulté croissante) et un pool de Pokémon sauvages propre (données).
- [x] Battre un Champion donne son badge ; les badges obtenus sont visibles (barre du haut ou écran dédié).
- [x] La difficulté des ennemis augmente d'une zone à l'autre via des modificateurs en données.
- [x] Entre deux zones, la partie continue avec le même deck, PV, objets et argent ; la victoire finale n'est plus après le 1er Champion.
- [x] Défaite à 0 PV et « Nouvelle partie » fonctionnent toujours à n'importe quelle zone.

---

## Implementation Notes

- Valeurs de gameplay en données (`assets/data/`), aucun code spécifique à un Pokémon.
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.
- **Question de design à trancher avec le joueur au début de `/dev-story`** (voir le brief : « à décider avant de coder »).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 013 : Conseil 4 et Éthernatos
- 014 : évolutions en cours de route
- 015 : sauvegarde

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`: at `qa.level: minimal` tests are **waived** (advisory, never "must exist and pass"), but a Visual/Feel or UI story's retained screenshot is not.*

**Story Type**: Integration
**Required evidence**:
- Integration : `tests/integration/run/structure-8-arenes_test.gd` OR playtest doc — advisory at `qa.level: minimal`, plus a retained screenshot in `production/qa/evidence/` when the story changes what the player sees.

**Status**: [x] Retained screenshots in `production/qa/evidence/story-012-structure-8-arenes/`

---

## Dependencies

- Depends on: Story 011
- Unlocks: Story 013

---

## Completion Notes
**Completed**: 2026-10-24
**Criteria**: 6/6 passing (confirmed by the user in play; 7 screenshots retained)
**Deviations**: Advisory only — victory title still reads "Champion d'arène" (final victory replaced by story 013); no Dark gym (only 2 Dark Pokémon); room type `boss` kept as the gym; elite pools grow only via type share and zone modifiers; screenshots taken with QA shortcuts (floor counter low); hand cards narrow to fit 1280 px when the hand is large; QA hooks ship in the build
**Design decisions (with the user)**: 6 floors per zone; one map per gym; gym types drawn at random per run (8 distinct of 9); badge = permanent bonus + heal 30% + wild-pool unlock; evolution after badge 1 (story 014 extends it)
**Test Evidence**: Integration — tests waived at qa.level minimal; screenshots at `production/qa/evidence/story-012-structure-8-arenes/`
**Code Review**: Skipped — Solo mode
**User report checked**: "immune attacks reduce my protection" — not reproduced: an immune hit (0 damage) leaves block untouched; block expires at the start of the player's next turn by design (user chose to keep it)
