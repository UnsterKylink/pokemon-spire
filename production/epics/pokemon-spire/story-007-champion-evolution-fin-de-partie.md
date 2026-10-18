# Story 007: Champion, évolution, victoire et défaite

> **Epic**: Pokémon Spire
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature 7`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (the **Player goal & fail state** field + MVP feature 7), scoped to this story:*

- [ ] Le boss Champion d'arène a plusieurs Pokémon ou un comportement spécial défini en données, plus difficile qu'une élite.
- [ ] Battre le Champion fait évoluer Salamèche en Reptincel : nouveau sprite, PV max augmentés, choix de nouvelles cartes.
- [ ] Après l'évolution, un écran de victoire résume la partie (étages, ennemis battus, deck final).
- [ ] Si les PV tombent à 0 à n'importe quel moment, un écran de défaite s'affiche.
- [ ] Depuis les écrans de victoire et de défaite, le joueur peut relancer une nouvelle partie depuis le début (état de partie entièrement réinitialisé).

---

## Implementation Notes

- L'évolution est une donnée du Pokémon (forme suivante + bonus), pas du code spécifique à Salamèche.
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Hors MVP : actes 2-3, Dracaufeu, autres starters

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/run/champion-evolution-fin-de-partie_test.gd` OR playtest doc — advisory at `qa.level: minimal`, plus a retained screenshot in `production/qa/evidence/` because the story changes what the player sees.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 006 must be DONE
- Unlocks: None (MVP complete)
