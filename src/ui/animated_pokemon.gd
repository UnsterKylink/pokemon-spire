class_name AnimatedPokemon
extends TextureRect
## Story 020b: a battle fighter sprite. Plays the Showdown sprite sheet res://assets/sprites/animated/<front|back>/<slug>.png
## (one row-major grid of frames) using assets/data/animated_sprites.json (slug -> {front|back: {w, h, frames, cols, ms}});
## slug = file name stem of the Pokémon's still sprite. Enemies use "front", the player's active Pokémon "back".
## No entry / no sheet -> the still sprite is shown the normal TextureRect way (keep-aspect, centred).
## The animated frame is drawn bottom-anchored: its lower edge sits at get_feet_y() so the feet rest on the backdrop
## platform. Its on-screen height is normalised from the frame height (sheets range ~35-200 px): small Pokémon are
## scaled up, big ones down, keeping a plausible size order (see _display_scale). Nearest filtering (set by the holder).
## Sheets load lazily (only when a fighter is shown). Display only: owns no game state.

const DATA_PATH: String = "res://assets/data/animated_sprites.json"
const SHEET_PATH: String = "res://assets/sprites/animated/%s/%s.png"
## Frame height (px) that fills the whole box; taller frames are scaled down to it.
const REF_FRAME_H: float = 115.0
## Exponent compressing size differences (1 = true relative size, 0 = all the same height).
const SIZE_CURVE: float = 0.6
## Smallest drawn height, as a fraction of the box height (tiny Pokémon stay readable).
const MIN_HEIGHT_RATIO: float = 0.48
## Widest drawn frame, as a fraction of the parent slot width (the slot column is wider than the box: wide sprites
## like Dracaufeu / Éthernatos may overflow the box sideways but never their own column).
const MAX_WIDTH_RATIO: float = 0.96
## Feet line, as a fraction of the box height (BattleScreen puts the platform ellipse there).
const FEET_RATIO: float = 0.9

static var _meta: Dictionary = {}
static var _meta_loaded: bool = false

var _path: String = ""
var _back: bool = false
var _sheet: Texture2D
var _w: int = 0
var _h: int = 0
var _frames: int = 1
var _cols: int = 1
var _ms: float = 30.0
var _frame: int = 0
var _elapsed: float = 0.0
var _motion: bool = true


func _init() -> void:
	set_process(false)


## Shows the Pokémon whose still sprite is `sprite_path`; `back` = seen from behind (player side).
func show_pokemon(sprite_path: String, back: bool) -> void:
	if sprite_path == _path and back == _back:
		return
	_path = sprite_path
	_back = back
	_sheet = null
	var slug: String = sprite_path.get_file().get_basename()
	var entry: Variant = _metadata().get(slug, null)
	var info: Variant = (entry as Dictionary).get("back" if back else "front", null) if entry is Dictionary else null
	var sheet_path: String = SHEET_PATH % ["back" if back else "front", slug]
	if info is Dictionary and ResourceLoader.exists(sheet_path):
		_sheet = load(sheet_path) as Texture2D
	if _sheet != null:
		var d: Dictionary = info
		_w = maxi(1, int(d.get("w", 1)))
		_h = maxi(1, int(d.get("h", 1)))
		_frames = maxi(1, int(d.get("frames", 1)))
		_cols = maxi(1, int(d.get("cols", 1)))
		_ms = maxf(1.0, float(d.get("ms", 30)))
		_frame = absi(hash(slug)) % _frames  # identical enemies do not move in sync
		_elapsed = 0.0
		texture = null
	else:
		texture = load(sprite_path) as Texture2D
		if texture == null and not sprite_path.is_empty():
			push_error("AnimatedPokemon: cannot load sprite %s" % sprite_path)
	set_process(_sheet != null and _motion)
	queue_redraw()


## True when a sprite sheet is playing (false = still sprite fallback).
func is_animated() -> bool:
	return _sheet != null


## Current frame index (QA).
func get_frame() -> int:
	return _frame


## Local y of the feet line (where the backdrop platform goes).
func get_feet_y() -> float:
	return size.y * FEET_RATIO


## Local rect the current frame is drawn in (animated), or the whole box (still sprite).
func get_drawn_rect() -> Rect2:
	if _sheet == null:
		return Rect2(Vector2.ZERO, size)
	var s: float = _display_scale()
	var ds := Vector2(_w * s, _h * s)
	return Rect2(Vector2((size.x - ds.x) * 0.5, get_feet_y() - ds.y), ds)


## Reduced motion: false freezes the animation on its current frame.
func set_motion_enabled(enabled: bool) -> void:
	_motion = enabled
	set_process(_sheet != null and _motion)


func _process(delta: float) -> void:
	_elapsed += delta * 1000.0
	if _elapsed < _ms:
		return
	var steps: int = int(_elapsed / _ms)
	_elapsed -= steps * _ms
	_frame = (_frame + steps) % _frames
	queue_redraw()


func _draw() -> void:
	if _sheet == null or size.x <= 0.0:
		return
	var region := Rect2((_frame % _cols) * _w, (_frame / _cols) * _h, _w, _h)
	draw_texture_rect_region(_sheet, get_drawn_rect(), region)


## Pixel scale of the frame: height = box * clamp((h / REF_FRAME_H) ^ SIZE_CURVE), then capped by the slot width.
func _display_scale() -> float:
	var box_h: float = get_feet_y()
	var ratio: float = clampf(pow(_h / REF_FRAME_H, SIZE_CURVE), MIN_HEIGHT_RATIO, 1.0)
	var s: float = box_h * ratio / _h
	var parent: Control = get_parent_control()
	var max_w: float = maxf(size.x, parent.size.x if parent != null else size.x) * MAX_WIDTH_RATIO
	return minf(s, max_w / _w)


static func _metadata() -> Dictionary:
	if not _meta_loaded:
		_meta_loaded = true
		var f: FileAccess = FileAccess.open(DATA_PATH, FileAccess.READ)
		if f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				_meta = parsed
	return _meta
