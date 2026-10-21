class_name MapScreen
extends Control
## Zone map screen (mouse only, fits 1280x720): header (story 012: "Zone n/8 — Arène <Type> (Champion <Leader>)" and
## "Étage x/6", HP, deck, map seed, "Voir le deck"), a zone banner on the zone's start ("Zone n — Arène <Type>",
## floor 0 only), the colour legend of the room types (the gym named after its type) and the scrollable map
## (MapCanvas). Holds no game state: it emits node_chosen and Main enters the room.
## Implements: story-005-carte-acte-1, story-012-structure-8-arenes (zone header, banner, gym label).

## Emitted when the player picks a reachable room.
signal node_chosen(node_id: String)
## Emitted by "Voir le deck" (Main opens the single deck panel).
signal deck_requested

const COLOR_BG: Color = Color(0.1, 0.11, 0.15)
const COLOR_TITLE: Color = Color(1.0, 0.9, 0.4)
const ACT_TITLE: String = "Acte 1"
const COLOR_FLOOR: Color = Color(0.95, 0.95, 0.98)
const COLOR_BANNER_BG: Color = Color(0.15, 0.16, 0.22)
const COLOR_BANNER_SUB: Color = Color(0.78, 0.8, 0.88)
## Story 012 texts (zone header, gym label, zone banner).
const TEXT_ZONE_TITLE: String = "Zone %d/%d — Arène %s (Champion %s)"
const TEXT_GYM: String = "Arène %s"
const TEXT_START: String = "Départ"
const TEXT_FLOOR: String = "Étage %d/%d"
const TEXT_BANNER: String = "Zone %d — Arène %s"
const TEXT_BANNER_SUB_FIRST: String = "Le Champion %s t'attend au sommet de la carte."
const TEXT_BANNER_SUB_NEXT: String = "Le Champion %s t'attend au sommet. Ton deck, tes PV, tes objets et ton argent te suivent."
## Legend order of the room types.
const LEGEND_ORDER: Array[String] = ["wild", "elite", "event", "center", "mart", "boss"]
const LEGEND_SWATCH: Vector2 = Vector2(18, 18)
## Where the "next floor" row sits in the visible map area when scrolling to it (0 = top, 1 = bottom).
const FOCUS_RATIO: float = 0.5

var _data: GameData
var _run: RunState
var _title: Label
var _floor: Label
var _info: Label
var _banner: PanelContainer
var _banner_style: StyleBoxFlat
var _banner_title: Label
var _banner_sub: Label
var _legend: HBoxContainer
var _scroll: ScrollContainer
var _canvas: MapCanvas
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
	var zone: Dictionary = run.current_zone()
	var zone_color: Color = data.get_type_color(String(zone.get("type_id", ""))) if not zone.is_empty() else COLOR_TITLE
	if zone.is_empty():
		_title.text = ACT_TITLE
	else:
		_title.text = TEXT_ZONE_TITLE % [int(zone["number"]), run.zones.size(), String(zone["type_name"]), String(zone["leader"])]
	_floor.text = TEXT_START if floor_now == 0 else TEXT_FLOOR % [floor_now, progress.graph.floors]
	_info.text = "PV %d/%d   |   Deck : %d cartes   |   Graine : %d" % [run.hp, run.max_hp, run.deck.size(), progress.graph.seed]
	var names: Dictionary = {}
	for rt: String in LEGEND_ORDER:
		names[rt] = data.get_room_name(rt)
	var gym_label: String = ""
	if not zone.is_empty():
		gym_label = TEXT_GYM % String(zone["type_name"])
		names["boss"] = gym_label
	_build_legend(names)
	_banner.visible = floor_now == 0 and not zone.is_empty()
	if _banner.visible:
		_banner_style.border_color = zone_color
		_banner_title.text = TEXT_BANNER % [int(zone["number"]), String(zone["type_name"])]
		_banner_title.add_theme_color_override("font_color", zone_color.lightened(0.3))
		_banner_sub.text = (TEXT_BANNER_SUB_FIRST if int(zone["index"]) == 0 else TEXT_BANNER_SUB_NEXT) % String(zone["leader"])
	_canvas.setup(progress, names, gym_label)
	_scroll_to_focus()


## Enters `node_id` if it is reachable (same path as a click). Ignored otherwise.
func choose(node_id: String) -> void:
	if _done or not _canvas.get_reachable_ids().has(node_id):
		return
	_done = true
	node_chosen.emit(node_id)


## Header title and floor ("Zone 1/8 — Arène Roche (Champion Pierre) — Étage 3/6").
func get_title_text() -> String:
	return "%s — %s" % [_title.text, _floor.text]


## Zone banner text ("Zone 2 — Arène Eau"), "" when the banner is hidden (after the zone's first room).
func get_banner_text() -> String:
	return _banner_title.text if _banner.visible else ""


## Header info line (HP, deck size, seed).
func get_info_text() -> String:
	return _info.text


## The map canvas (buttons, reachable ids), for the QA harness.
func get_map_canvas() -> MapCanvas:
	return _canvas


## "Voir le deck": asks Main to open the single deck panel (story 011).
func open_deck() -> void:
	deck_requested.emit()


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
	var titles := VBoxContainer.new()
	titles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 0)
	header.add_child(titles)
	_title = CardView.make_label(26)
	_title.name = "Title"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title.add_theme_color_override("font_color", COLOR_TITLE)
	titles.add_child(_title)
	var sub := HBoxContainer.new()
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub.add_theme_constant_override("separation", 24)
	titles.add_child(sub)
	_floor = CardView.make_label(20)
	_floor.name = "Floor"
	_floor.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_floor.add_theme_color_override("font_color", COLOR_FLOOR)
	sub.add_child(_floor)
	_info = CardView.make_label(18)
	_info.name = "Info"
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_info.add_theme_color_override("font_color", COLOR_BANNER_SUB)
	sub.add_child(_info)
	var deck_button := Button.new()
	deck_button.name = "DeckButton"
	deck_button.text = "Voir le deck"
	deck_button.custom_minimum_size = Vector2(150, 40)
	deck_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	deck_button.focus_mode = Control.FOCUS_NONE
	deck_button.pressed.connect(open_deck)
	header.add_child(deck_button)
	_banner = PanelContainer.new()
	_banner.name = "ZoneBanner"
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_style = StyleBoxFlat.new()
	_banner_style.bg_color = COLOR_BANNER_BG
	_banner_style.set_border_width_all(3)
	_banner_style.set_corner_radius_all(10)
	_banner_style.content_margin_top = 6
	_banner_style.content_margin_bottom = 6
	_banner.add_theme_stylebox_override("panel", _banner_style)
	root.add_child(_banner)
	var banner_box := VBoxContainer.new()
	banner_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_box.add_theme_constant_override("separation", 0)
	_banner.add_child(banner_box)
	_banner_title = CardView.make_label(30)
	_banner_title.name = "BannerTitle"
	_banner_title.add_theme_color_override("font_outline_color", Color.BLACK)
	_banner_title.add_theme_constant_override("outline_size", 6)
	banner_box.add_child(_banner_title)
	_banner_sub = CardView.make_label(17)
	_banner_sub.name = "BannerSub"
	_banner_sub.add_theme_color_override("font_color", COLOR_BANNER_SUB)
	banner_box.add_child(_banner_sub)
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
