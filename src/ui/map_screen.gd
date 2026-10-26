class_name MapScreen
extends Control
## Zone map screen (mouse only, fits 1280x720): header (story 012: "Zone n/8 — Arène <Type> (Champion <Leader>)" and
## "Étage x/6", HP, deck, map seed, "Voir le deck"), a zone banner on the zone's start ("Zone n — Arène <Type>",
## floor 0 only), the colour legend of the room types (the gym named after its type) and the scrollable map
## (MapCanvas). Holds no game state: it emits node_chosen and Main enters the room.
## Implements: story-005-carte-acte-1, story-012-structure-8-arenes (zone header, banner, gym label),
## story-020-style-graphique (zone backdrop tinted by the gym type, drawn room icons in the legend).

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
const LEGEND_ORDER: Array[String] = ["wild", "elite", "rival", "event", "center", "mart", "boss"]
## Story 018: tooltip line of the rival rooms.
const TEXT_RIVAL_TIP: String = "%s et son %s t'attendent"
const LEGEND_ICON_SIDE: float = 28.0
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
var _backdrop: MapBackdrop
var _header: PanelContainer
var _header_style: StyleBoxFlat
var _header_icon: MapCanvas.RoomIcon
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
	var has_rival: bool = false
	for n: MapNode in progress.graph.nodes.values():
		has_rival = has_rival or n.room_type == "rival"
	for rt: String in LEGEND_ORDER:
		if rt != "rival" or has_rival:  # story 018: the rival entry only on maps with a rival room
			names[rt] = data.get_room_name(rt)
	var gym_label: String = ""
	if not zone.is_empty():
		gym_label = TEXT_GYM % String(zone["type_name"])
		names["boss"] = gym_label
	_build_legend(names, zone_color)
	_backdrop.set_zone(String(zone.get("type_id", "")), zone_color if not zone.is_empty() else UiStyle.SUCCESS)
	_header_style.border_color = zone_color.darkened(0.35) if not zone.is_empty() else UiStyle.OUTLINE
	_header_icon.accent = zone_color
	_header_icon.queue_redraw()
	_canvas.set_zone_color(zone_color)
	_banner.visible = floor_now == 0 and not zone.is_empty()
	if _banner.visible:
		_banner_style.border_color = zone_color
		_banner_style.bg_color = Color(zone_color.darkened(0.7), 0.92)
		_banner_title.text = TEXT_BANNER % [int(zone["number"]), String(zone["type_name"])]
		_banner_title.add_theme_color_override("font_color", zone_color.lightened(0.35))
		_banner_sub.text = (TEXT_BANNER_SUB_FIRST if int(zone["index"]) == 0 else TEXT_BANNER_SUB_NEXT) % String(zone["leader"])
	var rival_tip: String = ""
	if not run.rival_name.is_empty():
		rival_tip = TEXT_RIVAL_TIP % [run.rival_name, String(data.get_pokemon_info(run.rival_current_form(data)).get("name", ""))]
	_canvas.setup(progress, names, gym_label, rival_tip)
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
	theme = UiStyle.make_theme()
	_backdrop = MapBackdrop.new()
	_backdrop.name = "ZoneBackdrop"
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)
	var root := VBoxContainer.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)
	_header = PanelContainer.new()
	_header.name = "Header"
	_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header_style = UiStyle.panel(Color(UiStyle.BG_PANEL, 0.92))
	_header_style.content_margin_top = 6.0
	_header_style.content_margin_bottom = 6.0
	_header.add_theme_stylebox_override("panel", _header_style)
	root.add_child(_header)
	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_constant_override("separation", 16)
	_header.add_child(header)
	_header_icon = MapCanvas.RoomIcon.new("boss", 48.0)
	_header_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_header_icon)
	var titles := VBoxContainer.new()
	titles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 0)
	header.add_child(titles)
	_title = CardView.make_label(26)
	_title.name = "Title"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	UiStyle.apply_label(_title, "heading")
	_title.add_theme_font_size_override("font_size", 26)
	titles.add_child(_title)
	var sub := HBoxContainer.new()
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub.add_theme_constant_override("separation", 24)
	titles.add_child(sub)
	_floor = CardView.make_label(20)
	_floor.name = "Floor"
	_floor.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_floor.add_theme_color_override("font_color", UiStyle.ACCENT_YELLOW)
	_floor.add_theme_color_override("font_outline_color", UiStyle.OUTLINE)
	_floor.add_theme_constant_override("outline_size", 5)
	sub.add_child(_floor)
	_info = CardView.make_label(18)
	_info.name = "Info"
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_info.add_theme_color_override("font_color", UiStyle.TEXT_MUTED)
	sub.add_child(_info)
	var deck_button := Button.new()
	deck_button.name = "DeckButton"
	deck_button.text = "Voir le deck"
	deck_button.custom_minimum_size = Vector2(150, 44)
	deck_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	deck_button.focus_mode = Control.FOCUS_NONE
	UiStyle.apply_button(deck_button, UiStyle.ACCENT_BLUE)
	deck_button.pressed.connect(open_deck)
	header.add_child(deck_button)
	_banner = PanelContainer.new()
	_banner.name = "ZoneBanner"
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_style = UiStyle.panel(Color(UiStyle.BG_DEEP, 0.9))
	_banner_style.content_margin_top = 4.0
	_banner_style.content_margin_bottom = 6.0
	_banner.add_theme_stylebox_override("panel", _banner_style)
	root.add_child(_banner)
	var banner_box := VBoxContainer.new()
	banner_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_box.add_theme_constant_override("separation", 0)
	_banner.add_child(banner_box)
	_banner_title = CardView.make_label(30)
	_banner_title.name = "BannerTitle"
	_banner_title.add_theme_color_override("font_outline_color", UiStyle.OUTLINE)
	_banner_title.add_theme_constant_override("outline_size", 8)
	banner_box.add_child(_banner_title)
	_banner_sub = CardView.make_label(17)
	_banner_sub.name = "BannerSub"
	_banner_sub.add_theme_color_override("font_color", UiStyle.TEXT_MUTED)
	banner_box.add_child(_banner_sub)
	var legend_row := CenterContainer.new()
	legend_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(legend_row)
	var legend_panel := PanelContainer.new()
	legend_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lsb: StyleBoxFlat = UiStyle.panel(Color(UiStyle.BG_DEEP, 0.8), 20, 2)
	lsb.content_margin_top = 3.0
	lsb.content_margin_bottom = 3.0
	lsb.content_margin_left = 16.0
	lsb.content_margin_right = 16.0
	legend_panel.add_theme_stylebox_override("panel", lsb)
	legend_row.add_child(legend_panel)
	_legend = HBoxContainer.new()
	_legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_legend.alignment = BoxContainer.ALIGNMENT_CENTER
	_legend.add_theme_constant_override("separation", 22)
	legend_panel.add_child(_legend)
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


func _build_legend(names: Dictionary, accent: Color) -> void:
	for child: Node in _legend.get_children():
		_legend.remove_child(child)
		child.queue_free()
	for rt: String in LEGEND_ORDER:
		if not names.has(rt):
			continue
		var item := HBoxContainer.new()
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_theme_constant_override("separation", 6)
		var icon := MapCanvas.RoomIcon.new(rt, LEGEND_ICON_SIDE, accent)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item.add_child(icon)
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


## Story 020: zone decor behind the map, drawn in code and tinted by the gym type colour: dark vertical gradient,
## soft rolling terrain, a few themed silhouettes (trees, peaks, waves, pylons, tombs, clouds, gears) and stars.
## Deterministic per type (fixed RNG seed); low contrast so the map stays readable. Display only.
class MapBackdrop extends Control:
	## Silhouette family per gym type (art bible §6, simplified for the map).
	const FAMILIES: Dictionary = {
		"grass": "trees", "bug": "trees", "fairy": "trees", "normal": "trees",
		"rock": "peaks", "ground": "peaks", "fighting": "peaks", "dragon": "peaks", "fire": "volcano", "ice": "ice",
		"water": "waves", "electric": "pylons", "ghost": "tombs", "dark": "tombs", "poison": "tombs",
		"flying": "clouds", "psychic": "clouds", "steel": "gears"}
	var type_id: String = ""
	var tint: Color = UiStyle.SUCCESS

	## Sets the zone's gym type and colour, then redraws.
	func set_zone(zone_type_id: String, color: Color) -> void:
		type_id = zone_type_id
		tint = color
		queue_redraw()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var top: Color = tint.darkened(0.82).lerp(UiStyle.BG_DEEP, 0.35)
		var bottom: Color = tint.darkened(0.58)
		draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
				PackedColorArray([top, top, bottom, bottom]))
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(type_id) & 0x7fffffff
		for i: int in 40:  # faint stars / sparkles in the upper sky
			draw_circle(Vector2(rng.randf() * w, rng.randf() * h * 0.5), rng.randf_range(0.8, 2.0),
					Color(1, 1, 1, rng.randf_range(0.08, 0.25)))
		var far: Color = tint.darkened(0.66)
		var near: Color = tint.darkened(0.5)
		var sil: Color = Color(tint.darkened(0.74), 0.9)
		var horizon: float = h * 0.72
		_silhouettes(String(FAMILIES.get(type_id, "hills")), rng, w, h, horizon, sil)
		var x: float = -60.0
		while x < w + 200.0:  # far rolling hills
			var r: float = rng.randf_range(180.0, 280.0)
			draw_circle(Vector2(x, horizon + r * 0.82), r, far)
			x += r * 1.2
		x = -100.0
		while x < w + 200.0:  # near terrain
			var r2: float = rng.randf_range(160.0, 240.0)
			draw_circle(Vector2(x, h + r2 * 0.55), r2, near)
			x += r2 * 1.3
		draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.12))  # keeps the decor behind the map

	func _silhouettes(family: String, rng: RandomNumberGenerator, w: float, h: float, base: float, col: Color) -> void:
		var count: int = 7
		for i: int in count:
			var x: float = w * (i + rng.randf_range(0.15, 0.85)) / count
			var s: float = rng.randf_range(0.8, 1.3)
			match family:
				"trees", "hills":
					draw_rect(Rect2(x - 6 * s, base - 50 * s, 12 * s, 60 * s), col)
					draw_circle(Vector2(x, base - 70 * s), 34 * s, col)
					draw_circle(Vector2(x - 24 * s, base - 50 * s), 24 * s, col)
					draw_circle(Vector2(x + 24 * s, base - 52 * s), 24 * s, col)
				"peaks", "ice":
					var pc: Color = col if family == "peaks" else Color(tint.lightened(0.3), 0.18)
					draw_colored_polygon(PackedVector2Array([Vector2(x - 90 * s, base + 20), Vector2(x - 10 * s, base - 150 * s),
							Vector2(x + 10 * s, base - 140 * s), Vector2(x + 90 * s, base + 20)]), pc)
				"volcano":
					draw_colored_polygon(PackedVector2Array([Vector2(x - 110 * s, base + 20), Vector2(x - 26 * s, base - 120 * s),
							Vector2(x + 26 * s, base - 120 * s), Vector2(x + 110 * s, base + 20)]), col)
					draw_circle(Vector2(x, base - 128 * s), 14 * s, Color(tint.lightened(0.2), 0.35))
				"waves":
					for k: int in 3:
						draw_arc(Vector2(x, base - 20 - k * 40), 40 * s, PI * 1.1, PI * 1.9, 16, Color(tint.lightened(0.4), 0.18), 5.0, true)
					draw_circle(Vector2(x + 30, base + 6), 28 * s, col)
				"pylons":
					draw_rect(Rect2(x - 4, base - 170 * s, 8, 190 * s), col)
					draw_rect(Rect2(x - 30 * s, base - 160 * s, 60 * s, 7), col)
					if i < count - 1:
						var nx: float = w * (i + 1.5) / count
						draw_line(Vector2(x + 30 * s, base - 156 * s), Vector2(nx - 30, base - 150), Color(tint, 0.25), 2.0, true)
				"tombs":
					draw_rect(Rect2(x - 22 * s, base - 50 * s, 44 * s, 60 * s), col)
					draw_circle(Vector2(x, base - 50 * s), 22 * s, col)
					if i == 2:
						draw_circle(Vector2(x, h * 0.16), 34.0, Color(tint.lightened(0.5), 0.22))
				"clouds":
					var cy: float = h * rng.randf_range(0.12, 0.45)
					var cc: Color = Color(tint.lightened(0.45), 0.12)
					draw_circle(Vector2(x, cy), 30 * s, cc)
					draw_circle(Vector2(x - 32 * s, cy + 10), 22 * s, cc)
					draw_circle(Vector2(x + 34 * s, cy + 8), 24 * s, cc)
				"gears":
					var gc := Vector2(x, base - 50 * s)
					for k: int in 8:
						draw_circle(gc + Vector2.from_angle(TAU * k / 8.0) * 44 * s, 12 * s, col)
					draw_circle(gc, 44 * s, col)
					draw_circle(gc, 16 * s, tint.darkened(0.6))
