# Story 018: Rival et nouveaux événements

> **Epic**: Pokémon Spire
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-26

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

- [x] Un rival apparaît plusieurs fois dans la partie (salles définies en données), avec une équipe qui grandit et évolue de zone en zone.
- [x] Le rival a un starter dont le type a l'avantage sur celui du Pokémon de départ du joueur.
- [x] Au moins 10 nouveaux événements en données (dont certains liés aux statuts, à la capture et au rival), avec choix et conséquences.
- [x] Battre le rival donne une récompense spéciale définie en données.
- [x] **Ajout du joueur (2026-10-25) — événements légendaires** : rares (au plus 1 par partie, à partir de la zone 3), 4 à 6 légendaires (ex. Darkrai « Cauchemar », Ho-Oh, Lugia, Mewtwo, Rayquaza, Celebi), chacun avec son récit, un choix (l'affronter seul dans un combat spécial difficile, ou s'éloigner avec un coût) ; le battre donne une carte légendaire unique portée par lui ; il est **capturable avec une très faible chance** (règles de capture de la story 017).

---

## Implementation Notes

- Valeurs de gameplay en données (`assets/data/`), aucun code spécifique à un Pokémon.
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.
- **Question de design à trancher avec le joueur au début de `/dev-story`** (voir le brief : « à décider avant de coder »).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 019 : équilibrage

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`: at `qa.level: minimal` tests are **waived** (advisory, never "must exist and pass"), but a Visual/Feel or UI story's retained screenshot is not.*

**Story Type**: Integration
**Required evidence**:
- Integration : `tests/integration/run/rival-et-evenements_test.gd` OR playtest doc — advisory at `qa.level: minimal`, plus a retained screenshot in `production/qa/evidence/` when the story changes what the player sees.

**Status**: [x] Captures conservées dans `production/qa/evidence/story-018-rival-et-evenements/`

---

## Dependencies

- Depends on: Story 017
- Unlocks: Story 019

## Completion Notes
**Completed**: 2026-10-26
**Criteria**: 5/5 passing (confirmés par le joueur en jeu ; captures 01–10 conservées)
**Deviations**: Advisory only — le coût de « Fuir » (−PV) n'est pas affiché sur le bouton de l'événement légendaire ; provocations du rival en français codées en dur ; salles d'étage 3 des zones 2/4/6 toutes en Rival (inévitable) ; écran « légendaire capturé » non capturé (chance trop faible) ; la capture n'est pas mesurée par le simulateur (34,5 % de victoires sur 2000 parties)
**Test Evidence**: Integration — tests waived at qa.level minimal ; captures dans `production/qa/evidence/story-018-rival-et-evenements/`
**Code Review**: Skipped — Solo mode
