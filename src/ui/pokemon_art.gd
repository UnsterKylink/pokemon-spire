class_name PokemonArt
extends RefCounted
## Story 033 (cohérence visuelle): the one off-battle picture of a Pokémon — its official HD artwork
## (assets/sprites/artwork/<slug>.png, 256 px), falling back to the cropped pixel sprite when the artwork is missing.
## Animated sprites stay in battle only. Display only: owns no game state.

const ARTWORK_DIR: String = "res://assets/sprites/artwork/"
const SPRITE_DIR: String = "res://assets/sprites/pokemon/"

static var _cache: Dictionary = {}


## Official artwork of Pokémon `slug` (sprite file name without extension, e.g. "charmander"); fallback: the cropped
## pixel sprite; null when neither exists.
static func texture_for(slug: String) -> Texture2D:
	if slug.is_empty():
		return null
	return texture_for_sprite(SPRITE_DIR + slug + ".png")


## Same as texture_for, from the Pokémon's sprite path (GameData pokemon info "sprite_path").
static func texture_for_sprite(sprite_path: String) -> Texture2D:
	if sprite_path.is_empty():
		return null
	if _cache.has(sprite_path):
		return _cache[sprite_path]
	var tex: Texture2D = null
	var art: String = CardView.artwork_path(sprite_path)
	if not art.is_empty() and ResourceLoader.exists(art):
		tex = CardView.cropped_sprite(art)
	elif ResourceLoader.exists(sprite_path):
		tex = CardView.cropped_sprite(sprite_path)
	_cache[sprite_path] = tex
	return tex


## True when `sprite_path` has an official artwork (the picture is then smooth, not pixel art).
static func has_artwork(sprite_path: String) -> bool:
	var art: String = CardView.artwork_path(sprite_path)
	return not art.is_empty() and ResourceLoader.exists(art)


## Puts the picture of `sprite_path` on `rect` with the right filter (smooth for artwork, nearest for a pixel
## fallback), keep-aspect centred.
static func apply(rect: TextureRect, sprite_path: String) -> void:
	rect.texture = texture_for_sprite(sprite_path)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS if has_artwork(sprite_path) \
			else CanvasItem.TEXTURE_FILTER_NEAREST
