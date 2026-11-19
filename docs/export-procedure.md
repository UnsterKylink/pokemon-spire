# Procédure d'export — Pokémon Spire (Windows)

Ce guide explique comment fabriquer le fichier `PokemonSpire.exe` depuis l'éditeur Godot 4.6.3 sur Windows.
Le fichier `export_presets.cfg` (à la racine du projet) contient déjà deux préréglages : **Windows** et **Linux** (ce dernier sert aux tests).

## 1. Une seule fois : télécharger les modèles d'export

1. Ouvre le projet dans Godot 4.6.3.
2. Menu **Éditeur → Gérer les modèles d'export**.
3. Clique sur **Télécharger et installer** (version 4.6.3.stable). Attends la fin (environ 1,2 Go).

## 2. Exporter le jeu

1. Menu **Projet → Exporter…**
2. Choisis le préréglage **Windows** dans la liste de gauche.
3. Vérifie que **Intégrer le PCK** est coché (un seul fichier .exe) et que la case « Exporter avec débogage » est **décochée**.
4. Clique sur **Exporter le projet…** (et non « Exporter PCK/ZIP »), choisis `build/windows/PokemonSpire.exe`.
5. **Décoche « Exporter avec débogage »** dans la fenêtre de sauvegarde, puis **Enregistrer**.

Le dossier `build/` est ignoré par Git : l'exécutable n'est jamais commité.

En ligne de commande (même résultat) :

```
Godot_v4.6.3-stable_win64.exe --headless --path . --export-release "Windows" build/windows/PokemonSpire.exe
```

## 3. L'icône

- Fichiers : `assets/art/icon/icon.ico` (256, 128, 64, 48, 32, 16 px) et `icon.png`.
- `icon.png` est l'icône du projet (`config/icon` dans `project.godot`, fenêtre du jeu).
- `icon.ico` est utilisé par le préréglage Windows pour l'icône du fichier .exe.
- Pour **incorporer** l'icône dans le .exe, Godot a besoin de l'outil `rcedit` : sous Windows, indique son chemin dans
  **Éditeur → Paramètres de l'éditeur → Export → Windows → rcedit** (télécharge `rcedit-x64.exe` sur le site du projet rcedit).
  Sans rcedit, le jeu fonctionne, mais le fichier .exe garde l'icône Godot par défaut (le nom du produit et la version non plus ne sont alors pas écrits).
  Un export depuis Linux n'incorpore pas l'icône (il faudrait rcedit + wine).

## 4. Comment les outils de test (QA) sont désactivés

Les deux préréglages posent la **fonctionnalité personnalisée** `release` (champ « Fonctionnalités personnalisées »).
Le script `src/run/qa_gate.gd` (`QaGate.enabled()`) vaut `not OS.has_feature("release")` :

- dans l'éditeur, avec `godot --path .` et dans les scripts de test : QA **actif** ;
- dans le jeu exporté : les options `--seed`, `--starter`, `--encounter` sont ignorées et toutes les fonctions `qa_*` (triche, victoire forcée…) ne font rien.

Règle : toute nouvelle entrée de test doit passer par `QaGate.enabled()`.

## 5. Tailles (mesurées le 2026-11-19)

| Élément | Avant | Après |
|---|---|---|
| Dossier `assets/` | 200 Mo | 105 Mo |
| Décors, cartes, titre (41 JPG) | 109 Mo | 14 Mo (1920 px de large, qualité 88) |
| `PokemonSpire.exe` (Windows, PCK intégré) | — | environ 215 Mo |

Les JPG sont importés avec compression « avec perte » (WebP, qualité 0,85). Les sprites pixel art restent sans perte.
Les sprites animés (65 Mo) et les cris (18 Mo) sont l'essentiel du reste. Les musiques sont en OGG, avec boucle activée (sauf les jingles de victoire et de défaite).

## 6. Alléger l'historique Git (.git ≈ 728 Mo)

Rien n'est réécrit automatiquement. Options, de la plus sûre à la plus radicale :

1. **Ne rien faire** : le dépôt est privé, ce poids est sans effet sur les joueurs.
2. `git gc --aggressive --prune=now` : gain faible, sans risque.
3. **Git LFS** pour `*.jpg`, `*.png`, `*.ogg` : les nouvelles versions des images ne gonflent plus le dépôt.
4. **Réécrire l'historique** avec `git filter-repo` (retirer les anciennes versions 2752 px des JPG) : gain important,
   mais change tous les identifiants de commit ; faire une sauvegarde complète avant et re-cloner ensuite.
5. Repartir d'un dépôt neuf (instantané sans historique) en gardant l'ancien en archive.
