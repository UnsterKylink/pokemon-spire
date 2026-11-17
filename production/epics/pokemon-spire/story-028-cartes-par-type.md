# Story 028: Réécriture des cartes par type

> **Epic**: Pokémon Spire
> **Status**: Complete
> **Layer**: Feature
> **Type**: Config/Data
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-17

## Context

**GDD**: `design/game-brief.md` + `design/revue-complete-2026-11.md` (§3.1, étape A.1)
**Requirement**: choix du joueur « Refonte large » (2026-11-16) ; moteur d'effets livré en story 027.

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**Engine**: Godot 4.6 | **Risk**: HIGH

---

## Acceptance Criteria

- [x] Une identité de jeu par type (18), écrite dans `design/card-identities.md` (rôle, effets favoris, faiblesse), ex. Feu = Brûlure et gros coups ; Eau = protection et soin ; Électrik = énergie, Paralysie, multi-coups ; Poison = dégâts dans la durée ; Combat = Force et multi-coups ; Psy = pioche et Faiblesse ; Spectre = Vulnérable et Épuisement ; Acier = protection qui frappe ; Dragon = Élan…
- [x] Les cartes existantes sont réécrites selon ces identités avec les effets de la story 027 (plus de la moitié des cartes font autre chose que « Inflige X dégâts ») ; 180–200 cartes au total, chaque type ayant des communes / peu communes / rares cohérentes et au moins 2 compétences.
- [x] Les decks de départ restent simples et jouables (5 attaques du starter, 4 Abri, 2 attaques plus fortes) ; les cartes de rival, de légendaire et d'événement restent valides.
- [x] Noms de capacités Pokémon officiels en français, porteurs cohérents (Pokémon du bon type).
- [x] Validation au chargement sans erreur ; aucun ID de carte référencé ailleurs (rewards, shop, events, rival, legendary, pokemon.json teaches/starter decks) ne casse.
- [x] Simulateur : le jeu reste gagnable (pas d'équilibrage fin ici, c'est la story 031) ; rapport `design/balance/report-post028.md`.

---

## Out of Scope

- 029 : objets ; 030 : ennemis et boss ; 031 : rééquilibrage fin

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**: chargement des données sans erreur + tests `tests/scratch/` qui passent + captures de mains / récompenses dans `production/qa/evidence/story-028-cartes-par-type/`

**Status**: [x] Tests `tests/scratch/t28_cards_by_type.gd` + captures dans `production/qa/evidence/story-028-cartes-par-type/`

---

## Dependencies

- Depends on: Story 027
- Unlocks: Story 031

## Completion Notes
**Completed**: 2026-11-17
**Criteria**: 6/6 (validé par le joueur ; t28 fails=0, t9/t11/t18/t20/t21/t24/t25/t26/t27 OK ; captures conservées)
**Deviations**: Advisory only — simulateur à 91,7 % de victoires (cible 35 %, rééquilibrage prévu en story 031) ; les compétences ont un `type` de thème sans multiplicateur ; quelques noms de capacités à confirmer (Amass'Sable, Purédpois, Danse-Plume, Choc Émotionnel) ; cartes fortes à surveiller en 031 (Blizzard, Laser Glace, Fracass'Tête, Luminocanon, Machination) ; le simulateur donne maintenant une cible aux compétences de protection qui affaiblissent un ennemi
**Test Evidence**: Config/Data — `tests/scratch/t28_cards_by_type.gd` + tests existants ; rapport `design/balance/report-post028.md` ; captures `production/qa/evidence/story-028-cartes-par-type/`
**Code Review**: Skipped — Solo mode
