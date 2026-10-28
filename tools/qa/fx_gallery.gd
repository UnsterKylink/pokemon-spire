extends SceneTree
## QA harness (story 021): renders every AttackFx effect on a battle backdrop for screenshots.
## Per type: its projectile (mid-flight) and its impact (mid-burst) in one cell of a 3x2 grid, 6 types per shot:
## 01-effets-<groupe>.png .. 03-..., then 04-statuts.png and 05-buffs.png. Effects are played slowed down
## (GALLERY_SPEED) and the shot is taken at a fixed fraction of their duration.
## Run (needs a display):
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --windowed --resolution 1280x720 -s res://tools/qa/fx_gallery.gd -- <out_dir> [project_dir]

const GALLERY_SPEED: float = 0.3
## Fraction of the (slowed) projectile duration that has elapsed at the screenshot; the impact is started earlier.
const SHOT_AT: float = 4.0
const SHOT_PROJECTILE_FRACTION: float = 0.34
const SHOT_IMPACT_FRACTION: float = 0.5
const GROUPS: Array = [
	["feu-eau-electrik-plante-glace-combat", ["fire", "water", "electric", "grass", "ice", "fighting"], "route"],
	["poison-sol-vol-psy-insecte-roche", ["poison", "ground", "flying", "psychic", "bug", "rock"], "water"],
	["spectre-dragon-tenebres-acier-fee-normal", ["ghost", "dragon", "dark", "steel", "fairy", "normal"], "league"],
]
const STATUS_IDS: Array[String] = ["sleep", "paralysis", "poison", "burn", "freeze"]
const BUFF_KINDS: Array[String] = ["block", "heal", "strength", "energy"]
const COLS: int = 3
const ROWS: int = 2

var _out_dir: String = "user://qa"
var _stage: Control
var _backdrop: BattleBackdrop
var _shot_index: int = 0


## Placeholder fighter silhouette so the effect is judged on top of a body.
class Dummy extends Control:
	func _draw() -> void:
		draw_circle(Vector2(0, -50), 32.0, Color(0.25, 0.28, 0.35, 0.9))
		draw_circle(Vector2(0, 8), 40.0, Color(0.25, 0.28, 0.35, 0.9))


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_out_dir = args[0]
	if not _out_dir.is_absolute_path() and not _out_dir.begins_with("user://") and not _out_dir.begins_with("res://"):
		var base: String = args[1] if args.size() > 1 else "."
		_out_dir = ProjectSettings.globalize_path("res://").path_join(_out_dir) if base == "." else base.path_join(_out_dir)
	DirAccess.make_dir_recursive_absolute(_out_dir)
	_run.call_deferred()


func _run() -> void:
	var size: Vector2 = Vector2(root.size)
	for g: Array in GROUPS:
		_new_stage(String(g[2]), size)
		var ids: Array = g[1]
		var events: Array = []
		for i: int in ids.size():
			var id: String = String(ids[i])
			var cell: Rect2 = _cell(i, size)
			_place_cell(cell, id)
			var dp: float = AttackFx.duration_of(id, AttackFx.KIND_PROJECTILE) / GALLERY_SPEED
			var di: float = AttackFx.duration_of(id, AttackFx.KIND_IMPACT) / GALLERY_SPEED
			events.append([SHOT_AT - dp * SHOT_PROJECTILE_FRACTION, func() -> void: AttackFx.play_projectile(_stage, id, _source(cell), _target(cell), GALLERY_SPEED)])
			events.append([SHOT_AT - di * SHOT_IMPACT_FRACTION, func() -> void: AttackFx.play_impact(_stage, id, _target(cell), GALLERY_SPEED, 1.0)])
		await _play_and_shoot(events, "%02d-effets-%s" % [_shot_index + 1, String(g[0])])
	_new_stage("route", size)
	var st_events: Array = []
	for i: int in STATUS_IDS.size():
		var sid: String = STATUS_IDS[i]
		var cell: Rect2 = _cell(i, size)
		_place_cell(cell, "")
		_label(cell, sid)
		var d: float = AttackFx.duration_of(sid, AttackFx.KIND_STATUS) / GALLERY_SPEED
		st_events.append([SHOT_AT - d * SHOT_IMPACT_FRACTION, func() -> void: AttackFx.play_status(_stage, sid, _target(cell), GALLERY_SPEED)])
	await _play_and_shoot(st_events, "%02d-statuts" % [_shot_index + 1])
	_new_stage("league", size)
	var bf_events: Array = []
	for i: int in BUFF_KINDS.size():
		var kind: String = BUFF_KINDS[i]
		var cell: Rect2 = _cell(i, size)
		_place_cell(cell, "")
		_label(cell, kind)
		var d: float = AttackFx.duration_of(kind, AttackFx.KIND_BUFF) / GALLERY_SPEED
		bf_events.append([SHOT_AT - d * SHOT_IMPACT_FRACTION, func() -> void: AttackFx.play_buff(_stage, kind, _target(cell), GALLERY_SPEED)])
	await _play_and_shoot(bf_events, "%02d-buffs" % [_shot_index + 1])
	quit()


## Fires every [start_time, callable] event at its time (seconds, relative to now), then takes the shot at SHOT_AT.
func _play_and_shoot(events: Array, shot_name: String) -> void:
	events.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var clock: float = 0.0
	for ev: Array in events:
		var at: float = maxf(float(ev[0]), 0.0)
		await _wait(at - clock)
		clock = maxf(clock, at)
		(ev[1] as Callable).call()
	await _wait(SHOT_AT - clock)
	await _shot(shot_name)
	await _wait(1.5)


func _new_stage(backdrop_id: String, size: Vector2) -> void:
	if _stage != null:
		_stage.queue_free()
	_stage = Control.new()
	_stage.size = size
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_stage)
	_backdrop = BattleBackdrop.new()
	_backdrop.size = size
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_backdrop)
	_backdrop.set_backdrop(backdrop_id)
	_backdrop.set_motion_enabled(false)
	_backdrop.set_hand_top(size.y)


func _cell(i: int, size: Vector2) -> Rect2:
	var w: float = size.x / float(COLS)
	var h: float = size.y / float(ROWS)
	return Rect2(float(i % COLS) * w, float(i / COLS) * h, w, h)


func _source(cell: Rect2) -> Vector2:
	return Vector2(cell.position.x + 70.0, cell.position.y + cell.size.y * 0.58)


func _target(cell: Rect2) -> Vector2:
	return Vector2(cell.end.x - 80.0, cell.position.y + cell.size.y * 0.58)


## Draws the two placeholder fighters of a cell (the attacker only when `type_id` is set) and the type label.
func _place_cell(cell: Rect2, type_id: String) -> void:
	var tgt: Control = Dummy.new()
	tgt.position = _target(cell) + Vector2(0, 55)
	_stage.add_child(tgt)
	if not type_id.is_empty():
		var src: Control = Dummy.new()
		src.position = _source(cell) + Vector2(0, 55)
		_stage.add_child(src)
		_label(cell, type_id)


func _label(cell: Rect2, text: String) -> void:
	var l: Label = Label.new()
	l.text = text.to_upper()
	l.position = cell.position + Vector2(14.0, 8.0)
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	_stage.add_child(l)


func _wait(seconds: float) -> void:
	await create_timer(maxf(seconds, 0.01)).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	img.save_png(_out_dir.path_join(shot_name + ".png"))
	print("shot ", shot_name)
	_shot_index += 1
