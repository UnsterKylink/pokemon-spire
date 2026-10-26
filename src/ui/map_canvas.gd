class_name MapCanvas
extends Control
## Draws the act map as an ink drawing on parchment (story 020b, Slay the Spire spirit): one (transparent) Button
## per room laid out by (col, floor) (floor 1 at the bottom, gym on top), corridors as hand-drawn ink dashes (slight
## jitter, varying thickness), room icons as ink stamps over a watercolour wash of the room colour, the travelled
## path as a solid ink trail, visited rooms circled by hand, a soft glow on the reachable rooms, a red circle and a
## Poké Ball pin on the current room, and the gym as a bigger illustrated emblem (laurels, type-coloured badge).
## The parchment sheet itself is drawn by MapScreen behind this (transparent) canvas.
## Only reachable rooms are clickable. Display only: reads MapGraph / ActProgress and emits node_pressed.
## Implements: story-005-carte-acte-1, story-020-style-graphique, story-020b-refonte-visuelle-premium (parchment map).

## Emitted when a reachable room button is clicked.
signal node_pressed(node_id: String)

## Drawing states of a room icon (draw_room_icon).
enum IconState { NORMAL, FUTURE, REACHABLE, VISITED, CURRENT }

const COL_SPACING: float = 150.0
const ROW_SPACING: float = 66.0
const PAD_TOP: float = 58.0
const PAD_BOTTOM: float = 36.0
## Radius of a room icon / of the gym emblem.
const ICON_RADIUS: float = 21.0
const BOSS_RADIUS: float = 30.0
## Click area of a room (the boss button also covers its label).
const NODE_SIZE: Vector2 = Vector2(52, 52)
const BOSS_SIZE: Vector2 = Vector2(76, 76)
const NODE_FONT_SIZE: int = 16
const BOSS_FONT_SIZE: int = 22
## Short label of each room (kept as the button text for the QA harness / tooltips; the icon is drawn).
const ROOM_SHORT: Dictionary = {"wild": "Combat", "elite": "Élite", "center": "Centre", "mart": "Mart",
		"event": "?", "boss": "Champion", "rival": "Rival"}
## Colour per room type (art bible §5; the watercolour wash under the ink stamp; also used by the legend and Main).
const ROOM_COLORS: Dictionary = {
	"wild": Color("#D95C4D"), "elite": Color("#AD5CE6"), "center": Color("#F280B3"),
	"mart": Color("#4D99F2"), "event": Color("#59BF6B"), "boss": Color("#FFC238"),
	"rival": Color("#F07A3A")}
const COLOR_UNKNOWN_ROOM: Color = Color(0.6, 0.6, 0.6)
## Ink palette (story 020b).
const INK: Color = Color("#2A1D12")
const INK_RED: Color = Color("#A3271B")
const PAPER: Color = Color("#EEDFBC")
const GLOW: Color = Color("#FFE58A")
## Alpha of the ink of rooms not reachable yet / of the faint corridors.
const FUTURE_ALPHA: float = 0.5
const WASH_ALPHA: float = 0.5
const DASH_LEN: float = 7.0
const DASH_GAP: float = 6.0
const TRAIL_WIDTH: float = 3.6
## Kept for compatibility (story 020 names).
const COLOR_TRAIL: Color = INK
const COLOR_VISITED_MARK: Color = INK

var _graph: MapGraph
var _progress: ActProgress
var _room_names: Dictionary = {}
var _buttons: Dictionary = {}
var _reachable: Array[String] = []
var _boss_label: String = ""
## Gym type colour (centre of the gym emblem), set by MapScreen.
var _zone_color: Color = UiStyle.ACCENT_RED


## Story 020: colour of the zone's gym type (drawn inside the gym emblem). Call before setup.
func set_zone_color(color: Color) -> void:
	_zone_color = color
	queue_redraw()


## Builds the buttons for `progress.graph`. `room_names`: room type -> display name (tooltips). `boss_label`
## (story 012, optional): text of the gym room ("Arène Roche"); ROOM_SHORT's "Champion" when empty.
## `rival_tip` (story 018, optional): extra tooltip line of the rival rooms (e.g. "Régis et Carapuce").
func setup(progress: ActProgress, room_names: Dictionary, boss_label: String = "", rival_tip: String = "") -> void:
	_progress = progress
	_graph = progress.graph
	_room_names = room_names
	_reachable = progress.reachable_ids()
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_buttons.clear()
	_boss_label = boss_label if not boss_label.is_empty() else String(ROOM_SHORT["boss"])
	custom_minimum_size = Vector2(_graph.width * COL_SPACING, PAD_TOP + PAD_BOTTOM + (_graph.floors - 1) * ROW_SPACING)
	for id: String in _graph.nodes.keys():
		var node: MapNode = _graph.nodes[id]
		var b := Button.new()
		b.name = "Room_" + id
		b.text = String(ROOM_SHORT.get(node.room_type, "?"))
		if node.room_type == "boss":
			b.text = _boss_label
		b.tooltip_text = "%s — étage %d" % [String(_room_names.get(node.room_type, node.room_type)), node.floor]
		if node.room_type == "rival" and not rival_tip.is_empty():
			b.tooltip_text += "\n" + rival_tip
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", BOSS_FONT_SIZE if node.room_type == "boss" else NODE_FONT_SIZE)
		_style_button(b, node)
		b.pressed.connect(_on_button_pressed.bind(id))
		add_child(b)
		_buttons[id] = b
	_layout()


## Ids currently clickable.
func get_reachable_ids() -> Array[String]:
	return _reachable


## The button of a room (null if unknown), for the QA harness.
func get_button(node_id: String) -> Button:
	return _buttons.get(node_id, null)


## Y (canvas coordinates) of the centre of a floor's row.
func floor_y(floor_number: int) -> float:
	return PAD_TOP + (_graph.floors - floor_number) * ROW_SPACING if _graph != null else 0.0


## Centre of a room in canvas coordinates (the boss is centred horizontally).
func node_center(node: MapNode) -> Vector2:
	var x0: float = (size.x - (_graph.width - 1) * COL_SPACING) * 0.5
	var x: float = x0 + node.col * COL_SPACING
	if node.room_type == "boss":
		x = size.x * 0.5
	return Vector2(x, floor_y(node.floor))


## Draws the ink stamp of a `room_type` room centred on `c` (radius `r`) on `ci`: watercolour wash of the room colour,
## dark ink glyph (the gym: laurels + type-coloured octagonal badge `accent`), then the state annotation (glow for
## reachable, hand-drawn ink circle for visited, red circle for the current room, faded ink for future rooms).
static func draw_room_icon(ci: CanvasItem, c: Vector2, r: float, room_type: String, state: int,
		accent: Color = UiStyle.ACCENT_RED) -> void:
	var base: Color = ROOM_COLORS.get(room_type, COLOR_UNKNOWN_ROOM)
	var seed_f: float = fposmod(c.x * 0.137 + c.y * 0.071, TAU)
	var ink_a: float = FUTURE_ALPHA if state == IconState.FUTURE else 1.0
	if state == IconState.VISITED:
		ink_a = 0.72
	if state == IconState.REACHABLE:
		for i: int in 5:
			ci.draw_circle(c, r + 18.0 - i * 3.5, Color(GLOW, 0.07 + i * 0.045))
	var wash_a: float = WASH_ALPHA * (0.45 if state == IconState.FUTURE else (0.6 if state == IconState.VISITED else 1.0))
	var wash_r: float = r * (1.05 if room_type == "boss" else 0.95)
	ci.draw_colored_polygon(_blob(c + Vector2(r * 0.06, r * 0.05), wash_r, seed_f, 0.1), Color(base, wash_a))
	ci.draw_colored_polygon(_blob(c - Vector2(r * 0.05, r * 0.04), wash_r * 0.72, seed_f + 2.0, 0.14),
			Color(base.lightened(0.15), wash_a * 0.6))
	var ink: Color = Color(INK, ink_a)
	if room_type == "boss":
		_draw_gym_emblem(ci, c, r, accent, state, ink)
	else:
		_draw_glyph(ci, c, r, room_type, ink)
	match state:
		IconState.VISITED:
			_hand_circle(ci, c, r + 6.0, seed_f, Color(INK, 0.85), 2.6)
		IconState.CURRENT:
			_hand_circle(ci, c, r + 7.0, seed_f, INK_RED, 3.4)
		IconState.REACHABLE:
			ci.draw_arc(c, r + 6.0, 0.0, TAU, 48, Color(INK, 0.35), 1.4, true)


## Draws a small Poké Ball (the "you are here" pin) of radius `r` at `c`.
static func draw_ball_marker(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c + Vector2(1.5, 3), r + 2.0, Color(INK, 0.3))
	ci.draw_circle(c, r + 2.0, INK)
	ci.draw_circle(c, r, Color.WHITE)
	var top := PackedVector2Array()
	for i: int in 17:
		top.append(c + Vector2.from_angle(PI + PI * i / 16.0) * r)
	ci.draw_colored_polygon(top, UiStyle.ACCENT_RED)
	ci.draw_line(c - Vector2(r, 0), c + Vector2(r, 0), INK, 2.5)
	ci.draw_circle(c, r * 0.36, INK)
	ci.draw_circle(c, r * 0.22, Color.WHITE)


## Gym emblem: two ink laurel branches, an octagonal badge (ink rim, type colour inside, parchment star).
static func _draw_gym_emblem(ci: CanvasItem, c: Vector2, r: float, accent: Color, state: int, ink: Color) -> void:
	for side: float in [-1.0, 1.0]:  # laurels
		var stem := PackedVector2Array()
		for k: int in 9:
			var a: float = deg_to_rad(110.0 - k * 17.0)
			stem.append(c + Vector2(side * cos(a) * (r + 9.0) * -1.0, sin(a) * (r + 9.0) * 0.95 + 3.0))
		ci.draw_polyline(stem, ink, 2.0, true)
		for k: int in range(1, 9):
			var p: Vector2 = stem[k]
			var dir: Vector2 = (stem[k] - stem[k - 1]).normalized()
			var nrm: Vector2 = Vector2(-dir.y, dir.x) * side * -1.0
			var tip: Vector2 = p + dir * 7.0 + nrm * 6.0
			var leaf := PackedVector2Array([p, p + dir * 3.5 + nrm * 4.5, tip, p + dir * 5.0 - nrm * 0.5])
			ci.draw_colored_polygon(leaf, ink)
	ci.draw_colored_polygon(_ngon(c + Vector2(2, 3), r + 3.0, 8, PI / 8.0), Color(INK, 0.25 * ink.a))
	ci.draw_colored_polygon(_ngon(c, r + 3.0, 8, PI / 8.0), ink)
	var fill: Color = accent if state != IconState.FUTURE else accent.lerp(PAPER, 0.35)
	ci.draw_colored_polygon(_ngon(c, r - 0.5, 8, PI / 8.0), fill.darkened(0.2))
	ci.draw_colored_polygon(_ngon(c - Vector2(0, r * 0.06), r * 0.86, 8, PI / 8.0), fill)
	ci.draw_polyline(_closed(_ngon(c, r * 0.66, 8, PI / 8.0)), Color(INK, 0.55 * ink.a), 1.6, true)
	var star: PackedVector2Array = _star(c, r * 0.5, r * 0.21)
	ci.draw_polyline(_closed(star), ink, 3.5, true)
	ci.draw_colored_polygon(star, PAPER)
	ci.draw_arc(c + Vector2(-r * 0.3, -r * 0.35), r * 0.32, deg_to_rad(200), deg_to_rad(270), 8,
			Color(1, 1, 1, 0.35), 2.0, true)


## Ink glyph of a normal room (filled silhouettes; "?" is drawn as a brush stroke, no font).
static func _draw_glyph(ci: CanvasItem, c: Vector2, r: float, room_type: String, ink: Color) -> void:
	match room_type:
		"wild":
			var by: float = c.y + r * 0.55
			for k: int in 3:
				var x: float = c.x + (k - 1) * r * 0.45
				var h: float = r * (1.15 if k == 1 else 0.85)
				var lean: float = (k - 1) * r * 0.22
				ci.draw_colored_polygon(PackedVector2Array([Vector2(x - r * 0.2, by), Vector2(x + lean, by - h),
						Vector2(x + r * 0.2, by)]), ink)
			ci.draw_line(Vector2(c.x - r * 0.8, by), Vector2(c.x + r * 0.8, by), ink, 2.2, true)
		"elite":
			ci.draw_colored_polygon(_star(c + Vector2(0, r * 0.04), r * 0.78, r * 0.34), ink)
			ci.draw_circle(c + Vector2(0, r * 0.04), r * 0.16, Color(PAPER, ink.a))
		"rival":
			var pts := PackedVector2Array()
			for p: Vector2 in [Vector2(0.22, -0.85), Vector2(-0.5, 0.12), Vector2(-0.05, 0.12), Vector2(-0.24, 0.85),
					Vector2(0.52, -0.16), Vector2(0.07, -0.16)]:
				pts.append(c + p * r)
			ci.draw_colored_polygon(pts, ink)
		"center":
			var a: float = r * 0.24
			var l: float = r * 0.7
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-a, -l), c + Vector2(a, -l), c + Vector2(a, -a),
					c + Vector2(l, -a), c + Vector2(l, a), c + Vector2(a, a), c + Vector2(a, l), c + Vector2(-a, l),
					c + Vector2(-a, a), c + Vector2(-l, a), c + Vector2(-l, -a), c + Vector2(-a, -a)]), ink)
		"mart":
			var pts := PackedVector2Array()
			for p: Vector2 in [Vector2(-0.62, 0.55), Vector2(-0.62, -0.55), Vector2(-0.3, -0.55), Vector2(0, -0.06),
					Vector2(0.3, -0.55), Vector2(0.62, -0.55), Vector2(0.62, 0.55), Vector2(0.32, 0.55), Vector2(0.32, 0.0),
					Vector2(0, 0.38), Vector2(-0.32, 0.0), Vector2(-0.32, 0.55)]:
				pts.append(c + p * r)
			ci.draw_colored_polygon(pts, ink)
		_:
			var hook := PackedVector2Array()
			var hc: Vector2 = c + Vector2(0, -r * 0.3)
			for k: int in 13:
				hook.append(hc + Vector2.from_angle(PI * 1.05 + k * PI * 1.35 / 12.0) * r * 0.36)
			hook.append(c + Vector2(0, r * 0.08))
			hook.append(c + Vector2(0, r * 0.26))
			ci.draw_polyline(hook, ink, r * 0.2, true)
			ci.draw_circle(c + Vector2(0, r * 0.58), r * 0.13, ink)


## Hand-drawn ink circle (a bit more than one turn, wobbly radius, brush thickness varying along the stroke).
static func _hand_circle(ci: CanvasItem, c: Vector2, r: float, seed_f: float, col: Color, width: float) -> void:
	var steps: int = 36
	var a0: float = -2.2 + seed_f * 0.2
	var prev: Vector2 = Vector2.ZERO
	for i: int in steps + 1:
		var t: float = float(i) / steps
		var a: float = a0 + t * TAU * 1.1
		var rr: float = r * (1.0 + 0.05 * sin(a * 2.0 + seed_f) + 0.07 * t)
		var p: Vector2 = c + Vector2(cos(a) * rr * 1.05, sin(a) * rr * 0.95)
		if i > 0:
			var w: float = width * (0.45 + 0.75 * sin(t * PI))
			ci.draw_line(prev, p, col, maxf(1.0, w), true)
		prev = p


static func _blob(c: Vector2, r: float, seed_f: float, wobble: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in 20:
		var a: float = TAU * i / 20.0
		var k: float = 1.0 + wobble * sin(a * 3.0 + seed_f) + wobble * 0.6 * sin(a * 5.0 + seed_f * 1.7)
		pts.append(c + Vector2.from_angle(a) * r * k)
	return pts


static func _closed(pts: PackedVector2Array) -> PackedVector2Array:
	var out: PackedVector2Array = pts.duplicate()
	out.append(pts[0])
	return out


static func _star(c: Vector2, ro: float, ri: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in 10:
		pts.append(c + Vector2.from_angle(-PI / 2.0 + i * PI / 5.0) * (ro if i % 2 == 0 else ri))
	return pts


static func _ngon(c: Vector2, r: float, n: int, phase: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in n:
		pts.append(c + Vector2.from_angle(phase + TAU * i / n) * r)
	return pts


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout()


func _layout() -> void:
	if _graph == null:
		return
	for id: String in _buttons.keys():
		var node: MapNode = _graph.nodes[id]
		var b: Button = _buttons[id]
		var s: Vector2 = BOSS_SIZE if node.room_type == "boss" else NODE_SIZE
		b.size = s
		b.position = node_center(node) - s * 0.5
	queue_redraw()


func _draw() -> void:
	if _graph == null:
		return
	var current: String = _progress.current_node_id
	var trails: Array[PackedVector2Array] = []
	for id: String in _graph.nodes.keys():
		var node: MapNode = _graph.nodes[id]
		var from: Vector2 = node_center(node)
		for next_id: String in node.next:
			var other: MapNode = _graph.get_node(next_id)
			if other == null:
				continue
			var to: Vector2 = node_center(other)
			var skip_a: float = _radius(node) + 7.0
			var skip_b: float = _radius(other) + 7.0
			if _is_walked(id, next_id):
				trails.append(PackedVector2Array([from, to, Vector2(skip_a, skip_b)]))
			elif id == current and _reachable.has(next_id):
				_ink_dashes(from, to, skip_a, skip_b, Color(INK, 0.9), 2.6)
			else:
				_ink_dashes(from, to, skip_a, skip_b, Color(INK, 0.42), 1.9)
	for seg: PackedVector2Array in trails:
		_ink_trail(seg[0], seg[1], seg[2].x, seg[2].y)
	for id: String in _graph.nodes.keys():
		var node: MapNode = _graph.nodes[id]
		var c: Vector2 = node_center(node)
		var r: float = _radius(node)
		draw_room_icon(self, c, r, node.room_type, _state_of(id), _zone_color)
		if node.room_type == "boss":
			_draw_boss_label(c, r)
	if not current.is_empty() and _graph.nodes.has(current):
		var cn: MapNode = _graph.nodes[current]
		var cr: float = _radius(cn)
		draw_ball_marker(self, node_center(cn) + Vector2(-cr - 9.0, -cr + 1.0), 9.0)


func _radius(node: MapNode) -> float:
	return BOSS_RADIUS if node.room_type == "boss" else ICON_RADIUS


## Gym name written in ink next to the emblem, on a small parchment-coloured halo so it reads over the dashes.
func _draw_boss_label(c: Vector2, r: float) -> void:
	var font: Font = get_theme_default_font()
	var pos: Vector2 = c + Vector2(r + 24.0, BOSS_FONT_SIZE * 0.36)
	draw_string_outline(font, pos, _boss_label, HORIZONTAL_ALIGNMENT_LEFT, -1, BOSS_FONT_SIZE, 8, Color(PAPER, 0.85))
	draw_string(font, pos, _boss_label, HORIZONTAL_ALIGNMENT_LEFT, -1, BOSS_FONT_SIZE, INK)
	var w: float = font.get_string_size(_boss_label, HORIZONTAL_ALIGNMENT_LEFT, -1, BOSS_FONT_SIZE).x
	var uy: float = pos.y + 5.0
	draw_line(Vector2(pos.x - 2.0, uy), Vector2(pos.x + w * 0.55, uy + 1.5), Color(INK, 0.8), 2.2, true)
	draw_line(Vector2(pos.x + w * 0.55, uy + 1.5), Vector2(pos.x + w + 4.0, uy - 0.5), Color(INK, 0.8), 1.4, true)


func _state_of(id: String) -> int:
	if id == _progress.current_node_id:
		return IconState.CURRENT
	if _progress.is_visited(id):
		return IconState.VISITED
	if _reachable.has(id):
		return IconState.REACHABLE
	return IconState.FUTURE


## Hand-drawn ink dashes from `a` to `b` (skipping `skip_a` / `skip_b` px at the ends): deterministic perpendicular
## jitter and varying stroke thickness so the corridor looks drawn with a nib.
func _ink_dashes(a: Vector2, b: Vector2, skip_a: float, skip_b: float, col: Color, width: float) -> void:
	var length: float = a.distance_to(b)
	var usable: float = length - skip_a - skip_b
	if usable <= DASH_LEN:
		return
	var dir: Vector2 = (b - a) / length
	var nrm: Vector2 = Vector2(-dir.y, dir.x)
	var seed_f: float = fposmod(a.x * 0.013 + b.y * 0.029 + b.x * 0.007, TAU)
	var step: float = DASH_LEN + DASH_GAP
	var n: int = int((usable + DASH_GAP) / step)
	var start: float = skip_a + (usable - (n * step - DASH_GAP)) * 0.5
	for i: int in n:
		var d0: float = start + i * step
		var d1: float = d0 + DASH_LEN * (0.8 + 0.3 * absf(sin(i * 2.3 + seed_f)))
		var j0: float = sin(d0 * 0.09 + seed_f) * 1.6
		var j1: float = sin(d1 * 0.09 + seed_f) * 1.6
		var w: float = width * (0.75 + 0.45 * absf(sin(i * 1.7 + seed_f * 2.0)))
		draw_line(a + dir * d0 + nrm * j0, a + dir * d1 + nrm * j1, col, w, true)


## Solid ink trail of a walked corridor (wobbly polyline, thickness varying like a brush stroke).
func _ink_trail(a: Vector2, b: Vector2, skip_a: float, skip_b: float) -> void:
	var length: float = a.distance_to(b)
	if length <= skip_a + skip_b:
		return
	var dir: Vector2 = (b - a) / length
	var nrm: Vector2 = Vector2(-dir.y, dir.x)
	var seed_f: float = fposmod(a.x * 0.011 + a.y * 0.017 + b.x * 0.023, TAU)
	var steps: int = maxi(4, int((length - skip_a - skip_b) / 6.0))
	var prev: Vector2 = Vector2.ZERO
	for i: int in steps + 1:
		var t: float = float(i) / steps
		var d: float = lerpf(skip_a - 2.0, length - skip_b + 2.0, t)
		var p: Vector2 = a + dir * d + nrm * sin(d * 0.07 + seed_f) * 1.4
		if i > 0:
			var w: float = TRAIL_WIDTH * (0.8 + 0.35 * sin(t * PI) + 0.12 * sin(i * 1.3 + seed_f))
			draw_line(prev, p, Color(INK, 0.92), w, true)
			draw_circle(p, w * 0.5, Color(INK, 0.92))
		prev = p


## True if the player walked from `a` straight to `b` (consecutive in the visit order).
func _is_walked(a: String, b: String) -> bool:
	var i: int = _progress.visited.find(a)
	return i >= 0 and i + 1 < _progress.visited.size() and _progress.visited[i + 1] == b


## Transparent click area (the icon is drawn by _draw); hover = faint ink ring. The text stays for the QA harness
## and is drawn invisible.
func _style_button(b: Button, node: MapNode) -> void:
	var clickable: bool = _reachable.has(node.id) and node.id != _progress.current_node_id
	b.disabled = not clickable
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if clickable else Control.CURSOR_ARROW
	var empty := StyleBoxEmpty.new()
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(GLOW, 0.3)
	hover.border_color = Color(INK, 0.75)
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(40)
	hover.anti_aliasing = true
	for state: String in ["normal", "disabled", "focus"]:
		b.add_theme_stylebox_override(state, empty)
	for state: String in ["hover", "pressed"]:
		b.add_theme_stylebox_override(state, hover)
	for c: String in ["font_color", "font_disabled_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, Color(0, 0, 0, 0))
	b.add_theme_constant_override("outline_size", 0)


func _on_button_pressed(node_id: String) -> void:
	if _reachable.has(node_id):
		node_pressed.emit(node_id)


## Legend / UI swatch: one room ink stamp drawn in a small Control (story 020).
class RoomIcon extends Control:
	var room_type: String = ""
	var accent: Color = UiStyle.ACCENT_RED

	func _init(type_id: String = "", side: float = 26.0, accent_color: Color = UiStyle.ACCENT_RED) -> void:
		room_type = type_id
		accent = accent_color
		custom_minimum_size = Vector2(side, side)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r: float = minf(size.x, size.y) * 0.5 - 3.0
		if room_type == "boss":
			r -= 4.0  # room for the laurels
		MapCanvas.draw_room_icon(self, size * 0.5, r, room_type, MapCanvas.IconState.NORMAL, accent)
