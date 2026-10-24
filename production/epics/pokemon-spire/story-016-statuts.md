# Story 016: Statuts : brûlure, poison, paralysie, sommeil, gel

> **Epic**: Pokémon Spire
> **Status**: Complete
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

- [x] 5 statuts définis en données, avec effets, durées et affichage : brûlure (dégâts par tour, attaques affaiblies), poison (dégâts croissants), paralysie (chance de rater), sommeil (passe des tours), gel (bloqué jusqu'à dégel).
- [x] Des cartes du joueur et des actions ennemies infligent des statuts ; les types immunisés comme dans les jeux (ex. Feu ne brûle pas, Électrik pas paralysé, Glace pas gelé, Poison/Acier pas empoisonnés).
- [x] Les statuts s'appliquent aux ennemis et au Pokémon actif du joueur ; leur icône et leur durée sont visibles en combat.
- [x] Des potions ou objets soignent les statuts (au moins un de chaque, en données).
- [x] L'intention affichée d'un ennemi tient compte de son statut (ex. endormi → « dort »).

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

**Status**: [x] Retained screenshots in `production/qa/evidence/story-016-statuts/`

---

## Dependencies

- Depends on: Story 015
- Unlocks: Story 017

---

## Completion Notes
**Completed**: 2026-10-24
**Criteria**: 5/5 passing (confirmed by the user in play; 10 screenshots retained)
**Deviations**: Advisory only — status chips use data short codes (BRU, DOR; change `short` in statuses.json); no floating text when a status simply expires or is cured; cases not captured because they depend on RNG (player paralysis fizzle, enemy paralysis fail, "Dégelé !") and hover tooltips; QA hooks ship in the build
**Design decisions (with the user)**: Slay-the-Spire-style stacking statuses; type immunities like the games; cards and enemies inflict statuses by type; statuses apply to the whole team (persist on switch); cures = potions, berries; after the first play-test the player asked for anti-lock rules: asleep/frozen team loses 2 energy (not the whole turn), 2-turn "Répit" immunity to sleep+freeze afterwards, paralysis not extendable while active
**Fixes after play-test**: battle layout tightened so the hand (cards 170x200) is fully visible at 1280x720 (cards end at y=712); project.godot stretch aspect set to `keep` (explicit)
**Test Evidence**: Integration — tests waived at qa.level minimal; screenshots at `production/qa/evidence/story-016-statuts/`
**Code Review**: Skipped — Solo mode
