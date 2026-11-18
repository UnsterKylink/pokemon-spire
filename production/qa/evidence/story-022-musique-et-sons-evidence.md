# Story 022 — Musique et effets sonores : preuve et validation

**Story** : `production/epics/pokemon-spire/story-022-musique-et-sons.md` (Visual/Feel)
**Captures** : `production/qa/evidence/story-022-musique-et-sons/` (voir README.md)
**Sources** : `design/audio/sources.md`

| Critère | Preuve |
|---|---|
| Musiques différentes : carte, combats sauvages, Dresseurs / Champions, Conseil 4, Éthernatos, victoire, défaite | 13 morceaux originaux générés par `tools/audio/chiptune.py` (`assets/audio/music/`), contextes dans `assets/data/audio.json` (`music`, `screens`) ; choix par écran / salle dans `Main._play_screen_music` ; phase 2 d'Éthernatos sur `Battle.enemy_phase_changed`. Test scratch `t22_audio` (carte, sauvage, arène, Centre, Mart, salle inconnue). `python3 tools/audio/chiptune.py --check` : aucun écrêtage (crête max −1,7 dBFS), aucune boucle silencieuse, jointure de boucle < 1 pas d'échantillon normal. |
| Effets : cartes jouées, coups selon l'efficacité, menus, achats, capture, évolution | 28 sons générés par `tools/audio/sfx.py` (`assets/audio/sfx/`), événements dans `audio.json` (`events`) ; branchés dans `BattleScreen` (file d'animation), `BattleFxDirector.capture_throw`, `UiStyle.install_button_sounds` (tous les boutons), `Main` (achat, Centre, badge, évolution) ; cris officiels à l'entrée en combat, au K.O., au switch, à la capture et à l'évolution. |
| Volumes musique / effets réglables et mémorisés | `01-options-volumes.png`, `02-options-volumes-regles.png` ; `GameSettings` `music_volume` / `sfx_volume` ; `t22_audio` (sauvegarde, rechargement, 0 = muet). |
| Sons libres de droits ou créés pour le projet, listés avec leur source | `design/audio/sources.md` (musique et effets : créés par le projet ; cris : PokéAPI, propriété Nintendo / Game Freak, usage privé). |
| Aucune régression | t25 (animations sans effet sur le résultat) `fails=0`, t11, t22_audio et les autres scratch identiques à la référence (les échecs de t2 / t4 / t5 / t5b / t8 / t10 / t17 existaient déjà avant la story, même nombre). |

Notes : en mode headless les bus Music / SFX sont muets ; à la vitesse « Instantané », les sons de combat (liés à la
file d'animation) ne jouent pas — seuls la musique, les clics et le son « carte jouée » restent.

## Sign-off

| Rôle | Statut |
|---|---|
| Joueur / direction artistique (écoute en jeu : musiques, sons, cris, volumes) | [ ] Approved |
