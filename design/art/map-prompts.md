# Carte d'avancement — prompts d'images (story 020b)

Deux séries d'images, dans le **même style que tes décors de combat** :

1. **18 cartes de région** (une par type d'arène) → `assets/art/map/<type>.jpg` (ou .png)
2. **8 icônes de salles** → `assets/art/map/icons/<salle>.png` (ou .jpg)

Le jeu pose les salles et dessine les chemins **par-dessus** la carte de région : l'image ne doit donc contenir
**ni route, ni ville, ni bâtiment au centre** — juste le paysage vu du dessus. Une image manquante = le jeu garde
la carte dessinée actuelle, rien ne casse.

Comment ajouter les images : comme pour les décors (GitHub → dossier → « Add file » → « Upload files » →
« Commit changes »), puis dis-moi « c'est uploadé » : je les intègre et je vérifie en capture.

---

## 1. Cartes de région → `assets/art/map/<type>.jpg`

**Format : 16:9, 1920×1080 (ou plus grand).**

### Préambule (à coller avant chaque prompt)

```
Official Pokémon video game region map illustration, top-down bird's-eye view like the Town Map of Pokémon
Scarlet & Violet / Sword & Shield, bright clean colourful cel-shaded art, soft shading, gentle painted textures,
same style as Pokémon anime background art. A single natural landscape seen from directly above, filling the whole
frame, with varied terrain (meadows, forests, hills, water) spread evenly. The landscape is calm and open so that
paths and icons can be drawn on top later: no roads, no paths, no towns, no buildings, no bridges in the image,
no strong contrast in the centre. No characters, no creatures, no Pokémon, no people, no text, no letters, no labels,
no logos, no compass, no legend, no UI, no frame, no border. 16:9, 1920x1080.
```

### Prompt négatif (si l'outil en accepte un)

```
roads, paths, towns, cities, buildings, houses, bridges, text, letters, labels, legend, compass, logo, watermark,
characters, creatures, pokemon, people, frame, border, perspective view, side view, horizon, sky, photorealistic,
3D render, pixel art, dark, gritty
```

### Les 18 cartes (fichier → prompt à coller après le préambule)

- `normal.jpg` : Gentle green countryside: soft meadows, small groves of round trees, a winding river, a few ponds, flower patches.
- `fire.jpg` : Volcanic region: dark brown and orange rocky land, two volcano craters with glowing lava at the edges of the map, lava rivers, ash fields, a few scorched trees.
- `water.jpg` : Tropical archipelago: turquoise sea covering most of the map, many small sandy islands with palm trees and green centres, coral reefs, shallow lagoons.
- `electric.jpg` : Stormy plains: yellow-green grassland, dark rocky outcrops, small lakes reflecting lightning-blue light, scattered power-crystal rocks glowing yellow, a few dead trees.
- `grass.jpg` : Lush forest region: dense green forests, clearings, mossy hills, a blue river, flower meadows, giant old trees.
- `ice.jpg` : Snowy region: white snowfields, frozen blue lakes, snow-covered pine forests, icy cliffs and glaciers at the edges.
- `fighting.jpg` : Mountain training region: rocky brown hills, cliffs, waterfalls, small dojo-like stone plateaus (no buildings), pine trees, warm tones.
- `poison.jpg` : Toxic swamp region: purple-tinted marshes, murky green-violet pools, twisted dark trees, mushroom clusters, misty lowlands.
- `ground.jpg` : Desert region: golden sand dunes, dry canyons, mesas, a few oases with palm trees, cracked earth.
- `flying.jpg` : Sky islands: floating green islands above a sea of white clouds, waterfalls falling off the island edges into the clouds, wind swirls.
- `psychic.jpg` : Mystic region: pastel pink and violet land, glowing crystal formations, calm mirror lakes, strange circular stone patterns, soft sparkles.
- `bug.jpg` : Giant forest region: huge tree canopies seen from above, mossy floor, berry bushes, spider-web glades, small streams, yellow-green light.
- `rock.jpg` : Canyon region: layered beige and brown rock plateaus, deep canyons, boulders, sparse dry shrubs, a dusty riverbed.
- `ghost.jpg` : Haunted region: dark violet and blue night-lit land, misty graveyard hills with tiny tombstones, dead trees, ghostly blue will-o'-wisps, foggy hollows.
- `dragon.jpg` : Mythic dragon region: tall jagged mountains, deep blue lakes, ancient ruins of stone circles (no buildings), cliffs, purple-blue tones.
- `dark.jpg` : Night region: dark forest and rocky land under moonlight, deep purple shadows, black lakes, thorny bushes, few glowing eyes-like lights (no creatures).
- `steel.jpg` : Industrial wasteland region: grey-blue metallic rock plates, mineral deposits, iron-coloured cliffs, small quarry pits, sparse grass (no buildings).
- `fairy.jpg` : Enchanted region: pastel pink and mint meadows, giant flowers, heart-shaped ponds, rainbow-coloured flower fields, sparkling streams.

---

## 2. Icônes des salles → `assets/art/map/icons/<salle>.png`

**Format : carré, 1024×1024. Fond uni blanc pur** (le jeu enlève le fond tout seul) — ou fond transparent si
ton outil sait le faire.

### Préambule (à coller avant chaque prompt)

```
Official Pokémon video game map icon, a single round badge-style emblem centred in the image, bright clean
colourful cel-shaded art with a thick dark outline and soft shading, same style as Pokémon Scarlet & Violet UI icons,
readable at small size, simple bold silhouette. Isolated on a plain pure white background, nothing else in the
image. No text, no letters, no numbers, no logos, no frame, no shadow on the background. Square 1:1, 1024x1024.
```

### Les 8 icônes (fichier → prompt à coller après le préambule)

- `wild.png` (Combat sauvage) : A tuft of tall green grass with a few blades swaying, with a mysterious glowing pair of eyes peeking from inside the grass.
- `elite.png` (Dresseur élite) : A Pokémon trainer's cap seen from the front, purple and white, with a small star emblem on it.
- `rival.png` (Rival) : An orange and black spiky-haired rival trainer's head silhouette with a confident grin, simple and bold.
- `center.png` (Centre Pokémon) : A small Pokémon Center building, white walls and red roof with a white Poké Ball emblem on the roof, cute and simple.
- `mart.png` (Poké Mart) : A small Poké Mart shop building, white walls and blue roof with a shopping-bag emblem, cute and simple.
- `event.png` (Événement) : A wooden signpost with a big glowing question mark symbol carved on it (the symbol only, no letters).
- `boss.png` (Arène) : A Pokémon Gym building, grand and imposing, with a dome roof and a golden badge emblem above the entrance.
- `player.png` (Ta position) : A red and white Poké Ball, shiny, slightly tilted, simple.
