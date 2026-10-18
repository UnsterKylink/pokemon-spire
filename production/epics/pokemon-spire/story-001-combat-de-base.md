# Story 001: Combat de base contre 1 ennemi

> **Epic**: Pokémon Spire
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: [fill before starting]
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: `Brief MVP feature 1`

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (the **Player goal & fail state** field + MVP feature 1), scoped to this story:*

- [ ] Le joueur commence chaque tour avec 3 énergies ; chaque carte a un coût en énergie et ne peut pas être jouée sans énergie suffisante.
- [ ] Début de tour : pioche de 5 cartes ; fin de tour : la main est défaussée ; quand la pioche est vide, la défausse est mélangée pour former une nouvelle pioche.
- [ ] Une carte d'attaque inflige ses dégâts à la cible ; une carte de protection donne des points de protection qui absorbent les dégâts et disparaissent au début du tour suivant du joueur.
- [ ] Salamèche a des PV max et un deck de départ de 10 cartes, définis dans des fichiers de données (Resources .tres ou JSON) — aucune valeur de gameplay en dur dans le code.
- [ ] L'ennemi (1 Pokémon) a des PV et effectue une action simple (attaque fixe) à la fin du tour du joueur.
- [ ] Le combat se termine par une victoire quand les PV de l'ennemi tombent à 0, ou une défaite quand ceux de Salamèche tombent à 0 (message simple à l'écran).
- [ ] Écran jouable : main de cartes visible, clic sur une carte puis sur la cible pour la jouer, bouton « Fin de tour », PV / protection / énergie affichés.
- [ ] Les sprites de Salamèche et de l'ennemi viennent de PokéAPI et sont stockés dans `assets/` (pas de téléchargement au lancement du jeu).

---

## Implementation Notes

- La scène de combat devient `run/main_scene` dans `project.godot`.
- Séparer la logique de combat (classes testables sans scène) de l'affichage (Control nodes).
- Données : `assets/data/` pour cartes et Pokémon ; sprites dans `assets/sprites/pokemon/`.
- Godot 4.6 is HIGH risk: check `docs/engine-reference/godot/` before using engine APIs.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- 002 : intentions ennemies, plusieurs ennemis
- 003 : types
- 004 : récompenses

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/combat/combat-de-base_test.gd` — advisory at `qa.level: minimal` (tests waived), plus a retained screenshot in `production/qa/evidence/` because the story changes what the player sees.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks: Story 002
