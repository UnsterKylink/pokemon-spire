# Story 008: 18 types et doubles types

> **Epic**: Pokémon Spire
> **Status**: In Progress
> **Layer**: Core
> **Type**: Logic
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-19

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature: Types (18) et doubles types` (design change 2026-10-19)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (the **Player goal & fail state** field + MVP feature « Types (18) et doubles types »), scoped to this story:*

- [ ] La table des types en données couvre les 18 types (Normal, Feu, Eau, Plante, Électrik, Glace, Combat, Poison, Sol, Vol, Psy, Insecte, Roche, Spectre, Dragon, Ténèbres, Acier, Fée) avec leur nom français et leur couleur.
- [ ] Les multiplicateurs sont ×1,5 (super efficace), ×0,5 (pas très efficace) et ×0 (immunité), avec les immunités des jeux officiels (ex. Normal et Combat → Spectre, Spectre → Normal, Sol → Vol, Électrik → Sol, Psy → Ténèbres, Dragon → Fée, Poison → Acier).
- [ ] Un Pokémon peut avoir 1 ou 2 types ; contre un double type, le multiplicateur final est le produit des deux (ex. ×1,5 × ×1,5 = ×2,25 ; ×1,5 × ×0,5 = ×1 ; une immunité donne ×0 quel que soit l'autre type).
- [ ] Les dégâts restent : base × multiplicateur final, arrondi à l'entier inférieur, avant la protection ; les intentions ennemies affichent la valeur finale.
- [ ] Le texte « Super efficace ! » apparaît dès que le multiplicateur final est > 1, « Ce n'est pas très efficace… » dès qu'il est entre 0 et 1, et « Ça n'affecte pas [Pokémon]… » à ×0 (0 dégât, la protection n'est pas consommée). Une intention ennemie d'attaque à ×0 affiche « Attaque 0 ».
- [ ] Les deux badges de type d'un Pokémon double type sont affichés à l'écran.
- [ ] Les 9 Pokémon existants reçoivent leurs vrais types (ex. Roucool Normal/Vol, Nosferapti Poison/Vol, Racaillou Roche/Sol, Mystherbe Plante/Poison, Aspicot Insecte/Poison).

---

## Implementation Notes

- Étendre `assets/data/types.json` et `TypeChart` ; `Combatant.type_id` devient une liste de types. Garder une seule fonction centrale de dégâts.
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 009 : Pokémon actif / switch
- 010 : nouveaux Pokémon

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Tests waived at `qa.level: minimal`; a retained screenshot in `production/qa/evidence/` is required because the story changes what the player sees.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 005 must be DONE
- Unlocks: Story 009
