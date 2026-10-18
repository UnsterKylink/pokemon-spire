# Story 004: Récompenses et vol d'attaque

> **Epic**: Pokémon Spire
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-18

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature 4`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (the **Player goal & fail state** field + MVP feature 4), scoped to this story:*

- [ ] Après une victoire, un écran de récompense propose 3 cartes ; le joueur en ajoute 1 à son deck ou passe.
- [ ] Au moins 1 des 3 cartes proposées est une attaque d'un Pokémon battu dans ce combat (si ce Pokémon en a dans les données).
- [ ] Les autres cartes sont tirées de la réserve de cartes de Salamèche (~25 cartes définies en données), avec des raretés (commune / peu commune / rare).
- [ ] Le deck du joueur et ses PV persistent d'un combat à l'autre pendant la partie.
- [ ] Le joueur peut consulter son deck complet depuis l'écran de récompense.

---

## Implementation Notes

- Le deck et les PV vivent dans un état de partie (RunState) distinct du combat.
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 005 : enchaînement des combats via la carte
- 006 : récompenses en objets et Pokédollars

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/run/recompenses-vol-attaque_test.gd` OR playtest doc — advisory at `qa.level: minimal`, plus a retained screenshot in `production/qa/evidence/` because the story changes what the player sees.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003 must be DONE
- Unlocks: Story 005

## Completion Notes
**Completed**: 2026-10-18
**Criteria**: 5/5 passing. Real mouse play on this version (reward screen, deck viewer, Passer) confirmed by the developer.
**Deviations**: ADVISORY — player HP never recovers yet (healing arrives with the Pokémon Center in stories 005/006); no pause between the killing blow and the reward screen; user-facing French strings (incl. rarity names/colours in `card_view.gd`) still hardcoded; `BattleScreen` still carries unused `COLOR_TEXT_*` constants. Scope additions: `src/main.gd` now owns GameData/RunState/RNGs and screen switching (UI no longer owns state, per the story 001 review); shared `src/ui/card_view.gd`; 9 enemies each teach 1–2 attack cards; reward pool = 28 non-starter cards. Design choices: stolen card is picked uniformly from all cards taught by the beaten Pokémon, the other slots by rarity weight (60/30/10); offers are shuffled; `battles_won` counts survived battles.
**Test Evidence**: tests waived at `qa.level: minimal` (no test file). Visual evidence: `production/qa/evidence/story-004-recompenses-vol-attaque/` (8 PNGs + README.md). Run result: OBSERVED on Godot 4.6.3 (Linux, Xvfb 1280x720). 1208/1208 throwaway headless assertions pass (run state, reward generator, data validation) plus the 202 type assertions from story 003.
**Code Review**: Skipped (solo mode).
