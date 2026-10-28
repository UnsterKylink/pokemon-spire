class_name MapScreen
extends Control
## Zone map screen (mouse only, fits 1280x720): header (story 012: "Zone n/8 — Arène <Type> (Champion <Leader>)" and
## "Étage x/6", HP, deck, map seed, "Voir le deck"), a zone banner on the zone's start ("Zone n — Arène <Type>",
## floor 0 only), the colour legend of the room types (the gym named after its type) and the scrollable map
## (MapCanvas). Holds no game state: it emits node_chosen and Main enters the room.
## Implements: story-005-carte-acte-1, story-012-structure-8-arenes (zone header, banner, gym label),
## story-020-style-graphique (zone backdrop tinted by the gym type, drawn room icons in the legend),
## story-020b-refonte-visuelle-premium (Pokémon look after player feedback: the map is a Town Map region drawn by
## MapCanvas on a sea framed like a Pokémon-game window; header, banner and legend are Pokémon menu panels — thick
## coloured frame with a dark outline around a rounded white box, dark text; the banner frame takes the gym type colour).

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
const LEGEND_ICON_SIDE: float = 30.0
## Story 020b: Pokémon menu panels (thick frame + white box) and the sea of the Town Map.
const FRAME_BLUE: Color = Color("#4F86D9")
const FRAME_OUTLINE: Color = Color("#1B2440")
const PANEL_WHITE: Color = Color("#FBFCFF")
const TEXT_SUB: Color = Color("#4A5578")
const FLOOR_RED: Color = Color("#D0342A")
## Frame thickness (outer panel padding) and sea inset (margin between the sea edge and the scrolling map).
const FRAME_PAD: int = 5
const SEA_INSET: int = 8
## Where the "next floor" row sits in the visible map area when scrolling to it (0 = top, 1 = bottom).
const FOCUS_RATIO: float = 0.5

var _data: GameData
var _run: RunState
var _title: Label
var _floor: Label
var _info: Label
var _banner: PanelContainer
var _banner_title: Label
var _banner_sub: Label
var _legend: HBoxContainer
var _backdrop: MapBackdrop
var _header: PanelContainer
var _header_icon: MapCanvas.RoomIcon
var _sheet_box: PanelContainer
var _banner_frame: StyleBoxFlat
var _banner_inner: StyleBoxFlat
var _sea: SeaView
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
	_sea.set_zone(zone_color if not zone.is_empty() else FRAME_BLUE, String(zone.get("type_id", "")))
	_header_icon.accent = zone_color
	_header_icon.queue_redraw()
	_canvas.set_zone_color(zone_color)
	_canvas.set_zone_type(String(zone.get("type_id", "")))
	_banner.visible = floor_now == 0 and not zone.is_empty()
	if _banner.visible:
		_banner_frame.bg_color = zone_color
		_banner_inner.border_color = zone_color.darkened(0.35)
		_banner_title.text = TEXT_BANNER % [int(zone["number"]), String(zone["type_name"])]
		_banner_title.add_theme_color_override("font_color", zone_color.darkened(0.55))
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
	_header.add_theme_stylebox_override("panel", _frame_box(FRAME_BLUE))
	root.add_child(_header)
	var header_inner := PanelContainer.new()
	header_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_inner.add_theme_stylebox_override("panel", _white_box(FRAME_BLUE, 14.0, 5.0))
	_header.add_child(header_inner)
	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_constant_override("separation", 14)
	header_inner.add_child(header)
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
	_dark_label(_title, UiStyle.TEXT_DARK)
	titles.add_child(_title)
	var sub := HBoxContainer.new()
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub.add_theme_constant_override("separation", 24)
	titles.add_child(sub)
	_floor = CardView.make_label(20)
	_floor.name = "Floor"
	_floor.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_dark_label(_floor, FLOOR_RED)
	sub.add_child(_floor)
	_info = CardView.make_label(18)
	_info.name = "Info"
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_dark_label(_info, TEXT_SUB)
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
	_banner_frame = _frame_box(FRAME_BLUE)
	_banner.add_theme_stylebox_override("panel", _banner_frame)
	root.add_child(_banner)
	var banner_inner := PanelContainer.new()
	banner_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_inner = _white_box(FRAME_BLUE, 16.0, 4.0)
	banner_inner.add_theme_stylebox_override("panel", _banner_inner)
	_banner.add_child(banner_inner)
	var banner_box := VBoxContainer.new()
	banner_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_box.add_theme_constant_override("separation", 0)
	banner_inner.add_child(banner_box)
	_banner_title = CardView.make_label(28)
	_banner_title.name = "BannerTitle"
	_dark_label(_banner_title, UiStyle.TEXT_DARK)
	banner_box.add_child(_banner_title)
	_banner_sub = CardView.make_label(17)
	_banner_sub.name = "BannerSub"
	_dark_label(_banner_sub, TEXT_SUB)
	banner_box.add_child(_banner_sub)
	# Story 020b: the Town Map window (legend panel + sea with the scrollable region), centred over the backdrop.
	_sheet_box = PanelContainer.new()
	_sheet_box.name = "Sheet"
	_sheet_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheet_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sheet_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_sheet_box.add_theme_stylebox_override("panel", _frame_box(FRAME_BLUE))
	root.add_child(_sheet_box)
	var sheet_col := VBoxContainer.new()
	sheet_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet_col.add_theme_constant_override("separation", FRAME_PAD)
	_sheet_box.add_child(sheet_col)
	var legend_panel := PanelContainer.new()
	legend_panel.name = "LegendPanel"
	legend_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	legend_panel.add_theme_stylebox_override("panel", _white_box(FRAME_BLUE, 12.0, 2.0))
	sheet_col.add_child(legend_panel)
	_legend = HBoxContainer.new()
	_legend.name = "Legend"
	_legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_legend.alignment = BoxContainer.ALIGNMENT_CENTER
	_legend.add_theme_constant_override("separation", 20)
	legend_panel.add_child(_legend)
	_sea = SeaView.new()
	_sea.name = "Sea"
	_sea.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sea.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sheet_col.add_child(_sea)
	var sea_margin := MarginContainer.new()
	sea_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	sea_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right", "top", "bottom"]:
		sea_margin.add_theme_constant_override("margin_" + side, SEA_INSET)
	_sea.add_child(sea_margin)
	_scroll = ScrollContainer.new()
	_scroll.name = "MapScroll"
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER  # wheel still scrolls; no bar on the sea
	sea_margin.add_child(_scroll)
	_canvas = MapCanvas.new()
	_canvas.name = "MapCanvas"
	_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL  # the region is centred when the sea is taller than the map
	_canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	_canvas.node_pressed.connect(choose)
	_scroll.add_child(_canvas)
	# Re-apply the focus scroll whenever the scroll range is (re)computed by the layout.
	_scroll.get_v_scroll_bar().changed.connect(_scroll_to_focus)
	# Story 020b: the painted region (drawn by the window) scrolls with the map.
	_scroll.get_v_scroll_bar().value_changed.connect(_sync_sea_scroll)
	_canvas.resized.connect(_sync_sea_scroll)


## Story 020b: tells the window where the scrolling map is, so its painted region moves with the rooms.
func _sync_sea_scroll(_value: float = 0.0) -> void:
	if _sea != null and _scroll != null and _canvas != null:
		_sea.set_scroll(float(_scroll.scroll_vertical), _canvas.size.y + SEA_INSET * 2.0)


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
		var side: float = LEGEND_ICON_SIDE
		if MapCanvas.icon_texture(rt) != null:  # story 020b: icon images read better a bit bigger
			side = MapCanvas.art_num("legend_icon_size", LEGEND_ICON_SIDE)
		var icon := MapCanvas.RoomIcon.new(rt, side, accent)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item.add_child(icon)
		var l: Label = CardView.make_label(16)
		l.text = String(names.get(rt, rt))
		_dark_label(l, UiStyle.TEXT_DARK)
		item.add_child(l)
		_legend.add_child(item)
	_size_sheet()


## Story 020b: the window is as wide as the map (+ frame and sea inset), never wider than the screen area.
func _size_sheet() -> void:
	if _sheet_box == null or _run == null or _run.act == null:
		return
	var w: float = _run.act.graph.width * MapCanvas.COL_SPACING + (FRAME_PAD + SEA_INSET) * 2.0 + 40.0
	_sheet_box.custom_minimum_size = Vector2(minf(w, 1256.0), 0)


## Story 020b: dark text on a white Pokémon panel (no outline, no shadow).
func _dark_label(l: Label, col: Color) -> void:
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))


## Story 020b: outer frame of a Pokémon menu window: thick `col` band, dark outline, rounded, drop shadow.
func _frame_box(col: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.border_color = FRAME_OUTLINE
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(18)
	sb.shadow_color = UiStyle.SHADOW
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	sb.set_content_margin_all(FRAME_PAD + 1)
	sb.anti_aliasing = true
	return sb


## Story 020b: inner white box of a Pokémon menu window (thin darker rim of the frame colour).
func _white_box(frame: Color, pad_x: float, pad_y: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL_WHITE
	sb.border_color = frame.darkened(0.35)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(13)
	sb.content_margin_left = pad_x
	sb.content_margin_right = pad_x
	sb.content_margin_top = pad_y
	sb.content_margin_bottom = pad_y
	sb.anti_aliasing = true
	return sb


## Scrolls so the row after the current floor (the next choice) sits mid-view.
func _scroll_to_focus() -> void:
	if _run == null or _run.act == null or _canvas == null:
		return
	var target_floor: int = clampi(_run.act.current_floor() + 1, 1, _run.act.graph.floors)
	_scroll.scroll_vertical = int(_canvas.floor_y(target_floor) - _scroll.size.y * FOCUS_RATIO)


## Story 020b: the Town Map sea (rounded, thin dark rim): bright blue slightly tinted by the zone, soft horizontal
## swell bands and little white wave marks (deterministic). The scrolling region (MapCanvas) is drawn over it.
## When the zone has a painted region image (MapCanvas.region_texture) the window shows it instead, cover-fit over the
## whole scrollable map (it scrolls with the rooms), with a light veil and a soft vignette (assets/data/map_art.json).
class SeaView extends Control:
	const CORNER: float = 12.0
	var tint: Color = Color("#4F86D9")
	var type_id: String = ""
	var scroll_offset: float = 0.0
	var content_height: float = 0.0

	## Sets the zone colour (slight tint of the sea) and gym type (painted region), then redraws.
	func set_zone(color: Color, zone_type_id: String = "") -> void:
		tint = color
		type_id = zone_type_id
		queue_redraw()

	## Story 020b: vertical scroll of the map and its full height (window coordinates), for the painted region.
	func set_scroll(offset: float, height: float) -> void:
		if is_equal_approx(offset, scroll_offset) and is_equal_approx(height, content_height):
			return
		scroll_offset = offset
		content_height = height
		queue_redraw()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		var region: Texture2D = MapCanvas.region_texture(type_id)
		if region != null:
			_draw_region_image(region)
			return
		var sea: Color = MapCanvas.SEA.lerp(tint, 0.08)
		var sb := StyleBoxFlat.new()
		sb.bg_color = sea
		sb.border_color = Color("#1B2440")
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(12)
		sb.anti_aliasing = true
		draw_style_box(sb, Rect2(Vector2.ZERO, size))
		var y: float = 14.0
		while y < size.y - 10.0:  # swell bands
			draw_rect(Rect2(6.0, y, size.x - 12.0, 9.0), Color(1, 1, 1, 0.05))
			y += 26.0
		var rng := RandomNumberGenerator.new()
		rng.seed = 4242
		for i: int in 70:  # wave marks
			var p := Vector2(rng.randf_range(20.0, size.x - 20.0), rng.randf_range(16.0, size.y - 14.0))
			draw_arc(p, 5.0, deg_to_rad(200), deg_to_rad(340), 6, Color(1, 1, 1, 0.45), 1.6, true)
			draw_arc(p + Vector2(9, 0), 5.0, deg_to_rad(200), deg_to_rad(340), 6, Color(1, 1, 1, 0.45), 1.6, true)

	## Painted region, cover-fit over the full map height and shifted by the scroll, clipped to the rounded window;
	## then a light veil, the vignette and the dark rim.
	func _draw_region_image(tex: Texture2D) -> void:
		var ts: Vector2 = tex.get_size()
		var outline: PackedVector2Array = _rounded_rect(Rect2(Vector2.ZERO, size), CORNER)
		if ts.x > 0.0 and ts.y > 0.0:
			var area := Vector2(size.x, maxf(size.y, content_height))
			var k: float = maxf(area.x / ts.x, area.y / ts.y)
			var ds: Vector2 = ts * k
			var origin: Vector2 = (area - ds) * 0.5 - Vector2(0.0, scroll_offset)
			var uvs := PackedVector2Array()
			for p: Vector2 in outline:
				uvs.append((p - origin) / ds)
			draw_polygon(outline, PackedColorArray([Color.WHITE]), uvs, tex)
		var veil: float = MapCanvas.art_num("region_darken", 0.06)
		if veil > 0.0:
			draw_colored_polygon(outline, Color(0, 0, 0, veil))
		var v: float = MapCanvas.art_num("vignette", 0.42)
		var vw: float = minf(MapCanvas.art_num("vignette_width", 70.0), minf(size.x, size.y) * 0.5)
		if v > 0.0 and vw > 0.0:
			var dark := Color(0.05, 0.06, 0.12, v)
			var clear := Color(0.05, 0.06, 0.12, 0.0)
			var w: float = size.x
			var h: float = size.y
			var c := CORNER * 0.3  # stay inside the rounded corners
			for quad: Array in [
					[Vector2(c, c), Vector2(w - c, c), Vector2(w - c, vw), Vector2(c, vw)],
					[Vector2(c, h - c), Vector2(w - c, h - c), Vector2(w - c, h - vw), Vector2(c, h - vw)],
					[Vector2(c, c), Vector2(c, h - c), Vector2(vw, h - c), Vector2(vw, c)],
					[Vector2(w - c, c), Vector2(w - c, h - c), Vector2(w - vw, h - c), Vector2(w - vw, c)]]:
				draw_polygon(PackedVector2Array(quad), PackedColorArray([dark, dark, clear, clear]))
		var rim := StyleBoxFlat.new()
		rim.draw_center = false
		rim.border_color = Color("#1B2440")
		rim.set_border_width_all(2)
		rim.set_corner_radius_all(int(CORNER))
		rim.anti_aliasing = true
		draw_style_box(rim, Rect2(Vector2.ZERO, size))

	static func _rounded_rect(r: Rect2, radius: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		var rad: float = minf(radius, minf(r.size.x, r.size.y) * 0.5)
		var corners: Array[Vector2] = [r.position + Vector2(r.size.x - rad, rad), r.end - Vector2(rad, rad),
				r.position + Vector2(rad, r.size.y - rad), r.position + Vector2(rad, rad)]
		for i: int in 4:
			for s: int in 7:
				var a: float = -PI / 2.0 + (i + s / 6.0) * PI / 2.0
				pts.append(corners[i] + Vector2.from_angle(a) * rad)
		return pts


## Story 020b: screen background behind the Town Map window, like a Pokémon menu backdrop: blue gradient tinted by the
## gym type, soft diagonal stripes and a big faint Poké Ball watermark. Display only.
class MapBackdrop extends Control:
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
		var top: Color = Color("#5C9BE6").lerp(tint, 0.28)
		var bottom: Color = Color("#2D5EB0").lerp(tint.darkened(0.3), 0.25)
		draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
				PackedColorArray([top, top, bottom, bottom]))
		var x: float = -h
		while x < w:  # diagonal stripes
			draw_colored_polygon(PackedVector2Array([Vector2(x, h), Vector2(x + h, 0), Vector2(x + h + 26.0, 0),
					Vector2(x + 26.0, h)]), Color(1, 1, 1, 0.05))
			x += 64.0
		var c := Vector2(w - 120.0, h - 90.0)  # Poké Ball watermark
		var wm: Color = Color(1, 1, 1, 0.08)
		draw_arc(c, 190.0, 0.0, TAU, 96, wm, 22.0, true)
		draw_line(c - Vector2(190, 0), c + Vector2(190, 0), wm, 22.0)
		draw_circle(c, 52.0, wm)
