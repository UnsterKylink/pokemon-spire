class_name MapCanvas
extends Control
## Draws the act map as a Pokémon-games Town Map (story 020b, after player feedback: "Slay the Spire for the way of
## doing things, Pokémon for the look"): a stylised region seen from above in a clean, bright vector look with soft
## cel shading — sea with shallow water and foam around a land mass (or islands for a Water zone) coloured by the
## zone's gym type (grass greens, volcanic browns, snowy whites, haunted lilacs...), themed scenery (trees, pines,
## volcanoes, mountains, tombs...), beige routes with a darker outline between the rooms, and the rooms as Town Map
## landmarks (tall-grass patch, trainer badges, Pokémon Center with a red roof and a Poké Ball sign, Poké Mart with a
## blue roof, a "?" signpost, the gym as a bigger building with a type-coloured roof and a badge). The travelled route
## is a red dotted trail, visited rooms are greyed with a green check, the next choices glow and their roads are
## brighter, and the current room has the red Town Map cursor and a Poké Ball pin.
## One (transparent) Button per room laid out by (col, floor) (floor 1 at the bottom, gym on top); only reachable rooms
## are clickable. Display only: reads MapGraph / ActProgress and emits node_pressed.
## Implements: story-005-carte-acte-1, story-020-style-graphique, story-020b-refonte-visuelle-premium (Town Map).

## Emitted when a reachable room button is clicked.
signal node_pressed(node_id: String)

## Drawing states of a room icon (draw_room_icon).
enum IconState { NORMAL, FUTURE, REACHABLE, VISITED, CURRENT }

const COL_SPACING: float = 150.0
const ROW_SPACING: float = 62.0
const PAD_TOP: float = 58.0
const PAD_BOTTOM: float = 44.0
## Radius of a room landmark / of the gym building.
const ICON_RADIUS: float = 21.0
const BOSS_RADIUS: float = 30.0
## Click area of a room (the boss button also covers its building).
const NODE_SIZE: Vector2 = Vector2(52, 52)
const BOSS_SIZE: Vector2 = Vector2(76, 76)
const NODE_FONT_SIZE: int = 16
const BOSS_FONT_SIZE: int = 22
## Font size of the gym's name sign.
const SIGN_FONT_SIZE: int = 19
## Short label of each room (kept as the button text for the QA harness / tooltips; the landmark is drawn).
const ROOM_SHORT: Dictionary = {"wild": "Combat", "elite": "Élite", "center": "Centre", "mart": "Mart",
		"event": "?", "boss": "Champion", "rival": "Rival"}
## Colour per room type (art bible §5; also used by Main for the placeholder room screen).
const ROOM_COLORS: Dictionary = {
	"wild": Color("#D95C4D"), "elite": Color("#AD5CE6"), "center": Color("#F280B3"),
	"mart": Color("#4D99F2"), "event": Color("#59BF6B"), "boss": Color("#FFC238"),
	"rival": Color("#F07A3A")}
const COLOR_UNKNOWN_ROOM: Color = Color(0.6, 0.6, 0.6)
## Town Map palette (story 020b).
const LINE: Color = Color("#262A3D")
const GLOW: Color = Color("#FFE066")
const SEA: Color = Color("#58B4EC")
const SHALLOW: Color = Color("#9FDDF7")
const ROAD: Color = Color("#F0DCA6")
const ROAD_EDGE: Color = Color("#9C7642")
const ROAD_NEXT: Color = Color("#FFF8DC")
const TRAIL_RED: Color = Color("#E8402A")
const ROAD_WIDTH: float = 11.0
const TRAIL_DOT_SPACING: float = 11.0
const ELITE_COLOR: Color = Color("#9C5BD9")
const RIVAL_COLOR: Color = Color("#F07A3A")
const CENTER_ROOF: Color = Color("#E8402A")
const MART_ROOF: Color = Color("#3B78E7")
const WALL: Color = Color("#FFF8EC")
const WOOD: Color = Color("#D9A35E")
## Kept for compatibility (story 020 / 020b names).
const INK: Color = LINE
const INK_RED: Color = TRAIL_RED
const PAPER: Color = Color("#FBFCFF")
const COLOR_TRAIL: Color = TRAIL_RED
const COLOR_VISITED_MARK: Color = Color("#5BD16E")
## Region look per gym type: land colour, beach colour, scenery kinds (picked at random, weighted by repetition),
## and whether the zone is an archipelago (Water) instead of one land mass.
const BIOMES: Dictionary = {
	"": {"land": Color("#86CC5E"), "beach": Color("#F2E3A8"), "deco": ["tree", "tree", "bush", "flowers"]},
	"grass": {"land": Color("#80C957"), "beach": Color("#F2E3A8"), "deco": ["tree", "tree", "bush", "flowers"]},
	"bug": {"land": Color("#76BE50"), "beach": Color("#EEDDA0"), "deco": ["tree", "tree", "tree", "bush"]},
	"normal": {"land": Color("#8ED068"), "beach": Color("#F2E3A8"), "deco": ["tree", "flowers", "bush", "house"]},
	"fairy": {"land": Color("#9AD67E"), "beach": Color("#F6E6B6"), "deco": ["pink_flowers", "tree", "pink_flowers", "bush"]},
	"fire": {"land": Color("#D48E58"), "beach": Color("#EDC48A"), "deco": ["volcano", "rock", "rock", "volcano"]},
	"ice": {"land": Color("#E9F3FA"), "beach": Color("#CFE4F2"), "deco": ["snow_pine", "snow_pine", "ice_rock"]},
	"water": {"land": Color("#86CC5E"), "beach": Color("#F4E4A6"), "deco": ["palm", "palm", "bush"], "islands": true},
	"rock": {"land": Color("#D6BB7C"), "beach": Color("#EBD7A2"), "deco": ["mountain", "rock", "rock", "mountain"]},
	"ground": {"land": Color("#DCBE76"), "beach": Color("#EFD9A0"), "deco": ["rock", "mountain", "rock"]},
	"fighting": {"land": Color("#C9B27E"), "beach": Color("#EBD7A2"), "deco": ["mountain", "rock", "tree"]},
	"dragon": {"land": Color("#7DBA78"), "beach": Color("#EEDDA0"), "deco": ["mountain", "tree", "mountain", "tree"]},
	"electric": {"land": Color("#BCD668"), "beach": Color("#F2E3A8"), "deco": ["pylon", "tree", "bush", "tree"]},
	"ghost": {"land": Color("#9F95BE"), "beach": Color("#D9D2E6"), "deco": ["dead_tree", "tomb", "tomb"]},
	"dark": {"land": Color("#8F8BA0"), "beach": Color("#D2CEDC"), "deco": ["dead_tree", "tomb", "rock"]},
	"poison": {"land": Color("#A592C4"), "beach": Color("#DCD2EA"), "deco": ["dead_tree", "tomb", "bush"]},
	"psychic": {"land": Color("#A9D98E"), "beach": Color("#F6E2C8"), "deco": ["pink_flowers", "tree", "bush"]},
	"flying": {"land": Color("#A6D98C"), "beach": Color("#F2E3A8"), "deco": ["tree", "bush", "flowers"]},
	"steel": {"land": Color("#BFC7D0"), "beach": Color("#DDE2E8"), "deco": ["house", "rock", "mountain"]}}

var _graph: MapGraph
var _progress: ActProgress
var _room_names: Dictionary = {}
var _buttons: Dictionary = {}
var _reachable: Array[String] = []
var _boss_label: String = ""
## Gym type colour (gym roof, badge, land tint), set by MapScreen.
var _zone_color: Color = UiStyle.ACCENT_RED
## Gym type id (picks the biome), set by MapScreen.
var _type_id: String = ""
## Region geometry, rebuilt on layout: land mass (superellipse centre / half-axes / wobble seed), islands and islets
## (x, y, radius), scenery ({"k": kind, "p": base point, "s": scale}) sorted back to front.
var _land_center: Vector2 = Vector2.ZERO
var _land_axes: Vector2 = Vector2.ZERO
var _land_seed: float = 0.0
var _islands: Array[Vector3] = []
var _islets: Array[Vector3] = []
var _deco: Array[Dictionary] = []
var _sign_box: StyleBoxFlat


## Story 020: colour of the zone's gym type (gym roof and badge, slight land tint). Call before setup.
func set_zone_color(color: Color) -> void:
	_zone_color = color
	queue_redraw()


## Story 020b: gym type id of the zone ("fire", "ice"...), picks the region look (land, scenery, islands).
func set_zone_type(type_id: String) -> void:
	_type_id = type_id
	_rebuild_region()
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


## Y (canvas coordinates) of the centre of a floor's row (the map is centred vertically when the canvas is taller).
func floor_y(floor_number: int) -> float:
	if _graph == null:
		return 0.0
	return PAD_TOP + _v_offset() + (_graph.floors - floor_number) * ROW_SPACING


## Centre of a room in canvas coordinates (the boss is centred horizontally).
func node_center(node: MapNode) -> Vector2:
	var x0: float = (size.x - (_graph.width - 1) * COL_SPACING) * 0.5
	var x: float = x0 + node.col * COL_SPACING
	if node.room_type == "boss":
		x = size.x * 0.5
	return Vector2(x, floor_y(node.floor))


## Draws the Town Map landmark of a `room_type` room centred on `c` (size `r`) on `ci`, then its state: soft yellow
## glow + white ring for reachable rooms, greyed + green check for visited ones, red Town Map cursor for the current
## room. The gym's roof and badge use `accent` (the gym type colour).
static func draw_room_icon(ci: CanvasItem, c: Vector2, r: float, room_type: String, state: int,
		accent: Color = UiStyle.ACCENT_RED) -> void:
	if state == IconState.REACHABLE:
		for i: int in 6:
			ci.draw_circle(c, r + 17.0 - i * 3.0, Color(GLOW, 0.06 + i * 0.05))
		ci.draw_arc(c, r + 6.0, 0.0, TAU, 48, Color(1, 1, 1, 0.95), 2.5, true)
	var dim: bool = state == IconState.VISITED
	ci.draw_colored_polygon(_ellipse(c + Vector2(r * 0.06, r * 0.66), r * 0.98, r * 0.26, 20), Color(0, 0, 0, 0.2))
	match room_type:
		"wild":
			_draw_grass_patch(ci, c, r, dim)
		"elite":
			_draw_trainer_badge(ci, c, r, ELITE_COLOR, false, dim)
		"rival":
			_draw_trainer_badge(ci, c, r, RIVAL_COLOR, true, dim)
		"center":
			_draw_building(ci, c, r, CENTER_ROOF, "ball", dim)
		"mart":
			_draw_building(ci, c, r, MART_ROOF, "mart", dim)
		"boss":
			_draw_gym(ci, c, r, accent, dim)
		_:
			_draw_signpost(ci, c, r, dim)
	match state:
		IconState.VISITED:
			var bc: Vector2 = c + Vector2(r * 0.8, r * 0.48)
			var br: float = maxf(5.5, r * 0.34)
			ci.draw_circle(bc, br + 1.8, LINE)
			ci.draw_circle(bc, br, COLOR_VISITED_MARK)
			ci.draw_polyline(PackedVector2Array([bc + Vector2(-br * 0.5, 0.0), bc + Vector2(-br * 0.12, br * 0.42),
					bc + Vector2(br * 0.55, -br * 0.4)]), Color.WHITE, maxf(1.6, br * 0.3), true)
		IconState.CURRENT:
			_draw_cursor(ci, c, r + 8.0)


## Draws a small Poké Ball (the "you are here" pin) of radius `r` at `c`.
static func draw_ball_marker(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.45, r * 0.7), c + Vector2(r * 0.45, r * 0.7),
			c + Vector2(0, r * 1.75)]), LINE)
	ci.draw_circle(c + Vector2(1.5, 3), r + 2.0, Color(0, 0, 0, 0.3))
	ci.draw_circle(c, r + 2.0, LINE)
	ci.draw_circle(c, r, Color.WHITE)
	var top := PackedVector2Array()
	for i: int in 17:
		top.append(c + Vector2.from_angle(PI + PI * i / 16.0) * r)
	ci.draw_colored_polygon(top, UiStyle.ACCENT_RED)
	ci.draw_arc(c + Vector2(-r * 0.3, -r * 0.35), r * 0.35, deg_to_rad(190), deg_to_rad(280), 8, Color(1, 1, 1, 0.6), 2.0, true)
	ci.draw_line(c - Vector2(r, 0), c + Vector2(r, 0), LINE, 2.5)
	ci.draw_circle(c, r * 0.38, LINE)
	ci.draw_circle(c, r * 0.24, Color.WHITE)


## Greys a colour for visited landmarks.
static func _tone(col: Color, dim: bool) -> Color:
	if not dim:
		return col
	var g: float = col.get_luminance()
	return col.lerp(Color(g, g, g), 0.7).lerp(Color("#D5D8E0"), 0.25)


## Filled polygon with a dark outline.
static func _shape(ci: CanvasItem, pts: PackedVector2Array, fill: Color, width: float = 2.0) -> void:
	ci.draw_colored_polygon(pts, fill)
	ci.draw_polyline(_closed(pts), LINE, width, true)


## Tall-grass patch: a dark rounded tuft bed and five bunches of blades (light front blade, shaded side blades).
static func _draw_grass_patch(ci: CanvasItem, c: Vector2, r: float, dim: bool) -> void:
	var bed: Vector2 = c + Vector2(0, r * 0.2)
	ci.draw_colored_polygon(_ellipse(bed, r * 0.98 + 2.0, r * 0.66 + 2.0, 24), LINE)
	ci.draw_colored_polygon(_ellipse(bed, r * 0.98, r * 0.66, 24), _tone(Color("#2F9440"), dim))
	ci.draw_colored_polygon(_ellipse(bed - Vector2(r * 0.08, r * 0.1), r * 0.8, r * 0.48, 24), _tone(Color("#45B24F"), dim))
	var lit: Color = _tone(Color("#A2EC6C"), dim)
	var shade: Color = _tone(Color("#62C955"), dim)
	var u: float = r * 0.42
	for p: Vector2 in [Vector2(-0.48, 0.02), Vector2(0.0, -0.14), Vector2(0.48, 0.02), Vector2(-0.24, 0.42), Vector2(0.24, 0.42)]:
		var b: Vector2 = c + p * r + Vector2(0, u * 0.45)
		for k: int in 3:
			var dx: float = (k - 1) * u * 0.5
			var h: float = u * (1.1 if k == 1 else 0.8)
			var tri := PackedVector2Array([b + Vector2(dx - u * 0.28, 0), b + Vector2(dx + (k - 1) * u * 0.22, -h),
					b + Vector2(dx + u * 0.28, 0)])
			_shape(ci, tri, lit if k == 1 else shade, 1.4)


## Round trainer badge (élite: trainer with a cap; rival: spiky hair) in `col`, white silhouette, cel shading.
static func _draw_trainer_badge(ci: CanvasItem, c: Vector2, r: float, col: Color, spiky: bool, dim: bool) -> void:
	var rr: float = r * 0.9
	var base: Color = _tone(col, dim)
	ci.draw_circle(c, rr + 2.2, LINE)
	ci.draw_circle(c, rr, base.darkened(0.22))
	ci.draw_circle(c - Vector2(rr * 0.06, rr * 0.08), rr * 0.9, base)
	ci.draw_arc(c, rr * 0.8, deg_to_rad(200), deg_to_rad(285), 12, Color(1, 1, 1, 0.45), maxf(1.5, r * 0.09), true)
	var white: Color = Color.WHITE if not dim else Color("#F0F1F4")
	var shoulders := PackedVector2Array()
	for i: int in 17:
		shoulders.append(c + Vector2(0, r * 0.62) + Vector2.from_angle(PI + PI * i / 16.0) * Vector2(r * 0.5, r * 0.44))
	ci.draw_colored_polygon(shoulders, white)
	var head: Vector2 = c + Vector2(0, -r * 0.16)
	ci.draw_circle(head, r * 0.25, white)
	if spiky:
		for k: int in 4:
			var a: float = deg_to_rad(-160.0 + k * 40.0)
			var root: Vector2 = head + Vector2.from_angle(a) * r * 0.2
			var tip: Vector2 = head + Vector2.from_angle(a + 0.25) * r * 0.46
			var side: Vector2 = Vector2.from_angle(a + PI / 2.0) * r * 0.12
			ci.draw_colored_polygon(PackedVector2Array([root - side, tip, root + side]), white)
	else:
		var cap := PackedVector2Array()
		for i: int in 11:
			cap.append(head + Vector2(0, -r * 0.04) + Vector2.from_angle(PI + PI * i / 10.0) * r * 0.27)
		ci.draw_colored_polygon(cap, base.darkened(0.45))
		ci.draw_line(head + Vector2(-r * 0.05, -r * 0.04), head + Vector2(r * 0.42, -r * 0.04), base.darkened(0.45),
				maxf(1.5, r * 0.1), true)


## Small Town Map building (Pokémon Center / Poké Mart): cream walls, coloured roof, door and windows, roof sign.
static func _draw_building(ci: CanvasItem, c: Vector2, r: float, roof_col: Color, sign_kind: String, dim: bool) -> void:
	var bw: float = r * 1.5
	var bottom: float = c.y + r * 0.64
	var top: float = c.y - r * 0.12
	var body := Rect2(c.x - bw * 0.5, top, bw, bottom - top)
	ci.draw_rect(body.grow(2.0), LINE)
	ci.draw_rect(body, _tone(WALL, dim))
	ci.draw_rect(Rect2(body.end.x - bw * 0.16, top, bw * 0.16, body.size.y), _tone(Color("#E2D6C2"), dim))
	var glass: Color = _tone(Color("#7CC8F4"), dim)
	var door := Rect2(c.x - r * 0.18, bottom - r * 0.44, r * 0.36, r * 0.44)
	ci.draw_rect(door.grow(1.2), LINE)
	ci.draw_rect(door, glass)
	ci.draw_line(Vector2(c.x, door.position.y), Vector2(c.x, bottom), LINE, 1.0)
	for sx: float in [-1.0, 1.0]:
		var win := Rect2(c.x + sx * r * 0.48 - r * 0.13, top + r * 0.16, r * 0.26, r * 0.22)
		ci.draw_rect(win.grow(1.0), LINE)
		ci.draw_rect(win, glass)
	var roof_c: Color = _tone(roof_col, dim)
	var rb: float = top + r * 0.06
	var roof := PackedVector2Array([Vector2(c.x - r * 0.96, rb), Vector2(c.x - r * 0.62, top - r * 0.6),
			Vector2(c.x + r * 0.62, top - r * 0.6), Vector2(c.x + r * 0.96, rb)])
	_shape(ci, roof, roof_c, 2.0)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(c.x - r * 0.9, rb - 1.0), Vector2(c.x + r * 0.9, rb - 1.0),
			Vector2(c.x + r * 0.84, rb - r * 0.14), Vector2(c.x - r * 0.84, rb - r * 0.14)]), roof_c.darkened(0.28))
	ci.draw_line(Vector2(c.x - r * 0.55, top - r * 0.52), Vector2(c.x + r * 0.55, top - r * 0.52),
			roof_c.lightened(0.35), maxf(1.2, r * 0.08), true)
	var sc: Vector2 = Vector2(c.x, top - r * 0.3)
	if sign_kind == "ball":
		var sr: float = r * 0.22
		ci.draw_circle(sc, sr + 1.5, LINE)
		ci.draw_circle(sc, sr, Color.WHITE)
		ci.draw_line(sc - Vector2(sr, 0), sc + Vector2(sr, 0), LINE, maxf(1.0, r * 0.06))
		ci.draw_circle(sc, sr * 0.38, LINE)
		ci.draw_circle(sc, sr * 0.22, Color.WHITE)
	else:
		var plate := Rect2(sc - Vector2(r * 0.3, r * 0.19), Vector2(r * 0.6, r * 0.38))
		ci.draw_rect(plate.grow(1.4), LINE)
		ci.draw_rect(plate, Color.WHITE)
		var m: float = r * 0.13
		ci.draw_polyline(PackedVector2Array([sc + Vector2(-m * 1.2, m), sc + Vector2(-m * 1.2, -m), sc + Vector2(0, m * 0.4),
				sc + Vector2(m * 1.2, -m), sc + Vector2(m * 1.2, m)]), roof_c, maxf(1.3, r * 0.08), true)


## Gym: bigger building with a type-coloured two-step roof, a badge on the dome, pillars and a double door.
static func _draw_gym(ci: CanvasItem, c: Vector2, r: float, accent: Color, dim: bool) -> void:
	var bw: float = r * 1.9
	var bottom: float = c.y + r * 0.62
	var top: float = c.y - r * 0.08
	var body := Rect2(c.x - bw * 0.5, top, bw, bottom - top)
	ci.draw_rect(body.grow(2.0), LINE)
	ci.draw_rect(body, _tone(WALL, dim))
	ci.draw_rect(Rect2(body.end.x - bw * 0.14, top, bw * 0.14, body.size.y), _tone(Color("#E2D6C2"), dim))
	for sx: float in [-0.72, -0.4, 0.4, 0.72]:
		ci.draw_line(Vector2(c.x + sx * r, top + r * 0.08), Vector2(c.x + sx * r, bottom - 1.0), _tone(Color("#CBBDA6"), dim),
				maxf(1.5, r * 0.08))
	var door := Rect2(c.x - r * 0.28, bottom - r * 0.46, r * 0.56, r * 0.46)
	ci.draw_rect(door.grow(1.4), LINE)
	ci.draw_rect(door, _tone(accent.darkened(0.45), dim))
	ci.draw_line(Vector2(c.x, door.position.y), Vector2(c.x, bottom), LINE, 1.2)
	var roof_c: Color = _tone(accent, dim)
	var rb: float = top + r * 0.06
	var roof := PackedVector2Array([Vector2(c.x - r * 1.12, rb), Vector2(c.x - r * 0.8, top - r * 0.42),
			Vector2(c.x + r * 0.8, top - r * 0.42), Vector2(c.x + r * 1.12, rb)])
	_shape(ci, roof, roof_c, 2.2)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(c.x - r * 1.06, rb - 1.0), Vector2(c.x + r * 1.06, rb - 1.0),
			Vector2(c.x + r * 1.0, rb - r * 0.12), Vector2(c.x - r * 1.0, rb - r * 0.12)]), roof_c.darkened(0.3))
	ci.draw_line(Vector2(c.x - r * 0.72, top - r * 0.35), Vector2(c.x + r * 0.72, top - r * 0.35), roof_c.lightened(0.35),
			maxf(1.2, r * 0.06), true)
	var dome: Vector2 = Vector2(c.x, top - r * 0.42)
	var dome_pts := PackedVector2Array()
	for i: int in 17:
		dome_pts.append(dome + Vector2.from_angle(PI + PI * i / 16.0) * Vector2(r * 0.52, r * 0.5))
	_shape(ci, dome_pts, roof_c.lightened(0.12), 2.0)
	var bc: Vector2 = dome + Vector2(0, -r * 0.2)
	var badge_r: float = r * 0.26
	ci.draw_colored_polygon(_ngon(bc, badge_r + 2.0, 8, PI / 8.0), LINE)
	ci.draw_colored_polygon(_ngon(bc, badge_r, 8, PI / 8.0), _tone(Color("#FFD23F"), dim))
	ci.draw_colored_polygon(_ngon(bc, badge_r * 0.68, 8, PI / 8.0), roof_c.darkened(0.15))
	ci.draw_colored_polygon(_star(bc, badge_r * 0.5, badge_r * 0.22), Color.WHITE)


## "?" signpost: wooden post and board, white "?" with a dark outline.
static func _draw_signpost(ci: CanvasItem, c: Vector2, r: float, dim: bool) -> void:
	var wood: Color = _tone(WOOD, dim)
	var post := Rect2(c.x - r * 0.1, c.y, r * 0.2, r * 0.66)
	ci.draw_rect(post.grow(1.5), LINE)
	ci.draw_rect(post, wood.darkened(0.35))
	var board := Rect2(c.x - r * 0.72, c.y - r * 0.66, r * 1.44, r * 0.96)
	ci.draw_rect(board.grow(2.0), LINE)
	ci.draw_rect(board, wood)
	ci.draw_rect(Rect2(board.position, Vector2(board.size.x, r * 0.16)), wood.lightened(0.22))
	ci.draw_rect(Rect2(board.position + Vector2(0, board.size.y - r * 0.14), Vector2(board.size.x, r * 0.14)), wood.darkened(0.18))
	var font: Font = UiStyle.font_bold()
	var fs: int = maxi(10, int(r * 1.0))
	var tw: float = font.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var pos := Vector2(c.x - tw * 0.5, board.get_center().y + (font.get_ascent(fs) - font.get_descent(fs)) * 0.5)
	ci.draw_string_outline(font, pos, "?", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, maxi(3, int(r * 0.22)), LINE)
	ci.draw_string(font, pos, "?", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)


## Red Town Map cursor: four corner brackets at half-size `d` around `c`.
static func _draw_cursor(ci: CanvasItem, c: Vector2, d: float) -> void:
	var l: float = d * 0.45
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			var k: Vector2 = c + Vector2(sx * d, sy * d)
			var pts := PackedVector2Array([k - Vector2(sx * l, 0), k, k - Vector2(0, sy * l)])
			ci.draw_polyline(pts, LINE, 7.0, true)
			ci.draw_polyline(pts, TRAIL_RED, 4.0, true)


static func _ellipse(c: Vector2, rx: float, ry: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in n:
		var a: float = TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
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


static func _shift(pts: PackedVector2Array, v: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Vector2 in pts:
		out.append(p + v)
	return out


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
	_rebuild_region()
	queue_redraw()


func _v_offset() -> float:
	return maxf(0.0, (size.y - custom_minimum_size.y) * 0.5)


func _biome() -> Dictionary:
	return BIOMES.get(_type_id, BIOMES[""])


## Land mass outline grown by `d` px: a wobbly superellipse around all the rooms (deterministic per map seed).
func _land_poly(d: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var s: float = _land_seed
	for i: int in 96:
		var t: float = TAU * i / 96.0
		var ct: float = cos(t)
		var st: float = sin(t)
		var k: float = 1.0 + 0.03 * sin(3.0 * t + s) + 0.02 * sin(7.0 * t + 2.0 * s) + 0.01 * sin(13.0 * t + 3.0 * s)
		var x: float = signf(ct) * pow(absf(ct), 0.42) * (_land_axes.x * k + d)
		var y: float = signf(st) * pow(absf(st), 0.42) * (_land_axes.y * k + d)
		pts.append(_land_center + Vector2(x, y))
	return pts


## Recomputes the land mass, islands, islets and scenery for the current size / graph / zone type.
func _rebuild_region() -> void:
	_islands.clear()
	_islets.clear()
	_deco.clear()
	if _graph == null or size.x <= 0.0 or _graph.nodes.is_empty():
		return
	var bio: Dictionary = _biome()
	var archipelago: bool = bool(bio.get("islands", false))
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	var centers: Array[Vector2] = []
	var segs: Array[PackedVector2Array] = []
	var boss_c: Vector2 = Vector2(-1000, -1000)
	for id: String in _graph.nodes.keys():
		var node: MapNode = _graph.nodes[id]
		var c: Vector2 = node_center(node)
		centers.append(c)
		lo = lo.min(c)
		hi = hi.max(c)
		if node.room_type == "boss":
			boss_c = c
			_islands.append(Vector3(c.x, c.y, 44.0))
		else:
			_islands.append(Vector3(c.x, c.y, 46.0))
		for next_id: String in node.next:
			var other: MapNode = _graph.get_node(next_id)
			if other != null:
				segs.append(PackedVector2Array([c, node_center(other)]))
	_land_seed = fposmod(float(_graph.seed) * 0.6180339 + float(hash(_type_id) % 1000) * 0.01, TAU)
	_land_center = (lo + hi) * 0.5
	_land_axes = Vector2(minf((hi.x - lo.x) * 0.5 + 66.0, size.x * 0.5 - 22.0), (hi.y - lo.y) * 0.5 + 44.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = (int(_graph.seed) * 7919 + hash(_type_id)) & 0x7fffffff
	var big: PackedVector2Array = _land_poly(40.0)
	var inner: PackedVector2Array = _land_poly(-22.0)
	var sign_rect := Rect2(boss_c + Vector2(BOSS_RADIUS * 1.1, -26.0), Vector2(230.0, 44.0))
	for i: int in 60:  # small islets out at sea
		if _islets.size() >= 5:
			break
		var p := Vector2(rng.randf_range(34.0, size.x - 34.0), rng.randf_range(30.0, maxf(size.y, custom_minimum_size.y) - 30.0))
		if not archipelago and Geometry2D.is_point_in_polygon(p, big):
			continue
		if archipelago and _near_any(p, centers, segs, 70.0):
			continue
		var ok: bool = true
		for q: Vector3 in _islets:
			ok = ok and p.distance_to(Vector2(q.x, q.y)) > 60.0
		if ok:
			_islets.append(Vector3(p.x, p.y, rng.randf_range(9.0, 16.0)))
	var kinds: Array = bio.get("deco", ["tree"])
	var step: float = 27.0
	var y: float = 4.0
	while y < maxf(size.y, custom_minimum_size.y):
		var x: float = 6.0
		while x < size.x:
			var p := Vector2(x + rng.randf_range(-9.0, 9.0), y + rng.randf_range(-8.0, 8.0))
			var roll: float = rng.randf()
			var kind: String = String(kinds[rng.randi() % kinds.size()])
			var sc: float = rng.randf_range(0.85, 1.15)
			x += step
			if roll > 0.4 or sign_rect.has_point(p):
				continue
			var on_land: bool = false
			if archipelago:
				for isl: Vector3 in _islands:
					on_land = on_land or p.distance_to(Vector2(isl.x, isl.y)) < isl.z - 10.0
			else:
				on_land = Geometry2D.is_point_in_polygon(p, inner)
			if not on_land or _near_any(p, [], segs, 15.0):
				continue
			var clear: bool = true
			for c: Vector2 in centers:
				var keep: float = 62.0 if c == boss_c else (30.0 if archipelago else 36.0)
				clear = clear and p.distance_to(c) > keep
			if clear:
				_deco.append({"k": kind, "p": p, "s": sc})
		y += step
	_deco.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return (a["p"] as Vector2).y < (b["p"] as Vector2).y)


## True if `p` is within `dist` of one of `points` or of one of the `segs` segments.
func _near_any(p: Vector2, points: Array, segs: Array[PackedVector2Array], dist: float) -> bool:
	for q: Vector2 in points:
		if p.distance_to(q) < dist:
			return true
	for s: PackedVector2Array in segs:
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p, s[0], s[1])) < dist:
			return true
	return false


func _draw() -> void:
	if _graph == null:
		return
	_draw_region()
	_draw_roads()
	var current: String = _progress.current_node_id
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
		draw_ball_marker(self, node_center(cn) + Vector2(cr + 11.0, -cr - 12.0), 8.5)


## Sea features, land mass / islands (shallow water, foam, dark coast, beach, land, cel highlight) and scenery.
func _draw_region() -> void:
	var bio: Dictionary = _biome()
	var land: Color = (bio["land"] as Color).lerp(_zone_color, 0.1)
	var beach: Color = bio["beach"] as Color
	var blobs: Array[Vector3] = _islets.duplicate()
	if bool(bio.get("islands", false)):
		blobs.append_array(_islands)
	else:
		draw_colored_polygon(_land_poly(22.0), Color(SHALLOW, 0.55))
		draw_polyline(_closed(_land_poly(9.0)), Color(1, 1, 1, 0.55), 2.0, true)
		draw_colored_polygon(_shift(_land_poly(3.0), Vector2(0, 5)), LINE)
		draw_colored_polygon(_land_poly(3.0), LINE)
		draw_colored_polygon(_shift(_land_poly(0.0), Vector2(0, 5)), beach.darkened(0.3))
		draw_colored_polygon(_land_poly(0.0), beach)
		draw_colored_polygon(_shift(_land_poly(-8.0), Vector2(0, -1)), land)
		draw_polyline(_closed(_shift(_land_poly(-8.0), Vector2(0, -1))), land.darkened(0.18), 2.0, true)
		draw_colored_polygon(_shift(_land_poly(-40.0), Vector2(-10, -10)), land.lightened(0.09))
	for b: Vector3 in blobs:
		draw_circle(Vector2(b.x, b.y), b.z + 14.0, Color(SHALLOW, 0.55))
	for b: Vector3 in blobs:
		draw_arc(Vector2(b.x, b.y), b.z + 6.0, 0.0, TAU, 32, Color(1, 1, 1, 0.5), 2.0, true)
	for b: Vector3 in blobs:
		draw_circle(Vector2(b.x, b.y + 4.0), b.z + 2.5, LINE)
		draw_circle(Vector2(b.x, b.y), b.z + 2.5, LINE)
	for b: Vector3 in blobs:
		draw_circle(Vector2(b.x, b.y + 4.0), b.z, beach.darkened(0.3))
		draw_circle(Vector2(b.x, b.y), b.z, beach)
	for b: Vector3 in blobs:
		draw_circle(Vector2(b.x, b.y - 1.0), b.z - 6.0, land)
	for b: Vector3 in blobs:
		draw_circle(Vector2(b.x - b.z * 0.18, b.y - b.z * 0.2), b.z * 0.62, land.lightened(0.09))
	for d: Dictionary in _deco:
		_draw_deco(String(d["k"]), d["p"] as Vector2, float(d["s"]))


## One scenery element standing on `p` (base point), scale `s`; cel-shaded with a dark outline.
func _draw_deco(kind: String, p: Vector2, s: float) -> void:
	draw_colored_polygon(_ellipse(p + Vector2(1, 1), 9.0 * s, 3.0 * s, 12), Color(0, 0, 0, 0.16))
	match kind:
		"tree", "palm":
			if kind == "palm":
				draw_line(p, p + Vector2(3, -15) * s, LINE, 4.0 * s)
				draw_line(p, p + Vector2(3, -15) * s, Color("#9A6A3A"), 2.2 * s)
				var top: Vector2 = p + Vector2(3, -16) * s
				for a: float in [-150.0, -110.0, -70.0, -30.0, 10.0, 170.0]:
					var tip: Vector2 = top + Vector2.from_angle(deg_to_rad(a)) * 10.0 * s + Vector2(0, 3) * s
					var side: Vector2 = Vector2.from_angle(deg_to_rad(a + 90.0)) * 2.6 * s
					_shape(self, PackedVector2Array([top - side, tip, top + side]), Color("#4FB54A"), 1.2)
			else:
				draw_rect(Rect2(p + Vector2(-2.2, -6) * s, Vector2(4.4, 7) * s), Color("#7A5230"))
				var cc: Vector2 = p + Vector2(0, -12) * s
				draw_circle(cc, 9.0 * s + 1.6, LINE)
				draw_circle(cc, 9.0 * s, Color("#2F8A3C"))
				draw_circle(cc - Vector2(1.6, 2.0) * s, 6.8 * s, Color("#4FB54A"))
				draw_circle(cc - Vector2(3.0, 3.6) * s, 2.6 * s, Color("#8BDC6A"))
		"snow_pine":
			draw_rect(Rect2(p + Vector2(-2, -4) * s, Vector2(4, 5) * s), Color("#7A5230"))
			var tri := PackedVector2Array([p + Vector2(-9, -3) * s, p + Vector2(0, -24) * s, p + Vector2(9, -3) * s])
			_shape(self, tri, Color("#3F8F70"), 1.6)
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -3) * s, p + Vector2(0, -24) * s, p + Vector2(9, -3) * s]),
					Color("#2E6F57"))
			_shape(self, PackedVector2Array([p + Vector2(-4.5, -13.5) * s, p + Vector2(0, -24) * s, p + Vector2(4.5, -13.5) * s,
					p + Vector2(1.5, -15) * s, p + Vector2(-1.5, -13) * s]), Color.WHITE, 1.2)
		"bush", "flowers", "pink_flowers":
			if kind == "bush":
				for o: Vector2 in [Vector2(-5, -4), Vector2(5, -4), Vector2(0, -8)]:
					draw_circle(p + o * s, 6.0 * s + 1.4, LINE)
				for o: Vector2 in [Vector2(-5, -4), Vector2(5, -4), Vector2(0, -8)]:
					draw_circle(p + o * s, 6.0 * s, Color("#3FA04A"))
					draw_circle(p + (o - Vector2(1.5, 1.5)) * s, 3.4 * s, Color("#6CCB5E"))
			else:
				var petals: Array = [Color("#FF6B6B"), Color("#FFE15A"), Color.WHITE] if kind == "flowers" \
						else [Color("#FF8FC8"), Color("#FFFFFF"), Color("#F7B6E0")]
				for k: int in 4:
					var fp: Vector2 = p + Vector2(-8 + k * 5.5, -3.0 - (k % 2) * 4.0) * s
					draw_circle(fp, 2.6 * s + 1.0, Color(LINE, 0.7))
					draw_circle(fp, 2.6 * s, petals[k % petals.size()] as Color)
					draw_circle(fp, 0.9 * s, Color("#F5A623"))
		"volcano":
			var cone := PackedVector2Array([p + Vector2(-16, 0) * s, p + Vector2(-5, -20) * s, p + Vector2(5, -20) * s,
					p + Vector2(16, 0) * s])
			_shape(self, cone, Color("#B4633A"), 1.8)
			draw_colored_polygon(PackedVector2Array([p + Vector2(1, 0) * s, p + Vector2(2, -20) * s, p + Vector2(5, -20) * s,
					p + Vector2(16, 0) * s]), Color("#8A452A"))
			_shape(self, _ellipse(p + Vector2(0, -20) * s, 5.5 * s, 2.2 * s, 12), Color("#FF8A2A"), 1.4)
			draw_line(p + Vector2(-1, -19) * s, p + Vector2(-4, -9) * s, Color("#FFB43A"), 2.2 * s, true)
		"rock", "ice_rock":
			var col: Color = Color("#A38D6E") if kind == "rock" else Color("#BFE6F5")
			var pts := PackedVector2Array([p + Vector2(-8, 0) * s, p + Vector2(-7, -6) * s, p + Vector2(-2, -10) * s,
					p + Vector2(5, -9) * s, p + Vector2(8, -3) * s, p + Vector2(7, 0) * s])
			_shape(self, pts, col, 1.5)
			draw_colored_polygon(PackedVector2Array([p + Vector2(-6, -5) * s, p + Vector2(-2, -9) * s, p + Vector2(3, -8) * s,
					p + Vector2(-1, -5) * s]), col.lightened(0.35))
		"mountain":
			var m := PackedVector2Array([p + Vector2(-17, 0) * s, p + Vector2(0, -24) * s, p + Vector2(17, 0) * s])
			_shape(self, m, Color("#C9A66A"), 1.8)
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, 0) * s, p + Vector2(0, -24) * s, p + Vector2(17, 0) * s]),
					Color("#9C7C48"))
			_shape(self, PackedVector2Array([p + Vector2(-5.5, -16) * s, p + Vector2(0, -24) * s, p + Vector2(5.5, -16) * s,
					p + Vector2(1.5, -18) * s, p + Vector2(-2, -15.5) * s]), Color.WHITE, 1.2)
		"dead_tree":
			draw_line(p, p + Vector2(0, -18) * s, LINE, 4.4 * s, true)
			draw_line(p, p + Vector2(0, -18) * s, Color("#5E4A6E"), 2.6 * s, true)
			for br: Array in [[Vector2(0, -10), Vector2(-7, -16)], [Vector2(0, -13), Vector2(6, -20)], [Vector2(0, -6), Vector2(6, -10)]]:
				draw_line(p + (br[0] as Vector2) * s, p + (br[1] as Vector2) * s, Color("#5E4A6E"), 2.0 * s, true)
		"tomb":
			var t := PackedVector2Array([p + Vector2(-6, 0) * s, p + Vector2(-6, -9) * s, p + Vector2(-4, -13) * s,
					p + Vector2(0, -14.5) * s, p + Vector2(4, -13) * s, p + Vector2(6, -9) * s, p + Vector2(6, 0) * s])
			_shape(self, t, Color("#B9B6C8"), 1.5)
			draw_line(p + Vector2(0, -11) * s, p + Vector2(0, -4) * s, Color("#6E6A82"), 1.5, true)
			draw_line(p + Vector2(-2.5, -8.5) * s, p + Vector2(2.5, -8.5) * s, Color("#6E6A82"), 1.5, true)
		"pylon":
			draw_line(p, p + Vector2(0, -24) * s, LINE, 4.0 * s)
			draw_line(p, p + Vector2(0, -24) * s, Color("#9AA3B5"), 2.2 * s)
			draw_line(p + Vector2(-7, -20) * s, p + Vector2(7, -20) * s, LINE, 3.0 * s)
			draw_line(p + Vector2(-7, -20) * s, p + Vector2(7, -20) * s, Color("#9AA3B5"), 1.6 * s)
			_shape(self, PackedVector2Array([p + Vector2(3, -30) * s, p + Vector2(-1, -25) * s, p + Vector2(2, -25) * s,
					p + Vector2(-2, -20) * s, p + Vector2(4, -26) * s, p + Vector2(1, -26) * s]), UiStyle.ACCENT_YELLOW, 1.0)
		"house":
			var body := Rect2(p + Vector2(-7, -9) * s, Vector2(14, 9) * s)
			draw_rect(body.grow(1.4), LINE)
			draw_rect(body, WALL)
			_shape(self, PackedVector2Array([p + Vector2(-9, -8) * s, p + Vector2(-5, -15) * s, p + Vector2(5, -15) * s,
					p + Vector2(9, -8) * s]), Color("#7C8AA8"), 1.4)


## Routes between the rooms: dark outline then beige strip (brighter, glowing for the next choices), then the red
## dotted trail on the travelled ones.
func _draw_roads() -> void:
	var current: String = _progress.current_node_id
	var walked: Array[PackedVector2Array] = []
	var nexts: Array[PackedVector2Array] = []
	var others: Array[PackedVector2Array] = []
	for id: String in _graph.nodes.keys():
		var node: MapNode = _graph.nodes[id]
		for next_id: String in node.next:
			var other: MapNode = _graph.get_node(next_id)
			if other == null:
				continue
			var seg := PackedVector2Array([node_center(node), node_center(other), Vector2(_radius(node), _radius(other))])
			if _is_walked(id, next_id):
				walked.append(seg)
			elif id == current and _reachable.has(next_id):
				nexts.append(seg)
			else:
				others.append(seg)
	var all: Array[PackedVector2Array] = []
	all.append_array(others)
	all.append_array(walked)
	all.append_array(nexts)
	for seg: PackedVector2Array in nexts:
		draw_line(seg[0], seg[1], Color(GLOW, 0.55), ROAD_WIDTH + 14.0, true)
	for seg: PackedVector2Array in all:
		_cap_line(seg[0], seg[1], ROAD_EDGE, ROAD_WIDTH + 4.0)
	for seg: PackedVector2Array in all:
		var fill: Color = ROAD_NEXT if nexts.has(seg) else ROAD
		_cap_line(seg[0], seg[1], fill, ROAD_WIDTH)
		draw_line(seg[0], seg[1], Color(fill.lightened(0.4), 0.55), ROAD_WIDTH * 0.32, true)
	for seg: PackedVector2Array in walked:
		var a: Vector2 = seg[0]
		var b: Vector2 = seg[1]
		var length: float = a.distance_to(b)
		var usable: float = length - seg[2].x - seg[2].y - 8.0
		if usable <= 0.0:
			continue
		var dir: Vector2 = (b - a) / length
		var n: int = int(usable / TRAIL_DOT_SPACING)
		var start: float = seg[2].x + 4.0 + (usable - n * TRAIL_DOT_SPACING) * 0.5
		for i: int in n + 1:
			var p: Vector2 = a + dir * (start + i * TRAIL_DOT_SPACING)
			draw_circle(p, 4.4, Color.WHITE)
			draw_circle(p, 3.0, TRAIL_RED)


func _cap_line(a: Vector2, b: Vector2, col: Color, width: float) -> void:
	draw_line(a, b, col, width, true)
	draw_circle(a, width * 0.5, col)
	draw_circle(b, width * 0.5, col)


func _radius(node: MapNode) -> float:
	return BOSS_RADIUS if node.room_type == "boss" else ICON_RADIUS


## Gym name on a white Pokémon-style sign (rounded, dark outline, type-coloured tab) right of the building.
func _draw_boss_label(c: Vector2, r: float) -> void:
	if _sign_box == null:
		_sign_box = StyleBoxFlat.new()
		_sign_box.bg_color = Color.WHITE
		_sign_box.border_color = LINE
		_sign_box.set_border_width_all(2)
		_sign_box.set_corner_radius_all(8)
		_sign_box.shadow_color = Color(0, 0, 0, 0.25)
		_sign_box.shadow_size = 3
		_sign_box.shadow_offset = Vector2(0, 2)
		_sign_box.anti_aliasing = true
	var font: Font = UiStyle.font_bold()
	var fs: int = SIGN_FONT_SIZE
	var tw: float = font.get_string_size(_boss_label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var h: float = font.get_height(fs) + 8.0
	var rect := Rect2(c + Vector2(r * 1.2 + 12.0, -h * 0.5 - r * 0.1), Vector2(tw + 26.0, h))
	draw_style_box(_sign_box, rect)
	draw_rect(Rect2(rect.position + Vector2(4, 4), Vector2(6, rect.size.y - 8)), _zone_color)
	draw_string(font, Vector2(rect.position.x + 17.0, rect.position.y + 4.0 + font.get_ascent(fs)), _boss_label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiStyle.TEXT_DARK)


func _state_of(id: String) -> int:
	if id == _progress.current_node_id:
		return IconState.CURRENT
	if _progress.is_visited(id):
		return IconState.VISITED
	if _reachable.has(id):
		return IconState.REACHABLE
	return IconState.FUTURE


## True if the player walked from `a` straight to `b` (consecutive in the visit order).
func _is_walked(a: String, b: String) -> bool:
	var i: int = _progress.visited.find(a)
	return i >= 0 and i + 1 < _progress.visited.size() and _progress.visited[i + 1] == b


## Transparent click area (the landmark is drawn by _draw); hover = soft white disc with a yellow ring. The text
## stays for the QA harness and is drawn invisible.
func _style_button(b: Button, node: MapNode) -> void:
	var clickable: bool = _reachable.has(node.id) and node.id != _progress.current_node_id
	b.disabled = not clickable
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if clickable else Control.CURSOR_ARROW
	var empty := StyleBoxEmpty.new()
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(1, 1, 1, 0.22)
	hover.border_color = UiStyle.ACCENT_YELLOW
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


## Legend / UI swatch: one room landmark drawn in a small Control (story 020).
class RoomIcon extends Control:
	var room_type: String = ""
	var accent: Color = UiStyle.ACCENT_RED

	func _init(type_id: String = "", side: float = 26.0, accent_color: Color = UiStyle.ACCENT_RED) -> void:
		room_type = type_id
		accent = accent_color
		custom_minimum_size = Vector2(side, side)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r: float = minf(size.x, size.y) * 0.5 - 2.0
		if room_type == "boss":
			r = (minf(size.x, size.y) * 0.5 - 1.0) / 1.15  # the roof is wider than the icon radius
		MapCanvas.draw_room_icon(self, size * 0.5 + Vector2(0, r * 0.08), r, room_type, MapCanvas.IconState.NORMAL, accent)
