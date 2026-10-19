# Story 006: Objets, potions, Centre Pokémon et Poké Mart

> **Epic**: Pokémon Spire
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature 6`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (the **Player goal & fail state** field + MVP feature 6), scoped to this story:*

- [ ] ~10 objets tenus définis en données, avec effets permanents (ex. Restes : +PV en fin de combat ; Bandeau : +dégâts de la 1re attaque par combat).
- [ ] ~5 potions à usage unique (ex. Potion : soigne ; Attaque + : bonus de dégâts ce tour), max 3 potions portées, utilisables pendant le combat.
- [ ] Les combats rapportent des Pokédollars ; les élites donnent un objet tenu.
- [ ] Centre Pokémon : choisir entre se soigner (30 % des PV max) ou améliorer une carte du deck.
- [ ] Poké Mart : acheter des cartes, objets et potions avec des Pokédollars, et retirer une carte du deck contre paiement.
- [ ] Les objets possédés et l'argent sont visibles en permanence.

---

## Implementation Notes

- Effets d'objets via des déclencheurs génériques (début/fin de combat, carte jouée…) plutôt que du code par objet.
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 007 : récompense du boss

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/run/objets-et-services_test.gd` OR playtest doc — advisory at `qa.level: minimal`, plus a retained screenshot in `production/qa/evidence/` because the story changes what the player sees.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 010 must be DONE (team design change, 2026-10-19)
- Unlocks: Story 007
