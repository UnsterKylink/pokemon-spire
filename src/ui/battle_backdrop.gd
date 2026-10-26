class_name BattleBackdrop
extends Control
## Story 020: full-screen battle backdrop drawn in code (no image files), art bible §6: vertical sky gradient,
## optional horizon glow, 1-3 silhouette layers, a ground band with a light detail pattern, one soft ellipse
## "platform" under each fighter, a 25 % dark band under the hand and up to 30 slow ambient particles.
## Every colour / shape count comes from assets/data/backdrops.json (one entry per backdrop id; unknown ids
## fall back to "route"). Display only: owns no game state. BattleScreen places the platforms (set_platforms).

const DATA_PATH: String = "res://assets/data/backdrops.json"
const ELLIPSE_POINTS: int = 40

## backdrops.json root cache (pure display data), filled on first use.
static var _root: Dictionary = {}
static var _loaded: bool = false

var _id: String = ""
var _def: Dictionary = {}
var _platforms: Array[Rect2] = []
var _hand_top: float = -1.0
var _particles: Array[Dictionary] = []
var _particle_def: Dictionary = {}
var _motion: bool = true
var _particle_layer: Control
var _layer_has_accent: bool = false


func _ready() -> void:
	_particle_layer = Control.new()
	_particle_layer.name = "Particles"
	_particle_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_particle_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_particle_layer.draw.connect(_draw_particles)
	add_child(_particle_layer)
	resized.connect(_on_resized)
	if _id.is_empty():
		set_backdrop("")


## Backdrop id actually used for `id` ("" / unknown -> the data fallback, "route").
static func resolve_id(id: String) -> String:
	var all: Dictionary = _backdrops()
	if all.has(id):
		return id
	return String(_data().get("fallback", "route"))


## All backdrop ids defined in backdrops.json.
static func get_ids() -> Array[String]:
	var ids: Array[String] = []
	for k: Variant in _backdrops():
		ids.append(String(k))
	return ids


## Shows backdrop `id` (a type id, "route", "league", "ethernatos", "legendary"); unknown ids use the fallback.
func set_backdrop(id: String) -> void:
	_id = resolve_id(id)
	_def = _backdrops().get(_id, {})
	_particle_def = _def.get("particles", {}) if _def.get("particles", null) is Dictionary else {}
	_seed_particles()
	queue_redraw()
	if _particle_layer != null:
		_particle_layer.queue_redraw()


## Backdrop id currently shown (after fallback).
func get_backdrop_id() -> String:
	return _id


## One platform ellipse per rect (local coordinates: x/width = the fighter's sprite, y = its feet).
func set_platforms(rects: Array[Rect2]) -> void:
	if rects == _platforms:
		return
	_platforms = rects.duplicate()
	queue_redraw()


## Top of the hand area (local y); below it the backdrop is darkened by `hand_shade`. -1 = no band.
func set_hand_top(y: float) -> void:
	if is_equal_approx(y, _hand_top):
		return
	_hand_top = y
	queue_redraw()


## Turns the ambient particle drift on / off (reduced motion: particles stay still).
func set_motion_enabled(enabled: bool) -> void:
	_motion = enabled
	set_process(enabled and not _particles.is_empty())


func _process(delta: float) -> void:
	if not _motion or _particles.is_empty():
		return
	var w: float = maxf(size.x, 1.0)
	var h: float = maxf(_shade_top(), 1.0)
	for p: Dictionary in _particles:
		var pos: Vector2 = p["pos"]
		pos += (p["vel"] as Vector2) * delta
		pos.x = fposmod(pos.x, w)
		pos.y = fposmod(pos.y, h)
		p["pos"] = pos
	_particle_layer.queue_redraw()


func _on_resized() -> void:
	_seed_particles()
	queue_redraw()


# --- Data --------------------------------------------------------------------------------------------

static func _data() -> Dictionary:
	if not _loaded:
		_loaded = true
		var f: FileAccess = FileAccess.open(DATA_PATH, FileAccess.READ)
		if f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				_root = parsed
		if _root.is_empty():
			push_error("BattleBackdrop: cannot read %s" % DATA_PATH)
	return _root


static func _backdrops() -> Dictionary:
	var b: Variant = _data().get("backdrops", {})
	return b if b is Dictionary else {}


func _num(key: String, default: float) -> float:
	return float(_data().get(key, default))


func _color(v: Variant, default: Color) -> Color:
	var s: String = String(v) if v != null else ""
	return Color(s) if s.begins_with("#") else default


func _horizon_y() -> float:
	return roundf(size.y * _num("horizon", 0.47))


func _shade_top() -> float:
	return _hand_top if _hand_top > 0.0 else size.y


func _sky_colors() -> Array[Color]:
	var sky: Array = _def.get("sky", ["#7EC8F2", "#D8F1FF"])
	return [_color(sky[0], Color("#7EC8F2")), _color(sky[sky.size() - 1], Color("#D8F1FF"))]


func _ground_colors() -> Array[Color]:
	var g: Array = _def.get("ground", ["#7AC74C"])
	var top: Color = _color(g[0], Color("#7AC74C"))
	var bottom: Color = _color(g[1], top) if g.size() > 1 else top.darkened(_num("ground_darken", 0.22))
	return [top, bottom]


# --- Drawing -----------------------------------------------------------------------------------------

func _draw() -> void:
	if _def.is_empty() or size.x <= 0.0:
		return
	var w: float = size.x
	var h: float = size.y
	var hy: float = _horizon_y()
	var sky: Array[Color] = _sky_colors()
	var ground: Array[Color] = _ground_colors()
	_gradient_rect(Rect2(0, 0, w, hy), sky[0], sky[1])
	if _def.has("glow"):
		var glow: Color = _color(_def["glow"], Color.WHITE)
		_gradient_rect(Rect2(0, hy - 120.0, w, 120.0), Color(glow, 0.0), Color(glow, 0.45))
	var layers: Array = _def.get("layers", [])
	for i: int in layers.size():
		if layers[i] is Dictionary:
			_draw_layer(layers[i], i, sky[1], ground[0], hy)
	_gradient_rect(Rect2(0, hy, w, h - hy), ground[0], ground[1])
	draw_line(Vector2(0, hy), Vector2(w, hy), ground[0].darkened(0.25), 2.0)
	_draw_ground_detail(String(_def.get("ground_detail", "none")), ground[0], hy)
	_draw_platforms(ground[0])
	if _hand_top > 0.0:
		var shade: float = _num("hand_shade", 0.25)
		_gradient_rect(Rect2(0, _hand_top - 24.0, w, 24.0), Color(0, 0, 0, 0), Color(0, 0, 0, shade))
		draw_rect(Rect2(0, _hand_top, w, h - _hand_top), Color(0, 0, 0, shade))


func _gradient_rect(r: Rect2, top: Color, bottom: Color) -> void:
	var pts := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	draw_polygon(pts, PackedColorArray([top, top, bottom, bottom]))


func _ellipse(center: Vector2, rx: float, ry: float, from_angle: float = 0.0, to_angle: float = TAU) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in ELLIPSE_POINTS + 1:
		var a: float = lerpf(from_angle, to_angle, float(i) / ELLIPSE_POINTS)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _fill(pts: PackedVector2Array, c: Color) -> void:
	if pts.size() >= 3:
		draw_colored_polygon(pts, c)


func _draw_platforms(ground_top: Color) -> void:
	var fill: Color = ground_top.lightened(_num("platform_lighten", 0.18))
	var rim: Color = ground_top.darkened(_num("platform_rim_darken", 0.4))
	for r: Rect2 in _platforms:
		var c := Vector2(r.position.x + r.size.x * 0.5, r.position.y)
		var rx: float = r.size.x * 0.5
		var ry: float = maxf(rx * 0.22, 10.0)
		_fill(_ellipse(c + Vector2(0, 5), rx + 4.0, ry + 3.0), Color(0, 0, 0, 0.18))
		_fill(_ellipse(c, rx, ry), rim)
		_fill(_ellipse(c - Vector2(0, 3), rx - 6.0, ry - 4.0), fill)
		_fill(_ellipse(c - Vector2(rx * 0.15, ry * 0.35), rx * 0.45, ry * 0.25), Color(1, 1, 1, 0.16))


func _draw_ground_detail(kind: String, top: Color, hy: float) -> void:
	var w: float = size.x
	var h: float = size.y
	var line: Color = Color(top.darkened(0.18), 0.55)
	match kind:
		"stripes":
			for i: int in 6:
				var y: float = hy + (h - hy) * pow(float(i + 1) / 7.0, 1.6)
				draw_line(Vector2(0, y), Vector2(w, y), Color(top.lightened(0.15), 0.5), 2.0)
		"tiles":
			for i: int in 6:
				var y: float = hy + (h - hy) * pow(float(i + 1) / 7.0, 1.5)
				draw_line(Vector2(0, y), Vector2(w, y), line, 2.0)
			for j: int in 15:
				var x_top: float = w * 0.5 + (j - 7) * 70.0
				var x_bot: float = w * 0.5 + (j - 7) * 260.0
				draw_line(Vector2(x_top, hy), Vector2(x_bot, h), line, 2.0)
		"waves":
			for i: int in 5:
				var y: float = hy + 14.0 + i * 26.0 * (1.0 + i * 0.4)
				var pts := PackedVector2Array()
				for k: int in 65:
					var x: float = w * k / 64.0
					pts.append(Vector2(x, y + sin(x / 38.0 + i * 1.7) * (3.0 + i)))
				draw_polyline(pts, Color(1, 1, 1, 0.45), 2.0, true)
		"grass":
			var rng := RandomNumberGenerator.new()
			rng.seed = 77
			for i: int in 70:
				var x: float = rng.randf() * w
				var y: float = hy + 10.0 + pow(rng.randf(), 1.4) * (h - hy - 10.0)
				var s: float = 4.0 + 8.0 * (y - hy) / (h - hy)
				draw_line(Vector2(x, y), Vector2(x - s * 0.4, y - s), line, 2.0)
				draw_line(Vector2(x, y), Vector2(x + s * 0.4, y - s), line, 2.0)
		"cracks":
			var rng2 := RandomNumberGenerator.new()
			rng2.seed = 91
			for i: int in 16:
				var p := Vector2(rng2.randf() * w, hy + 12.0 + rng2.randf() * (h - hy - 20.0))
				var pts2 := PackedVector2Array([p])
				for k: int in 3:
					p += Vector2(rng2.randf_range(14, 34), rng2.randf_range(-8, 8))
					pts2.append(p)
				draw_polyline(pts2, line, 2.0, true)


func _draw_layer(layer: Dictionary, index: int, sky_low: Color, ground_top: Color, hy: float) -> void:
	var default_color: Color = sky_low.darkened(_num("far_darken", 0.18)) if index == 0 \
			else ground_top.darkened(_num("near_darken", 0.22))
	var c: Color = _color(layer.get("color", null), default_color)
	c.a = float(layer.get("alpha", 0.6))
	var accent: Color = _color(layer.get("accent", null), c.lightened(0.4))
	accent.a = minf(1.0, c.a + 0.2)
	_layer_has_accent = layer.has("accent")
	var shape: String = String(layer.get("shape", "hills"))
	var count: int = maxi(1, int(layer.get("count", 4)))
	var hgt: float = float(layer.get("height", 100))
	var base: float = hy * float(layer.get("base", 1.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(layer.get("seed", index + 1))
	var w: float = size.x
	if shape == "waves":
		_shape_waves(base, hgt, c)
		return
	var tops: Array[Vector2] = []
	for i: int in count:
		var x: float = (i + 0.5 + rng.randf_range(-0.28, 0.28)) * w / count
		var hh: float = hgt * rng.randf_range(0.75, 1.15)
		var y: float = base + (rng.randf_range(-0.12, 0.12) * hy if base < hy * 0.99 else 0.0)
		tops.append(_draw_shape(shape, x, y, hh, c, accent, rng))
	if shape == "pylons":
		for i: int in tops.size() - 1:
			_cable(tops[i], tops[i + 1], c)


## Draws one silhouette standing at (x, y) of height h; returns its attachment point (pylons: cable top).
func _draw_shape(shape: String, x: float, y: float, h: float, c: Color, accent: Color, rng: RandomNumberGenerator) -> Vector2:
	match shape:
		"hills":
			_fill(_ellipse(Vector2(x, y), h * 1.6, h, PI, TAU), c)
		"dunes":
			_fill(_ellipse(Vector2(x, y), h * 2.6, h * 0.7, PI, TAU), c)
		"rocks":
			_fill(_ellipse(Vector2(x, y), h * 0.75, h * 0.6, PI, TAU), c)
			_fill(_ellipse(Vector2(x + h * 0.55, y), h * 0.45, h * 0.38, PI, TAU), c)
		"trees":
			draw_rect(Rect2(x - h * 0.06, y - h * 0.5, h * 0.12, h * 0.5), c)
			_fill(_ellipse(Vector2(x, y - h * 0.68), h * 0.3, h * 0.3), c)
			_fill(_ellipse(Vector2(x - h * 0.18, y - h * 0.52), h * 0.2, h * 0.2), c)
			_fill(_ellipse(Vector2(x + h * 0.18, y - h * 0.55), h * 0.2, h * 0.2), c)
		"pines":
			draw_rect(Rect2(x - h * 0.04, y - h * 0.2, h * 0.08, h * 0.2), c)
			for k: int in 3:
				var by: float = y - h * 0.15 - k * h * 0.25
				var hw: float = h * (0.28 - k * 0.06)
				_fill(PackedVector2Array([Vector2(x - hw, by), Vector2(x + hw, by), Vector2(x, by - h * 0.4)]), c)
		"houses":
			var hw2: float = h * 0.45
			draw_rect(Rect2(x - hw2, y - h * 0.6, hw2 * 2.0, h * 0.6), c)
			_fill(PackedVector2Array([Vector2(x - hw2 - 8, y - h * 0.6), Vector2(x + hw2 + 8, y - h * 0.6), Vector2(x, y - h)]), accent)
			draw_rect(Rect2(x - h * 0.08, y - h * 0.3, h * 0.16, h * 0.3), c.darkened(0.3))
		"volcanoes":
			var top_w: float = h * 0.28
			_fill(PackedVector2Array([Vector2(x - h * 1.4, y), Vector2(x - top_w, y - h), Vector2(x + top_w, y - h), Vector2(x + h * 1.4, y)]), c)
			_fill(_ellipse(Vector2(x, y - h), top_w, h * 0.06), accent)
			_fill(PackedVector2Array([Vector2(x - top_w * 0.5, y - h), Vector2(x + top_w * 0.2, y - h), Vector2(x + h * 0.2, y - h * 0.45), Vector2(x, y - h * 0.5)]), Color(accent, accent.a * 0.8))
			_fill(_ellipse(Vector2(x, y - h - 10), top_w * 1.6, 26), Color(accent, 0.25))
		"peaks":
			_fill(PackedVector2Array([Vector2(x - h * 0.85, y), Vector2(x, y - h), Vector2(x + h * 0.85, y)]), c)
			if _layer_has_accent:
				_fill(PackedVector2Array([Vector2(x - h * 0.22, y - h * 0.74), Vector2(x, y - h), Vector2(x + h * 0.22, y - h * 0.74),
						Vector2(x + h * 0.08, y - h * 0.68), Vector2(x - h * 0.06, y - h * 0.76)]), accent)
		"spikes":
			for k: int in 3:
				var sx: float = x + (k - 1) * h * 0.3
				var sh: float = h * (1.0 if k == 1 else 0.6)
				_fill(PackedVector2Array([Vector2(sx - h * 0.13, y), Vector2(sx + rng.randf_range(-6, 6), y - sh), Vector2(sx + h * 0.13, y)]), c)
		"cliffs":
			var pts := PackedVector2Array([Vector2(x - h * 0.8, y)])
			var steps: int = 5
			for k: int in steps + 1:
				var px: float = x - h * 0.7 + k * h * 1.4 / steps
				pts.append(Vector2(px, y - h * rng.randf_range(0.7, 1.0)))
			pts.append(Vector2(x + h * 0.8, y))
			_fill(pts, c)
		"cactus":
			var tw: float = h * 0.16
			draw_rect(Rect2(x - tw * 0.5, y - h, tw, h), c)
			_fill(_ellipse(Vector2(x, y - h), tw * 0.5, tw * 0.5), c)
			draw_rect(Rect2(x - tw * 1.6, y - h * 0.62, tw * 1.1, tw * 0.6), c)
			draw_rect(Rect2(x - tw * 1.6, y - h * 0.85, tw * 0.6, h * 0.25), c)
			draw_rect(Rect2(x + tw * 0.5, y - h * 0.45, tw * 1.1, tw * 0.6), c)
			draw_rect(Rect2(x + tw * 1.0, y - h * 0.7, tw * 0.6, h * 0.25), c)
		"clouds":
			var r: float = h * 0.5
			_fill(_ellipse(Vector2(x, y - r * 0.6), r * 1.1, r * 0.9), c)
			_fill(_ellipse(Vector2(x - r * 1.1, y - r * 0.3), r * 0.8, r * 0.6), c)
			_fill(_ellipse(Vector2(x + r * 1.1, y - r * 0.3), r * 0.85, r * 0.65), c)
			_fill(_ellipse(Vector2(x, y), r * 2.0, r * 0.4), c)
		"pillars", "floating":
			var pw: float = h * 0.18
			var bottom: float = y - (h * 0.25 if shape == "floating" else 0.0)
			draw_rect(Rect2(x - pw * 0.5, bottom - h, pw, h), c)
			draw_rect(Rect2(x - pw * 0.8, bottom - h - h * 0.07, pw * 1.6, h * 0.07), c)
			if shape == "pillars":
				draw_rect(Rect2(x - pw * 0.8, bottom - h * 0.06, pw * 1.6, h * 0.06), c)
			else:
				_fill(PackedVector2Array([Vector2(x - pw * 0.5, bottom), Vector2(x + pw * 0.5, bottom), Vector2(x, bottom + h * 0.15)]), c)
		"pipes":
			var pr: float = h * 0.1
			draw_rect(Rect2(x - pr, y - h, pr * 2.0, h), c)
			draw_rect(Rect2(x - pr, y - h, h * 0.9, pr * 2.0), c)
			draw_rect(Rect2(x - pr * 1.4, y - h * 0.5, pr * 2.8, pr * 0.8), c.darkened(0.2))
			_fill(_ellipse(Vector2(x + h * 0.9, y - h + pr), pr * 1.3, pr * 1.3), c)
		"trunks":
			var tw2: float = h * 0.12
			draw_rect(Rect2(x - tw2 * 0.5, y - h * 1.6, tw2, h * 1.6), c)
			_fill(PackedVector2Array([Vector2(x, y - h * 0.7), Vector2(x + h * 0.35, y - h * 0.95), Vector2(x + h * 0.36, y - h * 0.9), Vector2(x, y - h * 0.6)]), c)
			_fill(_ellipse(Vector2(x, y), tw2 * 1.2, tw2 * 0.3, PI, TAU), c)
		"webs":
			var cen := Vector2(x, y - h * 0.5)
			for k: int in 8:
				var a: float = TAU * k / 8.0
				draw_line(cen, cen + Vector2(cos(a), sin(a)) * h * 0.5, c, 1.5)
			for ring: int in 3:
				var rr: float = h * 0.15 * (ring + 1)
				var ring_pts := PackedVector2Array()
				for k: int in 9:
					var a2: float = TAU * k / 8.0
					ring_pts.append(cen + Vector2(cos(a2), sin(a2)) * rr)
				draw_polyline(ring_pts, c, 1.5, true)
		"tombs":
			var tw3: float = h * 0.4
			draw_rect(Rect2(x - tw3 * 0.5, y - h * 0.6, tw3, h * 0.6), c)
			_fill(_ellipse(Vector2(x, y - h * 0.6), tw3 * 0.5, tw3 * 0.45, PI, TAU), c)
			if rng.randf() < 0.4:
				draw_rect(Rect2(x - 3, y - h * 1.15, 6, h * 0.4), c)
				draw_rect(Rect2(x - h * 0.13, y - h * 1.02, h * 0.26, 6), c)
		"towers":
			var tw4: float = h * 0.28
			draw_rect(Rect2(x - tw4 * 0.5, y - h, tw4, h), c)
			_fill(PackedVector2Array([Vector2(x - tw4 * 0.7, y - h), Vector2(x + tw4 * 0.7, y - h), Vector2(x, y - h * 1.3)]), c)
			draw_rect(Rect2(x - tw4 * 0.15, y - h * 0.8, tw4 * 0.3, tw4 * 0.4), Color(accent, 0.7))
		"buildings":
			var bw: float = h * rng.randf_range(0.4, 0.6)
			draw_rect(Rect2(x - bw * 0.5, y - h, bw, h), c)
			for row: int in int(h / 26.0):
				for col: int in 2:
					if rng.randf() < 0.45:
						draw_rect(Rect2(x - bw * 0.3 + col * bw * 0.36, y - h + 12 + row * 26, bw * 0.22, 10), Color(accent, 0.55))
		"pylons":
			var pw2: float = h * 0.22
			var top := Vector2(x, y - h)
			draw_line(Vector2(x - pw2, y), top, c, 4.0)
			draw_line(Vector2(x + pw2, y), top, c, 4.0)
			for k: int in 4:
				var t: float = 0.2 + k * 0.2
				var hw3: float = pw2 * (1.0 - t)
				draw_line(Vector2(x - hw3, y - h * t), Vector2(x + hw3, y - h * t), c, 3.0)
				draw_line(Vector2(x - hw3, y - h * t), Vector2(x + pw2 * (1.0 - t - 0.2), y - h * (t + 0.2)), c, 2.0)
			draw_line(top + Vector2(-pw2 * 0.9, h * 0.12), top + Vector2(pw2 * 0.9, h * 0.12), c, 4.0)
			return top + Vector2(0, h * 0.12)
		"gears":
			var gr: float = h * 0.4
			var cen2 := Vector2(x, y - gr * 0.9)
			var teeth := PackedVector2Array()
			for k: int in 24:
				var a3: float = TAU * k / 24.0
				teeth.append(cen2 + Vector2(cos(a3), sin(a3)) * (gr if k % 2 == 0 else gr * 0.82))
			_fill(teeth, c)
			_fill(_ellipse(cen2, gr * 0.3, gr * 0.3), c.darkened(0.35))
		"beams":
			var bh: float = h * 0.1
			draw_rect(Rect2(x - h * 0.6, y - h, bh, h), c)
			draw_rect(Rect2(x + h * 0.5, y - h, bh, h), c)
			draw_rect(Rect2(x - h * 0.8, y - h, h * 1.7, bh), c)
			draw_line(Vector2(x - h * 0.55, y - h * 0.9), Vector2(x + h * 0.5, y - h * 0.1), c, bh * 0.6)
		"arches":
			draw_arc(Vector2(x, y), h * 0.8, PI, TAU, 32, c, h * 0.16, true)
		"flowers":
			draw_line(Vector2(x, y), Vector2(x, y - h * 0.7), c, 6.0)
			_fill(_ellipse(Vector2(x + h * 0.1, y - h * 0.35), h * 0.12, h * 0.05), c)
			var fc := Vector2(x, y - h * 0.8)
			for k: int in 6:
				var a4: float = TAU * k / 6.0
				_fill(_ellipse(fc + Vector2(cos(a4), sin(a4)) * h * 0.13, h * 0.1, h * 0.1), c)
			_fill(_ellipse(fc, h * 0.09, h * 0.09), accent)
		"banners":
			var bw2: float = h * 0.32
			draw_rect(Rect2(x - bw2 * 0.6, y - h - 6, bw2 * 1.2, 6), c)
			_fill(PackedVector2Array([Vector2(x - bw2 * 0.5, y - h), Vector2(x + bw2 * 0.5, y - h), Vector2(x + bw2 * 0.5, y),
					Vector2(x, y - bw2 * 0.4), Vector2(x - bw2 * 0.5, y)]), c)
			_fill(_ellipse(Vector2(x, y - h * 0.55), bw2 * 0.22, bw2 * 0.22), accent)
		"rings":
			draw_arc(Vector2(x, y), h * 0.5, 0.0, TAU, 48, c, 6.0, true)
			draw_arc(Vector2(x, y), h * 0.5 + 10, 0.3, 2.2, 24, Color(c, c.a * 0.5), 3.0, true)
		"crystals":
			var cw: float = h * 0.18
			var tilt: float = rng.randf_range(-0.25, 0.25) * h
			var pts3 := PackedVector2Array([Vector2(x - cw, y), Vector2(x - cw * 0.8 + tilt * 0.6, y - h * 0.8), Vector2(x + tilt, y - h),
					Vector2(x + cw * 0.8 + tilt * 0.6, y - h * 0.8), Vector2(x + cw, y)])
			_fill(pts3, c)
			draw_line(Vector2(x, y), Vector2(x + tilt, y - h), Color(accent, 0.6), 2.0)
		"moon":
			_fill(_ellipse(Vector2(x, y), h * 0.5 + 14, h * 0.5 + 14), Color(c, 0.18))
			_fill(_ellipse(Vector2(x, y), h * 0.5, h * 0.5), c)
	return Vector2(x, y - h)


func _shape_waves(base: float, amp: float, c: Color) -> void:
	var w: float = size.x
	var pts := PackedVector2Array([Vector2(0, base)])
	for k: int in 65:
		var x: float = w * k / 64.0
		pts.append(Vector2(x, base - amp * 0.5 - sin(x / 60.0) * amp * 0.25))
	pts.append(Vector2(w, base))
	_fill(pts, c)


func _cable(a: Vector2, b: Vector2, c: Color) -> void:
	var pts := PackedVector2Array()
	for k: int in 17:
		var t: float = k / 16.0
		pts.append(a.lerp(b, t) + Vector2(0, sin(t * PI) * 26.0))
	draw_polyline(pts, c, 2.0, true)


# --- Particles ---------------------------------------------------------------------------------------

func _seed_particles() -> void:
	_particles.clear()
	if _particle_def.is_empty() or size.x <= 0.0:
		set_process(false)
		return
	var n: int = mini(int(_particle_def.get("count", 0)), int(_num("max_particles", 30)))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(_id)
	var vel := Vector2(float(_particle_def.get("vx", 0.0)), float(_particle_def.get("vy", 0.0)))
	for i: int in n:
		_particles.append({"pos": Vector2(rng.randf() * size.x, rng.randf() * _shade_top()),
				"vel": vel * rng.randf_range(0.6, 1.4), "size": float(_particle_def.get("size", 2.5)) * rng.randf_range(0.7, 1.3),
				"alpha": rng.randf_range(0.45, 0.9)})
	set_process(_motion and not _particles.is_empty())


func _draw_particles() -> void:
	if _particles.is_empty():
		return
	var col: Color = _color(_particle_def.get("color", null), Color.WHITE)
	for p: Dictionary in _particles:
		var s: float = p["size"]
		_particle_layer.draw_circle(p["pos"], s * 1.8, Color(col, float(p["alpha"]) * 0.25))
		_particle_layer.draw_circle(p["pos"], s, Color(col, float(p["alpha"])))
