class_name MapScreen
extends Control
## Act map screen (mouse only, fits 1280x720): header (act/floor, HP, deck, map seed, "Voir le deck"),
## colour legend of the room types, and the scrollable map (MapCanvas). Holds no game state:
## it emits node_chosen and Main enters the room. Implements: story-005-carte-acte-1.

## Emitted when the player picks a reachable room.
signal node_chosen(node_id: String)

const COLOR_BG: Color = Color(0.1, 0.11, 0.15)
const COLOR_TITLE: Color = Color(1.0, 0.9, 0.4)
const ACT_TITLE: String = "Acte 1"
## Legend order of the room types.
const LEGEND_ORDER: Array[String] = ["wild", "elite", "event", "center", "mart", "boss"]
const LEGEND_SWATCH: Vector2 = Vector2(18, 18)
## Where the "next floor" row sits in the visible map area when scrolling to it (0 = top, 1 = bottom).
const FOCUS_RATIO: float = 0.5

var _data: GameData
var _run: RunState
var _title: Label
var _info: Label
var _legend: HBoxContainer
var _scroll: ScrollContainer
var _canvas: MapCanvas
var _deck_overlay: DeckOverlay
var _done: bool = false
var _built: bool = false


func _ready() -> void:
	_build_ui()


## Displays `run.act` (read only). Call after add_child.
func setup(data: GameData, run: RunState) -> void:
	_build_ui()
	_data = data
	_run = run
	_done = false
	var progress: ActProgress = run.act
	var floor_now: int = progress.current_floor()
	if floor_now == 0:
		_title.text = "%s — Départ" % ACT_TITLE
	else:
		_title.text = "%s — Étage %d/%d" % [ACT_TITLE, floor_now, progress.graph.floors]
	_info.text = "PV %d/%d   |   Deck : %d cartes   |   Graine : %d" % [run.hp, run.max_hp, run.deck.size(), progress.graph.seed]
	var names: Dictionary = {}
	for rt: String in LEGEND_ORDER:
		names[rt] = data.get_room_name(rt)
	_build_legend(names)
	_canvas.setup(progress, names)
	_deck_overlay.close()
	_scroll_to_focus()


## Enters `node_id` if it is reachable (same path as a click). Ignored otherwise or while the deck is open.
func choose(node_id: String) -> void:
	if _done or is_deck_open() or not _canvas.get_reachable_ids().has(node_id):
		return
	_done = true
	node_chosen.emit(node_id)


## Header title ("Acte 1 — Étage 3/15").
func get_title_text() -> String:
	return _title.text


## Header info line (HP, deck size, seed).
func get_info_text() -> String:
	return _info.text


## The map canvas (buttons, reachable ids), for the QA harness.
func get_map_canvas() -> MapCanvas:
	return _canvas


## Opens the deck overlay ("Voir le deck").
func open_deck() -> void:
	_deck_overlay.open(_run)


## Closes the deck overlay.
func close_deck() -> void:
	_deck_overlay.close()


## True while the deck overlay is shown.
func is_deck_open() -> bool:
	return _deck_overlay.is_open()


func _build_ui() -> void:
	if _built:
		return
	_built = true
	var bg := ColorRect.new()
	bg.color = COLOR_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var root := VBoxContainer.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)
	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_constant_override("separation", 20)
	root.add_child(header)
	_title = CardView.make_label(28)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title.add_theme_color_override("font_color", COLOR_TITLE)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	_info = CardView.make_label(18)
	header.add_child(_info)
	var deck_button := Button.new()
	deck_button.name = "DeckButton"
	deck_button.text = "Voir le deck"
	deck_button.custom_minimum_size = Vector2(150, 40)
	deck_button.focus_mode = Control.FOCUS_NONE
	deck_button.pressed.connect(open_deck)
	header.add_child(deck_button)
	_legend = HBoxContainer.new()
	_legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_legend.alignment = BoxContainer.ALIGNMENT_CENTER
	_legend.add_theme_constant_override("separation", 22)
	root.add_child(_legend)
	_scroll = ScrollContainer.new()
	_scroll.name = "MapScroll"
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(_scroll)
	_canvas = MapCanvas.new()
	_canvas.name = "MapCanvas"
	_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	_canvas.node_pressed.connect(choose)
	_scroll.add_child(_canvas)
	# Re-apply the focus scroll whenever the scroll range is (re)computed by the layout.
	_scroll.get_v_scroll_bar().changed.connect(_scroll_to_focus)
	_deck_overlay = DeckOverlay.new()
	add_child(_deck_overlay)


func _build_legend(names: Dictionary) -> void:
	for child: Node in _legend.get_children():
		_legend.remove_child(child)
		child.queue_free()
	for rt: String in LEGEND_ORDER:
		var item := HBoxContainer.new()
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_theme_constant_override("separation", 6)
		var swatch := ColorRect.new()
		swatch.color = MapCanvas.ROOM_COLORS.get(rt, MapCanvas.COLOR_UNKNOWN_ROOM)
		swatch.custom_minimum_size = LEGEND_SWATCH
		swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item.add_child(swatch)
		var l: Label = CardView.make_label(16)
		l.text = String(names.get(rt, rt))
		item.add_child(l)
		_legend.add_child(item)


## Scrolls so the row after the current floor (the next choice) sits mid-view.
func _scroll_to_focus() -> void:
	if _run == null or _run.act == null or _canvas == null:
		return
	var target_floor: int = clampi(_run.act.current_floor() + 1, 1, _run.act.graph.floors)
	_scroll.scroll_vertical = int(_canvas.floor_y(target_floor) - _scroll.size.y * FOCUS_RATIO)
