# Décors peints — prompts d'images (story 020b)

Ce fichier contient un prompt par décor de combat, plus l'écran titre. Tu peux
coller chaque prompt dans un générateur d'images (Midjourney, DALL·E, Stable Diffusion, Leonardo…). Les prompts sont
en anglais : les générateurs les comprennent mieux. **Colle toujours le « préambule de style » avant le prompt du
décor**, pour que toutes les images aient le même style.

Tant qu'une image manque, le jeu dessine le décor lui-même (formes + brume, lumière et profondeur en shader) : rien
ne casse.

## Comment ajouter une image (débutant)

1. Génère l'image en **16:9, 1920×1080** (1280×720 marche aussi). Format **PNG**.
2. Renomme-la exactement comme indiqué (ex. `fire.png`, tout en minuscules, sans accent).
3. Range-la dans le dossier `assets/art/backdrops/` du projet (crée le dossier s'il n'existe pas).
4. Ouvre (ou ré-active) la fenêtre de l'éditeur Godot : il importe l'image tout seul (une ligne apparaît en bas).
5. Appuie sur **F5** pour lancer le jeu : les combats de ce type utilisent ton image.
   Pour revenir au décor dessiné, supprime simplement le fichier.

Conseils : le sol en bas au centre doit rester **vide et assez plat** (les Pokémon s'y tiennent, sur des ovales
ajoutés par le jeu) ; l'horizon doit être vers **47 % de la hauteur** ; le bas de l'image est assombri sous les
cartes, donc n'y mets rien d'important. Le fichier titre est prêt pour une intégration future (le code
de ces écrans appartient à une autre story).

---

## Préambule de style (à coller avant chaque prompt)

```
Official Pokémon video game battle background art, in the style of the backgrounds of the Pokémon anime and of
Pokémon Scarlet & Violet / Pokémon Legends key art: bright, clean and colourful, soft cel shading, smooth gradients,
crisp shapes, friendly and adventurous mood, gentle depth with lighter far layers. Side-on battle-stage composition,
wide shot. The horizon line sits at about 47% of the image height. The centre-bottom ground area is an empty, mostly
flat clearing (two fighters will stand there: one on the left third, two or three on the right half), with no
objects and little detail in it. The bottom 25% of the image is simple ground that can be darkened.
No characters, no creatures, no Pokémon, no people, no animals, no text, no letters, no logos, no UI, no frame,
no border. 16:9, 1920x1080.
```

## Negative prompt (si l'outil en accepte un)

```
characters, creatures, pokemon, people, animals, monsters, text, letters, watermark, signature, logo, UI, frame,
border, photorealistic, photo, gritty, dark fantasy, painterly brush strokes, pixel art, low poly, cluttered foreground, objects in
the centre, tilted horizon, fisheye, blurry, jpeg artifacts, oversaturated neon
```

---

## Décors de combat → `assets/art/backdrops/<id>.png`

| Fichier | Décor | Prompt (après le préambule) |
|---|---|---|
| `route.png` | Route (défaut) | `A sunny Pokémon route: soft rolling green hills, round leafy trees at mid-distance, a few fluffy white clouds in a clear sky blue to pale cyan, light shafts from the upper right, short grass meadow in the foreground, warm late-morning light.` |
| `normal.png` | Normal | `A peaceful countryside village edge: pale blue sky, gentle hills, small cosy houses with red and brown roofs far away, a trodden dirt-and-grass plain in the foreground, soft daylight, calm and homely.` |
| `fire.png` | Feu | `A volcanic badland at dusk: orange to gold sky, two or three distant volcanoes with glowing lava rims and smoke plumes, jagged dark rock spikes at mid-distance, cracked brown basalt ground with faint ember glow in the cracks, floating sparks, heat haze at the horizon.` |
| `water.png` | Eau | `A bright seashore: deep blue sky fading to pale cyan, calm sea with soft waves on the horizon, a few smooth rocks in the water, white clouds, a wide flat sandy beach in the foreground, sparkling light on the water from the upper left.` |
| `electric.png` | Électrik | `A power plant district at night: indigo sky, silhouettes of city buildings with warm yellow lit windows, tall electricity pylons with sagging cables across the scene, glowing yellow sparks in the air, a dull concrete plaza in the foreground lit by a yellow horizon glow.` |
| `grass.png` | Plante | `A lush forest clearing: light green sky glow through the canopy, layered pine and broadleaf trees fading into green mist, god rays through the trees, a mossy flat clearing with soft grass in the foreground, floating pollen motes.` |
| `ice.png` | Glace | `A frozen mountain pass: very pale icy sky, snow-capped jagged peaks in the distance, ice crystal spikes at mid-distance, a flat snowfield in the foreground with soft blue shadows, gentle snowfall, cold crisp light.` |
| `fighting.png` | Combat | `A mountain training ground at golden hour: warm peach sky, rounded hills, ancient stone pillars of an outdoor dojo at mid-distance, a flat sandy packed-earth arena in the foreground, dust in the warm light.` |
| `poison.png` | Poison | `A polluted industrial marsh: violet sky, rusty pipes and tanks in purple haze, dark rocks, a flat murky ground with small toxic puddles at the edges only, drifting purple spores, eerie light.` |
| `ground.png` | Sol | `A desert of golden dunes: pale yellow sky, wide sweeping sand dunes, a few cacti silhouettes at mid-distance, a flat hard-packed sand ground in the foreground, heat shimmer at the horizon, blowing sand grains.` |
| `flying.png` | Vol | `A plateau above the clouds: bright white-blue sky, a sea of clouds below the horizon, distant mountain tips poking through, big soft cumulus clouds, a flat pale rocky summit in the foreground, strong sun shafts, wind feeling.` |
| `psychic.png` | Psy | `A dreamlike psychic sanctuary: pink and violet sky, floating stone pillars and fragments hanging in the air, ancient columns at mid-distance, a smooth pastel marble floor in the foreground, soft pink glow and sparkles.` |
| `bug.png` | Insecte | `A deep forest of giant tree trunks: yellow-green light, huge trunks with branches, large spider webs between trunks catching the light, a flat mossy forest floor with fallen leaves, floating glowing motes.` |
| `rock.png` | Roche | `A rocky canyon: sandy beige sky, tall layered cliffs at mid-distance, boulders, a flat dusty stone ground in the foreground, warm side light and long soft shadows, dust in the air.` |
| `ghost.png` | Spectre | `A haunted graveyard at night: dark indigo-purple sky with a big pale moon, ruined towers with lit windows, tombstones and crosses at mid-distance, a flat misty ground in the foreground, cyan will-o'-wisps, cold blue fog.` |
| `dragon.png` | Dragon | `A mythic dragon peak: deep indigo to violet sky, sharp crystal-like mountains, tall stone spikes, a flat dark stone plateau in the foreground, glowing cyan particles, dramatic light from above.` |
| `dark.png` | Ténèbres | `A dark city alley at night: near-black purple sky with a dim moon, silhouettes of tall buildings with few lit windows, a flat wet asphalt plaza in the foreground with faint reflections, thin purple fog, sinister mood.` |
| `steel.png` | Acier | `A steel factory interior opening to the sky: pale grey-blue light, giant gears and steel beams at mid-distance, metal girders, a flat riveted metal floor in the foreground, clean cold light, small sparks.` |
| `fairy.png` | Fée | `An enchanted pastel garden: soft pink sky, flower arches and giant pastel flowers at mid-distance, a flat smooth lawn with tiny flowers at the edges, floating sparkles and petals, gentle dreamy light.` |
| `league.png` | Conseil 4 | `The grand hall of the Pokémon League: royal purple and violet light, tall marble pillars, hanging golden banners with an emblem shape (no text), a polished stone arena floor in the foreground, golden light from above, solemn and majestic.` |
| `ethernatos.png` | Éthernatos (boss final) | `A cosmic final-boss arena: near-black sky with deep crimson and magenta nebula glow, huge glowing red energy rings in the sky, dark red crystals at mid-distance, a flat obsidian platform in the foreground, red sparks, ominous apocalyptic light.` |
| `legendary.png` | Légendaire | `A sacred legendary shrine: indigo to violet sky with golden aurora, floating ancient stone fragments, glowing crystals, a flat ancient stone altar floor in the foreground, golden motes, awe-inspiring holy light.` |

## Écran titre → `assets/art/title/title.png`

```
Key art for a roguelike card game set in the Pokémon world: a winding path climbing toward a tall mysterious
spire on a distant mountain, under a dramatic dawn sky with golden light shafts, layered hills and forest in haze,
the upper centre left calm and empty for the game title added later. Official Pokémon key-art style: bright,
clean, cel-shaded, colourful, adventurous. No characters, no creatures, no text, no logos. 16:9, 1920x1080.
```
