# Story 029: Objets variés et objets « à build »

> **Epic**: Pokémon Spire
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-18

## Context

**GDD**: `design/game-brief.md` + `design/revue-complete-2026-11.md` (§3.5, étape A.3)
**Requirement**: revue complète du 2026-11-16 : « au moins 40 objets, dont des objets à build » ; s'appuie sur le moteur de la story 027 (effets de cartes, Talents, Élan, Force, Faiblesse / Vulnérable).

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**Engine**: Godot 4.6 | **Risk**: HIGH

---

## Acceptance Criteria

- [x] Au moins 40 objets tenus en données (`assets/data/items.json`), répartis en communes / peu communes / rares, avec de nouveaux triggers et effets génériques (aucun code par objet).
- [x] Au moins 12 objets « à build » qui changent la façon de jouer : par Pokémon / type (ex. +dégâts pour les attaques d'un type, la première carte d'un type coûte 0), par Élan (le plafond d'Élan monte, l'Élan ne retombe pas à 0 mais de moitié), par Talents (un Talent peut se redéclencher une fois), par statuts (la Brûlure / le Poison infligés +N), par pioche / énergie / Force, par Épuisement (une carte épuisée revient une fois), par protection (la protection reste d'un tour à l'autre), par soin, par capture.
- [x] Les objets existants gardent leur comportement ; les baies d'immunité et de PV max restent mais sont moins dominantes dans les récompenses.
- [x] Acquisition : objets en récompense (élites, Champions, rival), au Mart et dans des événements ; les raretés pèsent comme avant ; aucun doublon dans une partie ; les objets sont décrits en français avec une infobulle.
- [x] Interface : les objets nouveaux s'affichent correctement (barre du haut, Mart, récompenses) avec leur illustration ; un objet sans illustration affiche un repli propre.
- [x] Le simulateur sait évaluer les nouveaux objets (valeur par effet) ; rapport de simulation ; pas de rééquilibrage fin (story 031).
- [x] Tests headless dans `tests/scratch/` (chaque trigger / effet nouveau).

---

## Out of Scope

- 030 : ennemis et boss ; 031 : rééquilibrage fin

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: tests `tests/scratch/t29_items.gd` + captures (Mart, barre d'objets) dans `production/qa/evidence/story-029-objets/`

**Status**: [x] Tests `tests/scratch/t29_items.gd` + captures dans `production/qa/evidence/story-029-objets/`

---

## Dependencies

- Depends on: Story 028
- Unlocks: Story 031

## Completion Notes
**Completed**: 2026-11-18
**Criteria**: 7/7 (validé par le joueur ; t29 131/0, t9/t11/t18/t20/t21/t24–t28 OK ; captures 01–05)
**Deviations**: Advisory only — simulateur à 91,0 % de victoires (cible 35 %, rééquilibrage en story 031) ; la rangée d'objets du Mart déborderait si 4 objets y étaient proposés (3 maximum aujourd'hui) ; événements et rival tirent leurs objets sans tenir compte du poids des baies ; effets « argent sur K.O. » et « taille de main » non réalisés (déjà couverts par draw_up)
**Test Evidence**: Logic — `tests/scratch/t29_items.gd` ; rapport `design/balance/report-post029.md` ; captures `production/qa/evidence/story-029-objets/`
**Code Review**: Skipped — Solo mode
