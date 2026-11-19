# Story 026: Niveaux de difficulté (façon Ascension)

> **Epic**: Pokémon Spire
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-19

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief feuille de route, étape 7` (« Après le MVP », 2026-10-21)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (section « Après le MVP — feuille de route », étape 7), scoped to this story:*

- [x] Après une victoire finale, un niveau de difficulté supérieur se débloque (jusqu'à un maximum défini en données).
- [x] Chaque niveau ajoute un modificateur cumulatif défini en données (ex. ennemis plus forts, moins de soin, prix plus élevés).
- [x] Le niveau se choisit au lancement d'une nouvelle partie ; le niveau débloqué est conservé d'une partie à l'autre.
- [x] Le niveau joué est affiché pendant la partie et sur l'écran de victoire / défaite.
- [x] **Choix du joueur (2026-11-19)** : **10 niveaux** ; récompense = **prestige + cosmétique** (niveau affiché sur le titre, les statistiques et le Pokédex ; cadre / badge visuel débloqué), aucun bonus de puissance ; déblocage **global** (une victoire au niveau N débloque N+1 quel que soit le starter). Niveau 0 = jeu actuel inchangé (≈ 35 % de victoires au simulateur) ; chaque niveau vérifié au simulateur (le taux baisse de façon régulière, le niveau 10 reste gagnable).

---

## Implementation Notes

- Valeurs de gameplay en données (`assets/data/`), aucun code spécifique à un Pokémon.
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Aucune — dernière story de la feuille de route

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level`: at `qa.level: minimal` tests are **waived** (advisory, never "must exist and pass"), but a Visual/Feel or UI story's retained screenshot is not.*

**Story Type**: Logic
**Required evidence**:
- Logic : `tests/unit/run/niveaux-de-difficulte_test.gd` — waived at `qa.level: minimal`, plus a retained screenshot in `production/qa/evidence/` because the story changes what the player sees.

**Status**: [x] 8 captures dans `production/qa/evidence/story-026-niveaux-de-difficulte/`, `tests/scratch/t26b_difficulty.gd`, `design/balance/report-difficulty.md`

---

## Dependencies

- Depends on: Story 025
- Unlocks: None

## Completion Notes
**Completed**: 2026-11-19
**Criteria**: 5/5 (validé par le joueur ; t26b 240/0, t9, t11, t18, t19, t23_menus, t24, t25, t25b, t32 OK ; courbe simulée 34,8 % (niv. 0) → 9,0 % (niv. 10) sur 500 parties par niveau ; 8 captures)
**Deviations**: Advisory only — les niveaux 3, 4, 6 et 8 (argent, soin, Débris, prix) ne baissent le taux de victoire que de ~0,6 à 1,8 point au simulateur (il utilise peu l'économie) : à ressentir en jeu ; marge d'erreur ±3,5–4 points à 500 parties (niveaux voisins qui se recouvrent) ; au niveau 6 la carte Débris coûte une pioche par combat (elle s'épuise en fin de tour, achetable à retirer au Mart) ; le liseré platine est peu contrasté sur le fond blanc du deck ; la capture de victoire utilise le raccourci de test vers le Conseil (0/8 badges affiché) ; une ligne `ERR_CANT_OPEN` en début de script de captures non tracée ; le déblocage est global (pas par type de starter)
**Test Evidence**: Config/Data + UI — `tests/scratch/t26b_difficulty.gd`, `design/balance/report-difficulty.md`, captures `production/qa/evidence/story-026-niveaux-de-difficulte/`
**Code Review**: Skipped — Solo mode
