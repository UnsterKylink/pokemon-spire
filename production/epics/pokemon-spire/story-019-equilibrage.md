# Story 019: Équilibrage et cartes manquantes

> **Epic**: Pokémon Spire
> **Status**: Complete
> **Layer**: Feature
> **Type**: Config/Data
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-24

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief feuille de route, étape 4` (« Après le MVP », 2026-10-21)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (section « Après le MVP — feuille de route », étape 4), scoped to this story:*

- [x] Ajout de cartes peu communes et rares pour les types qui n'en ont pas (Insecte, Ténèbres, Combat…) afin que chaque type ait au moins 2 peu communes et 1 rare.
- [x] Correction : un ennemi à double type attaque avec le type de l'action (défini en données) et non plus toujours avec son 1er type.
- [x] PV, dégâts et modificateurs des ennemis ajustés zone par zone pour une courbe de difficulté régulière ; prix, gains d'argent et taux de potions/objets ajustés.
- [x] Un simulateur (joueur automatique qui joue des parties complètes, du choix de départ jusqu'à Éthernatos) mesure le taux de victoire finale sur plusieurs centaines de parties ; l'outil est gardé dans `tools/` pour être relancé après chaque changement de contenu.
- [x] **Objectif fixé par le joueur (2026-10-24) : environ 35 % des parties complètes gagnées** (8 badges + Conseil 4 + Éthernatos), mesuré par le simulateur ; le rapport indique aussi où les parties perdues s'arrêtent (zone, Conseil, Éthernatos) pour une courbe régulière, sans mur ni partie trop facile.
- [x] **Progression garantie (exigence joueur, 2026-10-24)** : le joueur doit sentir qu'il va plus loin à chaque partie — au moins 75 % des parties obtiennent 3 badges ou plus, au moins 50 % atteignent le Conseil 4, au plus 5 % des parties meurent en zone 1, et aucune étape ne cause plus d'environ 20 % des défaites ; les défaites ont lieu surtout tard (zones 6–8, Ligue, Éthernatos), Éthernatos restant difficile mais battable. Mesuré par le simulateur (entonnoir des badges + ces 4 contrôles dans `design/balance/report-final.md`).
- [x] Les valeurs modifiées et leur justification sont notées dans le dossier d'équilibrage (design/balance/).

---

## Implementation Notes

- Valeurs de gameplay en données (`assets/data/`), aucun code spécifique à un Pokémon.
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.
- **Question de design à trancher avec le joueur au début de `/dev-story`** (voir le brief : « à décider avant de coder »).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 020 : esthétique

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`: at `qa.level: minimal` tests are **waived** (advisory, never "must exist and pass"), but a Visual/Feel or UI story's retained screenshot is not.*

**Story Type**: Config/Data
**Required evidence**:
- Config/Data : smoke check pass (`production/qa/smoke-*.md`) — advisory, plus a retained screenshot if anything on screen changes.

**Status**: [x] Simulator report `design/balance/report-final.md`, change log `design/balance/changes.md`, screenshots in `production/qa/evidence/story-019-equilibrage/`

---

## Dependencies

- Depends on: Story 016 (order changed by the player 2026-10-24: balance now, re-run the simulator after 017 and 018)
- Unlocks: Story 020

---

## Completion Notes
**Completed**: 2026-10-25
**Criteria**: 7/7 passing (incl. the progression requirement added by the player); difficulty curve confirmed by the user in play
**Result**: 35.8 % of complete runs won (1075/3000, 95 % CI 34.1–37.6) with the "correct, not expert" auto-player; robustness 35.7–38.1 % (second seed, block threshold ±0.1); ≥3 badges 87.9 %, Conseil reached 52.8 %, zone-1 deaths 3.2 %, deadliest stage Éthernatos 19 % of deaths, 74.4 % of runs reaching Éthernatos win
**Deviations**: Advisory only — measured with an auto-player, not humans; starter-type spread 20 % (Grass) to 59 % (Ghost); fixed gym teams replaced by roster-drawn teams; zone-1 gym at ×0.7 HP (below the suggested 0.8–1.0, for margin); immunity soft-lock fixed in code (encounter redraw when an enemy is immune to every attack type in the deck, `softlock_rerolls` in zones.json) — alternative would be a neutral card in every starter deck; League HP-lost metric covers 6 chained fights; must be re-run after stories 017 and 018 (`tools/balance/run.sh`)
**Test Evidence**: Config/Data + simulator — tests waived at qa.level minimal; scratch t3–t22 pass; screenshots at `production/qa/evidence/story-019-equilibrage/`
**Code Review**: Skipped — Solo mode
