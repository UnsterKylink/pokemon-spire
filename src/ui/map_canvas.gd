class_name MapCanvas
extends Control
## Draws the act map: one Button per room laid out by (col, floor) (floor 1 at the bottom, boss on top)
## and the corridors between rooms as lines (_draw). Only reachable rooms are clickable.
## Display only: reads MapGraph / ActProgress and emits node_pressed. Implements: story-005-carte-acte-1.

## Emitted when a reachable room button is clicked.
signal node_pressed(node_id: String)

const COL_SPACING: float = 150.0
const ROW_SPACING: float = 62.0
const PAD_TOP: float = 46.0
const PAD_BOTTOM: float = 34.0
const NODE_SIZE: Vector2 = Vector2(96, 36)
const BOSS_SIZE: Vector2 = Vector2(196, 46)
const NODE_FONT_SIZE: int = 16
const BOSS_FONT_SIZE: int = 20
## Short label shown on each room button (UI text, not gameplay data).
const ROOM_SHORT: Dictionary = {"wild": "Combat", "elite": "Élite", "center": "Centre", "mart": "Mart",
		"event": "?", "boss": "Champion", "rival": "Rival"}
## Colour per room type (also used by the legend).
const ROOM_COLORS: Dictionary = {
	"wild": Color(0.85, 0.36, 0.3), "elite": Color(0.68, 0.36, 0.9), "center": Color(0.95, 0.5, 0.7),
	"mart": Color(0.3, 0.6, 0.95), "event": Color(0.35, 0.75, 0.42), "boss": Color(1.0, 0.76, 0.22),
	"rival": Color(0.56, 0.18, 0.78)}  # story 018: deep purple, light text (ROOM_LIGHT_TEXT)
## Story 018: room types whose button text is light (dark background).
const ROOM_LIGHT_TEXT: Array[String] = ["rival"]
const COLOR_TEXT_LIGHT: Color = Color(0.97, 0.94, 1.0)
const COLOR_UNKNOWN_ROOM: Color = Color(0.6, 0.6, 0.6)
const COLOR_TEXT_DARK: Color = Color(0.08, 0.08, 0.1)
const COLOR_TEXT_VISITED: Color = Color(0.62, 0.62, 0.66)
const COLOR_REACHABLE_BORDER: Color = Color(1.0, 1.0, 1.0)
const COLOR_CURRENT_BORDER: Color = Color(1.0, 0.86, 0.3)
const COLOR_EDGE: Color = Color(0.36, 0.38, 0.48)
const COLOR_EDGE_REACHABLE: Color = Color(0.92, 0.92, 0.96)
const COLOR_EDGE_VISITED: Color = Color(1.0, 0.8, 0.28)
const EDGE_WIDTH: float = 2.0
const EDGE_WIDTH_REACHABLE: float = 3.0
const EDGE_WIDTH_VISITED: float = 5.0

var _graph: MapGraph
var _progress: ActProgress
var _room_names: Dictionary = {}
var _buttons: Dictionary = {}
var _reachable: Array[String] = []


## Builds the buttons for `progress.graph`. `room_names`: room type -> display name (tooltips). `boss_label`
## (story 012, optional): text of the gym room button ("Arène Roche"); ROOM_SHORT's "Champion" when empty.
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
	custom_minimum_size = Vector2(_graph.width * COL_SPACING, PAD_TOP + PAD_BOTTOM + (_graph.floors - 1) * ROW_SPACING)
	for id: String in _graph.nodes.keys():
		var node: MapNode = _graph.nodes[id]
		var b := Button.new()
		b.name = "Room_" + id
		b.text = String(ROOM_SHORT.get(node.room_type, "?"))
		if node.room_type == "boss" and not boss_label.is_empty():
			b.text = boss_label
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
	for id: String in _graph.nodes.keys():
		var node: MapNode = _graph.nodes[id]
		var from: Vector2 = node_center(node)
		for next_id: String in node.next:
			var other: MapNode = _graph.get_node(next_id)
			if other == null:
				continue
			var color: Color = COLOR_EDGE
			var width: float = EDGE_WIDTH
			if _is_walked(id, next_id):
				color = COLOR_EDGE_VISITED
				width = EDGE_WIDTH_VISITED
			elif id == current and _reachable.has(next_id):
				color = COLOR_EDGE_REACHABLE
				width = EDGE_WIDTH_REACHABLE
			draw_line(from, node_center(other), color, width, true)


## True if the player walked from `a` straight to `b` (consecutive in the visit order).
func _is_walked(a: String, b: String) -> bool:
	var i: int = _progress.visited.find(a)
	return i >= 0 and i + 1 < _progress.visited.size() and _progress.visited[i + 1] == b


func _style_button(b: Button, node: MapNode) -> void:
	var base: Color = ROOM_COLORS.get(node.room_type, COLOR_UNKNOWN_ROOM)
	var bg: Color = base.darkened(0.3)
	var border: Color = Color(0, 0, 0, 0)
	var border_w: int = 0
	var text: Color = COLOR_TEXT_LIGHT if ROOM_LIGHT_TEXT.has(node.room_type) else COLOR_TEXT_DARK
	var clickable: bool = false
	if node.id == _progress.current_node_id:
		bg = base
		border = COLOR_CURRENT_BORDER
		border_w = 4
	elif _progress.is_visited(node.id):
		bg = base.darkened(0.72)
		border = base.darkened(0.4)
		border_w = 2
		text = COLOR_TEXT_VISITED
	elif _reachable.has(node.id):
		bg = base.lightened(0.12)
		border = COLOR_REACHABLE_BORDER
		border_w = 4
		clickable = true
	b.disabled = not clickable
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if clickable else Control.CURSOR_ARROW
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(int(NODE_SIZE.y * 0.5))
	var sb_hover: StyleBoxFlat = sb.duplicate()
	sb_hover.bg_color = bg.lightened(0.25)
	for state: String in ["normal", "disabled"]:
		b.add_theme_stylebox_override(state, sb)
	for state: String in ["hover", "pressed"]:
		b.add_theme_stylebox_override(state, sb_hover)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for c: String in ["font_color", "font_disabled_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(c, text)


func _on_button_pressed(node_id: String) -> void:
	if _reachable.has(node_id):
		node_pressed.emit(node_id)
