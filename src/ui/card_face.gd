class_name CardFace
extends Control
## Drawn face of a card (art bible §7, « Cartoon vectoriel lumineux »): type-coloured gradient frame, cost gem,
## cream name banner, illustration window with the carrier Pokémon's artwork, type pill, carrier name strip,
## cream description box, rarity gem (legendary: gold frame + "Légendaire" ribbon). Built by CardView.fill_card_content
## as the Button's "Content" child, inset by INSET so the caller's own border (rarity / selection) stays visible.
## Lays itself out from its size (170x200, 220x270 and narrowed hand cards). Display only; ignores the mouse.
## Implements: story-020 (style graphique).

## Distance (px) between the button edge and the face, so the caller's border ring shows around the card.
const INSET: float = 3.0
## Reference inner height of a 170x200 card; every size / font scales with height / BASE_H.
const BASE_H: float = 194.0
const RADIUS: float = 8.0
const OUTLINE_W: float = 2.5
const PAD: float = 5.0
const GEM_R: float = 12.5
const BANNER_Y: float = 5.0
const BANNER_H: float = 23.0
const WINDOW_Y: float = 32.0
const WINDOW_H: float = 74.0
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

var card: CardData
var frame_color: Color = UiStyle.SKILL
var type_name: String = ""
var carrier_name: String = ""
var art: Texture2D
var art_is_pixel: bool = false
var hovered: bool = false

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


## Hover highlight (white glow around the face); driven by the parent Button's mouse signals.
func set_hovered(value: bool) -> void:
	if hovered != value:
		hovered = value
		queue_redraw()


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
	var name_rect := Rect2(_gem_c.x + r + 1.0 * s, _banner.position.y, _banner.end.x - (_gem_c.x + r) - 4.0 * s, _banner.size.y)
	_place(_name_label, name_rect, _fit_one_line(_name_label, card.display_name, roundi(FONT_NAME * s), roundi(FONT_NAME_MIN * s), name_rect.size.x))
	# Illustration window content.
	var inner: Rect2 = _window.grow(-3.0 * s)
	var small: int = roundi(FONT_SMALL * s)
	var pill_h: float = PILL_H * s
	var strip := Rect2(inner.position.x + 2.0 * s, inner.end.y - pill_h, inner.size.x - 4.0 * s, pill_h)
	_place(_carrier_label, strip, _fit_one_line(_carrier_label, carrier_name, small, maxi(8, small - 3), strip.size.x - 6.0 * s))
	var art_area := Rect2(inner.position, Vector2(inner.size.x, inner.size.y - pill_h * 0.55))
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
	var text_rect: Rect2 = _desc.grow_individual(-4.0 * s, -2.0 * s, -4.0 * s, -2.0 * s)
	_place(_desc_label, text_rect, _fit_multiline(_desc_label, card.description, roundi(FONT_DESC * s), roundi(FONT_DESC_MIN * s), text_rect.size))
	if _tab != null:
		var tfont: Font = _tab.get_theme_font("font")
		var tab_fs: int = maxi(8, small - 1)
		var tab_w: float = minf(w - 2.0 * pad, tfont.get_string_size(_tab.text, HORIZONTAL_ALIGNMENT_LEFT, -1, tab_fs).x + 12.0 * s)
		_place(_tab, Rect2(Vector2((w - tab_w) * 0.5, h - pill_h + 1.0 * s), Vector2(tab_w, pill_h - 1.0 * s)), tab_fs)
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
	# Body: soft vertical gradient of the frame colour, thick dark (gold) outline.
	var body_outline: Color = UiStyle.LEGENDARY if legendary else UiStyle.OUTLINE
	_rrect(_body.grow(-OUTLINE_W * 0.5), RADIUS * s, frame_color.lightened(0.28), frame_color.darkened(0.12),
			body_outline, (OUTLINE_W + (1.0 if legendary else 0.0)) * s)
	if legendary:
		_rrect(_body.grow(-4.5 * s), (RADIUS - 3.0) * s, Color(0, 0, 0, 0), Color(0, 0, 0, 0), UiStyle.LEGENDARY_INNER, 1.5 * s)
	# Name banner (cream, gold for legendary) then the cost gem on top of its left end.
	var banner_top: Color = BANNER_GOLD_TOP if legendary else BANNER_CREAM_TOP
	var banner_bottom: Color = UiStyle.LEGENDARY if legendary else UiStyle.CREAM.darkened(0.06)
	_rrect(_banner, _banner.size.y * 0.5, banner_top, banner_bottom, UiStyle.OUTLINE, 2.0 * s)
	var r: float = GEM_R * s
	draw_circle(_gem_c + Vector2(0, 1.5 * s), r + 1.5 * s, UiStyle.OUTLINE, true, -1.0, true)
	_rrect(Rect2(_gem_c - Vector2(r, r), Vector2(2.0 * r, 2.0 * r)), r, UiStyle.ACCENT_YELLOW.lightened(0.35),
			UiStyle.ACCENT_YELLOW.darkened(0.15), UiStyle.OUTLINE, 2.0 * s)
	draw_circle(_gem_c + Vector2(-r * 0.38, -r * 0.42), r * 0.22, Color(1, 1, 1, 0.75), true, -1.0, true)
	# Illustration window: light type backdrop + halo behind the Pokémon.
	_rrect(_window, 6.0 * s, frame_color.lightened(0.72), frame_color.lightened(0.38), UiStyle.OUTLINE, 2.0 * s)
	var halo_r: float = minf(_window.size.x, _window.size.y) * 0.42
	draw_circle(_window.get_center() - Vector2(0, 4.0 * s), halo_r, Color(1, 1, 1, 0.45), true, -1.0, true)
	# Description box.
	_rrect(_desc, 6.0 * s, UiStyle.CREAM.lightened(0.4), UiStyle.CREAM, UiStyle.OUTLINE, 2.0 * s)
	# Rarity gem on the bottom edge (legendary cards show the ribbon instead).
	if not legendary:
		var gc := Vector2(size.x * 0.5, size.y - DESC_BOTTOM * s * 0.5)
		var g: float = 5.5 * s
		var gem := PackedVector2Array([gc + Vector2(0, -g), gc + Vector2(g, 0), gc + Vector2(0, g), gc + Vector2(-g, 0)])
		draw_colored_polygon(gem, UiStyle.rarity_color(card.rarity))
		gem.append(gem[0])
		draw_polyline(gem, UiStyle.OUTLINE, 1.5 * s, true)
	if hovered:
		_rrect(_body.grow(-1.0), RADIUS * s, Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.0), HOVER_GLOW, 2.0 * s)


## Rounded rect with a vertical gradient fill (top -> bottom; transparent = no fill) and an outline (width 0 = none).
func _rrect(rect: Rect2, radius: float, top: Color, bottom: Color, outline: Color, outline_w: float) -> void:
	var pts: PackedVector2Array = _rounded_points(rect, radius)
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
			pts.append(corners[i] + Vector2(cos(a), sin(a)) * r)
	return pts
