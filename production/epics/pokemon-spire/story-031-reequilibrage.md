# Story 031: Rééquilibrage complet après la refonte du combat

> **Epic**: Pokémon Spire
> **Status**: In Progress
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

- [ ] Environ **35 %** de victoires complètes (8 badges + Conseil 4 + Maître + Éthernatos), joueur « correct, pas expert » du simulateur, sur ≥ 2000 parties.
- [ ] Progression garantie : ≥ 75 % des parties à 3 badges ou plus ; ≥ 50 % atteignent le Conseil 4 ; défaites en zone 1 ≤ 5 % ; aucune étape > ~20 % des défaites.
- [ ] Écart entre types de starter réduit : chaque type entre ~20 % et ~50 % de victoires (contre 17,5–61,3 % avant).
- [ ] Règles de terrain dures adoucies (arène Feu : la carte brûlée revient au combat suivant / n'est pas retirée pour tout le combat — à décider dans les données) ; Talents, Élan, objets et cartes fortes signalés en 028 (Blizzard, Laser Glace, Fracass'Tête, Luminocanon, Machination) vérifiés.
- [ ] Toutes les valeurs changées sont en données et listées dans `design/balance/changes.md` (avant → après, raison) ; rapport final `design/balance/report-final031.md`.
- [ ] Tous les tests `tests/scratch/` passent (seules les attentes de valeurs de données peuvent changer, listées).

---

## Out of Scope

- Raccourcir la partie (étape B de la revue, story à venir)

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**: rapport de simulation ≥ 2000 parties + tests `tests/scratch/` qui passent.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 027, 028, 029, 030
