# Story 028: Réécriture des cartes par type

> **Epic**: Pokémon Spire
> **Status**: In Progress
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

- [ ] Une identité de jeu par type (18), écrite dans `design/card-identities.md` (rôle, effets favoris, faiblesse), ex. Feu = Brûlure et gros coups ; Eau = protection et soin ; Électrik = énergie, Paralysie, multi-coups ; Poison = dégâts dans la durée ; Combat = Force et multi-coups ; Psy = pioche et Faiblesse ; Spectre = Vulnérable et Épuisement ; Acier = protection qui frappe ; Dragon = Élan…
- [ ] Les cartes existantes sont réécrites selon ces identités avec les effets de la story 027 (plus de la moitié des cartes font autre chose que « Inflige X dégâts ») ; 180–200 cartes au total, chaque type ayant des communes / peu communes / rares cohérentes et au moins 2 compétences.
- [ ] Les decks de départ restent simples et jouables (5 attaques du starter, 4 Abri, 2 attaques plus fortes) ; les cartes de rival, de légendaire et d'événement restent valides.
- [ ] Noms de capacités Pokémon officiels en français, porteurs cohérents (Pokémon du bon type).
- [ ] Validation au chargement sans erreur ; aucun ID de carte référencé ailleurs (rewards, shop, events, rival, legendary, pokemon.json teaches/starter decks) ne casse.
- [ ] Simulateur : le jeu reste gagnable (pas d'équilibrage fin ici, c'est la story 031) ; rapport `design/balance/report-post028.md`.

---

## Out of Scope

- 029 : objets ; 030 : ennemis et boss ; 031 : rééquilibrage fin

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**: chargement des données sans erreur + tests `tests/scratch/` qui passent + captures de mains / récompenses dans `production/qa/evidence/story-028-cartes-par-type/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 027
- Unlocks: Story 031
