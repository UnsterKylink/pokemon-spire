class_name MapCanvas
extends Control
## Draws the act map: one (transparent) Button per room laid out by (col, floor) (floor 1 at the bottom, boss on
## top), the room icons, the corridors (dotted, the travelled path as a thick yellow trail), a glow on the reachable
## rooms, a check mark on the visited ones and a Poké Ball marker on the current room (_draw).
## Only reachable rooms are clickable. Display only: reads MapGraph / ActProgress and emits node_pressed.
## Implements: story-005-carte-acte-1, story-020-style-graphique (room icons, travelled path; design/art-bible.md §5).

## Emitted when a reachable room button is clicked.
signal node_pressed(node_id: String)

## Drawing states of a room icon (draw_room_icon).
enum IconState { NORMAL, FUTURE, REACHABLE, VISITED, CURRENT }

const COL_SPACING: float = 150.0
const ROW_SPACING: float = 66.0
const PAD_TOP: float = 52.0
const PAD_BOTTOM: float = 40.0
## Radius of a room icon / of the gym badge.
const ICON_RADIUS: float = 21.0
const BOSS_RADIUS: float = 30.0
## Click area of a room (the boss button also covers its label).
const NODE_SIZE: Vector2 = Vector2(52, 52)
const BOSS_SIZE: Vector2 = Vector2(68, 68)
const NODE_FONT_SIZE: int = 16
const BOSS_FONT_SIZE: int = 22
## Short label of each room (kept as the button text for the QA harness / tooltips; the icon is drawn).
const ROOM_SHORT: Dictionary = {"wild": "Combat", "elite": "Élite", "center": "Centre", "mart": "Mart",
		"event": "?", "boss": "Champion", "rival": "Rival"}
## Colour per room type (art bible §5; also used by the legend and Main).
const ROOM_COLORS: Dictionary = {
	"wild": Color("#D95C4D"), "elite": Color("#AD5CE6"), "center": Color("#F280B3"),
	"mart": Color("#4D99F2"), "event": Color("#59BF6B"), "boss": Color("#FFC238"),
	"rival": Color("#F07A3A")}
const COLOR_UNKNOWN_ROOM: Color = Color(0.6, 0.6, 0.6)
const COLOR_TRAIL: Color = UiStyle.ACCENT_YELLOW
const COLOR_DOTS: Color = Color(0.706, 0.745, 0.867, 0.4)  # TEXT_MUTED 40 %
const COLOR_DOTS_NEXT: Color = Color(1.0, 1.0, 1.0, 0.95)
const COLOR_VISITED_MARK: Color = UiStyle.SUCCESS
const TRAIL_WIDTH: float = 6.0
const DOT_SPACING: float = 11.0

var _graph: MapGraph
var _progress: ActProgress
var _room_names: Dictionary = {}
var _buttons: Dictionary = {}
var _reachable: Array[String] = []
var _boss_label: String = ""
## Gym type colour (centre of the gym badge), set by MapScreen.
var _zone_color: Color = UiStyle.ACCENT_RED


## Story 020: colour of the zone's gym type (drawn inside the gym badge). Call before setup.
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


## Draws the icon of a `room_type` room centred on `c` (radius `r`) on `ci` (art bible §5): outlined round badge
## (the gym: golden octagon with the type colour `accent` inside), white glyph, state cues (glow, check, ring).
static func draw_room_icon(ci: CanvasItem, c: Vector2, r: float, room_type: String, state: int,
		accent: Color = UiStyle.ACCENT_RED) -> void:
	var base: Color = ROOM_COLORS.get(room_type, COLOR_UNKNOWN_ROOM)
	if state == IconState.REACHABLE or state == IconState.CURRENT:
		var glow: Color = UiStyle.ACCENT_YELLOW if state == IconState.CURRENT else Color.WHITE
		for i: int in 4:
			ci.draw_circle(c, r + 15.0 - i * 3.5, Color(glow, 0.1 + i * 0.05))
	var fill: Color = base
	if state == IconState.VISITED:
		fill = base.lerp(Color(0.5, 0.52, 0.6), 0.55).darkened(0.3)
	elif state == IconState.FUTURE:
		fill = base.darkened(0.18)
	if room_type == "boss":
		ci.draw_colored_polygon(_ngon(c, r + 3.5, 8, PI / 8.0), UiStyle.OUTLINE)
		ci.draw_colored_polygon(_ngon(c, r, 8, PI / 8.0), fill.darkened(0.15))
		ci.draw_colored_polygon(_ngon(c - Vector2(0, r * 0.08), r * 0.88, 8, PI / 8.0), fill)
		ci.draw_colored_polygon(_ngon(c, r * 0.64 + 2.0, 8, PI / 8.0), UiStyle.OUTLINE)
		ci.draw_colored_polygon(_ngon(c, r * 0.64, 8, PI / 8.0),
				accent if state != IconState.VISITED else accent.darkened(0.4))
		_glyph(ci, _star(c, r * 0.48, r * 0.2), Color.WHITE)
	else:
		ci.draw_circle(c, r + 3.0, UiStyle.OUTLINE)
		ci.draw_circle(c, r, fill.darkened(0.18))
		ci.draw_circle(c - Vector2(0, r * 0.1), r * 0.88, fill)
		ci.draw_circle(c + Vector2(-r * 0.38, -r * 0.42), r * 0.2, Color(1, 1, 1, 0.35))
		var glyph_col: Color = Color.WHITE if state != IconState.VISITED else Color(0.85, 0.86, 0.9)
		_draw_glyph(ci, c, r, room_type, glyph_col)
	if state == IconState.REACHABLE:
		ci.draw_arc(c, r + (7.0 if room_type == "boss" else 6.0), 0.0, TAU, 40, Color.WHITE, 2.5, true)
	elif state == IconState.CURRENT:
		ci.draw_arc(c, r + 6.0, 0.0, TAU, 40, UiStyle.ACCENT_YELLOW, 3.5, true)
	elif state == IconState.VISITED:
		var m: Vector2 = c + Vector2(r * 0.72, r * 0.68)
		ci.draw_circle(m, r * 0.42 + 2.0, UiStyle.OUTLINE)
		ci.draw_circle(m, r * 0.42, COLOR_VISITED_MARK)
		var s: float = r * 0.22
		ci.draw_polyline(PackedVector2Array([m + Vector2(-s, 0), m + Vector2(-s * 0.25, s * 0.8), m + Vector2(s * 1.1, -s * 0.8)]),
				Color.WHITE, 2.5, true)


## Draws a small Poké Ball (the "you are here" marker) of radius `r` at `c`.
static func draw_ball_marker(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c + Vector2(0, 3), r + 2.0, UiStyle.SHADOW)
	ci.draw_circle(c, r + 2.5, UiStyle.OUTLINE)
	ci.draw_circle(c, r, Color.WHITE)
	var top := PackedVector2Array()
	for i: int in 17:
		top.append(c + Vector2.from_angle(PI + PI * i / 16.0) * r)
	ci.draw_colored_polygon(top, UiStyle.ACCENT_RED)
	ci.draw_line(c - Vector2(r, 0), c + Vector2(r, 0), UiStyle.OUTLINE, 2.5)
	ci.draw_circle(c, r * 0.36, UiStyle.OUTLINE)
	ci.draw_circle(c, r * 0.22, Color.WHITE)


static func _draw_glyph(ci: CanvasItem, c: Vector2, r: float, room_type: String, col: Color) -> void:
	match room_type:
		"wild":
			var by: float = c.y + r * 0.5
			for k: int in 3:
				var x: float = c.x + (k - 1) * r * 0.42
				var h: float = r * (1.05 if k == 1 else 0.78)
				var lean: float = (k - 1) * r * 0.18
				_glyph(ci, PackedVector2Array([Vector2(x - r * 0.17, by), Vector2(x + lean, by - h), Vector2(x + r * 0.17, by)]), col)
		"elite":
			_glyph(ci, _star(c + Vector2(0, r * 0.04), r * 0.62, r * 0.27), col)
		"rival":
			var pts := PackedVector2Array()
			for p: Vector2 in [Vector2(0.18, -0.72), Vector2(-0.42, 0.1), Vector2(-0.04, 0.1), Vector2(-0.2, 0.72),
					Vector2(0.44, -0.14), Vector2(0.06, -0.14)]:
				pts.append(c + p * r)
			_glyph(ci, pts, col)
		"center":
			var a: float = r * 0.19
			var l: float = r * 0.58
			_glyph(ci, PackedVector2Array([c + Vector2(-a, -l), c + Vector2(a, -l), c + Vector2(a, -a), c + Vector2(l, -a),
					c + Vector2(l, a), c + Vector2(a, a), c + Vector2(a, l), c + Vector2(-a, l), c + Vector2(-a, a),
					c + Vector2(-l, a), c + Vector2(-l, -a), c + Vector2(-a, -a)]), col)
		"mart":
			var pts := PackedVector2Array()
			for p: Vector2 in [Vector2(-0.52, 0.45), Vector2(-0.52, -0.45), Vector2(-0.26, -0.45), Vector2(0, -0.04),
					Vector2(0.26, -0.45), Vector2(0.52, -0.45), Vector2(0.52, 0.45), Vector2(0.28, 0.45), Vector2(0.28, 0.0),
					Vector2(0, 0.34), Vector2(-0.28, 0.0), Vector2(-0.28, 0.45)]:
				pts.append(c + p * r)
			_glyph(ci, pts, col)
		_:
			var font: Font = ThemeDB.fallback_font
			var fs: int = int(r * 1.35)
			var pos: Vector2 = Vector2(c.x - r, c.y + fs * 0.36)
			ci.draw_string_outline(font, pos, "?", HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, fs, 5, UiStyle.OUTLINE)
			ci.draw_string(font, pos, "?", HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, fs, col)


static func _glyph(ci: CanvasItem, pts: PackedVector2Array, col: Color) -> void:
	var closed: PackedVector2Array = pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, UiStyle.OUTLINE, 4.0, true)
	ci.draw_colored_polygon(pts, col)


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
			if _is_walked(id, next_id):
				trails.append(PackedVector2Array([from, to]))
			elif id == current and _reachable.has(next_id):
				_dots(from, to, COLOR_DOTS_NEXT, 3.2, DOT_SPACING - 1.0)
			else:
				_dots(from, to, COLOR_DOTS, 2.3, DOT_SPACING)
	for seg: PackedVector2Array in trails:
		draw_line(seg[0], seg[1], UiStyle.OUTLINE, TRAIL_WIDTH + 4.0, true)
		draw_circle(seg[0], (TRAIL_WIDTH + 4.0) * 0.5, UiStyle.OUTLINE)
		draw_circle(seg[1], (TRAIL_WIDTH + 4.0) * 0.5, UiStyle.OUTLINE)
	for seg: PackedVector2Array in trails:
		draw_line(seg[0], seg[1], COLOR_TRAIL, TRAIL_WIDTH, true)
		draw_circle(seg[0], TRAIL_WIDTH * 0.5, COLOR_TRAIL)
		draw_circle(seg[1], TRAIL_WIDTH * 0.5, COLOR_TRAIL)
	for id: String in _graph.nodes.keys():
		var node: MapNode = _graph.nodes[id]
		var c: Vector2 = node_center(node)
		var r: float = BOSS_RADIUS if node.room_type == "boss" else ICON_RADIUS
		draw_room_icon(self, c, r, node.room_type, _state_of(id), _zone_color)
		if node.room_type == "boss":
			var font: Font = ThemeDB.fallback_font
			var pos: Vector2 = c + Vector2(r + 14.0, BOSS_FONT_SIZE * 0.36)
			draw_string_outline(font, pos, _boss_label, HORIZONTAL_ALIGNMENT_LEFT, -1, BOSS_FONT_SIZE, 7, UiStyle.OUTLINE)
			draw_string(font, pos, _boss_label, HORIZONTAL_ALIGNMENT_LEFT, -1, BOSS_FONT_SIZE, Color.WHITE)
	if not current.is_empty() and _graph.nodes.has(current):
		var cn: MapNode = _graph.nodes[current]
		var cr: float = BOSS_RADIUS if cn.room_type == "boss" else ICON_RADIUS
		draw_ball_marker(self, node_center(cn) + Vector2(-cr - 8.0, -cr + 2.0), 10.0)


func _state_of(id: String) -> int:
	if id == _progress.current_node_id:
		return IconState.CURRENT
	if _progress.is_visited(id):
		return IconState.VISITED
	if _reachable.has(id):
		return IconState.REACHABLE
	return IconState.FUTURE


## Rounded dotted corridor from `a` to `b` (dots skip the icons at both ends).
func _dots(a: Vector2, b: Vector2, col: Color, radius: float, spacing: float) -> void:
	var length: float = a.distance_to(b)
	var skip: float = ICON_RADIUS + 6.0
	var n: int = int((length - 2.0 * skip) / spacing)
	if n <= 0:
		return
	var start: float = (length - n * spacing) * 0.5
	for i: int in n + 1:
		draw_circle(a.lerp(b, (start + i * spacing) / length), radius, col)


## True if the player walked from `a` straight to `b` (consecutive in the visit order).
func _is_walked(a: String, b: String) -> bool:
	var i: int = _progress.visited.find(a)
	return i >= 0 and i + 1 < _progress.visited.size() and _progress.visited[i + 1] == b


## Transparent click area (the icon is drawn by _draw); hover = white ring. The text stays for the QA harness
## and is drawn invisible.
func _style_button(b: Button, node: MapNode) -> void:
	var clickable: bool = _reachable.has(node.id) and node.id != _progress.current_node_id
	b.disabled = not clickable
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if clickable else Control.CURSOR_ARROW
	var empty := StyleBoxEmpty.new()
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(1, 1, 1, 0.14)
	hover.border_color = Color.WHITE
	hover.set_border_width_all(3)
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


## Legend / UI swatch: one room icon drawn in a small Control (story 020).
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
		MapCanvas.draw_room_icon(self, size * 0.5, r, room_type, MapCanvas.IconState.NORMAL, accent)
