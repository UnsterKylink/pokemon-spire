class_name UiStyle
extends RefCounted
## Shared look of the game (« Cartoon vectoriel lumineux »): palette, type / rarity colours, StyleBoxFlat
## factories and a Theme. Values mirror design/art-bible.md; type colours come from assets/data/types.json.
## Display only: owns no game state. Implements: story-020 (style graphique).
## Story 020b (refonte premium): embedded fonts (Kreon titles / Nunito text, OFL, assets/fonts/), generated material
## textures (assets/art/ui/) and the « sheen » finish (grain, light gradient, inner highlight) on panels and buttons.

# --- Palette (art bible §2) -------------------------------------------------------------------------
const BG_DEEP: Color = Color("#161B33")
const BG_PANEL: Color = Color("#252E5A")
const BG_PANEL_LIGHT: Color = Color("#34407A")
const OUTLINE: Color = Color("#11142A")
const CREAM: Color = Color("#FFF6E0")
const TEXT: Color = Color("#FFFFFF")
const TEXT_MUTED: Color = Color("#B4BEDD")
const TEXT_DARK: Color = Color("#1E2233")
const ACCENT_RED: Color = Color("#E8402A")
const ACCENT_BLUE: Color = Color("#3B78E7")
const ACCENT_YELLOW: Color = Color("#FFCB05")
const HP_GREEN: Color = Color("#4CD964")
const HP_ORANGE: Color = Color("#FFA53A")
const HP_RED: Color = Color("#FF4F45")
const BLOCK_BLUE: Color = Color("#5AB4FF")
const SUCCESS: Color = Color("#5BD16E")
const SKILL: Color = Color("#7E9CCF")
const DISABLED_BG: Color = Color("#5A6078")
const DISABLED_TEXT: Color = Color("#A0A6BC")
const SHADOW: Color = Color(0, 0, 0, 0.35)

## Rarity colours (art bible §2); legendary cards use LEGENDARY (+ LEGENDARY_INNER for the inner trim).
const RARITY_COLORS: Dictionary = {
	"starter": Color("#A7B0C0"), "common": Color("#E8ECF4"), "uncommon": Color("#3FD0C0"), "rare": Color("#FFAA2B")}
const LEGENDARY: Color = Color("#FFD23F")
const LEGENDARY_INNER: Color = Color("#FF7AD9")

# --- Frames / typography (art bible §3-4) -----------------------------------------------------------
const PANEL_RADIUS: int = 14
const PANEL_BORDER: int = 3
const BUTTON_RADIUS: int = 12
const BUTTON_BORDER: int = 2
const BUTTON_BOTTOM: int = 5
const BUTTON_BOTTOM_PRESSED: int = 2
const BADGE_RADIUS: int = 9
## Label roles -> [font size, outline size, colour].
const LABEL_ROLES: Dictionary = {
	"title": [40, 8, TEXT], "heading": [28, 6, TEXT], "number": [22, 6, TEXT],
	"body": [18, 0, TEXT], "caption": [15, 0, TEXT_MUTED], "dark": [16, 0, TEXT_DARK]}
const DEFAULT_FONT_SIZE: int = 18

const TYPES_PATH: String = "res://assets/data/types.json"

# --- Story 020b: fonts, textures, finish (art bible §3, §4, §8) ------------------------------------------
## Titles, card names, numbers: Kreon (slab serif, the Slay the Spire family); text: Nunito (rounded, very readable).
const FONT_TITLE_PATH: String = "res://assets/fonts/kreon/Kreon-Variable.ttf"
const FONT_BODY_PATH: String = "res://assets/fonts/nunito/Nunito-Variable.ttf"
const WEIGHT_TITLE: int = 700
const WEIGHT_BODY: int = 600
const WEIGHT_BOLD: int = 800
## Roles drawn with the title font (the others use the body font).
const TITLE_ROLES: Array[String] = ["title", "heading", "number"]
## Labels at or above this size (set by screens) get the title font from the screen polisher.
const TITLE_FONT_MIN_SIZE: int = 24
const UI_TEXTURE_DIR: String = "res://assets/art/ui/"
const SHEEN_SHADER_PATH: String = "res://src/ui/shaders/ui_sheen.gdshader"
## Sheen strengths: [grain, mottling, top_light, bottom_shade, highlight_line] for panels and buttons.
const SHEEN_PANEL: Array[float] = [0.06, 0.07, 0.07, 0.14, 0.18]
const SHEEN_BUTTON: Array[float] = [0.05, 0.03, 0.16, 0.2, 0.42]
## Below this fill alpha a box is a see-through overlay: no sheen.
const SHEEN_MIN_ALPHA: float = 0.5

static var _fonts: Dictionary = {}
static var _textures: Dictionary = {}
static var _sheen_materials: Dictionary = {}

## types.json colour cache (type id -> Color), filled on first use. Pure display cache.
static var _type_colors: Dictionary = {}
static var _types_loaded: bool = false


## Display colour of a Pokémon type: from `chart` when given, else from types.json "types.<id>.color".
## Unknown / empty type ids give SKILL (the neutral card colour).
static func type_color(type_id: String, chart: TypeChart = null) -> Color:
	if type_id.is_empty():
		return SKILL
	if chart != null:
		return chart.get_type_color(type_id) if chart.is_known_type(type_id) else SKILL
	_load_type_colors()
	return _type_colors.get(type_id, SKILL)


## Story 020b: title font (Kreon Bold) — screen titles, headings, numbers, card names. Never null.
static func font_title() -> Font:
	return _font("title", FONT_TITLE_PATH, WEIGHT_TITLE)


## Story 020b: body font (Nunito SemiBold) — text, captions, card descriptions. Never null.
static func font_body() -> Font:
	return _font("body", FONT_BODY_PATH, WEIGHT_BODY)


## Story 020b: bold body font (Nunito ExtraBold) — buttons, pills, small labels. Never null.
static func font_bold() -> Font:
	return _font("bold", FONT_BODY_PATH, WEIGHT_BOLD)


## Generated UI / card texture `assets/art/ui/<tex_name>.png` (null when missing). Cached.
static func ui_texture(tex_name: String) -> Texture2D:
	if not _textures.has(tex_name):
		var path: String = UI_TEXTURE_DIR + tex_name + ".png"
		_textures[tex_name] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _textures[tex_name]


static func _font(key: String, path: String, weight: int) -> Font:
	if _fonts.has(key):
		return _fonts[key]
	var f: Font = ThemeDB.fallback_font
	if ResourceLoader.exists(path):
		var base: FontFile = load(path) as FontFile
		if base != null:
			var v := FontVariation.new()
			v.base_font = base
			v.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
			f = v
	_fonts[key] = f
	return f


## Rarity colour (art bible §2); `legendary` overrides the rarity with the legendary gold.
static func rarity_color(rarity: String, legendary: bool = false) -> Color:
	if legendary:
		return LEGENDARY
	return RARITY_COLORS.get(rarity, Color.WHITE)


## Readable text colour on top of `bg` (dark on light colours, white otherwise).
static func text_on(bg: Color) -> Color:
	return TEXT_DARK if bg.get_luminance() > 0.6 else TEXT


## Rounded panel (art bible §4): `bg` fill, dark outline, soft drop shadow, inner margins 12/10.
static func panel(bg: Color = BG_PANEL, radius: int = PANEL_RADIUS, border: int = PANEL_BORDER) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = OUTLINE
	sb.set_border_width_all(border)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = SHADOW
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	sb.anti_aliasing = true
	return sb


## Button style for one state ("normal", "hover", "pressed", "disabled", "focus") on base colour `base`:
## chunky darker bottom edge, pressed = shallower edge, disabled = grey, focus = yellow ring (no fill).
static func button_box(state: String, base: Color = ACCENT_BLUE) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(BUTTON_RADIUS)
	sb.anti_aliasing = true
	sb.content_margin_left = 14.0
	sb.content_margin_right = 14.0
	sb.content_margin_top = 6.0
	sb.content_margin_bottom = 6.0
	if state == "focus":
		sb.draw_center = false
		sb.border_color = ACCENT_YELLOW
		sb.set_border_width_all(3)
		return sb
	var fill: Color = base
	match state:
		"hover":
			fill = base.lightened(0.12)
		"pressed":
			fill = base.darkened(0.08)
		"disabled":
			fill = DISABLED_BG
	sb.bg_color = fill
	sb.border_color = OUTLINE
	sb.set_border_width_all(BUTTON_BORDER)
	sb.border_width_bottom = BUTTON_BOTTOM_PRESSED if state == "pressed" else BUTTON_BOTTOM
	sb.content_margin_top += 3.0 if state == "pressed" else 0.0
	sb.content_margin_bottom += 0.0 if state == "pressed" else 3.0
	sb.shadow_color = SHADOW
	sb.shadow_size = 0 if state == "pressed" else 3
	sb.shadow_offset = Vector2(0, 2)
	return sb


## Card frame (art bible §7): `color` gradient-less fill with a thick dark outline; legendary = gold outline.
static func card_frame(color: Color, legendary: bool = false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.border_color = LEGENDARY if legendary else OUTLINE
	sb.set_border_width_all(3 if legendary else 2)
	sb.set_corner_radius_all(8)
	sb.anti_aliasing = true
	return sb


## Small rounded badge (type / status chip) filled with `color`, dark outline.
static func badge(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.border_color = OUTLINE
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(BADGE_RADIUS)
	sb.content_margin_left = 9.0
	sb.content_margin_right = 9.0
	sb.content_margin_top = 1.0
	sb.content_margin_bottom = 1.0
	sb.anti_aliasing = true
	return sb


## Applies the five button states + white outlined text to `b` (base colour `base`).
static func apply_button(b: Button, base: Color = ACCENT_BLUE) -> void:
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(state, button_box(state, base))
	var text: Color = text_on(base)
	for key: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(key, text)
	b.add_theme_color_override("font_disabled_color", DISABLED_TEXT)
	b.add_theme_color_override("font_outline_color", OUTLINE)
	b.add_theme_constant_override("outline_size", 4 if text == TEXT else 0)


## Applies a typography role ("title", "heading", "number", "body", "caption", "dark") to `l`.
static func apply_label(l: Label, role: String) -> void:
	var spec: Array = LABEL_ROLES.get(role, LABEL_ROLES["body"])
	l.add_theme_font_size_override("font_size", int(spec[0]))
	l.add_theme_font_override("font", font_title() if TITLE_ROLES.has(role) else font_body())
	l.add_theme_constant_override("outline_size", int(spec[1]))
	l.add_theme_color_override("font_outline_color", OUTLINE)
	l.add_theme_color_override("font_color", spec[2])


## Theme for a screen root: buttons, panels, labels and tooltips in the art-bible look. Set it on the
## root Control (`root.theme = UiStyle.make_theme()`); explicit overrides on children still win.
static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = DEFAULT_FONT_SIZE
	t.default_font = font_body()
	t.set_font("font", "Button", font_bold())
	t.set_font("font", "TooltipLabel", font_body())
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		t.set_stylebox(state, "Button", button_box(state))
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", TEXT)
	t.set_color("font_pressed_color", "Button", TEXT)
	t.set_color("font_focus_color", "Button", TEXT)
	t.set_color("font_disabled_color", "Button", DISABLED_TEXT)
	t.set_color("font_outline_color", "Button", OUTLINE)
	t.set_constant("outline_size", "Button", 4)
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_outline_color", "Label", OUTLINE)
	t.set_stylebox("panel", "PanelContainer", panel())
	t.set_stylebox("panel", "Panel", panel())
	var tip: StyleBoxFlat = panel(BG_PANEL_LIGHT, 8, 2)
	tip.content_margin_top = 6.0
	tip.content_margin_bottom = 6.0
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_color("font_color", "TooltipLabel", TEXT)
	return t


static func _load_type_colors() -> void:
	if _types_loaded:
		return
	_types_loaded = true
	var f: FileAccess = FileAccess.open(TYPES_PATH, FileAccess.READ)
	if f == null:
		return
	var root: Variant = JSON.parse_string(f.get_as_text())
	if not (root is Dictionary) or not ((root as Dictionary).get("types", null) is Dictionary):
		return
	var types: Dictionary = (root as Dictionary)["types"]
	for id: Variant in types:
		var def: Variant = types[id]
		if def is Dictionary and String((def as Dictionary).get("color", "")).begins_with("#"):
			_type_colors[String(id)] = Color(String((def as Dictionary)["color"]))


## Story 020 (screens pass): gives `root` the art-bible theme and keeps re-skinning its subtree as it is built:
## plain Buttons get the bright outlined buttons (theme), custom StyleBoxFlat panels / buttons get rounded
## corners, a dark outline when they had none, a palette background when theirs was a plain dark grey and a soft
## shadow; big labels (>= 24 px) get a dark text outline. Card buttons (CardFace child) are left untouched.
## Display only; the helper node is internal, so get_children() of the screen is unchanged.
static func style_screen(root: Control) -> void:
	root.theme = make_theme()
	var p := _ScreenPolisher.new()
	p.name = "StylePolisher"
	root.add_child(p, false, Node.INTERNAL_MODE_BACK)


## Re-skins one node in place (see style_screen). Idempotent.
static func polish_node(n: Node) -> void:
	if n is Label:
		var l: Label = n
		if l.has_theme_font_size_override("font_size") and not l.has_theme_font_override("font") \
				and l.get_theme_font_size("font_size") >= TITLE_FONT_MIN_SIZE:
			l.add_theme_font_override("font", font_title())  # story 020b
		if l.has_theme_font_size_override("font_size") and not l.has_theme_constant_override("outline_size"):
			var fs: int = l.get_theme_font_size("font_size")
			if fs >= 24:
				l.add_theme_constant_override("outline_size", 8 if fs >= 32 else 6)
				l.add_theme_color_override("font_outline_color", OUTLINE)
	elif n is PanelContainer or n is Panel:
		var c: Control = n
		if c.has_theme_stylebox_override("panel") and c.get_theme_stylebox("panel") is StyleBoxFlat:
			_skin_box(c.get_theme_stylebox("panel") as StyleBoxFlat, true)
		add_sheen(c, true)
	elif n is Button:
		var b: Button = n
		for child: Node in b.get_children():
			if child is CardFace:
				return
		for state: String in ["normal", "hover", "pressed", "disabled"]:
			if b.has_theme_stylebox_override(state) and b.get_theme_stylebox(state) is StyleBoxFlat:
				_skin_box(b.get_theme_stylebox(state) as StyleBoxFlat, false)
		add_sheen(b, false)


## Story 020b: adds the material finish (grain, soft light gradient, inner top highlight; ui_sheen.gdshader) over the
## StyleBoxFlat of panel / button `c`, masked to its rounded rect. Skipped for see-through, borderless-fill or
## card boxes; idempotent. The finish is an internal Node2D child: not sorted by containers, not in get_children().
static func add_sheen(c: Control, is_panel: bool) -> void:
	if c.has_meta("ui_sheen"):
		return
	var sb: StyleBox = c.get_theme_stylebox("panel" if is_panel else "normal")
	if not (sb is StyleBoxFlat):
		return
	var flat: StyleBoxFlat = sb
	if not flat.draw_center or flat.bg_color.a < SHEEN_MIN_ALPHA:
		return
	var mat: ShaderMaterial = sheen_material(flat.corner_radius_top_left, flat.border_width_top,
			maxi(0, flat.border_width_bottom - flat.border_width_top), is_panel)
	if mat == null:
		return
	c.set_meta("ui_sheen", true)
	var sheen := _Sheen.new()
	sheen.name = "UiSheen"
	sheen.material = mat
	c.add_child(sheen, false, Node.INTERNAL_MODE_FRONT)


## Shared sheen material for a box shape (radius / border / bottom relief, panel or button strengths). Cached.
static func sheen_material(radius: int, border: int, bottom_inset: int, is_panel: bool) -> ShaderMaterial:
	var key: String = "%d_%d_%d_%s" % [radius, border, bottom_inset, is_panel]
	if _sheen_materials.has(key):
		return _sheen_materials[key]
	var mat: ShaderMaterial = null
	if ResourceLoader.exists(SHEEN_SHADER_PATH):
		mat = ShaderMaterial.new()
		mat.shader = load(SHEEN_SHADER_PATH) as Shader
		var k: Array[float] = SHEEN_PANEL if is_panel else SHEEN_BUTTON
		mat.set_shader_parameter("noise_tex", ui_texture("ui_noise"))
		mat.set_shader_parameter("radius", float(radius))
		mat.set_shader_parameter("border", float(border))
		mat.set_shader_parameter("bottom_inset", float(bottom_inset))
		mat.set_shader_parameter("grain", k[0])
		mat.set_shader_parameter("mottling", k[1])
		mat.set_shader_parameter("top_light", k[2])
		mat.set_shader_parameter("bottom_shade", k[3])
		mat.set_shader_parameter("highlight_line", k[4])
	_sheen_materials[key] = mat
	return mat


static func _skin_box(sb: StyleBoxFlat, is_panel: bool) -> void:
	if sb.has_meta("ui_skinned"):
		return
	sb.set_meta("ui_skinned", true)
	var bg: Color = sb.bg_color
	if bg.a > 0.5 and bg.s < 0.4 and bg.v < 0.36:
		var pal: Color = BG_PANEL if is_panel else BG_PANEL_LIGHT
		sb.bg_color = Color(pal.lightened(clampf((bg.v - 0.16) * 1.5, 0.0, 0.3)), bg.a)
	var radius: int = maxi(sb.corner_radius_top_left, 12 if is_panel else 10)
	sb.set_corner_radius_all(radius)
	if sb.border_width_left + sb.border_width_top + sb.border_width_right + sb.border_width_bottom == 0:
		sb.set_border_width_all(PANEL_BORDER if is_panel else BUTTON_BORDER)
		sb.border_color = OUTLINE
	if is_panel and sb.shadow_size == 0 and sb.bg_color.a > 0.9:
		sb.shadow_color = SHADOW
		sb.shadow_size = 6
		sb.shadow_offset = Vector2(0, 3)
	sb.anti_aliasing = true


## Internal helper node of style_screen: polishes the screen's existing subtree, then every node added under it
## (deferred one frame so the screen's own overrides are already set).
class _ScreenPolisher extends Node:
	var _pending: Array[Node] = []
	var _queued: bool = false

	func _ready() -> void:
		_walk(get_parent())
		get_tree().node_added.connect(_on_node_added)

	func _walk(n: Node) -> void:
		UiStyle.polish_node(n)
		for c: Node in n.get_children():
			_walk(c)

	func _on_node_added(n: Node) -> void:
		var root: Node = get_parent()
		if root == null or not root.is_ancestor_of(n):
			return
		_pending.append(n)
		if not _queued:
			_queued = true
			_flush.call_deferred()

	func _flush() -> void:
		_queued = false
		var nodes: Array[Node] = _pending.duplicate()
		_pending.clear()
		for n: Node in nodes:
			if is_instance_valid(n):
				UiStyle.polish_node(n)


## Story 020b: the finish drawn over a panel / button box (see add_sheen). Covers the parent's rect, redraws on resize.
class _Sheen extends Node2D:
	func _ready() -> void:
		var p: Control = get_parent() as Control
		if p != null:
			p.resized.connect(queue_redraw)

	func _draw() -> void:
		var p: Control = get_parent() as Control
		var tex: Texture2D = UiStyle.ui_texture("ui_noise")
		if p == null or tex == null or p.size.x <= 0.0 or p.size.y <= 0.0:
			return
		draw_texture_rect(tex, Rect2(Vector2.ZERO, p.size), false)
