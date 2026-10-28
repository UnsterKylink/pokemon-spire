class_name BattleFxDirector
extends Node
## Story 021 (animations d'attaque et de combat): plays a queue of visual events on top of an already-resolved battle.
## Implements: production/epics/pokemon-spire/story-021-animations-attaque.md.
## The battle logic is synchronous; BattleScreen records the events its signals emit during one logic call and hands the
## list to run(). Nothing here reads or changes combat state. Every duration comes from assets/data/animations.json.
## Speed presets (data): Normal / Rapide / Instantané. Instantané (factor 0) = reduced motion: nothing is spawned.
## Headless (no rendering) counts as disabled unless allow_headless is set (tests).
## skip() fast-forwards the queue to its end state synchronously; run() also skips by itself after `limit` seconds.
## Particle / shape effects per attack type come from AttackFx (src/ui/attack_fx.gd), loaded dynamically so this file
## parses and works (without those effects) when that file is absent.

## Emitted when the queue has played (or been skipped) to its end.
signal finished

const CONFIG_PATH: String = "res://assets/data/animations.json"
const SETTINGS_PATH: String = "user://settings.json"
const SETTINGS_KEY: String = "animation_speed"
const ATTACK_FX_PATH: String = "res://src/ui/attack_fx.gd"
const FALLBACK_PRESETS: Dictionary = {"normal": 1.0, "fast": 2.5, "instant": 0.0}
const COLOR_BALL_OUTLINE: Color = Color(0.08, 0.08, 0.12)

## Tests: let the director run for real without a rendering window.
static var allow_headless: bool = false
static var _config: Dictionary = {}
static var _config_loaded: bool = false
static var _attack_fx: Script = null
static var _attack_fx_tried: bool = false

var _speed: String = "normal"
var _busy: bool = false
var _skip: bool = false
var _elapsed: float = 0.0
var _limit: float = 0.0
var _events: Array[Dictionary] = []
var _idx: int = 0
var _handler: Callable = Callable()
var _tweens: Array[Tween] = []
var _gen: int = 0


## A small code-drawn Poké Ball (top half in `color`).
class FxBall extends Control:
	var color: Color = Color(0.9, 0.2, 0.2)

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r: float = minf(size.x, size.y) * 0.5
		var c: Vector2 = size * 0.5
		draw_circle(c, r, BattleFxDirector.COLOR_BALL_OUTLINE)
		draw_circle(c, r - 2.0, Color.WHITE)
		var pts := PackedVector2Array()
		for i: int in 17:
			var a: float = PI + PI * float(i) / 16.0
			pts.append(c + Vector2(cos(a), sin(a)) * (r - 2.0))
		draw_colored_polygon(pts, color)
		draw_line(c + Vector2(-r + 2.0, 0), c + Vector2(r - 2.0, 0), BattleFxDirector.COLOR_BALL_OUTLINE, 3.0)
		draw_circle(c, r * 0.32, BattleFxDirector.COLOR_BALL_OUTLINE)
		draw_circle(c, r * 0.2, Color.WHITE)


# --- Data / settings ---------------------------------------------------------------------

## Whole animations.json (cached).
static func config() -> Dictionary:
	if not _config_loaded:
		_config_loaded = true
		var f: FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.READ)
		if f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				_config = parsed
		if _config.is_empty():
			push_error("BattleFxDirector: cannot read %s (defaults used)" % CONFIG_PATH)
	return _config


## Value `key` of group `group` ("" = top level) with a default.
static func cfg(group: String, key: String, default: Variant) -> Variant:
	var src: Variant = config() if group.is_empty() else config().get(group, {})
	if src is Dictionary and (src as Dictionary).has(key):
		return (src as Dictionary)[key]
	return default


## Float setting with a default.
static func cfg_f(group: String, key: String, default: float) -> float:
	return float(cfg(group, key, default))


## RGB(A) array setting as a Color.
static func cfg_color(group: String, key: String, default: Color) -> Color:
	var v: Variant = cfg(group, key, null)
	if v is Array and (v as Array).size() >= 3:
		var a: Array = v
		return Color(float(a[0]), float(a[1]), float(a[2]), float(a[3]) if a.size() > 3 else 1.0)
	return default


## Speed factor per preset id (data).
static func presets() -> Dictionary:
	var p: Variant = config().get("speed_presets", null)
	return p if p is Dictionary and not (p as Dictionary).is_empty() else FALLBACK_PRESETS


## Preset ids in button order.
static func preset_order() -> Array[String]:
	var out: Array[String] = []
	var v: Variant = config().get("speed_order", null)
	if v is Array:
		for s: Variant in v:
			if presets().has(String(s)):
				out.append(String(s))
	if out.is_empty():
		for k: Variant in presets().keys():
			out.append(String(k))
	return out


## French label of a preset ("Normal", "Rapide", "Instantané").
static func speed_label(preset: String) -> String:
	var labels: Variant = config().get("speed_labels", {})
	return String((labels as Dictionary).get(preset, preset)) if labels is Dictionary else preset


## True when there is no rendering window (animations are then treated as instant).
static func is_headless() -> bool:
	return DisplayServer.get_name() == "headless"


## Saved speed preset (user://settings.json), or the data default.
static func load_saved_speed() -> String:
	var preset: String = String(cfg("", "default_speed", "normal"))
	var f: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.READ) if FileAccess.file_exists(SETTINGS_PATH) else null
	if f != null:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		f.close()
		if parsed is Dictionary and presets().has(String((parsed as Dictionary).get(SETTINGS_KEY, ""))):
			preset = String((parsed as Dictionary)[SETTINGS_KEY])
	return preset if presets().has(preset) else "normal"


## Saves the speed preset next to the other settings (atomic: temp file then rename; failures are ignored).
static func save_speed(preset: String) -> void:
	var data: Dictionary = {}
	var f: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.READ) if FileAccess.file_exists(SETTINGS_PATH) else null
	if f != null:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		f.close()
		if parsed is Dictionary:
			data = parsed
	data[SETTINGS_KEY] = preset
	var tmp: String = SETTINGS_PATH + ".tmp"
	var w: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if w == null:
		return
	w.store_string(JSON.stringify(data, "  "))
	w.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(SETTINGS_PATH))


## True when animations would play with the saved speed (used by screens without a director, e.g. evolution).
static func saved_enabled() -> bool:
	return float(presets().get(load_saved_speed(), 1.0)) > 0.0 and (not is_headless() or allow_headless)


## Evolution screen: the sprite flashes white and grows into place. Fire and forget; no-op when animations are off.
static func evolve_pop(sprite: Control) -> void:
	if sprite == null or not saved_enabled():
		return
	await sprite.get_tree().process_frame
	if not is_instance_valid(sprite):
		return
	sprite.pivot_offset = sprite.size * 0.5
	sprite.scale = Vector2.ONE * cfg_f("evolution", "grow_from", 0.35)
	sprite.modulate = cfg_color("evolution", "flash_modulate", Color(4, 4, 4, 1))
	var tw: Tween = sprite.create_tween().set_parallel(true)
	tw.tween_property(sprite, "scale", Vector2.ONE, cfg_f("evolution", "grow_seconds", 0.7)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(sprite, "modulate", Color.WHITE, cfg_f("evolution", "flash_seconds", 0.6))


# --- Speed ----------------------------------------------------------------------------------

func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	if not _busy:
		return
	_elapsed += delta
	if _limit > 0.0 and _elapsed > _limit:
		skip()


## Selects a speed preset id ("normal" | "fast" | "instant"); unknown ids are ignored.
func set_speed(preset: String) -> void:
	if presets().has(preset):
		_speed = preset


## Current preset id.
func get_speed() -> String:
	return _speed


## Moves to the next preset (data order) and returns it.
func cycle_speed() -> String:
	var order: Array[String] = preset_order()
	var i: int = order.find(_speed)
	_speed = order[(i + 1) % order.size()]
	return _speed


## Speed factor of the current preset (0 = instant).
func speed_scale() -> float:
	return float(presets().get(_speed, 1.0))


## True when animations are generated at all (not Instantané, not headless unless allowed).
func is_enabled() -> bool:
	return speed_scale() > 0.0 and (not is_headless() or allow_headless)


## True while a queue is playing (the screen locks its input then).
func is_busy() -> bool:
	return _busy


## Id of the current queue (bumped by every run). A handler that awaited compares it after the await: a different
## value means its queue was skipped and a newer one started, so it must not spawn effects into the new queue.
func generation() -> int:
	return _gen


## True when `gen` (read before an await) is no longer the live, unskipped queue.
func is_stale(gen: int) -> bool:
	return gen != _gen or _skip or not _busy


## True from skip() until the next run (fx helpers are no-ops, waits return immediately).
func is_skipping() -> bool:
	return _skip


## Real seconds for `sec` normal-speed seconds.
func t(sec: float) -> float:
	var s: float = speed_scale()
	return 0.0 if s <= 0.0 else sec / s


# --- Queue ----------------------------------------------------------------------------------

## Plays `events` in order: `await handler.call(event, false)` for each, a short gap between them. After `limit` seconds
## (0 = no limit) or on skip() the rest runs synchronously as handler.call(event, true). Emits finished at the end.
func run(events: Array[Dictionary], handler: Callable, limit: float) -> void:
	_gen += 1
	var my_gen: int = _gen
	_busy = true
	_skip = false
	_elapsed = 0.0
	_limit = limit
	_events = events
	_idx = 0
	_handler = handler
	while _idx < _events.size() and not _skip:
		var ev: Dictionary = _events[_idx]
		_idx += 1
		await _handler.call(ev, false)
		if my_gen != _gen or _skip or not is_inside_tree():
			break
		await wait(t(cfg_f("gaps", "event", 0.06)))
		if my_gen != _gen:
			break
	if my_gen == _gen and _busy:
		_finish()


## Fast-forwards the running queue to its end state, synchronously. Does nothing when idle.
func skip() -> void:
	if not _busy:
		return
	_skip = true
	kill_tweens()
	while _idx < _events.size():
		var ev: Dictionary = _events[_idx]
		_idx += 1
		_handler.call(ev, true)
	_finish()


func _finish() -> void:
	_busy = false
	_events = []
	kill_tweens()
	finished.emit()


## Waits `sec` real seconds (returns at once when skipping or `sec` <= 0). Await it.
func wait(sec: float) -> void:
	if sec <= 0.0 or _skip or not is_inside_tree():
		return
	var my_gen: int = _gen
	var left: float = sec
	while left > 0.0 and not _skip and my_gen == _gen:
		await get_tree().process_frame
		left -= get_process_delta_time()


## A tween owned by `node`, killed on skip.
func new_tween(node: Node) -> Tween:
	var live: Array[Tween] = []
	for tw: Tween in _tweens:
		if tw.is_valid():
			live.append(tw)
	_tweens = live
	var tween: Tween = node.create_tween()
	_tweens.append(tween)
	return tween


## Kills every running tween of this director.
func kill_tweens() -> void:
	for tw: Tween in _tweens:
		if tw.is_valid():
			tw.kill()
	_tweens.clear()


func _active() -> bool:
	return is_enabled() and not _skip


# --- AttackFx bridge (particle / shape effects, written by another module) ----------------------------

static func _attack_fx_script() -> Script:
	if not _attack_fx_tried:
		_attack_fx_tried = true
		if ResourceLoader.exists(ATTACK_FX_PATH):
			_attack_fx = load(ATTACK_FX_PATH) as Script
	return _attack_fx


func _call_fx(method: String, args: Array) -> float:
	if not _active():
		return 0.0
	var s: Script = _attack_fx_script()
	if s == null:
		return 0.0
	var r: Variant = s.callv(method, args)
	return float(r) if r is float or r is int else 0.0


## Projectile of attack type `type_id` from -> to (positions in `parent` coordinates). Returns its duration.
func fx_projectile(parent: Control, type_id: String, from_pos: Vector2, to_pos: Vector2) -> float:
	return _call_fx("play_projectile", [parent, type_id, from_pos, to_pos, speed_scale()])


## Impact effect of attack type `type_id` at `at_pos`. Returns its duration.
func fx_impact(parent: Control, type_id: String, at_pos: Vector2, strength: float = 1.0) -> float:
	return _call_fx("play_impact", [parent, type_id, at_pos, speed_scale(), strength])


## Status effect (poison, burn…) at `at_pos`. Returns its duration.
func fx_status(parent: Control, status_id: String, at_pos: Vector2) -> float:
	return _call_fx("play_status", [parent, status_id, at_pos, speed_scale()])


## Buff effect, kind "block" | "heal" | "strength" | "energy". Returns its duration.
func fx_buff(parent: Control, kind: String, at_pos: Vector2) -> float:
	return _call_fx("play_buff", [parent, kind, at_pos, speed_scale()])


# --- Node animation primitives (positions are restored by reset_node) ------------------------------------

func _base(node: Control) -> Vector2:
	if not node.has_meta("fx_base_pos"):
		node.set_meta("fx_base_pos", node.position)
	return node.get_meta("fx_base_pos") as Vector2


## Puts a node back to its rest transform (after a skip or at the end of a queue).
func reset_node(node: Control) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node.has_meta("fx_base_pos"):
		node.position = node.get_meta("fx_base_pos") as Vector2
		node.remove_meta("fx_base_pos")
	node.scale = Vector2.ONE
	node.rotation = 0.0
	node.z_index = 0
	node.modulate = Color.WHITE


## Charge: the node dashes `distance` px along `dir`, holds, and returns. Returns the time to the peak.
func lunge(node: Control, dir: Vector2, distance: float) -> float:
	if not _active():
		return 0.0
	var base: Vector2 = _base(node)
	var out_s: float = t(cfg_f("lunge", "out_seconds", 0.2))
	node.z_index = int(cfg_f("lunge", "z_index", 20.0))
	var tw: Tween = new_tween(node)
	tw.tween_property(node, "position", base + dir * distance, out_s).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(t(cfg_f("lunge", "hold_seconds", 0.04)))
	tw.tween_property(node, "position", base, t(cfg_f("lunge", "back_seconds", 0.28))).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void: node.z_index = 0)
	return out_s


## Hit shake. Returns its duration.
func shake(node: Control) -> float:
	if not _active():
		return 0.0
	var base: Vector2 = _base(node)
	var amp: float = cfg_f("shake", "amplitude", 12.0)
	var total: float = t(cfg_f("shake", "seconds", 0.32))
	var n: int = maxi(2, int(cfg_f("shake", "count", 8.0)))
	var tw: Tween = new_tween(node)
	for i: int in n:
		var k: float = 1.0 - float(i) / float(n)
		tw.tween_property(node, "position:x", base.x + (amp if i % 2 == 0 else -amp) * k, total / float(n))
	tw.tween_property(node, "position", base, 0.02)
	return total


## White (or `color`) flash fading back to normal. Returns its duration.
func flash(node: CanvasItem, color: Color = Color(-1, -1, -1, -1)) -> float:
	if not _active():
		return 0.0
	var c: Color = color if color.r >= 0.0 else cfg_color("flash", "modulate", Color(3.4, 3.4, 3.4, 1.0))
	var secs: float = t(cfg_f("flash", "seconds", 0.22))
	node.modulate = c
	new_tween(node).tween_property(node, "modulate", Color.WHITE, secs)
	return secs


## Scale pulse around the centre (chips, block label). Returns its duration.
func pulse(node: Control, factor: float, seconds: float) -> float:
	if not _active():
		return 0.0
	var secs: float = t(seconds)
	node.pivot_offset = node.size * 0.5
	var tw: Tween = new_tween(node)
	tw.tween_property(node, "scale", Vector2.ONE * factor, secs * 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector2.ONE, secs * 0.6)
	return secs


## K.O.: flash, then fade and shrink out after `delay` seconds. Returns delay + duration.
func ko_fade(node: Control, delay: float) -> float:
	if not _active():
		return 0.0
	var fade: float = t(cfg_f("ko", "fade_seconds", 0.55))
	var fl: float = t(cfg_f("ko", "flash_seconds", 0.2))
	node.pivot_offset = Vector2(node.size.x * 0.5, node.size.y * 0.9)
	var tw: Tween = new_tween(node)
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_callback(func() -> void: node.modulate = cfg_color("flash", "modulate", Color(3.4, 3.4, 3.4, 1.0)))
	tw.tween_property(node, "modulate", Color.WHITE, fl)
	tw.tween_property(node, "modulate:a", 0.0, fade)
	tw.parallel().tween_property(node, "scale", Vector2.ONE * cfg_f("ko", "end_scale", 0.55), fade)
	return delay + fl + fade


## Slides the node `dx` px sideways while fading out. Returns its duration.
func slide_out(node: Control, dx: float, seconds: float) -> float:
	if not _active():
		return 0.0
	var base: Vector2 = _base(node)
	var secs: float = t(seconds)
	var tw: Tween = new_tween(node).set_parallel(true)
	tw.tween_property(node, "position:x", base.x + dx, secs).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(node, "modulate:a", 0.0, secs)
	return secs


## Slides the node in from `dx` px aside to its rest position with a pop. Returns its duration.
func slide_in(node: Control, dx: float, seconds: float, pop: float) -> float:
	if not _active():
		return 0.0
	var base: Vector2 = _base(node)
	var secs: float = t(seconds)
	node.position = base + Vector2(dx, 0)
	node.modulate = Color(1, 1, 1, 0)
	node.pivot_offset = Vector2(node.size.x * 0.5, node.size.y * 0.9)
	var tw: Tween = new_tween(node).set_parallel(true)
	tw.tween_property(node, "position", base, secs).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "modulate:a", 1.0, secs * 0.6)
	tw.tween_property(node, "scale", Vector2.ONE * pop, secs * 0.5).set_trans(Tween.TRANS_QUAD)
	tw.chain().tween_property(node, "scale", Vector2.ONE, secs * 0.5)
	return secs


## Floating number / word at `at` (in `parent` coordinates) (centre of the text), popping then rising and fading. Returns the pop time.
func number(parent: Control, text: String, color: Color, font_size: int, at: Vector2) -> float:
	if not _active():
		return 0.0
	var l: Label = CardView.make_label(font_size)
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 9)
	parent.add_child(l)
	l.size = l.get_minimum_size()
	var screen_w: float = parent.get_viewport_rect().size.x
	var x: float = clampf(at.x - l.size.x * 0.5, 8.0, maxf(8.0, screen_w - l.size.x - 8.0))
	l.position = Vector2(x, at.y - l.size.y * 0.5)
	l.pivot_offset = l.size * 0.5
	l.scale = Vector2.ONE * cfg_f("number", "pop_scale", 1.5)
	var secs: float = t(cfg_f("number", "seconds", 1.05))
	var fade: float = t(cfg_f("number", "fade_seconds", 0.35))
	var pop: float = t(cfg_f("number", "pop_seconds", 0.14))
	var tw: Tween = new_tween(l).set_parallel(true)
	tw.tween_property(l, "scale", Vector2.ONE, pop).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:y", l.position.y - cfg_f("number", "rise", 64.0), secs)
	tw.tween_property(l, "modulate:a", 0.0, fade).set_delay(maxf(0.0, secs - fade))
	tw.chain().tween_callback(l.queue_free)
	return pop


## Burst of small diamonds from `at` (sparkles / poof). Returns its duration.
func burst(parent: Control, at: Vector2, color: Color, count: int, radius: float, seconds: float) -> float:
	if not _active():
		return 0.0
	var secs: float = t(seconds)
	for i: int in count:
		var d := ColorRect.new()
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		d.color = color
		d.size = Vector2(9, 9)
		d.pivot_offset = d.size * 0.5
		d.rotation = PI * 0.25
		parent.add_child(d)
		d.position = at - d.size * 0.5
		var a: float = TAU * float(i) / float(maxi(count, 1))
		var dist: float = radius * (0.65 + 0.35 * float(i % 3) / 2.0)
		var tw: Tween = new_tween(d).set_parallel(true)
		tw.tween_property(d, "position", at - d.size * 0.5 + Vector2(cos(a), sin(a)) * dist, secs).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(d, "modulate:a", 0.0, secs).set_delay(secs * 0.4)
		tw.tween_property(d, "scale", Vector2.ONE * 0.3, secs)
		tw.chain().tween_callback(d.queue_free)
	return secs


func _ball_arc(p: float, ball: Control, from: Vector2, to: Vector2, arc: float) -> void:
	if is_instance_valid(ball):
		ball.position = from.lerp(to, p) - Vector2(0, sin(p * PI) * arc) - ball.size * 0.5
		ball.rotation = p * TAU * 2.0


## Capture throw (await it): a ball arcs from `from` to `to`, `target` is absorbed, the ball wobbles, then sparkles
## (success) or a poof and the target pops back (failure). Positions are in `parent` coordinates.
func capture_throw(parent: Control, from: Vector2, to: Vector2, color: Color, success: bool, target: Control) -> void:
	if not _active():
		return
	var size_px: float = cfg_f("capture", "ball_size", 30.0)
	var ball := FxBall.new()
	ball.color = color
	ball.size = Vector2.ONE * size_px
	ball.pivot_offset = ball.size * 0.5
	parent.add_child(ball)
	ball.position = from - ball.size * 0.5
	var arc: float = cfg_f("capture", "arc_height", 150.0)
	var ts: float = t(cfg_f("capture", "throw_seconds", 0.55))
	var tw: Tween = new_tween(ball)
	tw.tween_method(_ball_arc.bind(ball, from, to, arc), 0.0, 1.0, ts)
	await wait(ts)
	if _skip or not is_instance_valid(ball):
		return
	var absorb: float = t(cfg_f("capture", "absorb_seconds", 0.25))
	if target != null and is_instance_valid(target):
		target.pivot_offset = Vector2(target.size.x * 0.5, target.size.y * 0.7)
		target.modulate = cfg_color("flash", "modulate", Color(3.4, 3.4, 3.4, 1.0))
		var at: Tween = new_tween(target).set_parallel(true)
		at.tween_property(target, "scale", Vector2.ONE * 0.12, absorb).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		at.tween_property(target, "modulate", Color(1, 1, 1, 0.0), absorb)
	var drop: Tween = new_tween(ball)
	drop.tween_property(ball, "position:y", ball.position.y + 24.0, absorb).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await wait(absorb + t(0.05))
	var wob: float = t(cfg_f("capture", "wobble_seconds", 0.28))
	var deg: float = deg_to_rad(cfg_f("capture", "wobble_degrees", 24.0))
	var count: int = int(cfg_f("capture", "wobble_count", 3.0))
	if not _skip and is_instance_valid(ball):
		ball.rotation = 0.0
		var wt: Tween = new_tween(ball)
		for i: int in count:
			wt.tween_property(ball, "rotation", deg, wob * 0.25)
			wt.tween_property(ball, "rotation", -deg, wob * 0.5)
			wt.tween_property(ball, "rotation", 0.0, wob * 0.25)
			wt.tween_interval(wob * 0.3)
		await wait((wob * 1.3) * float(count))
	if _skip or not is_instance_valid(ball):
		return
	var centre: Vector2 = ball.position + ball.size * 0.5
	var burst_s: float = cfg_f("capture", "burst_seconds", 0.55)
	var n: int = int(cfg_f("capture", "sparkle_count", 14.0))
	var radius: float = cfg_f("capture", "sparkle_radius", 70.0)
	if success:
		burst(parent, centre, cfg_color("capture", "success_color", Color(1, 0.95, 0.5)), n, radius, burst_s)
		pulse(ball, 1.5, 0.4)
		await wait(t(0.45))
	else:
		burst(parent, centre, cfg_color("capture", "failure_color", Color(0.85, 0.85, 0.9)), maxi(6, n / 2), radius * 0.7, burst_s)
		new_tween(ball).tween_property(ball, "modulate:a", 0.0, t(0.2))
		if target != null and is_instance_valid(target):
			var back: Tween = new_tween(target).set_parallel(true)
			back.tween_property(target, "scale", Vector2.ONE, t(0.25)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			back.tween_property(target, "modulate", Color.WHITE, t(0.25))
		await wait(t(0.3))
	if is_instance_valid(ball):
		ball.queue_free()
