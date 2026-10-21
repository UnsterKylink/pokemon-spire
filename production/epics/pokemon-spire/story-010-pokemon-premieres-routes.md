# Story 010: Pokémon des premières routes, toutes générations

> **Epic**: Pokémon Spire
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-21

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature: Pokémon des premières routes` (design change 2026-10-19)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (the **Player goal & fail state** field + MVP feature « Pokémon des premières routes »), scoped to this story:*

- [x] Une liste d'environ 50 Pokémon en données : starters et Pokémon des premières routes de toutes les générations (1 à 9), avec nom français, 1 ou 2 types, PV, comportement ennemi, sprite PokéAPI stocké dans `assets/sprites/pokemon/`, et 1–2 cartes d'attaque à leur nom.
- [x] Les combats sauvages tirent leurs ennemis dans cette liste (pools par étage en données) ; élites et boss restent des rencontres définies en données.
- [x] Les cartes de récompense (hors carte volée) : chaque carte d'attaque d'un type T est portée par un Pokémon de la liste ayant le type T, tiré au hasard mais cohérent (ex. une carte Feu peut être portée par un starter Feu ou un Pokémon Feu des premières routes).
- [x] Chaque Pokémon de la liste a au moins une carte d'attaque cohérente avec ses types (ex. Moustillon : Pistolet à O).
- [x] Début de partie : un écran propose 3 Pokémon de départ tirés au hasard parmi les starters et Pokémon de route 1 de la liste, de 3 types (principaux) différents ; le joueur en choisit 1, qui remplace Salamèche : son deck de départ (10 cartes, défini en données pour chaque Pokémon proposable) et Pokémon actif au début de chaque combat.
- [x] Les données sont validées au chargement (types connus, sprites présents, cartes existantes) ; une erreur de données est signalée sans planter le jeu.

---

## Implementation Notes

- Liste de Pokémon en données (`assets/data/pokemon.json` ou un nouveau fichier) ; télécharger les sprites une fois et les garder dans le projet (pas de téléchargement en jeu).
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 006 : objets / boutique
- 007 : boss et évolution

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Tests waived at `qa.level: minimal`; a retained screenshot in `production/qa/evidence/` is required because the story changes what the player sees.

**Status**: [x] Retained screenshots in `production/qa/evidence/story-010-pokemon-premieres-routes/`

---

## Dependencies

- Depends on: Story 009 must be DONE
- Unlocks: Story 006

---

## Completion Notes
**Completed**: 2026-10-21
**Criteria**: 6/6 passing (starter choice and roster/carrier behaviour confirmed by the user; screenshots 01–05 retained)
**Deviations**: Advisory only — roster has 67 Pokémon (brief said ~50); French strings hardcoded; QA helpers ship in the build; dual-type enemies attack with their first type; primary type = first type; Ground has no starter entry
**Test Evidence**: Integration — tests waived at qa.level minimal; retained screenshots at `production/qa/evidence/story-010-pokemon-premieres-routes/`
**Code Review**: Skipped — Solo mode
