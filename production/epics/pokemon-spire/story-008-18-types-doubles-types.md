# Story 008: 18 types et doubles types

> **Epic**: Pokémon Spire
> **Status**: Complete
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

## Completion Notes
**Completed**: 2026-10-19
**Criteria**: 7/7 passing. Real mouse play on this version confirmed by the developer.
**Deviations**: ADVISORY — a dual-type enemy attacks with its first listed type (no per-attack type yet; revisit with story 010); no on-screen "Attaque 0" intent (no roster Pokémon is immune vs Salamèche's Fire; covered by the headless test, becomes visible with the switch of story 009); `BattleScreen.qa_force_hand` is a public QA helper that ships in the build (gate before sharing); the old `_make_type_badge` helper in `battle_screen.gd` is now unused; user-facing French strings still hardcoded. `Combatant.from_dict` still accepts the legacy single `type` key (GameData is strict). `take_damage(0)` no longer emits `changed`.
**Test Evidence**: tests waived at `qa.level: minimal` (no test file). Visual evidence: `production/qa/evidence/story-008-18-types-doubles-types/` (3 PNGs + README.md). Run result: OBSERVED on Godot 4.6.3 (Linux, Xvfb 1280x720). Throwaway headless assertions: t8 785 / 0 (all 324 pairs vs the official chart, dual types, immunities, rounding, block untouched on ×0, intent == damage, 14 data rejections); t3 101 / 0, t4 1208 / 0, t5b 465 / 0.
**Code Review**: Skipped (solo mode).
