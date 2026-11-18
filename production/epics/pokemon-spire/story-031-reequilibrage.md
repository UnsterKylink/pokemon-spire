# Story 031: Rééquilibrage complet après la refonte du combat

> **Epic**: Pokémon Spire
> **Status**: Complete
> **Layer**: Feature
> **Type**: Config/Data
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/game-brief.md` + `design/revue-complete-2026-11.md` (étape A.5) ; objectifs du joueur (story 019, 2026-10-24).
**Requirement**: après les stories 027–030 le simulateur gagne 79 % des parties (`design/balance/report-post030.md`) ; revenir à la cible du joueur.

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**Engine**: Godot 4.6 | **Risk**: HIGH

---

## Acceptance Criteria

- [x] Environ **35 %** de victoires complètes (8 badges + Conseil 4 + Maître + Éthernatos), joueur « correct, pas expert » du simulateur, sur ≥ 2000 parties.
- [x] Progression garantie : ≥ 75 % des parties à 3 badges ou plus ; ≥ 50 % atteignent le Conseil 4 ; défaites en zone 1 ≤ 5 % ; aucune étape > ~20 % des défaites.
- [x] Écart entre types de starter réduit : chaque type entre ~20 % et ~50 % de victoires (contre 17,5–61,3 % avant).
- [x] Règles de terrain dures adoucies (arène Feu : la carte brûlée revient au combat suivant / n'est pas retirée pour tout le combat — à décider dans les données) ; Talents, Élan, objets et cartes fortes signalés en 028 (Blizzard, Laser Glace, Fracass'Tête, Luminocanon, Machination) vérifiés.
- [x] Toutes les valeurs changées sont en données et listées dans `design/balance/changes.md` (avant → après, raison) ; rapport final `design/balance/report-final031.md`.
- [x] Tous les tests `tests/scratch/` passent (seules les attentes de valeurs de données peuvent changer, listées).

---

## Out of Scope

- Raccourcir la partie (étape B de la revue, story à venir)

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**: rapport de simulation ≥ 2000 parties + tests `tests/scratch/` qui passent.

**Status**: [x] Rapports `design/balance/report-final031.md` (2000 parties) et `report-rob031.md`, journal `design/balance/changes.md`

---

## Dependencies

- Depends on: Stories 027, 028, 029, 030

## Completion Notes
**Completed**: 2026-11-18
**Criteria**: 6/6 (validé par le joueur ; final031 : 35,0 % de victoires, ≥3 badges 81,5 %, Conseil 4 atteint 58,0 %, zone 1 3,9 %, étape la plus meurtrière 17,6 % ; 12 tests OK)
**Deviations**: Advisory only — la règle de l'arène Feu remplace la brûlure de la carte la plus chère (attaques Feu +2 dégâts des deux côtés + Brûlure 1 tous les 3 tours) au lieu de la renvoyer à la défausse (cela demanderait un changement de `battle.gd`) ; sur une 2e série (graine 7, 300 parties) les défaites en zone 1 sont pile à 5,0 % (marge possible : multiplicateur de PV du Champion de la zone 1 0,7 → 0,65) ; types de starter encore faibles : Insecte 24,6 %, Vol 25,0 % (petit échantillon), Psy 25,9 %, Normal 27,2 % ; Éclat Magique plafonne maintenant l'Élan à 5 (effet du plafond de base 3) ; attentes de valeurs modifiées dans t27 et t29 ; texte de la bannière de la nouvelle règle Feu non vu en jeu
**Test Evidence**: Config/Data — rapports de simulation ci-dessus + tests `tests/scratch/` (t9, t11, t18, t20, t21, t24–t30)
**Code Review**: Skipped — Solo mode
