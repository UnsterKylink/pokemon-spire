class_name ItemIcon
extends Control
## Official illustration of a held item / potion / berry / Poké Ball (assets/sprites/items/<id>.png, PokeAPI
## dream-world art) drawn aspect-fit with an optional soft drop shadow. Missing file -> fallback: a drawn Poké Ball
## for ball ids (BallIcon.draw_ball), else a small cream tag. Mouse ignored (the parent carries the tooltip).
## Display only. Implements: story-020b-refonte-visuelle-premium (item sprites in the Mart, HUD, rewards, events).

## Default art path of an item id ("" icon_path).
const PATH_PATTERN: String = "res://assets/sprites/items/%s.png"
## Drop shadow: offset (fraction of the side) and per-layer alpha (3 layers, slightly spread = soft).
const SHADOW_OFFSET: float = 0.07
const SHADOW_ALPHA: float = 0.16
const FALLBACK_BG: Color = UiStyle.CREAM
const FALLBACK_LINE: Color = UiStyle.OUTLINE

## path -> Texture2D or null (missing file), shared by every icon.
static var _cache: Dictionary = {}

var item_id: String = ""
## Optional explicit art path (data "icon" field); "" = PATH_PATTERN % item_id.
var icon_path: String = ""
var shadow: bool = true
var _texture: Texture2D


## Texture of `id` (or of `path` when given), null when the file does not exist. Cached.
static func texture_for(id: String, path: String = "") -> Texture2D:
	var p: String = path if not path.is_empty() else PATH_PATTERN % id
	if _cache.has(p):
		return _cache[p]
	var tex: Texture2D = null
	if not id.is_empty() and ResourceLoader.exists(p):
		tex = load(p) as Texture2D
	_cache[p] = tex
	return tex


## True when `id` has an illustration on disk.
static func has_art(id: String) -> bool:
	return texture_for(id) != null


## Builds a `side` x `side` icon for `id` (shadow on by default).
static func make(id: String, side: float, with_shadow: bool = true, path: String = "") -> ItemIcon:
	var icon := ItemIcon.new()
	icon.item_id = id
	icon.icon_path = path
	icon.shadow = with_shadow
	icon.custom_minimum_size = Vector2(side, side)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


## Aspect-fit rect of `tex` inside `area`.
static func fit_rect(tex: Texture2D, area: Rect2) -> Rect2:
	var ts: Vector2 = tex.get_size()
	if ts.x <= 0.0 or ts.y <= 0.0:
		return area
	var k: float = minf(area.size.x / ts.x, area.size.y / ts.y)
	var s: Vector2 = ts * k
	return Rect2(area.position + (area.size - s) * 0.5, s)


## Draws the art of `tex` in `area` on `ci`, with a soft shadow under it when `with_shadow`.
static func draw_art(ci: CanvasItem, tex: Texture2D, area: Rect2, with_shadow: bool) -> void:
	var r: Rect2 = fit_rect(tex, area)
	if with_shadow:
		var off: float = area.size.y * SHADOW_OFFSET
		for k: int in 3:
			var grow: float = k * area.size.x * 0.012
			ci.draw_texture_rect(tex, Rect2(r.position + Vector2(off * 0.4, off) - Vector2(grow, grow) * 0.5,
					r.size + Vector2(grow, grow)), false, Color(0, 0, 0, SHADOW_ALPHA))
	ci.draw_texture_rect(tex, r, false)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_texture = texture_for(item_id, icon_path)


func _draw() -> void:
	var side: float = minf(size.x, size.y)
	if side <= 2.0:
		return
	var area := Rect2((size - Vector2(side, side)) * 0.5, Vector2(side, side))
	if _texture == null:
		_texture = texture_for(item_id, icon_path)
	if _texture != null:
		draw_art(self, _texture, area, shadow)
		return
	var c: Vector2 = size * 0.5
	if BallIcon.PALETTES.has(item_id) or item_id.ends_with("_ball"):
		BallIcon.draw_ball(self, c, side * 0.5 - 1.0, item_id)
		return
	var tag := Rect2(area.position + area.size * 0.15, area.size * 0.7)
	draw_rect(tag, FALLBACK_BG)
	draw_rect(tag, FALLBACK_LINE, false, maxf(1.0, side * 0.05))
	draw_circle(tag.position + Vector2(tag.size.x * 0.5, tag.size.y * 0.25), side * 0.06, FALLBACK_LINE)
