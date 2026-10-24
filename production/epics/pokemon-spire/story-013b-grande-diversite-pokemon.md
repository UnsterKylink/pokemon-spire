# Story 013b: Grande diversité de Pokémon

> **Epic**: Pokémon Spire
> **Status**: In Progress
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-24

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief feuille de route, étape 2 (demande du joueur 2026-10-24)` (« Après le MVP », 2026-10-21)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From the player's request (2026-10-24, « une grande diversité de Pokémon ») and `design/game-brief.md` étape 2, scoped to this story:*

- [ ] Plusieurs centaines de Pokémon jouables en données, toutes générations (1 à 9) : au minimum les lignées d'évolution complètes de Pokémon communs de tous les types, avec nom français, types, PV, comportement ennemi, sprite PokéAPI stocké dans `assets/sprites/pokemon/` et 1–2 cartes d'attaque cohérentes avec leurs types.
- [ ] Chaque type (18) a au moins 15 Pokémon, de sorte que les zones, les arènes et le Conseil 4 tirent dans des pools variés ; le type Ténèbres devient possible en arène.
- [ ] Les Pokémon sauvages des zones, les élites, les porteurs de cartes de récompense et les propositions de départ tirent dans ce grand roster (pools et poids en données), sans casser la cohérence de type.
- [ ] Les nouveaux Pokémon ont leurs données d'évolution (forme suivante) quand elle existe.
- [ ] Les données restent validées au chargement (types, sprites, cartes) ; le temps de chargement reste raisonnable (< 3 s).

---

## Implementation Notes

- Générer les données depuis les CSV PokéAPI (raw.githubusercontent.com — pokeapi.co est bloqué par le proxy) avec un script outil gardé dans `tools/`, pour pouvoir en ajouter d'autres plus tard.
- Éditer `pokemon.json` de façon textuelle ou passer à un fichier dédié au roster ; ne pas casser les chargeurs existants.
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.

---

## Out of Scope

- 014 : évolutions en cours de route (le 3e stade)
- 017 : capture

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration : tests waived at `qa.level: minimal`, plus a retained screenshot in `production/qa/evidence/` showing the new variety.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 013
- Unlocks: Story 014
