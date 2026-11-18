class_name UiStyle
extends RefCounted
## Shared look of the game (« Cartoon vectoriel lumineux »): palette, type / rarity colours, StyleBoxFlat
## factories and a Theme. Values mirror design/art-bible.md; type colours come from assets/data/types.json.
## Display only: owns no game state. Implements: story-020 (style graphique).
## Story 020b (refonte premium): embedded fonts (Lilita One titles in Pokémon-logo colours / Jost text, OFL,
## assets/fonts/; a fan font dropped in assets/fonts/pokemon/ replaces Lilita One for titles), generated material
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
## Story 033: disabled buttons are light grey with dark grey text — greyed but readable on white windows and on the
## dark battle screen alike.
const DISABLED_BG: Color = Color("#C9CEDA")
const DISABLED_TEXT: Color = Color("#555C72")
const SHADOW: Color = Color(0, 0, 0, 0.35)

# --- Story 033: « menu Pokémon » windows (art bible §4) ----------------------------------------------
## Frame band, outer outline, inner white box, secondary dark text and the frame thickness of the menu windows.
const FRAME_BLUE: Color = Color("#4F86D9")
const FRAME_OUTLINE: Color = Color("#1B2440")
const PANEL_WHITE: Color = Color("#FBFCFF")
const TEXT_SUB: Color = Color("#4A5578")
const MENU_FRAME_PAD: int = 5
## Light sub-box inside a window (rows, cells, nested panels).
const SUB_FILL: Color = Color("#EAF1FC")
## Accent colours readable on white (titles of special screens, gains, warnings).
const INK_GOLD: Color = Color("#9A6B00")
const INK_GREEN: Color = Color("#1F7A35")
const INK_RED: Color = Color("#B3261E")

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
	"title": [40, 8, ACCENT_YELLOW], "heading": [28, 6, TEXT], "number": [22, 6, TEXT],
	"body": [18, 0, TEXT], "caption": [15, 0, TEXT_MUTED], "dark": [16, 0, TEXT_DARK]}
const DEFAULT_FONT_SIZE: int = 18

const TYPES_PATH: String = "res://assets/data/types.json"

# --- Story 020b: fonts, textures, finish (art bible §3, §4, §8) ------------------------------------------
## Story 020b follow-up (style Pokémon): titles = Lilita One (chunky rounded display, drawn in the Pokémon-logo colours
## by apply_logo); UI / card text = Jost (geometric Futura-like sans, close to modern Pokémon games / TCG).
const FONT_TITLE_PATH: String = "res://assets/fonts/lilita_one/LilitaOne-Regular.ttf"
const FONT_BODY_PATH: String = "res://assets/fonts/jost/Jost-Variable.ttf"
## Any .ttf / .otf dropped here (preferred: FONT_FAN_FILE) replaces Lilita One for titles; Lilita One stays as the
## fallback for glyphs the fan font lacks (accents).
const FONT_FAN_DIR: String = "res://assets/fonts/pokemon/"
const FONT_FAN_FILE: String = "Pokemon Solid.ttf"
const FONT_FAN_EXTENSIONS: Array[String] = ["ttf", "otf"]
const WEIGHT_BODY: int = 500
const WEIGHT_BOLD: int = 700
const WEIGHT_NUMBER: int = 800
## Roles drawn with the title font; "number" uses font_number(), the others the body font.
const TITLE_ROLES: Array[String] = ["title", "heading"]
## Pokémon-logo look of big titles: yellow fill (ACCENT_YELLOW), thick blue outline, deep blue drop shadow.
const LOGO_BLUE: Color = Color("#2A62B8")
const LOGO_SHADOW: Color = Color("#16245E")
const LOGO_SHADOW_OFFSET: int = 4
## Screen labels at or above this size without their own colour get the logo look from the screen polisher.
const LOGO_MIN_SIZE: int = 36
## Labels at or above this size (set by screens) get the title font from the screen polisher.
const TITLE_FONT_MIN_SIZE: int = 24
const UI_TEXTURE_DIR: String = "res://assets/art/ui/"
const SHEEN_SHADER_PATH: String = "res://src/ui/shaders/ui_sheen.gdshader"
## Sheen strengths: [grain, mottling, top_light, bottom_shade, highlight_line] for panels and buttons.
const SHEEN_PANEL: Array[float] = [0.06, 0.03, 0.07, 0.14, 0.18]
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


## Title font — screen titles and headings: the fan font of assets/fonts/pokemon/ when present, else Lilita One.
## Never null.
static func font_title() -> Font:
	if _fonts.has("title"):
		return _fonts["title"]
	var lilita: Font = _font("lilita", FONT_TITLE_PATH, 0)
	var f: Font = lilita
	var fan_path: String = fan_font_path()
	if not fan_path.is_empty():
		var fan: FontFile = load(fan_path) as FontFile
		if fan != null:
			var v := FontVariation.new()
			v.base_font = fan
			v.fallbacks = [lilita]
			f = v
	_fonts["title"] = f
	return f


## Path of the user-supplied title font in FONT_FAN_DIR (FONT_FAN_FILE first, else the first .ttf / .otf by name);
## "" when there is none.
static func fan_font_path() -> String:
	if not DirAccess.dir_exists_absolute(FONT_FAN_DIR):
		return ""
	if ResourceLoader.exists(FONT_FAN_DIR + FONT_FAN_FILE):
		return FONT_FAN_DIR + FONT_FAN_FILE
	var names: Array[String] = []
	for file: String in DirAccess.get_files_at(FONT_FAN_DIR):
		var n: String = file.trim_suffix(".import").trim_suffix(".remap")
		if FONT_FAN_EXTENSIONS.has(n.get_extension().to_lower()) and not names.has(n):
			names.append(n)
	names.sort()
	for n: String in names:
		if ResourceLoader.exists(FONT_FAN_DIR + n):
			return FONT_FAN_DIR + n
	return ""


## Body font (Jost Medium) — text, captions, card descriptions. Never null.
static func font_body() -> Font:
	return _font("body", FONT_BODY_PATH, WEIGHT_BODY)


## Bold UI font (Jost Bold) — buttons, pills, small labels, card names. Never null.
static func font_bold() -> Font:
	return _font("bold", FONT_BODY_PATH, WEIGHT_BOLD)


## Number font (Jost ExtraBold) — HP, energy, card cost. Never null.
static func font_number() -> Font:
	return _font("number", FONT_BODY_PATH, WEIGHT_NUMBER)


## Pokémon-logo look on `l` (yellow fill, thick blue outline, deep blue drop shadow) at outline width `outline`.
static func apply_logo(l: Label, outline: int = 8) -> void:
	l.add_theme_font_override("font", font_title())
	l.add_theme_color_override("font_color", ACCENT_YELLOW)
	l.add_theme_color_override("font_outline_color", LOGO_BLUE)
	l.add_theme_constant_override("outline_size", outline)
	l.add_theme_color_override("font_shadow_color", LOGO_SHADOW)
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", LOGO_SHADOW_OFFSET)
	l.add_theme_constant_override("shadow_outline_size", outline + 2)


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
			f = base
			if weight > 0:
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


## Story 033: « menu Pokémon » window (art bible §4): thick `frame` band with a dark outline and a drop shadow around a
## rounded white box; `pad_x` / `pad_y` = inner margins of the content inside the white box.
static func menu_panel(frame: Color = FRAME_BLUE, pad_x: float = 18.0, pad_y: float = 12.0) -> MenuBox:
	var mb := MenuBox.new()
	mb.frame_color = frame
	var edge: float = float(MENU_FRAME_PAD + 1)
	mb.content_margin_left = edge + pad_x
	mb.content_margin_right = edge + pad_x
	mb.content_margin_top = edge + pad_y
	mb.content_margin_bottom = edge + pad_y
	return mb


## Story 033 (moved from map_screen, story 020b): outer frame of a menu window: `col` band, dark outline, rounded,
## drop shadow; content margin = the frame thickness (put a menu_inner box inside).
static func menu_frame(col: Color = FRAME_BLUE) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.border_color = FRAME_OUTLINE
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(18)
	sb.shadow_color = SHADOW
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	sb.set_content_margin_all(MENU_FRAME_PAD + 1)
	sb.anti_aliasing = true
	return sb


## Story 033 (moved from map_screen, story 020b): inner white box of a menu window (thin darker rim of `frame`).
static func menu_inner(frame: Color = FRAME_BLUE, pad_x: float = 14.0, pad_y: float = 5.0) -> StyleBoxFlat:
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


## Story 033: light sub-box inside a menu window (a row, a cell, a nested panel): pale blue fill, thin blue rim.
static func menu_sub_panel(rim: Color = FRAME_BLUE, pad: float = 10.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = SUB_FILL
	sb.border_color = rim.lightened(0.15)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(pad)
	sb.anti_aliasing = true
	return sb


## Story 033: dark text on a white window (no outline, no shadow), colour `col`.
static func dark_label(l: Label, col: Color = TEXT_DARK) -> void:
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	l.set_meta("menu_ink", true)


## Story 033: readable version of colour `c` on a white window (white -> TEXT_DARK, light grey -> TEXT_SUB, bright
## colours darkened until they read; dark colours unchanged). `big` = title-sized text.
static func ink_on_white(c: Color, big: bool = false) -> Color:
	if c.get_luminance() <= 0.42:
		return Color(c, 1.0) if c.a > 0.0 else c
	if c.s < 0.28:
		return TEXT_DARK if c.v > 0.86 or big else TEXT_SUB
	var h: float = c.h
	if big and h > 0.09 and h < 0.19:  # yellow / gold titles
		return TEXT_DARK
	var out: Color = c
	for i: int in 8:
		if out.get_luminance() <= 0.36:
			break
		out = out.darkened(0.14)
	return Color(out, 1.0)


## Applies the five button states + white outlined text to `b` (base colour `base`).
static func apply_button(b: Button, base: Color = ACCENT_BLUE) -> void:
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(state, button_box(state, base))
	var text: Color = text_on(base)
	for key: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(key, text)
	b.add_theme_color_override("font_disabled_color", DISABLED_TEXT)
	b.add_theme_color_override("font_outline_color", OUTLINE)
	b.add_theme_constant_override("outline_size", 0)  # story 033: the dark outline made greyed text unreadable


## Applies a typography role ("title", "heading", "number", "body", "caption", "dark") to `l`.
static func apply_label(l: Label, role: String) -> void:
	var spec: Array = LABEL_ROLES.get(role, LABEL_ROLES["body"])
	l.add_theme_font_size_override("font_size", int(spec[0]))
	if role == "title":
		apply_logo(l, int(spec[1]))
		return
	var font: Font = font_body()
	if TITLE_ROLES.has(role):
		font = font_title()
	elif role == "number":
		font = font_number()
	l.add_theme_font_override("font", font)
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
	t.set_constant("outline_size", "Button", 0)  # story 033
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_outline_color", "Label", OUTLINE)
	t.set_stylebox("panel", "PanelContainer", menu_panel())  # story 033: menu windows by default
	t.set_stylebox("panel", "Panel", menu_panel())
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
## corners, a dark outline when they had none and a soft shadow; big labels (>= 24 px) get the title font; very big
## labels (>= LOGO_MIN_SIZE) with no colour of their own get the Pokémon-logo look (apply_logo). Card buttons
## (CardFace child) are left untouched. Display only; the helper nodes are internal, so get_children() is unchanged.
## Story 033 (cohérence visuelle): the « menu Pokémon » look by default — `backdrop` adds the shared MenuBackdrop
## behind the screen (opaque full-screen dark ColorRects directly under `root` are then hidden; pass false for
## overlays drawn over another screen); dark panels become white menu windows (MenuBox; nested ones become light
## sub-boxes), dark buttons become blue buttons, and every label on a white window gets dark ink (ink_on_white),
## re-checked a few times per second so colours set later by the screen are converted too.
static func style_screen(root: Control, backdrop: bool = true) -> void:
	root.theme = make_theme()
	root.set_meta("menu_style", true)
	if backdrop:
		var bd := MenuBackdrop.new()
		bd.name = "MenuBackdrop"
		bd.set_anchors_preset(Control.PRESET_FULL_RECT)
		bd.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(bd, false, Node.INTERNAL_MODE_FRONT)
		root.set_meta("menu_backdrop", bd)
	var p := _ScreenPolisher.new()
	p.name = "StylePolisher"
	root.add_child(p, false, Node.INTERNAL_MODE_BACK)


## Story 033: the shared backdrop added by style_screen under `root` (null when none).
static func screen_backdrop(root: Control) -> MenuBackdrop:
	return root.get_meta("menu_backdrop", null) as MenuBackdrop if root.has_meta("menu_backdrop") else null


## Re-skins one node in place (see style_screen). Idempotent.
static func polish_node(n: Node) -> void:
	var menu: bool = _menu_root(n) != null
	if n is Label:
		var l: Label = n
		if l.has_theme_font_size_override("font_size") and not l.has_theme_font_override("font") \
				and l.get_theme_font_size("font_size") >= TITLE_FONT_MIN_SIZE:
			l.add_theme_font_override("font", font_title())  # story 020b
			if l.get_theme_font_size("font_size") >= LOGO_MIN_SIZE and not l.has_theme_color_override("font_color") \
					and not (menu and _on_light(l)):
				apply_logo(l, 8)
				return
		if menu:
			ink_label(l)
			return
		if l.has_theme_font_size_override("font_size") and not l.has_theme_constant_override("outline_size"):
			var fs: int = l.get_theme_font_size("font_size")
			if fs >= 24:
				l.add_theme_constant_override("outline_size", 8 if fs >= 32 else 6)
				l.add_theme_color_override("font_outline_color", OUTLINE)
	elif n is ColorRect:
		if menu and n.get_parent() == _menu_root(n) and screen_backdrop(_menu_root(n)) != null:
			var cr: ColorRect = n
			if cr.color.a > 0.9 and cr.color.v < 0.4 and cr.anchor_right == 1.0 and cr.anchor_bottom == 1.0:
				cr.self_modulate.a = 0.0  # the shared backdrop shows instead
	elif n is PanelContainer or n is Panel:
		var c: Control = n
		if menu and not c.has_meta("menu_keep"):
			_menu_panel_node(c)
		if c.has_theme_stylebox_override("panel") and c.get_theme_stylebox("panel") is StyleBoxFlat:
			_skin_box(c.get_theme_stylebox("panel") as StyleBoxFlat, true)
		add_sheen(c, true)
	elif n is Button:
		var b: Button = n
		for child: Node in b.get_children():
			if child is CardFace:
				return
		if menu and not b.has_meta("menu_keep"):
			_menu_button(b)
		for state: String in ["normal", "hover", "pressed", "disabled"]:
			if b.has_theme_stylebox_override(state) and b.get_theme_stylebox(state) is StyleBoxFlat:
				_skin_box(b.get_theme_stylebox(state) as StyleBoxFlat, false)
		add_sheen(b, false)


## Story 033: gives label `l` dark ink when it sits on a light window (idempotent; re-converts when the screen set a
## new colour since the last pass). Labels on the backdrop / dark boxes keep light text with a dark outline.
static func ink_label(l: Label) -> void:
	if l.has_meta("menu_ink") or l.has_meta("menu_keep") or _in_card(l):
		return
	if l.has_theme_color_override("font_outline_color") and l.get_theme_color("font_outline_color") == LOGO_BLUE:
		return  # logo look: readable everywhere
	var light: bool = _on_light(l)
	var cur: Color = l.get_theme_color("font_color") if l.has_theme_color_override("font_color") else TEXT
	if light:
		if l.has_meta("ink_out") and Color(l.get_meta("ink_out")) == cur and l.get_meta("ink_light", false):
			return
		var big: bool = l.get_theme_font_size("font_size") >= 28
		var ink: Color = ink_on_white(cur, big)
		l.add_theme_color_override("font_color", ink)
		l.add_theme_constant_override("outline_size", 0)
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
		l.set_meta("ink_out", ink)
		l.set_meta("ink_light", true)
	elif l.get_meta("ink_light", true) or not l.has_meta("ink_out"):
		l.set_meta("ink_light", false)
		l.set_meta("ink_out", cur)
		if not l.has_theme_constant_override("outline_size") or l.get_theme_constant("outline_size") == 0:
			var fs: int = l.get_theme_font_size("font_size")
			l.add_theme_constant_override("outline_size", 8 if fs >= 32 else (6 if fs >= 22 else 4))
			l.add_theme_color_override("font_outline_color", OUTLINE)


## Story 033: true inside a card button / card face (cards keep their own look).
static func _in_card(n: Node) -> bool:
	var p: Node = n.get_parent()
	while p != null and not p.has_meta("menu_style"):
		if p is CardFace or p.has_meta("menu_keep"):
			return true
		if p is Button:
			for c: Node in p.get_children():
				if c is CardFace:
					return true
		p = p.get_parent()
	return false


## Story 033: the style_screen root above `n` (or `n` itself), null when `n` is not on a menu-styled screen.
static func _menu_root(n: Node) -> Control:
	var p: Node = n
	while p != null:
		if p is Control and p.has_meta("menu_style"):
			return p as Control
		p = p.get_parent()
	return null


## Story 033: true when the nearest opaque box behind `n` (panel or button) is light (white window, cream, pale).
static func _on_light(n: Node) -> bool:
	var p: Node = n.get_parent()
	while p != null:
		var sb: StyleBox = null
		if p is PanelContainer or p is Panel:
			sb = (p as Control).get_theme_stylebox("panel")
		elif p is Button:
			sb = (p as Control).get_theme_stylebox("normal")
		if sb is MenuBox:
			return true
		if sb is StyleBoxFlat and (sb as StyleBoxFlat).draw_center and (sb as StyleBoxFlat).bg_color.a > 0.6:
			return (sb as StyleBoxFlat).bg_color.get_luminance() > 0.62
		if p.has_meta("menu_style"):
			return false
		p = p.get_parent()
	return false


## Story 033: a dark panel becomes a white menu window (top level) or a light sub-box (inside a window).
static func _menu_panel_node(c: Control) -> void:
	if c.has_meta("menu_done"):
		return
	c.set_meta("menu_done", true)
	var sb: StyleBox = c.get_theme_stylebox("panel")
	var flat: StyleBoxFlat = sb as StyleBoxFlat
	if sb is MenuBox:
		return
	if flat != null and not (flat.draw_center and flat.bg_color.a > 0.8 and flat.bg_color.v < 0.42):
		return  # light, coloured or see-through boxes keep their look
	var margins: Array[float] = [10.0, 10.0, 10.0, 10.0]
	if flat != null:
		margins = [flat.content_margin_left, flat.content_margin_top, flat.content_margin_right,
				flat.content_margin_bottom]
		for i: int in 4:
			margins[i] = maxf(margins[i], 0.0)
	if _inside_window(c):
		var sub: StyleBoxFlat = menu_sub_panel()
		sub.content_margin_left = margins[0]
		sub.content_margin_top = margins[1]
		sub.content_margin_right = margins[2]
		sub.content_margin_bottom = margins[3]
		c.add_theme_stylebox_override("panel", sub)
		c.set_meta("ui_sheen", true)  # no grain on the pale box
		return
	var mb: MenuBox = menu_panel()
	var edge: float = float(MENU_FRAME_PAD + 1)
	mb.content_margin_left = edge + maxf(margins[0], 12.0)
	mb.content_margin_top = edge + maxf(margins[1], 10.0)
	mb.content_margin_right = edge + maxf(margins[2], 12.0)
	mb.content_margin_bottom = edge + maxf(margins[3], 10.0)
	c.add_theme_stylebox_override("panel", mb)


static func _inside_window(n: Node) -> bool:
	var p: Node = n.get_parent()
	while p != null and not p.has_meta("menu_style"):
		if (p is PanelContainer or p is Panel) and (p as Control).get_theme_stylebox("panel") is MenuBox:
			return true
		p = p.get_parent()
	return false


## Story 033: a button with a dark custom box becomes a standard blue button (keeps its size and text).
static func _menu_button(b: Button) -> void:
	if b.has_meta("menu_done"):
		return
	b.set_meta("menu_done", true)
	if not b.has_theme_stylebox_override("normal"):
		return
	var flat: StyleBoxFlat = b.get_theme_stylebox("normal") as StyleBoxFlat
	if flat == null or not flat.draw_center or flat.bg_color.a < 0.8 or flat.bg_color.v >= 0.42 \
			or flat.bg_color.s > 0.5:
		return
	apply_button(b, ACCENT_BLUE)


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

	var _frames: int = 0

	func _ready() -> void:
		_walk(get_parent())
		get_tree().node_added.connect(_on_node_added)

	## Story 033: re-inks the labels every few frames (colours / parents set after the build are converted too).
	func _process(_delta: float) -> void:
		_frames += 1
		if _frames % 12 == 0 and get_parent() != null and get_parent().is_visible_in_tree():
			_ink(get_parent())

	func _ink(n: Node) -> void:
		if n is Label:
			UiStyle.ink_label(n as Label)
		for c: Node in n.get_children():
			_ink(c)

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


# --- Story 027: combat depth accents (Élan pips, talent pill, Force chips, keyword badges, exhaust burn) ---------
## Élan pip (filled) and empty pip.
const ELAN: Color = Color("#FF8A3D")
const ELAN_EMPTY: Color = Color(0.24, 0.22, 0.3)
## Talent pill (gold) and its used-up state (grey).
const TALENT: Color = Color("#F2C94C")
const TALENT_USED: Color = Color(0.4, 0.4, 0.46)
## Force chips (battle / turn) and the next-attack bonus chip.
const FORCE: Color = Color("#E5533D")
const NEXT_ATTACK: Color = Color("#FFB347")
## Keyword badge line on cards, exhaust burn, live damage pill (base / raised / lowered).
const KEYWORD_BG: Color = Color(0.1, 0.08, 0.2, 0.9)
const EXHAUST_BURN: Color = Color("#FF7A2F")
const DAMAGE_BASE: Color = Color(0.62, 0.13, 0.11)
const DAMAGE_UP: Color = Color(0.13, 0.52, 0.22)
const DAMAGE_DOWN: Color = Color(0.38, 0.38, 0.44)
