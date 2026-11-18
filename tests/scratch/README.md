# Tests « scratch »

Scripts de test headless écrits au fil des stories (t3 … t25). Lancer depuis la racine :

    godot --headless --path . -s tests/scratch/<fichier>.gd

Chaque script affiche un total `pass` / `fail` et sort avec 0 échec quand tout va bien.

`t32_pacing.gd` (story 032) : cartes de zone à 4 étages, règles de zone (sauvages / élites seulement), bandeau de carte et
pastille de combat, récompenses thématiques (`zone_type_bias`), anciennes sauvegardes à 6 étages.

`t22_audio.gd` (story 022) : audio.json complet (morceaux, effets, événements, contextes), un cri pour chaque Pokémon du roster / de pokemon.json, AudioManager en headless (musique, fondu, effets, cris, volumes enregistrés, fichiers manquants tolérés) et Main (musique par écran / combat, curseurs des Options).
