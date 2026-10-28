# Story 021 — Animations d'attaque et de combat : preuve et validation

**Story** : `production/epics/pokemon-spire/story-021-animations-attaque.md` (Visual/Feel)
**Captures** : `production/qa/evidence/story-021-animations-attaque/` (voir README.md)

| Critère | Preuve |
|---|---|
| Animation de l'attaquant + effet selon le type (données) | `01`–`03`, `1x-01`, `1x-02` ; `assets/data/attack_fx.json` |
| Retour visuel : dégâts, protection, statuts, switch, K.O., évolution | `1x-02`…`1x-08`, `04`, `05` |
| Durée plafonnée en données + option d'accélération (Normal / Rapide / Instantané, clic ou Espace pour passer) | `assets/data/animations.json` (`max_action_seconds`), bouton « Animations : … » |
| Aucune animation ne change le résultat | test scratch t25 (`fails=0`), t11 / t18 / t24 OK |

## Sign-off

| Rôle | Statut |
|---|---|
| Joueur / direction artistique (ressenti en jeu) | [ ] Approved |
