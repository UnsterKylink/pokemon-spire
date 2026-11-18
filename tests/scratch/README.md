# Tests « scratch »

Scripts de test headless écrits au fil des stories (t3 … t25). Lancer depuis la racine :

    godot --headless --path . -s tests/scratch/<fichier>.gd

Chaque script affiche un total `pass` / `fail` et sort avec 0 échec quand tout va bien.

`t32_pacing.gd` (story 032) : cartes de zone à 4 étages, règles de zone (sauvages / élites seulement), bandeau de carte et
pastille de combat, récompenses thématiques (`zone_type_bias`), anciennes sauvegardes à 6 étages.
