class_name EffectArt
extends Control
## Illustration of a card without a carrier Pokémon (« Équipe » skill cards), drawn in code in the Pokémon move-effect
## style (bright fill, soft vertical shading, thick dark outline, white gloss). The picture follows the card's main
## effect, derived from its data (no per-card code): status inflicted -> the status symbol in its statuses.json colour
## (sleep Zzz, paralysis bolt, poison drop, burn flame, freeze crystal; any other status = buff arrow), heal -> pink
## heart, block -> green hexagon barrier (Abri / Protect), draw -> fanned cards, energy -> yellow energy orb, damage ->
## impact burst. Several effects: the first one in EFFECT_ORDER wins. Display only; ignores the mouse.
## Implements: story-020b follow-up (illustrations d'effet des cartes compétence, design/art-bible.md §7).

const KIND_BLOCK: String = "block"
const KIND_HEAL: String = "heal"
const KIND_DRAW: String = "draw"
const KIND_ENERGY: String = "energy"
const KIND_BUFF: String = "buff"
const KIND_ATTACK: String = "attack"
const KIND_NONE: String = ""
## Status ids that have their own symbol (others map to KIND_BUFF).
const STATUS_KINDS: Array[String] = ["sleep", "paralysis", "poison", "burn", "freeze"]
## Priority of the effects when a card has several: [CardData property, kind] ("status" = status_id).
const EFFECT_ORDER: Array = [["status", ""], ["heal", KIND_HEAL], ["block", KIND_BLOCK], ["draw", KIND_DRAW],
		["energy", KIND_ENERGY], ["strength", KIND_BUFF], ["damage", KIND_ATTACK]]
## Short effect word shown in the card's carrier strip (statuses use their statuses.json name).
const LABELS: Dictionary = {KIND_BLOCK: "Protection", KIND_HEAL: "Soin", KIND_DRAW: "Pioche", KIND_ENERGY: "Énergie",
		KIND_BUFF: "Renfort", KIND_ATTACK: "Attaque"}
const LABEL_FALLBACK: String = "Équipe"
const STATUSES_PATH: String = "res://assets/data/statuses.json"
## Fallback status colours when statuses.json is missing (same values as the data file).
const STATUS_COLORS: Dictionary = {"sleep": Color("#a890f0"), "paralysis": Color("#f8d030"), "poison": Color("#a040a0"),
		"burn": Color("#f08030"), "freeze": Color("#98d8d8")}
const SHIELD_GREEN: Color = Color("#4FE070")
const SHIELD_DEEP: Color = Color("#23A04E")
const HEART_PINK: Color = Color("#FF8FBF")
const HEART_DEEP: Color = Color("#E0407E")
const BUFF_RED: Color = Color("#FF5A4A")
const BUFF_DEEP: Color = Color("#C21F2A")
const FLAME_CORE: Color = Color("#FFE45C")
const GLOSS: Color = Color(1, 1, 1, 0.75)
## Size of the drawing relative to the smaller side of the rect, and outline width relative to that radius.
const RADIUS_FACTOR: float = 0.44
const OUTLINE_FACTOR: float = 0.075

# Normalised shapes (unit radius, y down).
const BOLT: Array[Vector2] = [Vector2(0.2, -1.0), Vector2(-0.5, 0.1), Vector2(-0.05, 0.1), Vector2(-0.25, 1.0),
		Vector2(0.5, -0.15), Vector2(0.05, -0.15), Vector2(0.35, -1.0)]
const FLAME: Array[Vector2] = [Vector2(0.05, -1.0), Vector2(0.3, -0.5), Vector2(0.52, -0.78), Vector2(0.62, -0.2),
		Vector2(0.66, 0.3), Vector2(0.42, 0.78), Vector2(0.0, 0.95), Vector2(-0.42, 0.78), Vector2(-0.66, 0.3),
		Vector2(-0.58, -0.25), Vector2(-0.38, -0.6), Vector2(-0.22, -0.3)]
const CRYSTAL: Array[Vector2] = [Vector2(0.0, -1.0), Vector2(0.5, -0.45), Vector2(0.5, 0.5), Vector2(0.0, 1.0),
		Vector2(-0.5, 0.5), Vector2(-0.5, -0.45)]
const ARROW: Array[Vector2] = [Vector2(0.0, -1.0), Vector2(0.78, -0.12), Vector2(0.32, -0.12), Vector2(0.32, 0.95),
		Vector2(-0.32, 0.95), Vector2(-0.32, -0.12), Vector2(-0.78, -0.12)]

static var _status_info: Dictionary = {}
static var _status_loaded: bool = false

## Effect kind drawn (KIND_* or a STATUS_KINDS id).
var kind: String = KIND_NONE


## New illustration for `card` (kind from effect_kind).
static func create(card: CardData) -> EffectArt:
	var a := EffectArt.new()
	a.name = "EffectArt"
	a.kind = effect_kind(card)
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return a


## Main effect of `card`: the first non-empty entry of EFFECT_ORDER (status -> its id, or KIND_BUFF when the status
## has no symbol). KIND_NONE when the card has no effect data.
static func effect_kind(card: CardData) -> String:
	if card == null:
		return KIND_NONE
	for entry: Array in EFFECT_ORDER:
		var prop: String = entry[0]
		if prop == "status":
			if not card.status_id.is_empty():
				return card.status_id if STATUS_KINDS.has(card.status_id) else KIND_BUFF
			continue
		var v: Variant = card.get(prop)
		if (v is int or v is float) and float(v) > 0.0:
			return String(entry[1])
	return KIND_NONE


## Short French word for the carrier strip of a card whose main effect is `effect` (statuses: their data name).
static func label_of(effect: String) -> String:
	if STATUS_KINDS.has(effect):
		var n: String = String(_status(effect).get("name", ""))
		if not n.is_empty():
			return n
	return String(LABELS.get(effect, LABEL_FALLBACK))


## Display colour of a status id (statuses.json "color", fallback STATUS_COLORS).
static func status_color(status_id: String) -> Color:
	var c: String = String(_status(status_id).get("color", ""))
	if c.begins_with("#"):
		return Color(c)
	return STATUS_COLORS.get(status_id, Color.WHITE)


static func _status(status_id: String) -> Dictionary:
	if not _status_loaded:
		_status_loaded = true
		var f: FileAccess = FileAccess.open(STATUSES_PATH, FileAccess.READ)
		if f != null:
			var root: Variant = JSON.parse_string(f.get_as_text())
			if root is Dictionary:
				var d: Dictionary = root
				var src: Variant = d.get("statuses", d)
				if src is Dictionary:
					for k: Variant in src:
						if src[k] is Dictionary:
							_status_info[String(k)] = src[k]
	var v: Variant = _status_info.get(status_id, {})
	return v if v is Dictionary else {}


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var r: float = minf(size.x, size.y) * RADIUS_FACTOR
	var c: Vector2 = size * 0.5
	var w: float = maxf(1.5, r * OUTLINE_FACTOR)
	match kind:
		KIND_BLOCK:
			_draw_shield(c, r, w)
		KIND_HEAL:
			_draw_heart(c, r, w)
		KIND_DRAW:
			_draw_cards(c, r, w)
		KIND_ENERGY:
			_draw_energy(c, r, w)
		KIND_BUFF:
			_draw_buff(c, r, w)
		KIND_ATTACK:
			_draw_burst(c, r, w)
		"sleep":
			_draw_sleep(c, r, w)
		"paralysis":
			var col: Color = status_color("paralysis")
			_shape(_pts(BOLT, c, r), col.lightened(0.45), col.darkened(0.15), w)
			_gloss(c + Vector2(-0.05, -0.45) * r, r * 0.12)
			_sparks(c, r, col, w)
		"poison":
			_draw_poison(c, r, w)
		"burn":
			var col: Color = status_color("burn")
			_shape(_pts(FLAME, c, r), col.lightened(0.25), Color("#E0301E"), w)
			_shape(_pts(FLAME, c + Vector2(0, r * 0.32), r * 0.55), Color.WHITE.lerp(FLAME_CORE, 0.6), FLAME_CORE, 0.0)
			_gloss(c + Vector2(-0.3, -0.15) * r, r * 0.1)
		"freeze":
			_draw_freeze(c, r, w)


## Abri / Protect: translucent green hexagon barrier with honeycomb facets and a gloss.
func _draw_shield(c: Vector2, r: float, w: float) -> void:
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i: int in 6:
		var a: float = -PI * 0.5 + TAU * float(i) / 6.0
		outer.append(c + Vector2(cos(a), sin(a)) * r * 1.05)
		inner.append(c + Vector2(cos(a), sin(a)) * r * 0.55)
	draw_circle(c, r * 1.2, Color(SHIELD_GREEN, 0.25), true, -1.0, true)
	_shape(outer, SHIELD_GREEN.lightened(0.4), SHIELD_GREEN.darkened(0.1), 0.0)
	var facet: Color = Color(1, 1, 1, 0.55)
	for i: int in 6:
		draw_line(inner[i], outer[i], facet, maxf(1.0, w * 0.5), true)
	var loop_in: PackedVector2Array = inner.duplicate()
	loop_in.append(inner[0])
	draw_colored_polygon(inner, Color(1, 1, 1, 0.18))
	draw_polyline(loop_in, facet, maxf(1.0, w * 0.6), true)
	var loop: PackedVector2Array = outer.duplicate()
	loop.append(outer[0])
	draw_polyline(loop, SHIELD_DEEP, w * 1.6, true)
	draw_polyline(loop, UiStyle.OUTLINE, maxf(1.0, w * 0.55), true)
	draw_arc(c, r * 0.8, PI * 1.08, PI * 1.42, 8, GLOSS, w * 0.9, true)
	_star(c + Vector2(r * 0.78, -r * 0.72), r * 0.2, Color.WHITE)


func _draw_heart(c: Vector2, r: float, w: float) -> void:
	var pts := PackedVector2Array()
	for i: int in 48:
		var t: float = TAU * float(i) / 48.0
		var x: float = 16.0 * pow(sin(t), 3)
		var y: float = -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		pts.append(c + Vector2(x, y + 2.0) * (r / 16.5))
	_shape(pts, HEART_PINK.lightened(0.25), HEART_DEEP, w)
	_gloss(c + Vector2(-0.45, -0.35) * r, r * 0.16)
	_star(c + Vector2(r * 0.85, -r * 0.8), r * 0.26, Color.WHITE)
	_star(c + Vector2(-r * 0.95, r * 0.55), r * 0.15, Color.WHITE)


## Three cards fanned from the bottom centre (blue backs with a white ball mark).
func _draw_cards(c: Vector2, r: float, w: float) -> void:
	var card_size := Vector2(r * 0.95, r * 1.35)
	var pivot: Vector2 = c + Vector2(0, r * 0.75)
	for deg: float in [-20.0, 0.0, 20.0]:
		draw_set_transform(pivot, deg_to_rad(deg), Vector2.ONE)
		var rect := Rect2(Vector2(-card_size.x * 0.5, -card_size.y * 1.05), card_size)
		draw_rect(rect.grow(w * 0.5), UiStyle.OUTLINE, true, -1.0, true)
		draw_rect(rect, Color.WHITE, true, -1.0, true)
		var back: Rect2 = rect.grow(-card_size.x * 0.12)
		draw_rect(back, UiStyle.ACCENT_BLUE, true, -1.0, true)
		draw_rect(Rect2(back.position, Vector2(back.size.x, back.size.y * 0.4)), UiStyle.ACCENT_BLUE.lightened(0.25), true)
		draw_circle(back.get_center(), back.size.x * 0.24, Color.WHITE, true, -1.0, true)
		draw_circle(back.get_center(), back.size.x * 0.24, UiStyle.OUTLINE, false, maxf(1.0, w * 0.5), true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_energy(c: Vector2, r: float, w: float) -> void:
	var col: Color = UiStyle.ACCENT_YELLOW
	draw_circle(c, r + w * 0.5, UiStyle.OUTLINE, true, -1.0, true)
	draw_circle(c, r, col.darkened(0.12), true, -1.0, true)
	draw_circle(c + Vector2(-0.12, -0.12) * r, r * 0.82, col.lightened(0.2), true, -1.0, true)
	_shape(_pts(BOLT, c, r * 0.68), Color.WHITE, UiStyle.CREAM, w * 0.8)
	_gloss(c + Vector2(-0.5, -0.5) * r, r * 0.13)


func _draw_buff(c: Vector2, r: float, w: float) -> void:
	_shape(_pts(ARROW, c, r), BUFF_RED.lightened(0.3), BUFF_DEEP, w)
	_gloss(c + Vector2(-0.12, -0.55) * r, r * 0.1)
	_star(c + Vector2(r * 0.85, r * 0.45), r * 0.22, UiStyle.ACCENT_YELLOW)
	_star(c + Vector2(-r * 0.85, r * 0.6), r * 0.16, UiStyle.ACCENT_YELLOW)


func _draw_burst(c: Vector2, r: float, w: float) -> void:
	var pts := PackedVector2Array()
	for i: int in 16:
		var a: float = -PI * 0.5 + TAU * float(i) / 16.0
		pts.append(c + Vector2(cos(a), sin(a)) * r * (1.0 if i % 2 == 0 else 0.55))
	_shape(pts, UiStyle.ACCENT_YELLOW.lightened(0.3), Color("#FF8A2A"), w)


## Sommeil: three outlined « Z » of growing size (status colour).
func _draw_sleep(c: Vector2, r: float, w: float) -> void:
	var col: Color = status_color("sleep")
	var font: Font = UiStyle.font_title()
	var specs: Array = [[Vector2(-0.85, 0.85), 0.8], [Vector2(-0.2, 0.3), 1.05], [Vector2(0.4, -0.25), 1.35]]
	for spec: Array in specs:
		var fs: int = maxi(8, roundi(r * float(spec[1])))
		var pos: Vector2 = c + (spec[0] as Vector2) * r
		draw_string_outline(font, pos, "Z", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, maxi(2, roundi(w * 1.6)), UiStyle.OUTLINE)
		draw_string(font, pos, "Z", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col.lightened(0.25))


func _draw_poison(c: Vector2, r: float, w: float) -> void:
	var col: Color = status_color("poison")
	var pts := PackedVector2Array()
	var bc: Vector2 = c + Vector2(0, r * 0.3)
	var br: float = r * 0.66
	for i: int in 25:
		var a: float = deg_to_rad(-35.0 + 250.0 * float(i) / 24.0)
		pts.append(bc + Vector2(cos(a), sin(a)) * br)
	pts.append(c + Vector2(0, -r))
	_shape(pts, col.lightened(0.4), col.darkened(0.2), w)
	_gloss(bc + Vector2(-0.35, -0.3) * br, r * 0.13)
	for b: Array in [[Vector2(0.75, -0.55), 0.16], [Vector2(0.95, -0.15), 0.1], [Vector2(-0.8, -0.35), 0.12]]:
		var p: Vector2 = c + (b[0] as Vector2) * r
		var br2: float = r * float(b[1])
		draw_circle(p, br2 + w * 0.5, UiStyle.OUTLINE, true, -1.0, true)
		draw_circle(p, br2, col.lightened(0.3), true, -1.0, true)


func _draw_freeze(c: Vector2, r: float, w: float) -> void:
	var col: Color = status_color("freeze")
	for side: float in [-1.0, 1.0]:
		var sc: Vector2 = c + Vector2(side * r * 0.62, r * 0.35)
		_crystal(sc, r * 0.5, col, w * 0.8)
	_crystal(c, r, col, w)
	_star(c + Vector2(r * 0.75, -r * 0.75), r * 0.2, Color.WHITE)


func _crystal(c: Vector2, r: float, col: Color, w: float) -> void:
	var pts: PackedVector2Array = _pts(CRYSTAL, c, r)
	_shape(pts, col.lightened(0.5), col.darkened(0.3), 0.0)
	# Left facets lighter, right facets darker, central ridge.
	draw_colored_polygon(PackedVector2Array([pts[0], pts[5], pts[4], pts[3], c]), Color(1, 1, 1, 0.35))
	draw_colored_polygon(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], c]), Color(0, 0.2, 0.4, 0.12))
	draw_line(pts[0], pts[3], Color(1, 1, 1, 0.6), maxf(1.0, w * 0.5), true)
	var loop: PackedVector2Array = pts.duplicate()
	loop.append(pts[0])
	draw_polyline(loop, UiStyle.OUTLINE, w, true)


## Little bright sparks around a centre (paralysis).
func _sparks(c: Vector2, r: float, col: Color, w: float) -> void:
	for a: float in [-0.3, 2.6, 3.6]:
		var p: Vector2 = c + Vector2(cos(a), sin(a)) * r * 0.95
		var q: Vector2 = c + Vector2(cos(a), sin(a)) * r * 1.2
		draw_line(p, q, UiStyle.OUTLINE, w * 1.8, true)
		draw_line(p, q, col.lightened(0.4), w * 0.9, true)


## Polygon with a vertical gradient (`top` -> `bottom`) and a dark outline (`w` 0 = none).
func _shape(pts: PackedVector2Array, top: Color, bottom: Color, w: float) -> void:
	if pts.size() < 3:
		return
	var y0: float = INF
	var y1: float = -INF
	for p: Vector2 in pts:
		y0 = minf(y0, p.y)
		y1 = maxf(y1, p.y)
	var cols := PackedColorArray()
	for p: Vector2 in pts:
		cols.append(top.lerp(bottom, clampf((p.y - y0) / maxf(y1 - y0, 1.0), 0.0, 1.0)))
	if w > 0.0:
		var loop: PackedVector2Array = pts.duplicate()
		loop.append(pts[0])
		draw_polyline(loop, UiStyle.OUTLINE, w * 2.0, true)
	draw_polygon(pts, cols)
	if w > 0.0:
		var loop2: PackedVector2Array = pts.duplicate()
		loop2.append(pts[0])
		draw_polyline(loop2, UiStyle.OUTLINE, w, true)


func _gloss(p: Vector2, rad: float) -> void:
	draw_set_transform(p, -0.5, Vector2(1.0, 0.6))
	draw_circle(Vector2.ZERO, rad, GLOSS, true, -1.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Four-point sparkle.
func _star(p: Vector2, rad: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i: int in 8:
		var a: float = -PI * 0.5 + TAU * float(i) / 8.0
		pts.append(p + Vector2(cos(a), sin(a)) * rad * (1.0 if i % 2 == 0 else 0.3))
	var loop: PackedVector2Array = pts.duplicate()
	loop.append(pts[0])
	draw_polyline(loop, Color(UiStyle.OUTLINE, 0.7), maxf(1.0, rad * 0.18), true)
	draw_colored_polygon(pts, col)


static func _pts(norm: Array[Vector2], c: Vector2, r: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for v: Vector2 in norm:
		out.append(c + v * r)
	return out
