class_name AttackFx
extends RefCounted
## Story 021: attack / status / buff effects drawn in code (no image files), Pokémon-move look: bright cel-shaded
## shapes with a dark outline, a white gloss and a soft additive glow layer. Every effect is a temporary Node2D (plus
## an additive child for the glow) added to `parent` with z_index FX_Z; a Tween drives its progress `t` 0..1 and frees
## it at the end (nothing leaks; freeing the parent mid-play frees the effect and its tween with it).
## Pure visual: no game state, no signals. All numbers / colours / shapes come from assets/data/attack_fx.json (one
## entry per type id of types.json + "default", plus "status" and "buff" tables; see its _doc for the schema).
## Speed: every play_* divides its duration by speed_scale; speed_scale <= 0 means instant (returns 0.0, spawns nothing).
## Implements: story-021 (animations d'attaque), design/art-bible.md (type colours).

const DATA_PATH: String = "res://assets/data/attack_fx.json"
const TYPES_PATH: String = "res://assets/data/types.json"
const STATUSES_PATH: String = "res://assets/data/statuses.json"
const DEFAULT_ID: String = "default"
const FX_Z: int = 50
const MAX_PARTICLES: int = 60
## duration_of kinds.
const KIND_PROJECTILE: String = "projectile"
const KIND_IMPACT: String = "impact"
const KIND_STATUS: String = "status"
const KIND_BUFF: String = "buff"
const GLOW_SHAPES: Array[String] = ["ember", "star4", "bolt", "flame"]

# Normalised shapes (unit radius, y down); same family as EffectArt.
const BOLT: Array[Vector2] = [Vector2(0.2, -1.0), Vector2(-0.5, 0.1), Vector2(-0.05, 0.1), Vector2(-0.25, 1.0),
		Vector2(0.5, -0.15), Vector2(0.05, -0.15), Vector2(0.35, -1.0)]
const CRYSTAL: Array[Vector2] = [Vector2(0.0, -1.0), Vector2(0.5, -0.45), Vector2(0.5, 0.5), Vector2(0.0, 1.0),
		Vector2(-0.5, 0.5), Vector2(-0.5, -0.45)]
const ARROW: Array[Vector2] = [Vector2(0.0, -1.0), Vector2(0.78, -0.12), Vector2(0.32, -0.12), Vector2(0.32, 0.95),
		Vector2(-0.32, 0.95), Vector2(-0.32, -0.12), Vector2(-0.78, -0.12)]

static var _data: Dictionary = {}
static var _types: Dictionary = {}
static var _statuses: Dictionary = {}
static var _loaded: bool = false
static var _halo_texture: Texture2D
static var _add_material: CanvasItemMaterial


## Node that paints one effect at progress `t` (0..1) through `paint` (called as paint(node, t, is_glow_layer)).
class FxNode extends Node2D:
	var t: float = 0.0:
		set(v):
			t = v
			queue_redraw()
			if twin != null:
				twin.t = v
	var glow: bool = false
	var paint: Callable
	var twin: FxNode

	func _draw() -> void:
		if paint.is_valid():
			paint.call(self, t, glow)


# ------------------------------------------------------------------------------------------------ public API

## Travelling part of the `type_id` attack from `from_pos` to `to_pos` (coordinates of `parent`). Returns its duration.
static func play_projectile(parent: Node, type_id: String, from_pos: Vector2, to_pos: Vector2, speed_scale: float = 1.0) -> float:
	if speed_scale <= 0.0:
		return 0.0
	_ensure_loaded()
	var def: Dictionary = _type_def(type_id)
	var pd: Dictionary = _dict(def, "projectile")
	var dur: float = _f(pd, "duration", 0.45) / speed_scale
	if not _can_spawn(parent):
		return dur
	var delta: Vector2 = to_pos - from_pos
	var length: float = maxf(delta.length(), 1.0)
	_spawn(parent, from_pos, delta.angle(), dur, _paint_proj.bind(pd, _type_palette(def, type_id), length))
	return dur


## Burst at the target. `strength` (clamped 0.6..1.6) scales the size. Returns its duration.
static func play_impact(parent: Node, type_id: String, at_pos: Vector2, speed_scale: float = 1.0, strength: float = 1.0) -> float:
	if speed_scale <= 0.0:
		return 0.0
	_ensure_loaded()
	var def: Dictionary = _type_def(type_id)
	var d: Dictionary = _dict(def, "impact")
	var dur: float = _f(d, "duration", 0.55) / speed_scale
	if not _can_spawn(parent):
		return dur
	_spawn(parent, at_pos, 0.0, dur, _paint_layers.bind(d, _type_palette(def, type_id), clampf(strength, 0.6, 1.6)))
	return dur


## Short effect when the status `status_id` (statuses.json id) is applied; colours come from statuses.json.
static func play_status(parent: Node, status_id: String, at_pos: Vector2, speed_scale: float = 1.0) -> float:
	if speed_scale <= 0.0:
		return 0.0
	_ensure_loaded()
	var table: Dictionary = _dict(_data, "status")
	var d: Dictionary = _dict(table, status_id) if table.has(status_id) else _dict(table, DEFAULT_ID)
	var dur: float = _f(d, "duration", 0.9) / speed_scale
	if not _can_spawn(parent):
		return dur
	var base: Color = Color(String(_dict(_statuses, status_id).get("color", d.get("color", "#FFFFFF"))))
	_spawn(parent, at_pos, 0.0, dur, _paint_layers.bind(d, _make_palette(base, base.lightened(0.55), base.darkened(0.45)), 1.0))
	return dur


## Buff feedback; `kind` in "block", "heal", "strength", "energy" (anything else = "energy"). Returns its duration.
static func play_buff(parent: Node, kind: String, at_pos: Vector2, speed_scale: float = 1.0) -> float:
	if speed_scale <= 0.0:
		return 0.0
	_ensure_loaded()
	var table: Dictionary = _dict(_data, "buff")
	var d: Dictionary = _dict(table, kind) if table.has(kind) else _dict(table, "energy")
	var dur: float = _f(d, "duration", 0.9) / speed_scale
	if not _can_spawn(parent):
		return dur
	_spawn(parent, at_pos, 0.0, dur, _paint_layers.bind(d, _palette_from(_dict(d, "colors"), Color.WHITE), 1.0))
	return dur


## The 18 type ids of attack_fx.json (without "default"), in file order.
static func type_ids() -> Array[String]:
	_ensure_loaded()
	var ids: Array[String] = []
	for k: Variant in _dict(_data, "types"):
		if String(k) != DEFAULT_ID and not String(k).begins_with("_"):
			ids.append(String(k))
	return ids


## Base duration (seconds at speed 1) of an effect: `kind` is KIND_PROJECTILE / KIND_IMPACT (id = type id),
## KIND_STATUS (id = status id) or KIND_BUFF (id = buff kind). 0.0 when unknown.
static func duration_of(id: String, kind: String) -> float:
	_ensure_loaded()
	match kind:
		KIND_PROJECTILE:
			return _f(_dict(_type_def(id), "projectile"), "duration", 0.45)
		KIND_IMPACT:
			return _f(_dict(_type_def(id), "impact"), "duration", 0.55)
		KIND_STATUS:
			var st: Dictionary = _dict(_data, "status")
			return _f(_dict(st, id) if st.has(id) else _dict(st, DEFAULT_ID), "duration", 0.9)
		KIND_BUFF:
			var bf: Dictionary = _dict(_data, "buff")
			return _f(_dict(bf, id) if bf.has(id) else _dict(bf, "energy"), "duration", 0.9)
	return 0.0


# ------------------------------------------------------------------------------------------------ plumbing

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_data = _read_json(DATA_PATH)
	_types = _dict(_read_json(TYPES_PATH), "types")
	_statuses = _dict(_read_json(STATUSES_PATH), "statuses")


static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func _dict(d: Dictionary, key: String) -> Dictionary:
	var v: Variant = d.get(key, {})
	return v if v is Dictionary else {}


static func _f(d: Dictionary, key: String, default: float) -> float:
	return float(d.get(key, default))


static func _type_def(type_id: String) -> Dictionary:
	var all: Dictionary = _dict(_data, "types")
	return _dict(all, type_id) if all.has(type_id) else _dict(all, DEFAULT_ID)


static func _type_palette(def: Dictionary, type_id: String) -> Dictionary:
	var cols: Dictionary = _dict(def, "colors")
	var fallback: Color = Color(String(_dict(_types, type_id).get("color", "#FFFFFF")))
	return _palette_from(cols, fallback)


static func _palette_from(cols: Dictionary, fallback: Color) -> Dictionary:
	var main: Color = Color(String(cols["main"])) if cols.has("main") else fallback
	var light: Color = Color(String(cols["light"])) if cols.has("light") else main.lightened(0.5)
	var dark: Color = Color(String(cols["dark"])) if cols.has("dark") else main.darkened(0.45)
	return _make_palette(main, light, dark)


static func _make_palette(main: Color, light: Color, dark: Color) -> Dictionary:
	return {"main": main, "light": light, "dark": dark, "white": Color.WHITE}


static func _can_spawn(parent: Node) -> bool:
	return parent != null and is_instance_valid(parent) and parent.is_inside_tree()


static func _additive() -> CanvasItemMaterial:
	if _add_material == null:
		_add_material = CanvasItemMaterial.new()
		_add_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _add_material


static func _spawn(parent: Node, pos: Vector2, rot: float, dur: float, painter: Callable) -> void:
	var base: FxNode = FxNode.new()
	base.position = pos
	base.rotation = rot
	base.z_index = FX_Z
	base.paint = painter
	var gl: FxNode = FxNode.new()
	gl.glow = true
	gl.paint = painter
	gl.z_index = 1
	gl.material = _additive()
	base.twin = gl
	base.add_child(gl)
	parent.add_child(base)
	var tw: Tween = base.create_tween()
	tw.tween_property(base, "t", 1.0, maxf(dur, 0.01))
	tw.tween_callback(base.queue_free)


# ------------------------------------------------------------------------------------------------ helpers

static func _h(i: int, salt: int = 0) -> float:
	return fposmod(sin(float(i) * 12.9898 + float(salt) * 78.233 + 1.7) * 43758.5453, 1.0)


static func _eo(x: float) -> float:
	var u: float = 1.0 - clampf(x, 0.0, 1.0)
	return 1.0 - u * u * u


## Ease-out with a little overshoot (scale pop).
static func _eb(x: float) -> float:
	var u: float = clampf(x, 0.0, 1.0) - 1.0
	return 1.0 + 2.2 * u * u * u + 1.2 * u * u


static func _a(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, c.a * clampf(a, 0.0, 1.0))


static func _c(pal: Dictionary, key: Variant) -> Color:
	var k: String = String(key)
	if k.begins_with("#"):
		return Color(k)
	return pal.get(k, pal["main"])


static func _halo_tex() -> Texture2D:
	if _halo_texture == null:
		var g: Gradient = Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.3, 0.65, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.12), Color(1, 1, 1, 0)])
		var tx: GradientTexture2D = GradientTexture2D.new()
		tx.gradient = g
		tx.width = 96
		tx.height = 96
		tx.fill = GradientTexture2D.FILL_RADIAL
		tx.fill_from = Vector2(0.5, 0.5)
		tx.fill_to = Vector2(1.0, 0.5)
		_halo_texture = tx
	return _halo_texture


static func _halo(ci: Node2D, pos: Vector2, r: float, col: Color) -> void:
	if r < 1.0 or col.a <= 0.01:
		return
	ci.draw_texture_rect(_halo_tex(), Rect2(pos - Vector2(r, r), Vector2(r, r) * 2.0), false, col)


static func _reset(ci: Node2D) -> void:
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _scaled(pts: Array[Vector2], s: float) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in pts:
		out.append(p * s)
	return out


## Filled polygon with an outline of visible width `ow`.
static func _poly(ci: Node2D, pts: PackedVector2Array, fill: Color, edge: Color, ow: float) -> void:
	if pts.size() < 3:
		return
	if ow > 0.0 and edge.a > 0.0:
		var cl: PackedVector2Array = pts.duplicate()
		cl.append(pts[0])
		cl.append(pts[1])
		ci.draw_polyline(cl, edge, ow * 2.0, true)
	ci.draw_colored_polygon(pts, fill)


## Pointed ellipse centred on the origin, spanning x -len/2..len/2.
static func _lens(len: float, w: float, n: int = 8) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for k: int in n + 1:
		var u: float = float(k) / float(n)
		pts.append(Vector2((u - 0.5) * len, -sin(u * PI) * w))
	for k: int in range(n - 1, 0, -1):
		var u: float = float(k) / float(n)
		pts.append(Vector2((u - 0.5) * len, sin(u * PI) * w))
	return pts


static func _star_pts(points: int, r: float, inner: float, rot: float) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for k: int in points * 2:
		var rr: float = r if k % 2 == 0 else r * inner
		var ang: float = rot + PI * float(k) / float(points)
		pts.append(Vector2(cos(ang), sin(ang)) * rr)
	return pts


static func _crescent(r: float, thick: float, half_arc: float, n: int = 10) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for k: int in n + 1:
		var th: float = -half_arc + 2.0 * half_arc * float(k) / float(n)
		pts.append(Vector2(r * cos(th), r * sin(th)))
	for k: int in range(n - 1, 0, -1):
		var th: float = -half_arc + 2.0 * half_arc * float(k) / float(n)
		var u: float = th / half_arc
		pts.append(Vector2(r * cos(th) - thick * (1.0 - u * u), r * sin(th)))
	return pts


static func _rock(r: float, seed: int) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	var n: int = 8
	for k: int in n:
		var ang: float = TAU * float(k) / float(n)
		pts.append(Vector2(cos(ang), sin(ang)) * r * (0.72 + 0.4 * _h(seed * 8 + k, 31)))
	return pts


## Cel-shaded ball: dark outline, fill, lighter inner, white gloss (gloss stays up-left whatever the node rotation).
static func _blob(ci: Node2D, pos: Vector2, r: float, col: Color, soft: bool) -> void:
	if r < 0.6:
		return
	var up: Vector2 = Vector2(-0.28, -0.34).rotated(-ci.global_rotation) * r
	if soft:
		ci.draw_circle(pos, r, Color(col, col.a * 0.8))
		ci.draw_circle(pos, r * 0.62, Color(col.lightened(0.55), col.a))
		ci.draw_circle(pos + up * 0.3, r * 0.3, Color(1, 1, 1, col.a))
	else:
		ci.draw_circle(pos, r + 2.2, Color(col.darkened(0.55), col.a))
		ci.draw_circle(pos, r, col)
		ci.draw_circle(pos + up * 0.35, r * 0.62, Color(col.lightened(0.45), col.a))
		ci.draw_circle(pos + up, r * 0.2, Color(1, 1, 1, col.a * 0.9))


## Small particle shapes (all centred on `pos`, +x = direction of motion unless noted).
static func _pshape(ci: Node2D, shape: String, pos: Vector2, rot: float, sz: float, col: Color) -> void:
	if sz < 0.8 or col.a <= 0.01:
		return
	var dark: Color = Color(col.darkened(0.5), col.a)
	var light: Color = Color(col.lightened(0.55), col.a)
	ci.draw_set_transform(pos, rot, Vector2.ONE)
	match shape:
		"ember":
			ci.draw_circle(Vector2.ZERO, sz, col)
			ci.draw_circle(Vector2.ZERO, sz * 0.55, light)
		"drop":
			_poly(ci, _drop_pts(sz, false), col, dark, 1.4)
			ci.draw_circle(Vector2(-sz * 0.3, -sz * 0.3), sz * 0.22, Color(1, 1, 1, col.a * 0.8))
		"flame":
			_poly(ci, _drop_pts(sz, true), col, dark, 1.2)
			var inner: PackedVector2Array = _drop_pts(sz * 0.55, true)
			for k: int in inner.size():
				inner[k] += Vector2(0.0, sz * 0.28)
			ci.draw_colored_polygon(inner, light)
		"star4":
			_poly(ci, _star_pts(4, sz * 1.5, 0.26, 0.0), col, dark, 1.2)
			ci.draw_circle(Vector2.ZERO, sz * 0.3, Color(1, 1, 1, col.a))
		"leaf":
			_poly(ci, _lens(sz * 1.9, sz * 0.78), col, dark, 1.4)
			ci.draw_line(Vector2(-sz * 0.8, 0), Vector2(sz * 0.8, 0), light, 1.4)
		"shard":
			var kite: PackedVector2Array = PackedVector2Array([Vector2(sz * 1.5, 0), Vector2(0, -sz * 0.5), Vector2(-sz * 0.8, 0), Vector2(0, sz * 0.5)])
			_poly(ci, kite, col, dark, 1.2)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(sz * 1.5, 0), Vector2(0, -sz * 0.5), Vector2(-sz * 0.8, 0)]), Color(light, col.a * 0.7))
		"bubble":
			ci.draw_circle(Vector2.ZERO, sz, Color(col, col.a * 0.28))
			ci.draw_arc(Vector2.ZERO, sz, 0.0, TAU, 20, col, 1.8, true)
			ci.draw_arc(Vector2.ZERO, sz * 0.66, deg_to_rad(200), deg_to_rad(265), 6, Color(1, 1, 1, col.a * 0.9), 1.8, true)
		"rock":
			var rk: PackedVector2Array = _rock(sz, int(sz * 7.0))
			_poly(ci, rk, col, dark, 1.6)
			ci.draw_colored_polygon(PackedVector2Array([Vector2.ZERO, rk[4], rk[5], rk[6], rk[7]]), Color(light, col.a * 0.55))
		"feather":
			_poly(ci, _lens(sz * 2.2, sz * 0.62), col, dark, 1.1)
			ci.draw_line(Vector2(-sz * 1.0, 0), Vector2(sz * 1.0, 0), Color(dark, col.a * 0.8), 1.2)
		"cross":
			var t: float = sz * 0.36
			var pts: PackedVector2Array = PackedVector2Array([Vector2(-t, -sz), Vector2(t, -sz), Vector2(t, -t), Vector2(sz, -t),
					Vector2(sz, t), Vector2(t, t), Vector2(t, sz), Vector2(-t, sz), Vector2(-t, t), Vector2(-sz, t),
					Vector2(-sz, -t), Vector2(-t, -t)])
			_poly(ci, pts, col, dark, 1.6)
		"arrow":
			var ap: PackedVector2Array = PackedVector2Array()
			for p: Vector2 in ARROW:
				ap.append(Vector2(-p.y, p.x) * sz)
			_poly(ci, ap, col, dark, 1.8)
		"zee":
			var zp: PackedVector2Array = PackedVector2Array([Vector2(-1, -1) * sz * 0.8, Vector2(1, -1) * sz * 0.8,
					Vector2(-1, 1) * sz * 0.8, Vector2(1, 1) * sz * 0.8])
			ci.draw_polyline(zp, dark, sz * 0.62 + 3.0, true)
			ci.draw_polyline(zp, col, sz * 0.62, true)
			for q: Vector2 in zp:
				ci.draw_circle(q, sz * 0.31 + 1.5, dark)
			for q: Vector2 in zp:
				ci.draw_circle(q, sz * 0.31, col)
		"bolt":
			_poly(ci, _scaled(BOLT, sz), col, dark, 1.6)
		"crystal":
			var cp: PackedVector2Array = _scaled(CRYSTAL, sz)
			_poly(ci, cp, col, dark, 1.6)
			ci.draw_colored_polygon(PackedVector2Array([cp[0], cp[1], Vector2(0, sz * 0.1), cp[5]]), Color(light, col.a * 0.8))
		"puff":
			ci.draw_circle(Vector2.ZERO, sz, Color(col, col.a * 0.8))
			ci.draw_circle(Vector2(-sz * 0.2, -sz * 0.25), sz * 0.6, Color(light, col.a * 0.6))
		"streak":
			ci.draw_line(Vector2(-sz * 1.4, 0), Vector2(sz * 1.4, 0), dark, sz * 0.45 + 3.0, true)
			ci.draw_line(Vector2(-sz * 1.4, 0), Vector2(sz * 1.4, 0), col, sz * 0.4, true)
		_:
			ci.draw_circle(Vector2.ZERO, sz + 1.5, dark)
			ci.draw_circle(Vector2.ZERO, sz, col)
			ci.draw_circle(Vector2(-sz * 0.3, -sz * 0.3), sz * 0.32, Color(1, 1, 1, col.a * 0.6))
	_reset(ci)


## Tear-drop polygon (tip on +x, or on -y when `up`).
static func _drop_pts(sz: float, up: bool) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array([Vector2(sz * 1.7, 0)])
	for k: int in 9:
		var a: float = deg_to_rad(40.0 + float(k) * 35.0)
		pts.append(Vector2(cos(a), sin(a)) * sz)
	if up:
		for k: int in pts.size():
			pts[k] = Vector2(pts[k].y, -pts[k].x)
	return pts


# ------------------------------------------------------------------------------------------------ projectiles

static func _paint_proj(ci: Node2D, t: float, glow: bool, d: Dictionary, pal: Dictionary, length: float) -> void:
	var size: float = _f(d, "size", 18.0)
	var p: float = 1.0 - (1.0 - t) * (1.0 - t)
	var fa: float = clampf((1.0 - t) / 0.1, 0.0, 1.0)
	var pop: float = clampf(t / 0.1, 0.0, 1.0)
	var s: float = size * (0.45 + 0.55 * pop) * (0.5 + 0.5 * fa)
	var head: Vector2 = Vector2(length * p, 0.0)
	match String(d.get("style", "ball")):
		"ball": _pr_ball(ci, glow, t, p, head, s, fa, d, pal, length)
		"stream": _pr_stream(ci, glow, t, p, head, s, fa, d, pal, length)
		"bolt": _pr_bolt(ci, glow, t, p, head, s, fa, d, pal, length)
		"leaves": _pr_leaves(ci, glow, t, p, head, s, fa, d, pal, length)
		"shards": _pr_shards(ci, glow, t, p, head, s, fa, d, pal, length)
		"crescents": _pr_crescents(ci, glow, t, p, head, s, fa, d, pal, length)
		"rings": _pr_rings(ci, glow, t, p, head, s, fa, d, pal, length)
		"fist": _pr_fist(ci, glow, t, p, head, s, fa, d, pal, length)
		"swarm": _pr_swarm(ci, glow, t, p, head, s, fa, d, pal, length)
		"boulders": _pr_boulders(ci, glow, t, p, head, s, fa, d, pal, length)
		"sparkles": _pr_sparkles(ci, glow, t, p, head, s, fa, d, pal, length)
		"streaks": _pr_streaks(ci, glow, t, p, head, s, fa, d, pal, length)
		_: _pr_ball(ci, glow, t, p, head, s, fa, d, pal, length)
	_trail_sparks(ci, glow, t, head, s, fa, d, pal)


static func _pr_ball(ci: Node2D, glow: bool, t: float, _p: float, head: Vector2, s: float, fa: float, d: Dictionary, pal: Dictionary, _length: float) -> void:
	var main: Color = _c(pal, d.get("ball_color", "main"))
	var light: Color = _c(pal, "light")
	var tail: bool = bool(d.get("tail", false))
	var tl: float = s * _f(d, "tail_len", 3.0)
	var cluster: int = int(d.get("cluster", 1))
	var soft: bool = String(d.get("look", "cel")) == "soft"
	var orbit: bool = bool(d.get("orbit", false))
	if tail:
		for pass_i: int in 2:
			for k: int in range(9, -1, -1):
				var u: float = float(k) / 10.0
				var cx: float = head.x - u * tl
				if cx < 0.0:
					continue
				var cy: float = sin(t * 34.0 + u * 7.0) * s * 0.2 * u
				var r: float = s * (0.95 - 0.8 * u)
				var col: Color = _a(light.lerp(main, clampf(u * 1.5, 0.0, 1.0)), fa * (1.0 - u * 0.45))
				if glow:
					if pass_i == 0 and k % 2 == 0:
						_halo(ci, Vector2(cx, cy), r * 2.2, _a(main, 0.45 * fa))
				elif pass_i == 0:
					ci.draw_circle(Vector2(cx, cy), r + 2.0, Color(col.darkened(0.55), col.a))
				else:
					ci.draw_circle(Vector2(cx, cy), r, col)
			if glow:
				break
	for c: int in cluster:
		var pos: Vector2 = head
		var cr: float = s
		if cluster > 1:
			var ang: float = float(c) * TAU / float(cluster) + t * (9.0 if orbit else 5.0)
			var rad: float = s * (1.15 if orbit else 0.7)
			if orbit:
				pos += Vector2(cos(ang), sin(ang)) * rad
			else:
				pos += Vector2(cos(ang), sin(ang)) * rad * (0.4 + 0.8 * _h(c, 5))
			cr = s * (0.55 if orbit else 0.6 + 0.25 * _h(c, 6)) * (0.9 + 0.1 * sin(t * 30.0 + float(c)))
		if glow:
			_halo(ci, pos, cr * 2.8, _a(main, 0.6 * fa))
		else:
			_blob(ci, pos, cr, _a(main, fa), soft)
	if glow:
		_halo(ci, head, s * 4.0, _a(main, 0.22 * fa))


static func _pr_stream(ci: Node2D, glow: bool, t: float, _p: float, head: Vector2, s: float, fa: float, d: Dictionary, pal: Dictionary, _length: float) -> void:
	var main: Color = _a(_c(pal, "main"), fa)
	var light: Color = _a(_c(pal, "light"), fa)
	var x0: float = maxf(0.0, head.x - s * _f(d, "jet_len", 9.0))
	var n: int = 26
	if glow:
		for k: int in range(0, n, 4):
			var u: float = float(k) / float(n - 1)
			_halo(ci, Vector2(lerpf(x0, head.x, u), 0.0), s * (0.9 + u * 1.2), _a(main, 0.3 * fa))
		_halo(ci, head, s * 2.8, _a(main, 0.5 * fa))
		return
	for pass_i: int in 3:
		for k: int in n:
			var u: float = float(k) / float(n - 1)
			var pos: Vector2 = Vector2(lerpf(x0, head.x, u), sin(u * 8.0 - t * 38.0) * s * 0.22 * (1.0 - u * 0.3))
			var r: float = s * (0.28 + 0.62 * u)
			match pass_i:
				0: ci.draw_circle(pos, r + 2.2, Color(main.darkened(0.55), main.a))
				1: ci.draw_circle(pos, r, main)
				2: ci.draw_circle(pos + Vector2(0.0, -r * 0.3), r * 0.45, Color(light, light.a * 0.85))
	_blob(ci, head, s * 0.95, main, false)


static func _pr_bolt(ci: Node2D, glow: bool, t: float, _p: float, head: Vector2, s: float, fa: float, _d: Dictionary, pal: Dictionary, _length: float) -> void:
	var main: Color = _a(_c(pal, "main"), fa)
	var flick: int = int(t * 16.0)
	var segs: int = 12
	var pts: PackedVector2Array = PackedVector2Array()
	for k: int in segs + 1:
		var u: float = float(k) / float(segs)
		var amp: float = s * 1.1 * sin(u * PI)
		var y: float = (_h(k, flick) - 0.5) * 2.0 * amp if k > 0 and k < segs else 0.0
		pts.append(Vector2(head.x * u, y))
	var branch: PackedVector2Array = PackedVector2Array()
	var bk: int = segs / 2
	for k: int in 4:
		branch.append(pts[bk] + Vector2(float(k) * s * 0.9, float(k) * s * 0.8 * (1.0 if flick % 2 == 0 else -1.0) + (_h(k, flick + 9) - 0.5) * s))
	if glow:
		ci.draw_polyline(pts, _a(main, 0.35), s * 2.0, true)
		_halo(ci, head, s * 3.4, _a(main, 0.6 * fa))
		return
	for poly: PackedVector2Array in [pts, branch]:
		var k: float = 1.0 if poly == pts else 0.55
		ci.draw_polyline(poly, Color(main.darkened(0.55), main.a), s * 0.9 * k + 2.0, true)
		ci.draw_polyline(poly, main, s * 0.5 * k, true)
		ci.draw_polyline(poly, Color(1, 1, 1, fa), s * 0.2 * k + 0.6, true)
	_pshape(ci, "star4", head, t * 6.0, s * 0.8, _a(_c(pal, "light"), fa))


static func _pr_leaves(ci: Node2D, glow: bool, t: float, _p: float, _head: Vector2, s: float, fa: float, d: Dictionary, pal: Dictionary, length: float) -> void:
	var n: int = mini(int(d.get("count", 7)), 20)
	var keys: Array[String] = ["main", "light", "main", "dark"]
	for i: int in n:
		var tt: float = clampf((t - float(i) / float(n) * 0.4) / 0.6, 0.0, 1.0)
		if tt <= 0.0 or tt >= 1.0:
			continue
		var e: float = tt * (2.0 - tt)
		var pos: Vector2 = Vector2(length * e, sin(tt * TAU * 1.25 + float(i) * 1.7) * s * 1.5 + (_h(i, 5) - 0.5) * s * 2.4 * (1.0 - e * 0.6))
		var col: Color = _a(_c(pal, keys[i % keys.size()]), 1.0 - clampf((tt - 0.9) / 0.1, 0.0, 1.0))
		if glow:
			_halo(ci, pos, s * 1.6, _a(_c(pal, "light"), 0.35 * col.a))
		else:
			_pshape(ci, "leaf", pos, tt * TAU * 2.5 * (1.0 if i % 2 == 0 else -1.0) + float(i), s * (0.9 + 0.5 * _h(i, 7)), col)


static func _pr_shards(ci: Node2D, glow: bool, t: float, _p: float, _head: Vector2, s: float, fa: float, d: Dictionary, pal: Dictionary, length: float) -> void:
	var n: int = mini(int(d.get("count", 5)), 12)
	var metal: bool = bool(d.get("metal", false))
	for i: int in n:
		var tt: float = clampf((t - float(i) / float(n) * 0.3) / 0.7, 0.0, 1.0)
		if tt <= 0.0 or tt >= 1.0:
			continue
		var e: float = _eo(tt)
		var lane: float = (float(i) - float(n - 1) * 0.5) * s * 0.95 * (1.0 - 0.7 * e)
		var pos: Vector2 = Vector2(length * e, lane)
		var ang: float = atan2(-lane * 0.6, maxf(length * 0.3, 1.0)) * 0.5
		var col: Color = _c(pal, "light" if i % 2 == 0 else "main")
		if glow:
			_halo(ci, pos, s * 2.0, _a(col, 0.45))
			if metal:
				ci.draw_line(pos - Vector2(s * 3.0, 0), pos + Vector2(s * 1.5, 0), Color(1, 1, 1, 0.5), 2.5, true)
		else:
			ci.draw_line(pos - Vector2(s * 3.0, 0), pos, Color(col, 0.35), s * 0.3, true)
			_pshape(ci, "shard", pos, ang, s * 1.05, col)
			if metal:
				ci.draw_line(pos + Vector2(-s * 0.3, -s * 0.35), pos + Vector2(s * 0.7, -s * 0.05), Color(1, 1, 1, 0.9), 1.8, true)


static func _pr_crescents(ci: Node2D, glow: bool, t: float, _p: float, _head: Vector2, s: float, _fa: float, d: Dictionary, pal: Dictionary, length: float) -> void:
	var n: int = mini(int(d.get("count", 3)), 8)
	var r: float = _f(d, "radius", 28.0) * (s / maxf(_f(d, "size", 18.0), 1.0))
	var thick: float = _f(d, "thick", 0.45) * r
	var fill: Color = _c(pal, d.get("fill", "main"))
	var edge: Color = _c(pal, d.get("edge", "dark"))
	var inner_key: String = String(d.get("inner", ""))
	for i: int in n:
		var tt: float = clampf((t - float(i) / float(n) * 0.3) / 0.7, 0.0, 1.0)
		if tt <= 0.0:
			continue
		var a: float = 1.0 - clampf((tt - 0.85) / 0.15, 0.0, 1.0)
		var off: float = float(i) - float(n - 1) * 0.5
		var pos: Vector2 = Vector2(length * _eo(tt) - r * 0.5, off * r * 0.6 * (1.0 + 0.4 * tt))
		var sc: float = 0.7 + 0.4 * tt
		ci.draw_set_transform(pos, off * 0.15, Vector2(sc, sc))
		if glow:
			_halo(ci, Vector2(r * 0.6, 0.0), r * 1.2, _a(_c(pal, "light"), 0.4 * a))
		else:
			_poly(ci, _crescent(r, thick, 1.1), _a(fill, a), _a(edge, a), 2.5)
			if not inner_key.is_empty():
				ci.draw_colored_polygon(_crescent(r * 0.9, thick * 0.45, 0.95), _a(_c(pal, inner_key), a))
		_reset(ci)


static func _pr_rings(ci: Node2D, glow: bool, t: float, p: float, head: Vector2, s: float, fa: float, d: Dictionary, pal: Dictionary, length: float) -> void:
	var n: int = mini(int(d.get("count", 4)), 8)
	var main: Color = _c(pal, "main")
	var light: Color = _c(pal, "light")
	if glow:
		_halo(ci, head, s * 3.0, _a(light, 0.55 * fa))
	for i: int in n:
		var pp: float = maxf(0.0, p - float(i) * 0.06)
		var r: float = s * (0.7 + 0.22 * float(i)) * (1.0 + 0.1 * sin(t * 40.0 + float(i) * 1.3))
		var a: float = fa * (1.0 - float(i) / float(n) * 0.6)
		ci.draw_set_transform(Vector2(length * pp, 0.0), 0.0, Vector2(0.45, 1.0))
		if glow:
			ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, _a(main, 0.4 * a), s * 0.7, true)
		else:
			ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, _a(main.darkened(0.5), a), s * 0.34 + 3.0, true)
			ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, _a(main, a), s * 0.34, true)
			ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 40, _a(light, a), s * 0.12, true)
		_reset(ci)
	if not glow:
		ci.draw_circle(head, s * 0.45, _a(light, fa))
		ci.draw_circle(head, s * 0.22, Color(1, 1, 1, fa))


static func _pr_fist(ci: Node2D, glow: bool, t: float, _p: float, head: Vector2, s: float, fa: float, _d: Dictionary, pal: Dictionary, _length: float) -> void:
	var main: Color = _a(_c(pal, "main"), fa)
	var light: Color = _a(_c(pal, "light"), fa)
	if glow:
		_halo(ci, head, s * 3.0, _a(main, 0.5 * fa))
		return
	for k: int in 5:
		var y: float = (float(k) - 2.0) * s * 0.5
		var x1: float = head.x - s * 1.3
		var x0: float = x1 - s * (1.4 + 1.6 * _h(k, 3))
		ci.draw_line(Vector2(maxf(x0, 0.0), y), Vector2(maxf(x1, 0.0), y), _a(Color.WHITE, 0.85 * fa), 2.5, true)
	ci.draw_set_transform(head, sin(t * 30.0) * 0.08, Vector2.ONE)
	for pass_i: int in 2:
		var grow: float = 2.2 if pass_i == 0 else 0.0
		var col: Color = Color(main.darkened(0.55), main.a) if pass_i == 0 else main
		ci.draw_circle(Vector2.ZERO, s + grow, col)
		for k: int in 4:
			ci.draw_circle(Vector2(s * 0.72, (float(k) - 1.5) * s * 0.55), s * 0.34 + grow, col)
		ci.draw_circle(Vector2(-s * 0.1, -s * 0.85), s * 0.3 + grow, col)
	for k: int in 3:
		var y2: float = (float(k) - 1.0) * s * 0.55
		ci.draw_line(Vector2(s * 0.5, y2), Vector2(s * 1.05, y2), Color(main.darkened(0.5), main.a), 1.6, true)
	ci.draw_circle(Vector2(-s * 0.2, -s * 0.25), s * 0.55, light)
	ci.draw_circle(Vector2(-s * 0.35, -s * 0.45), s * 0.18, Color(1, 1, 1, fa))
	_reset(ci)


static func _pr_swarm(ci: Node2D, glow: bool, t: float, _p: float, _head: Vector2, s: float, fa: float, d: Dictionary, pal: Dictionary, length: float) -> void:
	var n: int = mini(int(d.get("count", 12)), 24)
	for i: int in n:
		var tt: float = clampf((t - _h(i, 2) * 0.2) / 0.8, 0.0, 1.0)
		if tt <= 0.0 or tt >= 1.0:
			continue
		var y0: float = (_h(i, 1) - 0.5) * s * 3.2
		var x: float = maxf(length * _eo(tt) - _h(i, 3) * s * 2.5 * (1.0 - tt), 0.0)
		var pos: Vector2 = Vector2(x, y0 * (1.0 - 0.8 * tt) + sin(t * 26.0 + float(i) * 2.1) * s * 0.5)
		var col: Color = _c(pal, "main" if i % 2 == 0 else "light")
		if glow:
			_halo(ci, pos, s * 1.1, _a(col, 0.4))
			continue
		ci.draw_circle(pos + Vector2(-s * 0.1, -s * 0.4), s * 0.36, Color(1, 1, 1, 0.55))
		ci.draw_circle(pos + Vector2(-s * 0.1, s * 0.4), s * 0.36, Color(1, 1, 1, 0.55))
		ci.draw_set_transform(pos, 0.0, Vector2(1.4, 1.0))
		ci.draw_circle(Vector2.ZERO, s * 0.4 + 1.8, col.darkened(0.55))
		ci.draw_circle(Vector2.ZERO, s * 0.4, col)
		ci.draw_circle(Vector2(-s * 0.05, -s * 0.12), s * 0.2, col.lightened(0.5))
		_reset(ci)
		ci.draw_colored_polygon(PackedVector2Array([pos + Vector2(s * 0.5, -s * 0.18), pos + Vector2(s * 1.1, 0.0), pos + Vector2(s * 0.5, s * 0.18)]), Color(0.15, 0.1, 0.05))


static func _pr_boulders(ci: Node2D, glow: bool, t: float, _p: float, _head: Vector2, s: float, fa: float, d: Dictionary, pal: Dictionary, length: float) -> void:
	var n: int = mini(int(d.get("count", 3)), 10)
	var arc: float = _f(d, "arc", 0.25)
	for i: int in n:
		var tt: float = clampf((t - float(i) / float(n) * 0.25) / 0.75, 0.0, 1.0)
		if tt <= 0.0 or tt >= 1.0:
			continue
		var lane: float = (float(i) - float(n - 1) * 0.5) * s * 0.9 * (1.0 - tt)
		var pos: Vector2 = Vector2(length * (tt * 0.6 + 0.4 * _eo(tt)), -sin(tt * PI) * arc * length + lane)
		var r: float = s * (1.0 if i == 0 else 0.62)
		var col: Color = _c(pal, "main" if i % 2 == 0 else "dark")
		if glow:
			_halo(ci, pos, r * 1.6, _a(_c(pal, "light"), 0.18))
		else:
			_pshape(ci, "rock", pos, tt * TAU * 2.0 * (1.0 if i % 2 == 0 else -1.0) + float(i), r * (1.0 + 0.0), col)


static func _pr_sparkles(ci: Node2D, glow: bool, t: float, _p: float, head: Vector2, s: float, fa: float, _d: Dictionary, pal: Dictionary, _length: float) -> void:
	var main: Color = _c(pal, "main")
	var light: Color = _c(pal, "light")
	if glow:
		_halo(ci, head, s * 3.4, _a(main, 0.6 * fa))
		return
	var wave: PackedVector2Array = PackedVector2Array()
	for k: int in 12:
		var u: float = float(k) / 11.0
		var x: float = head.x - u * s * 5.0
		if x >= 0.0:
			wave.append(Vector2(x, sin(u * 9.0 - t * 30.0) * s * 0.45 * u))
	if wave.size() >= 2:
		ci.draw_polyline(wave, _a(light, 0.7 * fa), 3.0, true)
	var pulse: float = 1.0 + 0.12 * sin(t * 40.0)
	_pshape(ci, "star4", head, t * 8.0, s * 0.95 * pulse, _a(main, fa))
	_pshape(ci, "star4", head + Vector2(cos(t * 14.0), sin(t * 14.0)) * s * 1.4, -t * 6.0, s * 0.42, _a(light, fa))


static func _pr_streaks(ci: Node2D, glow: bool, t: float, _p: float, head: Vector2, s: float, fa: float, _d: Dictionary, pal: Dictionary, _length: float) -> void:
	var light: Color = _c(pal, "light")
	if glow:
		_halo(ci, head, s * 3.2, _a(light, 0.5 * fa))
		return
	for k: int in 6:
		var off: float = (float(k) - 2.5) * 0.13
		var len: float = s * (2.5 + 2.5 * _h(k, 4))
		var dir: Vector2 = Vector2(-1.0, 0.0).rotated(off)
		var a: Vector2 = head + dir * s * 1.1
		var b: Vector2 = head + dir * (s * 1.1 + len)
		if b.x < 0.0:
			b.x = 0.0
		ci.draw_line(a, b, _a(_c(pal, "main"), 0.9 * fa), 6.0, true)
		ci.draw_line(a, b, _a(Color.WHITE, fa), 3.0, true)
	_blob(ci, head, s, _a(light, fa), false)
	_pshape(ci, "star4", head + Vector2(s * 0.9, 0.0), t * 5.0, s * 0.4, _a(Color.WHITE, fa))


## Particles shed behind the head (d.sparks, spark_shape, spark_colors, spark_size, spark_back, spark_gravity).
static func _trail_sparks(ci: Node2D, glow: bool, t: float, head: Vector2, s: float, fa: float, d: Dictionary, pal: Dictionary) -> void:
	var n: int = mini(int(d.get("sparks", 0)), 24)
	if n <= 0:
		return
	var shape: String = String(d.get("spark_shape", "ember"))
	var cols: Array = d.get("spark_colors", ["light", "main"])
	var glowy: bool = GLOW_SHAPES.has(shape)
	for i: int in n:
		var tt: float = fposmod(t * 1.6 + _h(i, 11), 1.0)
		var pos: Vector2 = head + Vector2(-tt * s * _f(d, "spark_back", 3.0), 0.0)
		pos += Vector2(0.0, (_h(i, 12) - 0.5) * s * 1.8 * (0.3 + tt) + _f(d, "spark_gravity", 0.0) * s * tt * tt)
		if pos.x < 0.0:
			continue
		var sz: float = s * _f(d, "spark_size", 0.3) * (1.0 - tt) * (0.6 + 0.8 * _h(i, 13))
		var col: Color = _a(_c(pal, cols[i % cols.size()]), fa * (1.0 - tt))
		if glow:
			if glowy:
				_halo(ci, pos, sz * 2.6, _a(col, 0.5))
		else:
			_pshape(ci, shape, pos, tt * 6.0 + float(i), sz, col)


# ------------------------------------------------------------------------------------------------ layered effects

## Impact / status / buff painter: draws every layer of d.layers at its own local progress.
static func _paint_layers(ci: Node2D, t: float, glow: bool, d: Dictionary, pal: Dictionary, strength: float) -> void:
	var size: float = _f(d, "size", 64.0) * strength
	var layers: Array = d.get("layers", [])
	for entry: Variant in layers:
		var ly: Dictionary = entry
		var delay: float = _f(ly, "delay", 0.0)
		if t < delay:
			continue
		var life: float = _f(ly, "life", 1.0 - delay)
		var lt: float = clampf((t - delay) / maxf(life, 0.01), 0.0, 1.0)
		if lt >= 1.0:
			continue
		match String(ly.get("kind", "")):
			"flash": _ly_flash(ci, glow, lt, ly, pal, size)
			"ring": _ly_ring(ci, glow, lt, ly, pal, size)
			"burst": _ly_burst(ci, glow, lt, ly, pal, size)
			"star": _ly_star(ci, glow, lt, ly, pal, size)
			"claws": _ly_claws(ci, glow, lt, ly, pal, size)
			"bolts": _ly_bolts(ci, glow, lt, ly, pal, size)
			"spikes": _ly_spikes(ci, glow, lt, ly, pal, size)
			"hex": _ly_hex(ci, glow, lt, ly, pal, size)


static func _ly_flash(ci: Node2D, glow: bool, lt: float, ly: Dictionary, pal: Dictionary, size: float) -> void:
	var col: Color = _c(pal, ly.get("color", "light"))
	var r: float = size * _f(ly, "radius", 1.0)
	var a: float = pow(1.0 - lt, 1.6)
	var e: float = _eo(lt)
	if glow:
		_halo(ci, Vector2.ZERO, r * (0.7 + 0.6 * e), _a(col, a * 0.95))
	else:
		ci.draw_circle(Vector2.ZERO, r * 0.4 * (0.4 + 0.6 * e), _a(Color.WHITE.lerp(col, 0.2), a))


static func _ly_ring(ci: Node2D, glow: bool, lt: float, ly: Dictionary, pal: Dictionary, size: float) -> void:
	var col: Color = _c(pal, ly.get("color", "main"))
	var r: float = size * _f(ly, "radius", 1.0) * _eo(lt)
	var w: float = size * _f(ly, "width", 0.1) * (1.0 - lt) + 1.5
	var a: float = 1.0 - lt * lt
	ci.draw_set_transform(Vector2(0.0, size * _f(ly, "oy", 0.0)), 0.0, Vector2(1.0, _f(ly, "squash", 1.0)))
	if glow:
		ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 56, _a(col, a * 0.5), w * 2.4, true)
	else:
		ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 56, _a(col.darkened(0.5), a * 0.75), w + 4.0, true)
		ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 56, _a(col, a), w, true)
	_reset(ci)


static func _ly_burst(ci: Node2D, glow: bool, lt: float, ly: Dictionary, pal: Dictionary, size: float) -> void:
	var n: int = mini(int(ly.get("count", 10)), MAX_PARTICLES)
	var shape: String = String(ly.get("shape", "circle"))
	var cols: Array = ly.get("colors", ["main"])
	var speed: float = size * _f(ly, "speed", 1.0)
	var psize: float = size * _f(ly, "size", 0.12)
	var grav: float = size * _f(ly, "gravity", 0.0)
	var dir: float = deg_to_rad(_f(ly, "dir", 0.0))
	var spread: float = deg_to_rad(_f(ly, "spread", 360.0))
	var spin: float = _f(ly, "spin", 0.0)
	var alpha: float = _f(ly, "alpha", 1.0)
	var stag: float = _f(ly, "stagger", 0.0)
	var upright: bool = String(ly.get("rot_mode", "dir")) == "upright"
	var glowy: bool = bool(ly.get("glow", GLOW_SHAPES.has(shape)))
	var oy: float = size * _f(ly, "oy", 0.0)
	for i: int in n:
		var u: float = (float(i) + _h(i, 1) * 0.8) / float(n)
		var li: float = clampf((lt - stag * u) / maxf(1.0 - stag, 0.05), 0.0, 1.0)
		if li <= 0.0 or li >= 1.0:
			continue
		var ang: float = dir + (u - 0.5) * spread
		var v: float = speed * (0.45 + 0.55 * _h(i, 2))
		var pos: Vector2 = Vector2(cos(ang), sin(ang)) * v * _eo(li) + Vector2(0.0, grav * li * li + oy)
		var rot: float = (_h(i, 4) - 0.5) * 0.6 if upright else ang
		rot += spin * li * (1.0 if i % 2 == 0 else -1.0)
		var fade: float = clampf((1.0 - li) / 0.35, 0.0, 1.0)
		var sz: float = psize * (0.6 + 0.8 * _h(i, 3)) * clampf(li / 0.12, 0.0, 1.0) * (0.4 + 0.6 * fade)
		var col: Color = _a(_c(pal, cols[i % cols.size()]), fade * alpha)
		if glow:
			if glowy:
				_halo(ci, pos, sz * 2.8, _a(col, 0.55))
		else:
			_pshape(ci, shape, pos, rot, sz, col)


static func _ly_star(ci: Node2D, glow: bool, lt: float, ly: Dictionary, pal: Dictionary, size: float) -> void:
	var col: Color = _c(pal, ly.get("color", "main"))
	var inner_col: Color = _c(pal, ly.get("inner_color", "light"))
	var a: float = 1.0 - clampf((lt - 0.45) / 0.55, 0.0, 1.0)
	var r: float = size * _f(ly, "radius", 1.0) * (0.45 + 0.55 * _eb(lt / 0.3)) * (1.0 - 0.25 * lt)
	var pts_n: int = int(ly.get("points", 8))
	var inner: float = _f(ly, "inner", 0.5)
	var rot: float = deg_to_rad(_f(ly, "rot", 0.0)) + lt * 0.4
	if glow:
		_halo(ci, Vector2.ZERO, r * 1.35, _a(col, a * 0.6))
		return
	var edge: Color = Color(col.darkened(0.55), a)
	_poly(ci, _star_pts(pts_n, r, inner, rot), _a(col, a), edge, size * 0.04 + 1.5)
	ci.draw_colored_polygon(_star_pts(pts_n, r * 0.58, inner, rot), _a(inner_col, a))


static func _ly_claws(ci: Node2D, glow: bool, lt: float, ly: Dictionary, pal: Dictionary, size: float) -> void:
	var n: int = mini(int(ly.get("count", 3)), 8)
	var length: float = size * _f(ly, "length", 1.5)
	var wmax: float = size * _f(ly, "width", 0.14)
	var ang: float = deg_to_rad(_f(ly, "angle", 40.0))
	var spacing: float = size * _f(ly, "spacing", 0.3)
	var fill: Color = _c(pal, ly.get("color", "main"))
	var edge: Color = _c(pal, ly.get("edge", "dark"))
	var dirv: Vector2 = Vector2(cos(ang), sin(ang))
	var perp: Vector2 = Vector2(-dirv.y, dirv.x)
	var fade: float = 1.0 - clampf((lt - 0.55) / 0.45, 0.0, 1.0)
	for i: int in n:
		var tt: float = clampf((lt - float(i) * 0.1) / 0.4, 0.0, 1.0)
		if tt <= 0.0:
			continue
		var e: float = _eo(tt)
		var start: Vector2 = perp * (float(i) - float(n - 1) * 0.5) * spacing - dirv * length * 0.5
		if glow:
			_halo(ci, start + dirv * length * e, wmax * 3.0, _a(_c(pal, "light"), 0.7 * fade))
			continue
		ci.draw_set_transform(start, ang, Vector2(maxf(e, 0.02), 1.0))
		_poly(ci, _lens(length, wmax, 10) + PackedVector2Array([]), _a(fill, fade), _a(edge, fade), 2.2)
		_reset(ci)
		ci.draw_set_transform(start, ang, Vector2(maxf(e, 0.02), 1.0))
		var core: PackedVector2Array = _lens(length * 0.9, wmax * 0.35, 10)
		for k: int in core.size():
			core[k] += Vector2(length * 0.5 * 0.0, 0.0)
		ci.draw_colored_polygon(core, _a(_c(pal, ly.get("core", "white")), fade * 0.75))
		_reset(ci)


static func _ly_bolts(ci: Node2D, glow: bool, lt: float, ly: Dictionary, pal: Dictionary, size: float) -> void:
	var n: int = mini(int(ly.get("count", 6)), 16)
	var len: float = size * _f(ly, "length", 1.2)
	var col: Color = _c(pal, ly.get("color", "main"))
	var flick: int = int(lt * 10.0)
	var reveal: float = _eo(clampf(lt / 0.4, 0.0, 1.0))
	var fade: float = 1.0 - clampf((lt - 0.5) / 0.5, 0.0, 1.0)
	for i: int in n:
		var ang: float = TAU * (float(i) + _h(i, 5) * 0.5) / float(n)
		var dirv: Vector2 = Vector2(cos(ang), sin(ang))
		var perp: Vector2 = Vector2(-dirv.y, dirv.x)
		var pts: PackedVector2Array = PackedVector2Array([dirv * size * 0.12])
		for k: int in range(1, 6):
			var r: float = len * float(k) / 5.0 * reveal
			pts.append(dirv * r + perp * (_h(i * 7 + k, flick) - 0.5) * size * 0.35)
		if glow:
			ci.draw_polyline(pts, _a(col, 0.35 * fade), size * 0.2, true)
		else:
			ci.draw_polyline(pts, Color(col.darkened(0.55), fade), size * 0.1 + 3.0, true)
			ci.draw_polyline(pts, _a(col, fade), size * 0.05 + 1.5, true)
			ci.draw_polyline(pts, Color(1, 1, 1, fade), size * 0.02 + 0.8, true)


static func _ly_spikes(ci: Node2D, glow: bool, lt: float, ly: Dictionary, pal: Dictionary, size: float) -> void:
	if glow:
		return
	var n: int = mini(int(ly.get("count", 5)), 12)
	var h: float = size * _f(ly, "radius", 1.0)
	var spacing: float = size * _f(ly, "spacing", 0.28)
	var col: Color = _c(pal, ly.get("color", "main"))
	var oy: float = size * _f(ly, "oy", 0.3)
	var rise: float = _eo(clampf(lt / 0.3, 0.0, 1.0)) * (1.0 - clampf((lt - 0.6) / 0.4, 0.0, 1.0))
	for i: int in n:
		var off: float = float(i) - float(n - 1) * 0.5
		var x: float = off * spacing
		var hh: float = h * (1.0 - 0.1 * absf(off)) * rise * (0.8 + 0.3 * _h(i, 8))
		var w: float = size * 0.12
		if hh < 2.0:
			continue
		var lean: float = off * 0.04 * size
		var tri: PackedVector2Array = PackedVector2Array([Vector2(x - w, oy), Vector2(x + lean, oy - hh), Vector2(x + w, oy)])
		_poly(ci, tri, col, Color(col.darkened(0.55), 1.0), 2.0)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - w, oy), Vector2(x + lean, oy - hh), Vector2(x, oy)]), col.lightened(0.4))


static func _ly_hex(ci: Node2D, glow: bool, lt: float, ly: Dictionary, pal: Dictionary, size: float) -> void:
	var col: Color = _c(pal, ly.get("color", "main"))
	var edge: Color = _c(pal, ly.get("edge", "light"))
	var a: float = 1.0 - clampf((lt - 0.6) / 0.4, 0.0, 1.0)
	var r: float = size * _f(ly, "radius", 1.0) * (0.5 + 0.5 * _eb(lt / 0.4))
	if glow:
		_halo(ci, Vector2.ZERO, r * 1.3, _a(col, a * 0.55))
		return
	var pts: PackedVector2Array = PackedVector2Array()
	var inner_pts: PackedVector2Array = PackedVector2Array()
	for k: int in 6:
		var ang: float = deg_to_rad(30.0 + 60.0 * float(k))
		pts.append(Vector2(cos(ang), sin(ang)) * r)
		inner_pts.append(Vector2(cos(ang), sin(ang)) * r * 0.7)
	ci.draw_colored_polygon(pts, _a(col, a * _f(ly, "fill", 0.3)))
	var cl: PackedVector2Array = pts.duplicate()
	cl.append(pts[0])
	cl.append(pts[1])
	ci.draw_polyline(cl, Color(col.darkened(0.5), a), 9.0, true)
	ci.draw_polyline(cl, _a(edge, a), 5.0, true)
	var cl2: PackedVector2Array = inner_pts.duplicate()
	cl2.append(inner_pts[0])
	cl2.append(inner_pts[1])
	ci.draw_polyline(cl2, _a(edge, a * 0.7), 2.0, true)
	for k: int in 6:
		ci.draw_line(inner_pts[k], pts[k], _a(edge, a * 0.5), 1.5, true)
