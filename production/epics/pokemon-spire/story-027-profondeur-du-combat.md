# Story 027: Profondeur du combat — effets de cartes, Talents et Élan

> **Epic**: Pokémon Spire
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-11-17

## Context

**GDD**: `design/game-brief.md` + `design/revue-complete-2026-11.md` (§3.1, §3.2)
**Requirement**: revue complète du 2026-11-16, étape A.1 et A.2 ; choix du joueur : « Talent + Élan », « Refonte large ».

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**Engine**: Godot 4.6 | **Risk**: HIGH

---

## Acceptance Criteria

- [x] **Nouveaux effets de cartes, en données** : piocher, gagner de l'énergie, frapper plusieurs fois, frapper tous les ennemis, s'épuiser (retirée jusqu'à la fin du combat), renforcer (force) pour le tour ou le combat, affaiblir l'ennemi (Faiblesse : il frappe moins fort ; Vulnérable : il subit plus), effets conditionnels (« si le Pokémon était déjà actif », « si la cible a un statut », « si c'est super efficace »), effet à la pioche / en fin de tour (cartes Rétention).
- [x] **Talents** : chaque Pokémon porteur a un talent (en données, par Pokémon ou par défaut selon son type principal) qui se déclenche quand il ENTRE sur le terrain ; affiché sur l'écran de combat et dans le deck.
- [x] **Élan** : rester sur le même Pokémon donne de l'Élan (compteur visible) : chaque carte d'attaque suivante du même Pokémon gagne un bonus défini en données ; changer de Pokémon remet l'Élan à zéro.
- [x] Les cartes affichent leurs mots-clés (Épuisement, Rétention, Faiblesse, Vulnérable, Élan…) avec une infobulle qui les explique.
- [x] Le simulateur d'équilibrage (`tools/balance/`) joue les nouveaux effets (il reste « correct, pas expert »).
- [x] Les anciennes sauvegardes ne font pas planter le jeu (version de sauvegarde gérée).
- [x] Tests headless des nouveaux effets dans `tests/scratch/`.

---

## Out of Scope

- 028 : réécriture du contenu des cartes par type (cette story fournit le moteur et quelques cartes d'exemple)
- 029 : objets ; 030 : ennemis et boss ; 031 : rééquilibrage complet

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: tests headless dans `tests/scratch/` + captures du combat (Talent, Élan, mots-clés) dans `production/qa/evidence/story-027-profondeur-du-combat/`

**Status**: [x] Tests `tests/scratch/t26_card_effects.gd`, `t27_talent_elan.gd` + captures dans `production/qa/evidence/story-027-profondeur-du-combat/`

---

## Dependencies

- Depends on: Story 021
- Unlocks: Stories 028, 029, 030, 031

## Completion Notes
**Completed**: 2026-11-17
**Criteria**: 7/7 (clôture demandée par le joueur ; tests t26 106/0, t27 69/0, t9/t11/t18/t24/t25 OK ; captures 01–08)
**Deviations**: Advisory only — règle des Talents changée à la demande du joueur : 1 fois par combat et par Pokémon (`talent_trigger` en données) ; équilibre à refaire (simulateur 78,7 % de victoires, cible 35 %, story 031) ; barre de PV qui tombe d'un coup sur les multi-coups ; bannière de Talent qui recouvre un instant le nom ; infobulles au survol de la souris seulement
**Test Evidence**: Logic — `tests/scratch/t26_card_effects.gd`, `tests/scratch/t27_talent_elan.gd` ; captures `production/qa/evidence/story-027-profondeur-du-combat/`
**Code Review**: Skipped — Solo mode
