# Sources des musiques et des sons (story 022)

Tout l'audio du jeu est listé ici avec sa source. Musiques et effets sont **créés pour le projet** par du code (aucun échantillon externe, aucune mélodie existante recopiée) ; les cris des Pokémon sont les **cris officiels** récupérés sur PokéAPI.

> **Propriété intellectuelle.** Les cris (`assets/audio/cries/`) sont la propriété de Nintendo / Game Freak / The Pokémon Company, comme les noms et sprites des Pokémon. Leur usage est acceptable pour ce jeu **privé, non distribué** ; ils devraient être retirés (ou remplacés par des cris générés) avant toute diffusion publique. Les musiques et effets générés n'ont pas cette restriction.

Réglages : `assets/data/audio.json` (contextes, événements, volumes par défaut, fondu). Lecture : `src/audio/audio_manager.gd` (`AudioManager`).

## Musiques — `assets/audio/music/` (OGG Vorbis, 22 050 Hz mono)

Source : **généré par `tools/audio/chiptune.py`** (compositions originales, synthèse 8 bits façon Game Boy : 2 voies carrées 12,5 / 25 / 50 %, basse triangle 4 bits, batterie au bruit LFSR). Relancer `python3 tools/audio/chiptune.py` puis `godot --headless --path . --import` pour régénérer.

| Fichier | Ambiance | Tonalité | Tempo | Boucle |
|---|---|---|---|---|
| `titre.ogg` | thème principal, héroïque | D majeur | 132 BPM | oui |
| `carte.ogg` | aventure joyeuse | G majeur | 116 BPM | oui |
| `combat_sauvage.ogg` | combat sauvage, énergique | A mineur | 168 BPM | oui |
| `combat_dresseur.ogg` | combat de Dresseur, tendu | E mineur | 176 BPM | oui |
| `champion.ogg` | Champion, épique | C mineur | 160 BPM | oui |
| `conseil.ogg` | Conseil 4, solennel et grave | F mineur | 100 BPM | oui |
| `ethernatos_1.ogg` | Éthernatos phase 1, sombre | B♭ phrygien | 150 BPM | oui |
| `ethernatos_2.ogg` | Éthernatos phase 2 (Infinitamax), intense | B phrygien | 184 BPM | oui |
| `victoire.ogg` | jingle de victoire (non bouclé) | C majeur | 140 BPM | non (jingle) |
| `defaite.ogg` | défaite, court et triste (non bouclé) | D mineur | 76 BPM | non (jingle) |
| `centre.ogg` | Centre Pokémon, doux et apaisant | F majeur | 92 BPM | oui |
| `mart.ogg` | Boutique, léger et sautillant | B♭ majeur | 132 BPM | oui |
| `evenement.ogg` | Événement, mystérieux | D dorien | 96 BPM | oui |

## Effets sonores — `assets/audio/sfx/` (WAV 22 050 Hz mono 16 bits)

Source : **généré par `tools/audio/sfx.py`** (générateur façon sfxr : ondes carrées / triangle, bruit LFSR, glissements de hauteur, enveloppes). Relancer `python3 tools/audio/sfx.py`.

| Fichier | Source |
|---|---|
| `card_play.wav` | généré par `tools/audio/sfx.py` |
| `card_draw.wav` | généré par `tools/audio/sfx.py` |
| `hit_normal.wav` | généré par `tools/audio/sfx.py` |
| `hit_super.wav` | généré par `tools/audio/sfx.py` |
| `hit_weak.wav` | généré par `tools/audio/sfx.py` |
| `hit_immune.wav` | généré par `tools/audio/sfx.py` |
| `block.wav` | généré par `tools/audio/sfx.py` |
| `heal.wav` | généré par `tools/audio/sfx.py` |
| `status_apply.wav` | généré par `tools/audio/sfx.py` |
| `ko.wav` | généré par `tools/audio/sfx.py` |
| `switch.wav` | généré par `tools/audio/sfx.py` |
| `energy.wav` | généré par `tools/audio/sfx.py` |
| `button_click.wav` | généré par `tools/audio/sfx.py` |
| `button_hover.wav` | généré par `tools/audio/sfx.py` |
| `error.wav` | généré par `tools/audio/sfx.py` |
| `coin.wav` | généré par `tools/audio/sfx.py` |
| `buy.wav` | généré par `tools/audio/sfx.py` |
| `capture_throw.wav` | généré par `tools/audio/sfx.py` |
| `capture_shake.wav` | généré par `tools/audio/sfx.py` |
| `capture_success.wav` | généré par `tools/audio/sfx.py` |
| `capture_fail.wav` | généré par `tools/audio/sfx.py` |
| `evolution.wav` | généré par `tools/audio/sfx.py` |
| `level_up.wav` | généré par `tools/audio/sfx.py` |
| `badge.wav` | généré par `tools/audio/sfx.py` |
| `talent.wav` | généré par `tools/audio/sfx.py` |
| `elan.wav` | généré par `tools/audio/sfx.py` |
| `debris.wav` | généré par `tools/audio/sfx.py` |
| `phase_change.wav` | généré par `tools/audio/sfx.py` |

## Cris des Pokémon — `assets/audio/cries/<slug>.ogg` (893 fichiers)

Source : **cri officiel PokéAPI** (dépôt `PokeAPI/cries`, dossier `cries/pokemon/latest/<n° Pokédex>.ogg`), téléchargé par `tools/audio/fetch_cries.py` pour chaque Pokémon ayant un sprite dans `assets/sprites/pokemon/` (le nom du fichier est celui du sprite ; n° Pokédex tiré de `pokemon.csv` de PokéAPI, formes par défaut pour aegislash / lycanroc / oinkologne). Le fichier « latest » de pikachu est en réalité un MP3 : il est converti en OGG par ffmpeg. Propriété de Nintendo / Game Freak / The Pokémon Company — usage privé uniquement.

