class_name CardFace
extends Control
## Drawn face of a card (art bible §7, « Cartoon vectoriel lumineux »): type-coloured gradient frame, cost gem,
## cream name banner, illustration window with the carrier Pokémon's artwork, type pill, carrier name strip,
## cream description box, rarity gem (legendary: gold frame + "Légendaire" ribbon). Built by CardView.fill_card_content
## as the Button's "Content" child, inset by INSET so the caller's own border (rarity / selection) stays visible.
## Lays itself out from its size (170x200, 220x270 and narrowed hand cards). Display only; ignores the mouse.
## Implements: story-020 (style graphique).
## Story 020b (premium): textured frame whose material follows the rarity (starter / common = slate, uncommon = brushed
## silver, rare = gold, legendary = gold + gems), body still tinted by the type, inner bevel, parchment banner and text
## box, soft drop shadow, animated holographic foil on rare / legendary (card_holo.gdshader), Kreon / Nunito fonts,
## and a hover that scales the face up and tilts it toward the cursor (visual only: the Button keeps its rect, so
## layout and clicks are unchanged).

## Distance (px) between the button edge and the face, so the caller's border ring shows around the card.
const INSET: float = 3.0
## Reference inner height of a 170x200 card; every size / font scales with height / BASE_H.
const BASE_H: float = 194.0
const RADIUS: float = 8.0
const OUTLINE_W: float = 2.5
const PAD: float = 7.0
const GEM_R: float = 12.5
const BANNER_Y: float = 5.0
const BANNER_H: float = 23.0
const WINDOW_Y: float = 32.0
const WINDOW_H: float = 78.0
const DESC_GAP: float = 4.0
const DESC_BOTTOM: float = 11.0
const PILL_H: float = 15.0
const FONT_NAME: int = 15
const FONT_COST: int = 18
const FONT_SMALL: int = 11
const FONT_DESC: int = 13
const FONT_DESC_MIN: int = 9
const FONT_NAME_MIN: int = 10
const BANNER_CREAM_TOP: Color = Color("#FFFDF4")
const BANNER_GOLD_TOP: Color = Color("#FFF1A8")
const STRIP_BG: Color = Color(0.07, 0.08, 0.16, 0.72)
const HOVER_GLOW: Color = Color(1, 1, 1, 0.9)
## Story 020b: frame band width (reference px), frame material texture per rarity, gem colour of legendary frames.
const FRAME_BAND: float = 6.0
const RARITY_MATERIAL: Dictionary = {
	"starter": "card_stone", "common": "card_stone", "uncommon": "card_silver", "rare": "card_gold"}
const LEGENDARY_GEM: Color = Color("#E0307A")
## Generated textures are 512 px; UVs = local px / TEX_SIZE (+ a per-card offset so cards do not look stamped).
const TEX_SIZE: float = 512.0
## How much of the type colour tints the frame material (0 = raw metal / stone).
const FRAME_TYPE_TINT: float = 0.1
## Drop shadow: offset (reference px) and alpha of the three soft layers; hovered = longer shadow.
const SHADOW_OFFSET: float = 4.0
const SHADOW_OFFSET_HOVER: float = 9.0
const SHADOW_ALPHAS: Array[float] = [0.2, 0.12, 0.06]
## Hover: scale, max tilt toward the cursor (degrees), tween time (s), z-index while lifted, tilt smoothing.
const HOVER_SCALE: float = 1.08
const HOVER_TILT_DEG: float = 2.5
const HOVER_TIME: float = 0.14
const HOVER_Z: int = 10
const TILT_FOLLOW: float = 12.0
## Holographic foil strength (card_holo.gdshader `holo`) and hover glare.
const HOLO_RARE: float = 0.3
const HOLO_LEGENDARY: float = 0.4
const GLARE_HOVER: float = 0.1
## Foil strength kept over the description box (fraction), so the text stays readable.
const HOLO_CALM: float = 0.2
const HOLO_SHADER_PATH: String = "res://src/ui/shaders/card_holo.gdshader"

static var _holo_shader: Shader

var card: CardData
var frame_color: Color = UiStyle.SKILL
var type_name: String = ""
var carrier_name: String = ""
var art: Texture2D
var art_is_pixel: bool = false
## True while the cursor is over the card (face lifted); the glow ring also needs `_glow` (playable card).
var hovered: bool = false
var _glow: bool = false
var _foil: ColorRect
var _foil_mat: ShaderMaterial
var _tween: Tween
var _mouse_uv: Vector2 = Vector2(0.5, 0.3)
var _uv_offset: Vector2 = Vector2.ZERO

var _name_label: Label
var _cost_label: Label
var _type_label: Label
var _carrier_label: Label
var _desc_label: Label
var _art_rect: TextureRect
var _ball: BallIcon
var _tab: Label
# Rects computed by _layout (local px), used by _draw.
var _s: float = 1.0
var _body: Rect2
var _gem_c: Vector2
var _banner: Rect2
var _window: Rect2
var _desc: Rect2


## Builds a face for `card`: `color` = frame colour (type colour, SKILL for skills), `type_label_text` = French type name
## ("" = no pill), `carrier` = carrier name (or "Équipe"), `texture` = artwork (null = none; `pixel` = nearest filter).
static func create(card_data: CardData, color: Color, type_label_text: String, carrier: String, texture: Texture2D,
		pixel: bool) -> CardFace:
	var f := CardFace.new()
	f.name = "Content"
	f.card = card_data
	f.frame_color = color
	f.type_name = type_label_text
	f.carrier_name = carrier
	f.art = texture
	f.art_is_pixel = pixel
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.set_anchors_preset(Control.PRESET_FULL_RECT)
	f.offset_left = INSET
	f.offset_top = INSET
	f.offset_right = -INSET
	f.offset_bottom = -INSET
	f._build()
	return f


## Hover highlight (white glow around the face + lift); kept for callers of story 020. See hover().
func set_hovered(value: bool) -> void:
	hover(value, value)


## Story 020b: cursor over the card (`on`): scale up to HOVER_SCALE around the bottom centre, raise the z-index,
## follow the cursor with a small tilt and the glare; `glow` = white ring too (playable cards). Visual only.
func hover(on: bool, glow: bool = true) -> void:
	_glow = glow and on
	if hovered == on:
		queue_redraw()
		return
	hovered = on
	z_index = HOVER_Z if on else 0
	if _tween != null:
		_tween.kill()
	if is_inside_tree():
		_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.tween_property(self, "scale", Vector2.ONE * (HOVER_SCALE if on else 1.0), HOVER_TIME)
	else:
		scale = Vector2.ONE * (HOVER_SCALE if on else 1.0)
	if on:
		_ensure_foil()
	if _foil != null:
		_foil.visible = on or _holo_strength() > 0.0
		_foil_mat.set_shader_parameter("glare", GLARE_HOVER if on else 0.0)
	set_process(true)
	queue_redraw()


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	var target_rot: float = 0.0
	var m := Vector2(0.5, 0.3)
	if hovered and size.x > 0.0 and size.y > 0.0:
		var lm: Vector2 = get_local_mouse_position()
		m = Vector2(clampf(lm.x / size.x, 0.0, 1.0), clampf(lm.y / size.y, 0.0, 1.0))
		target_rot = deg_to_rad(HOVER_TILT_DEG) * (m.x - 0.5) * 2.0
	var k: float = minf(1.0, delta * TILT_FOLLOW)
	rotation = lerpf(rotation, target_rot, k)
	_mouse_uv = _mouse_uv.lerp(m, k)
	if _foil_mat != null:
		_foil_mat.set_shader_parameter("mouse", _mouse_uv)
	if not hovered and absf(rotation) < 0.0005:
		rotation = 0.0
		set_process(false)


func _holo_strength() -> float:
	if card.legendary:
		return HOLO_LEGENDARY
	return HOLO_RARE if card.rarity == "rare" else 0.0


## Foil / glare overlay (created at build for holo cards, on first hover for the others).
func _ensure_foil() -> void:
	if _foil != null:
		return
	if _holo_shader == null and ResourceLoader.exists(HOLO_SHADER_PATH):
		_holo_shader = load(HOLO_SHADER_PATH) as Shader
	if _holo_shader == null:
		return
	_foil_mat = ShaderMaterial.new()
	_foil_mat.shader = _holo_shader
	_foil_mat.set_shader_parameter("noise_tex", UiStyle.ui_texture("ui_noise"))
	_foil_mat.set_shader_parameter("holo", _holo_strength())
	_foil_mat.set_shader_parameter("glare", 0.0)
	_foil_mat.set_shader_parameter("calm_factor", HOLO_CALM)
	_foil = ColorRect.new()
	_foil.name = "Foil"
	_foil.material = _foil_mat
	_add(_foil)
	_layout()


func _build() -> void:
	if art != null:
		_art_rect = TextureRect.new()
		_art_rect.name = "PokemonArt"
		_art_rect.texture = art
		_art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_art_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if art_is_pixel else CanvasItem.TEXTURE_FILTER_LINEAR
		_add(_art_rect)
	elif card.pokemon_id.is_empty():
		_ball = BallIcon.make("poke_ball", 32.0)
		_ball.size_flags_vertical = Control.SIZE_FILL
		_add(_ball)
	_name_label = _make_label("CardName", UiStyle.TEXT_DARK, 0)
	_name_label.text = card.display_name
	_cost_label = _make_label("CardCost", UiStyle.TEXT, 5)
	_cost_label.text = str(card.cost)
	if not type_name.is_empty():
		_type_label = _make_label("CardType", UiStyle.TEXT, 3)
		_type_label.text = type_name
		_type_label.add_theme_stylebox_override("normal", _pill(frame_color.darkened(0.1), UiStyle.OUTLINE))
	_carrier_label = _make_label("PokemonName", UiStyle.TEXT if not card.pokemon_id.is_empty() else UiStyle.CREAM, 3)
	_carrier_label.text = carrier_name
	_carrier_label.add_theme_stylebox_override("normal", _pill(STRIP_BG, Color(0, 0, 0, 0)))
	_desc_label = _make_label("CardDescription", UiStyle.TEXT_DARK, 0)
	_desc_label.text = card.description
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if card.legendary:
		_tab = _make_label("LegendaryTab", UiStyle.TEXT_DARK, 0)
		_tab.text = CardView.TEXT_LEGENDARY
		_tab.add_theme_stylebox_override("normal", _pill(UiStyle.LEGENDARY, UiStyle.OUTLINE))
	_name_label.add_theme_font_override("font", UiStyle.font_title())
	_cost_label.add_theme_font_override("font", UiStyle.font_title())
	_desc_label.add_theme_font_override("font", UiStyle.font_body())
	for l: Label in [_type_label, _carrier_label, _tab]:
		if l != null:
			l.add_theme_font_override("font", UiStyle.font_bold())
	var h: int = absi(hash(card.id))
	_uv_offset = Vector2(float(h % 97) / 97.0, float(floori(h / 97.0) % 89) / 89.0) * 0.4
	if _holo_strength() > 0.0:
		_ensure_foil()


func _add(c: Control) -> void:
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)


func _make_label(node_name: String, color: Color, outline: int) -> Label:
	var l := Label.new()
	l.name = node_name
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.clip_text = true
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", UiStyle.OUTLINE)
	l.add_theme_constant_override("outline_size", outline)
	l.add_theme_constant_override("line_spacing", 0)
	_add(l)
	return l


static func _pill(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(7)
	sb.border_color = border
	sb.set_border_width_all(1 if border.a > 0.0 else 0)
	sb.anti_aliasing = true
	return sb


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_THEME_CHANGED:
		_layout()


func _layout() -> void:
	var w: float = size.x
	var h: float = size.y
	if w <= 0.0 or h <= 0.0:
		return
	_s = h / BASE_H
	var s: float = _s
	var pad: float = PAD * s
	_body = Rect2(Vector2.ZERO, size)
	var r: float = GEM_R * s
	_gem_c = Vector2(pad + r - 2.0 * s, BANNER_Y * s + BANNER_H * s * 0.5)
	_banner = Rect2(_gem_c.x, BANNER_Y * s, w - pad - _gem_c.x, BANNER_H * s)
	_window = Rect2(pad, WINDOW_Y * s, w - 2.0 * pad, WINDOW_H * s)
	var desc_top: float = _window.end.y + DESC_GAP * s
	_desc = Rect2(pad, desc_top, w - 2.0 * pad, h - DESC_BOTTOM * s - desc_top)
	# Cost gem number.
	_place(_cost_label, Rect2(_gem_c - Vector2(r, r), Vector2(2.0 * r, 2.0 * r)), roundi(FONT_COST * s))
	# Name: fit on one line inside the banner (right of the gem).
	var name_rect := Rect2(_gem_c.x + r + 2.0 * s, _banner.position.y, _banner.end.x - (_gem_c.x + r) - 6.0 * s, _banner.size.y)
	_place(_name_label, name_rect, _fit_one_line(_name_label, card.display_name, roundi(FONT_NAME * s), roundi(FONT_NAME_MIN * s),
			name_rect.size.x - 4.0 * s))
	# Illustration window content.
	var inner: Rect2 = _window.grow(-3.0 * s)
	var small: int = roundi(FONT_SMALL * s)
	var pill_h: float = PILL_H * s
	var strip := Rect2(inner.position.x + 2.0 * s, inner.end.y - pill_h, inner.size.x - 4.0 * s, pill_h)
	_place(_carrier_label, strip, _fit_one_line(_carrier_label, carrier_name, small, maxi(8, small - 3), strip.size.x - 6.0 * s))
	var art_area := Rect2(inner.position, Vector2(inner.size.x, inner.size.y - pill_h * 0.2))
	if _art_rect != null:
		_art_rect.position = art_area.position
		_art_rect.size = art_area.size
	if _ball != null:
		var side: float = minf(art_area.size.y * 0.72, art_area.size.x * 0.6)
		_ball.custom_minimum_size = Vector2(side, side)
		_ball.position = art_area.get_center() - Vector2(side, side) * 0.5
		_ball.size = Vector2(side, side)
	if _type_label != null:
		var font: Font = _type_label.get_theme_font("font")
		var tw: float = font.get_string_size(type_name, HORIZONTAL_ALIGNMENT_LEFT, -1, small).x + 10.0 * s
		tw = minf(tw, inner.size.x)
		_place(_type_label, Rect2(inner.end.x - tw, inner.position.y, tw, pill_h), small)
	# Description: biggest font that fits the cream box.
	var text_rect: Rect2 = _desc.grow_individual(-5.0 * s, -3.0 * s, -5.0 * s, -3.0 * s)
	_place(_desc_label, text_rect, _fit_multiline(_desc_label, card.description, roundi(FONT_DESC * s), roundi(FONT_DESC_MIN * s), text_rect.size))
	if _tab != null:
		var tfont: Font = _tab.get_theme_font("font")
		var tab_fs: int = maxi(8, small - 1)
		var tab_w: float = minf(w - 2.0 * pad, tfont.get_string_size(_tab.text, HORIZONTAL_ALIGNMENT_LEFT, -1, tab_fs).x + 12.0 * s)
		_place(_tab, Rect2(Vector2((w - tab_w) * 0.5, h - pill_h + 1.0 * s), Vector2(tab_w, pill_h - 1.0 * s)), tab_fs)
	pivot_offset = Vector2(w * 0.5, h * 0.92)
	if _foil != null:
		_foil.position = Vector2.ZERO
		_foil.size = size
		_foil_mat.set_shader_parameter("radius_px", RADIUS * s)
		_foil_mat.set_shader_parameter("calm_rect", Vector4(_desc.position.x / w, _desc.position.y / h,
				_desc.size.x / w, _desc.size.y / h))
	queue_redraw()


func _place(l: Label, rect: Rect2, font_size: int) -> void:
	l.add_theme_font_size_override("font_size", font_size)
	l.position = rect.position
	l.size = rect.size


## Largest font size in [min_size, start] at which `text` fits `width` on one line.
func _fit_one_line(l: Label, text: String, start: int, min_size: int, width: float) -> int:
	var font: Font = l.get_theme_font("font")
	var fs: int = start
	while fs > min_size and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > width:
		fs -= 1
	return fs


## Largest font size in [min_size, start] at which the wrapped `text` fits `box`.
func _fit_multiline(l: Label, text: String, start: int, min_size: int, box: Vector2) -> int:
	var font: Font = l.get_theme_font("font")
	var fs: int = start
	while fs > min_size:
		var ts: Vector2 = font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, box.x, fs, -1,
				TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE)
		if ts.y <= box.y and ts.x <= box.x + 0.5:
			break
		fs -= 1
	return fs


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var s: float = _s
	var legendary: bool = card.legendary
	# Soft drop shadow (3 layers), longer while lifted.
	var off: float = (SHADOW_OFFSET_HOVER if hovered else SHADOW_OFFSET) * s
	for i: int in SHADOW_ALPHAS.size():
		var c := Color(0, 0, 0, SHADOW_ALPHAS[i])
		_rrect(_body.grow(1.0 + 2.5 * float(i) * s).grow_individual(0, -off * 0.5, 0, 0), (RADIUS + 2.0 * i) * s,
				c, c, Color(0, 0, 0, 0), 0.0, Vector2(0, off))
	# Frame: material texture of the rarity (slate / silver / gold), lightly tinted by the type colour.
	var mat_name: String = "card_gold" if legendary else String(RARITY_MATERIAL.get(card.rarity, "card_stone"))
	var tint: Color = Color.WHITE.lerp(frame_color, FRAME_TYPE_TINT)
	_rrect_tex(_body, RADIUS * s, UiStyle.ui_texture(mat_name), tint.lightened(0.1), tint.darkened(0.12))
	# Body: type colour over a fine grain, inset by the frame band.
	var band: float = FRAME_BAND * s
	var inner: Rect2 = _body.grow(-band)
	_rrect_tex(inner, (RADIUS - 2.5) * s, UiStyle.ui_texture("card_grain"), frame_color.lightened(0.25), frame_color.darkened(0.18))
	# Bevel: light rim on the frame, dark inner shadow where the body sinks under it.
	_rrect(_body.grow(-OUTLINE_W * s), (RADIUS - 1.0) * s, Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(1, 1, 1, 0.35), 1.0 * s)
	_rrect(inner, (RADIUS - 2.5) * s, Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0.5), 1.6 * s)
	_rrect(inner.grow(-1.5 * s), (RADIUS - 3.5) * s, Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0.18), 1.4 * s)
	if legendary:
		_rrect(inner.grow(-2.8 * s), (RADIUS - 4.0) * s, Color(0, 0, 0, 0), Color(0, 0, 0, 0), UiStyle.LEGENDARY_INNER, 1.3 * s)
	# Outer outline (gold on legendary cards).
	var body_outline: Color = UiStyle.LEGENDARY.darkened(0.25) if legendary else UiStyle.OUTLINE
	_rrect(_body.grow(-OUTLINE_W * 0.5), RADIUS * s, Color(0, 0, 0, 0), Color(0, 0, 0, 0), body_outline,
			(OUTLINE_W + (0.5 if legendary else 0.0)) * s)
	# Name banner: parchment (gold metal on legendary cards), then the cost gem on top of its left end.
	if legendary:
		_rrect_tex(_banner, _banner.size.y * 0.5, UiStyle.ui_texture("card_gold"), BANNER_GOLD_TOP, UiStyle.LEGENDARY)
	else:
		_rrect_tex(_banner, _banner.size.y * 0.5, UiStyle.ui_texture("ui_parchment"), Color.WHITE, UiStyle.CREAM.darkened(0.04))
	_rrect(_banner.grow(-1.5 * s), _banner.size.y * 0.5, Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(1, 1, 1, 0.55), 1.0 * s)
	_rrect(_banner, _banner.size.y * 0.5, Color(0, 0, 0, 0), Color(0, 0, 0, 0), UiStyle.OUTLINE, 2.0 * s)
	var r: float = GEM_R * s
	draw_circle(_gem_c + Vector2(0, 1.5 * s), r + 1.5 * s, UiStyle.OUTLINE, true, -1.0, true)
	_rrect(Rect2(_gem_c - Vector2(r, r), Vector2(2.0 * r, 2.0 * r)), r, UiStyle.ACCENT_YELLOW.lightened(0.35),
			UiStyle.ACCENT_YELLOW.darkened(0.25), UiStyle.OUTLINE, 2.0 * s)
	draw_arc(_gem_c, r - 3.0 * s, PI * 0.15, PI * 0.85, 10, Color(0.55, 0.3, 0.0, 0.35), 1.5 * s, true)
	draw_circle(_gem_c + Vector2(-r * 0.38, -r * 0.42), r * 0.22, Color(1, 1, 1, 0.8), true, -1.0, true)
	# Illustration window: light type backdrop + halo, inner shadow from the top edge.
	_rrect(_window, 6.0 * s, frame_color.lightened(0.72), frame_color.lightened(0.38), Color(0, 0, 0, 0), 0.0)
	var halo_r: float = minf(_window.size.x, _window.size.y) * 0.46
	draw_circle(_window.get_center() - Vector2(0, 4.0 * s), halo_r, Color(1, 1, 1, 0.45), true, -1.0, true)
	var shade := Rect2(_window.position, Vector2(_window.size.x, _window.size.y * 0.3))
	_rrect(shade, 6.0 * s, Color(0, 0, 0, 0.22), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0), 0.0)
	_rrect(_window, 6.0 * s, Color(0, 0, 0, 0), Color(0, 0, 0, 0), UiStyle.OUTLINE, 2.0 * s)
	# Description box: parchment, inner shadow at the top, dark outline.
	_rrect_tex(_desc, 6.0 * s, UiStyle.ui_texture("ui_parchment"), Color.WHITE, UiStyle.CREAM)
	var dshade := Rect2(_desc.position, Vector2(_desc.size.x, minf(8.0 * s, _desc.size.y * 0.3)))
	_rrect(dshade, 6.0 * s, Color(0.35, 0.2, 0.05, 0.22), Color(0.35, 0.2, 0.05, 0.0), Color(0, 0, 0, 0), 0.0)
	_rrect(_desc, 6.0 * s, Color(0, 0, 0, 0), Color(0, 0, 0, 0), UiStyle.OUTLINE, 2.0 * s)
	if legendary:
		# Gold + gem: a faceted gem set in each side band, where the window meets the text box.
		var gy: float = (_window.end.y + _desc.position.y) * 0.5
		for gx: float in [band * 0.5 + 0.5 * s, size.x - band * 0.5 - 0.5 * s]:
			_gem(Vector2(gx, gy), 5.5 * s, LEGENDARY_GEM)
	else:
		# Rarity gem on the bottom edge (legendary cards show the ribbon instead).
		_gem(Vector2(size.x * 0.5, size.y - DESC_BOTTOM * s * 0.5), 5.5 * s, UiStyle.rarity_color(card.rarity))
	if hovered and _glow:
		_rrect(_body.grow(1.5 * s), (RADIUS + 1.5) * s, Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(1, 0.95, 0.75, 0.45), 3.0 * s)
		_rrect(_body.grow(-1.0), RADIUS * s, Color(1, 1, 1, 0.05), Color(1, 1, 1, 0.0), HOVER_GLOW, 2.0 * s)


## Faceted diamond gem (`color`) with a dark outline and a white glint.
func _gem(c: Vector2, g: float, color: Color) -> void:
	var top := c + Vector2(0, -g)
	var right := c + Vector2(g, 0)
	var bottom := c + Vector2(0, g)
	var left := c + Vector2(-g, 0)
	draw_colored_polygon(PackedVector2Array([top, right, bottom, left]), color.darkened(0.15))
	draw_colored_polygon(PackedVector2Array([top, c, left]), color.lightened(0.35))
	draw_colored_polygon(PackedVector2Array([top, right, c]), color.lightened(0.1))
	draw_colored_polygon(PackedVector2Array([c, right, bottom]), color.darkened(0.3))
	draw_polyline(PackedVector2Array([top, right, bottom, left, top]), UiStyle.OUTLINE, maxf(1.0, g * 0.25), true)
	draw_circle(c + Vector2(-g * 0.3, -g * 0.35), g * 0.16, Color(1, 1, 1, 0.85), true, -1.0, true)


## Rounded rect filled with `tex` (UV = local px / TEX_SIZE + this card's offset) multiplied by a vertical
## gradient `top` -> `bottom`. Falls back to the plain gradient when the texture is missing.
func _rrect_tex(rect: Rect2, radius: float, tex: Texture2D, top: Color, bottom: Color) -> void:
	if tex == null:
		_rrect(rect, radius, top, bottom, Color(0, 0, 0, 0), 0.0)
		return
	var pts: PackedVector2Array = _rounded_points(rect, radius)
	var cols := PackedColorArray()
	var uvs := PackedVector2Array()
	for p: Vector2 in pts:
		cols.append(top.lerp(bottom, clampf((p.y - rect.position.y) / maxf(rect.size.y, 1.0), 0.0, 1.0)))
		uvs.append(p / TEX_SIZE + _uv_offset)
	draw_polygon(pts, cols, uvs, tex)


## Rounded rect with a vertical gradient fill (top -> bottom; transparent = no fill) and an outline (width 0 = none).
func _rrect(rect: Rect2, radius: float, top: Color, bottom: Color, outline: Color, outline_w: float,
		offset: Vector2 = Vector2.ZERO) -> void:
	var pts: PackedVector2Array = _rounded_points(Rect2(rect.position + offset, rect.size), radius)
	if top.a > 0.0 or bottom.a > 0.0:
		var cols := PackedColorArray()
		for p: Vector2 in pts:
			cols.append(top.lerp(bottom, clampf((p.y - rect.position.y) / maxf(rect.size.y, 1.0), 0.0, 1.0)))
		draw_polygon(pts, cols)
	if outline_w > 0.0 and outline.a > 0.0:
		var loop: PackedVector2Array = pts.duplicate()
		loop.append(pts[0])
		draw_polyline(loop, outline, outline_w, true)


static func _rounded_points(rect: Rect2, radius: float, segments: int = 6) -> PackedVector2Array:
	var r: float = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var pts := PackedVector2Array()
	var corners: Array[Vector2] = [
		Vector2(rect.end.x - r, rect.position.y + r), Vector2(rect.end.x - r, rect.end.y - r),
		Vector2(rect.position.x + r, rect.end.y - r), Vector2(rect.position.x + r, rect.position.y + r)]
	var start_angles: Array[float] = [-PI * 0.5, 0.0, PI * 0.5, PI]
	for i: int in 4:
		for k: int in segments + 1:
			var a: float = start_angles[i] + (PI * 0.5) * float(k) / float(segments)
			var p: Vector2 = corners[i] + Vector2(cos(a), sin(a)) * r
			# Pills / circles: skip coincident points (zero-length edges break the triangulation).
			if pts.is_empty() or pts[pts.size() - 1].distance_squared_to(p) > 0.01:
				pts.append(p)
	if pts.size() > 1 and pts[0].distance_squared_to(pts[pts.size() - 1]) <= 0.01:
		pts.remove_at(pts.size() - 1)
	return pts
