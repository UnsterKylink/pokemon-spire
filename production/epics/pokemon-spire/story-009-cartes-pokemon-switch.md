# Story 009: Cartes Pokémon, switch et PV communs

> **Epic**: Pokémon Spire
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-19

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature: Cartes Pokémon et switch` (design change 2026-10-19)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (the **Player goal & fail state** field + MVP feature « Cartes Pokémon et switch »), scoped to this story:*

- [ ] Chaque carte d'attaque porte un Pokémon (id) affiché sur la carte (nom + petit sprite) ; le deck de départ contient des cartes de Salamèche.
- [ ] Une seule barre de PV pour toute l'équipe (PV de partie) ; à 0 la partie est perdue. Les PV max peuvent augmenter (événements déjà existants, objets de la tâche 006).
- [ ] Le combat a un « Pokémon actif » (au départ celui du deck de départ, Salamèche) affiché à gauche avec son sprite, son nom et ses badges de type.
- [ ] Jouer une carte d'attaque d'un autre Pokémon le fait entrer sur le terrain (sprite, nom, types changent) avant que l'attaque ne parte ; rejouer une carte du Pokémon déjà actif ne change rien.
- [ ] Les cartes de protection ou de renforcement (sans dégâts) ne font jamais changer le Pokémon actif ; leur effet s'applique à l'équipe (protection commune).
- [ ] Les ennemis attaquent le Pokémon actif : les multiplicateurs de type sont calculés contre SES types (doubles types compris) ; les intentions affichées se mettent à jour quand le Pokémon actif change.
- [ ] Le vol de carte : la carte volée proposée après une victoire est une carte d'un Pokémon mis K.O. dans ce combat, portée par ce Pokémon.
- [ ] Le Pokémon actif revient au Pokémon de départ au début de chaque combat.

---

## Implementation Notes

- Ajouter `pokemon` aux cartes d'attaque (données), un `active_pokemon` dans `Battle`, et recalculer les intentions ennemies quand il change. Les PV restent dans `RunState` (déjà commun).
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 010 : liste des Pokémon des premières routes et cartes portées par des Pokémon aléatoires
- 006 : objets qui augmentent les PV max

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Tests waived at `qa.level: minimal`; a retained screenshot in `production/qa/evidence/` is required because the story changes what the player sees.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 008 must be DONE
- Unlocks: Story 010

## Completion Notes
**Completed**: 2026-10-19
**Criteria**: 8/8 passing. Real mouse play on this version (switch, intents changing) confirmed by the developer.
**Deviations**: ADVISORY — skill cards show "Équipe" instead of a Pokémon; the card → Pokémon mapping is fixed in `cards.json` (story 010 makes non-stolen cards carried by a random coherent Pokémon, and adds the starting-Pokémon choice); no validation that starter-deck cards belong to the starter and no check that a card's type matches its Pokémon's types (by design, like Scratch on Charmander); `RemoveCard(card_id)` removes the first card with that id whatever its Pokémon; `qa_force_hand` / `qa_set_hp` are public QA helpers shipping in the build (gate before sharing); an enemy with two types still attacks with its first type; user-facing French strings still hardcoded. Scope notes: deck lines and counts are keyed by (card, Pokémon) via `CardData.deck_key()`; `Battle` takes an optional Pokémon lookup + starter id; card sprites are cropped to their opaque area for legibility.
**Test Evidence**: tests waived at `qa.level: minimal` (no test file). Visual evidence: `production/qa/evidence/story-009-cartes-pokemon-switch/` (7 PNGs + README.md). Run result: OBSERVED on Godot 4.6.3 (Linux, Xvfb 1280x720). Throwaway headless assertions: t9 199 / 0 (switch rules, intent recompute, shared HP/block, stolen card carrier, data rejections), t3 101, t4 1208, t5b 465, t8 785 — all 0 failures.
**Code Review**: Skipped (solo mode).
