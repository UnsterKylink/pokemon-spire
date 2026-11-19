class_name TitleScreen
extends Control
## Story 023 (story-023-menu-options-tutoriel): the title screen shown at launch (real game). Layout « B — Deck de
## légende » with the « Or royal » logo (design/art/title-mockups/logo1-or-royal.png): the League hall
## (assets/art/backdrops/league.jpg, cover-fit, blurred once and darkened), a warm radial glow behind the logo (gentle
## pulse when animations are on), a fan of 5 real cards drawn from the card pool (at least one rare and one legendary
## when possible; deterministic per launch, QA: set_fan_cards), the rendered logo (assets/art/title/logo.png, label
## fallback), a dark gradient towards the bottom, a horizontal row of menu buttons (Continuer — only with a valid save,
## its save summary just above it —, Nouvelle partie — confirmation when a save exists —, Tutoriel, Options, Quitter)
## and one discreet statistics line (PlayerStats). Display only: it emits signals and Main acts (resume, new run,
## tutorial replay, options, quit). Keyboard / gamepad: the buttons take focus (left / right between them).

signal continue_requested
signal new_game_requested
signal tutorial_requested
signal options_requested
signal quit_requested

const BACKGROUND_PATH: String = "res://assets/art/backdrops/league.jpg"
## Background darkening (multiplier) and blur (the image is shrunk until it is at most this wide, then scaled back).
const BACKGROUND_DIM: float = 0.5
const BLUR_WIDTH: int = 240
const LOGO_TEXT: String = "Pokémon Spire"
const LOGO_SIZE: int = 92
const LOGO_OUTLINE: int = 18
const SUBTITLE: String = "Roguelike de cartes"
## Rendered logo (tools/art/make_logo.py); the label logo is the fallback.
const LOGO_PATH: String = "res://assets/art/title/logo.png"
const LOGO_WIDTH: float = 830.0
## Layout of the 1280x720 stage (mockup coordinates, centred in the screen).
const STAGE_SIZE: Vector2 = Vector2(1280, 720)
const LOGO_TOP: float = 150.0
## Warm glow behind the logo: centre, size, colour; pulse (alpha / scale, seconds per half cycle).
const GLOW_CENTER: Vector2 = Vector2(640, 260)
const GLOW_SIZE: Vector2 = Vector2(980, 760)
const GLOW_COLOR: Color = Color(1.0, 0.82, 0.36, 0.42)
const GLOW_PULSE_ALPHA: float = 0.7
const GLOW_PULSE_SCALE: float = 1.06
const GLOW_PULSE_TIME: float = 2.6
## Card fan: count, size, centre of the middle card, horizontal step, extra drop per step from the centre, angle step.
const FAN_COUNT: int = 5
const FAN_CARD_SIZE: Vector2 = Vector2(210, 250)
const FAN_CENTER: Vector2 = Vector2(640, 300)
const FAN_SPREAD: float = 150.0
const FAN_DROP: float = 28.0
const FAN_ANGLE_DEG: float = 13.0
const FAN_DIM: Color = Color(0.8, 0.8, 0.8)
## Bottom gradient (colour; alpha stops at fractions of the screen height), as in the mockup.
const SHADE_COLOR: Color = Color("#060818")
const SHADE_STOPS: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(0.167, 0.0), Vector2(0.528, 0.19), Vector2(0.764, 0.64),
		Vector2(1.0, 0.98)]
const BUTTON_SIZE: Vector2 = Vector2(212, 52)
const BUTTON_FONT: int = 23
const BUTTON_GAP: int = 22
const MENU_BOTTOM: float = 22.0
const TEXT_CONTINUE: String = "Continuer"
const TEXT_NEW_GAME: String = "Nouvelle partie"
const TEXT_TUTORIAL: String = "Tutoriel"
const TEXT_OPTIONS: String = "Options"
const TEXT_QUIT: String = "Quitter"
## The three stats texts (get_stats_lines) and the single line shown.
const TEXT_PLAYED: String = "Parties jouées : %d"
const TEXT_WON: String = "Parties gagnées : %d"
const TEXT_BEST: String = "Meilleur résultat : %s"
const TEXT_STATS_LINE: String = "Parties : %d  ·  Victoires : %d  ·  Meilleur : %s"
const TEXT_SAVE_ERROR: String = "Sauvegarde illisible : %s (conservée en .bak)"
const TEXT_CONFIRM_TITLE: String = "Nouvelle partie ?"
const TEXT_CONFIRM_BODY: String = "Une partie est en cours. En commencer une nouvelle supprimera sa sauvegarde (elle ne comptera pas dans les statistiques)."
const TEXT_CONFIRM_OK: String = "Nouvelle partie"
const TEXT_CANCEL: String = "Annuler"

## Seed of the card fan, drawn once per launch (same fan each time the title comes back during the launch).
static var _launch_seed: int = 0
## Blurred background, computed once per launch.
static var _blurred_bg: Texture2D

var _built: bool = false
var _background: TextureRect
var _stage: Control
var _glow: TextureRect
var _glow_tween: Tween
var _fan: Control
var _fan_ids: PackedStringArray = PackedStringArray()
var _data: GameData
var _logo: Control
var _menu: HBoxContainer
var _buttons: Array[Button] = []
var _new_game_button: Button
var _continue_button: Button
var _continue_caption: Label
var _error_label: Label
var _stats_label: Label
var _stats_texts: PackedStringArray = PackedStringArray(["", "", ""])
var _confirm: Control
var _has_save: bool = false
var _pokemon_sprite: String = ""


func _init() -> void:
	name = "TitleScreen"
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	_build()
	_start_glow()


## Fills the screen: `stats` (PlayerStats), `save_summary` ("" = no valid save: no « Continuer »; else the caption above
## it), `save_error` ("" or the reason of an unreadable save), `pokemon_sprite` (sprite of the launch's title Pokémon:
## no longer drawn, kept for callers and QA), `data` (card pool of the fan; null = no fan).
func setup(stats: PlayerStats, save_summary: String, save_error: String, pokemon_sprite: String, data: GameData = null) -> void:
	_build()
	_has_save = not save_summary.is_empty()
	_continue_button.visible = _has_save
	_continue_caption.text = save_summary
	_error_label.visible = not save_error.is_empty()
	_error_label.text = TEXT_SAVE_ERROR % save_error if not save_error.is_empty() else ""
	var s: PlayerStats = stats if stats != null else PlayerStats.new()
	var best: String = s.best_result_text()
	_stats_texts = PackedStringArray([TEXT_PLAYED % s.runs_played, TEXT_WON % s.runs_won, TEXT_BEST % best])
	_stats_label.text = TEXT_STATS_LINE % [s.runs_played, s.runs_won, best]
	_pokemon_sprite = pokemon_sprite
	_data = data
	if _data != null:
		_show_fan(draw_fan_ids(_data, launch_seed()))
	_confirm.visible = false
	_focus_later(_continue_button if _has_save else _new_game_button)


## True when « Continuer » is offered.
func has_continue() -> bool:
	return _continue_button != null and _continue_button.visible


## The three stats texts (parties jouées / gagnées / meilleur résultat), shown on one line (QA).
func get_stats_lines() -> PackedStringArray:
	return _stats_texts.duplicate()


## The single statistics line shown under the buttons (QA).
func get_stats_line() -> String:
	return _stats_label.text if _stats_label != null else ""


## Sprite path of the launch's title Pokémon given to setup (QA; no longer drawn).
func get_pokemon_sprite() -> String:
	return _pokemon_sprite


## The visible menu button texts, left to right (QA).
func get_button_texts() -> PackedStringArray:
	var out := PackedStringArray()
	for b: Button in _buttons:
		if b.visible:
			out.append(b.text)
	return out


## Ids of the fan cards, left to right (QA).
func get_fan_card_ids() -> PackedStringArray:
	return _fan_ids.duplicate()


## QA: shows exactly these cards in the fan, left to right (unknown ids skipped; needs the data given to setup).
func set_fan_cards(ids: PackedStringArray) -> void:
	_build()
	if _data != null:
		_show_fan(ids)


## Seed of this launch's fan (drawn once per launch).
static func launch_seed() -> int:
	if _launch_seed == 0:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		_launch_seed = maxi(1, rng.randi())
	return _launch_seed


## QA: forces the fan seed of the launch (0 = draw a new one next time).
static func qa_set_launch_seed(seed_value: int) -> void:
	_launch_seed = seed_value


## FAN_COUNT card ids drawn from `data`'s pool with `seed_value` (deterministic): cards carried by a Pokémon when there
## are enough, at least one legendary and one (other) rare when the pool has them, then shuffled.
static func draw_fan_ids(data: GameData, seed_value: int) -> PackedStringArray:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var all: Array[CardData] = []
	for id: String in data.get_card_ids():
		var c: CardData = data.get_card(id)
		if c != null and c.kind != CardData.KIND_JUNK:
			all.append(c)
	var carried: Array[CardData] = []
	for c: CardData in all:
		if not c.pokemon_id.is_empty():
			carried.append(c)
	var pool: Array[CardData] = carried if carried.size() >= FAN_COUNT else all
	var legendary: Array[CardData] = []
	var rare: Array[CardData] = []
	for c: CardData in pool:
		if c.legendary:
			legendary.append(c)
		elif c.rarity == "rare":
			rare.append(c)
	var picked: Array[CardData] = []
	for group: Array[CardData] in [legendary, rare]:
		if not group.is_empty() and picked.size() < FAN_COUNT:
			picked.append(group[rng.randi_range(0, group.size() - 1)])
	var rest: Array[CardData] = []
	for c: CardData in pool:
		if not picked.has(c):
			rest.append(c)
	while picked.size() < FAN_COUNT and not rest.is_empty():
		picked.append(rest.pop_at(rng.randi_range(0, rest.size() - 1)))
	# Fisher-Yates with the same rng (Array.shuffle would use the global one).
	for i: int in range(picked.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: CardData = picked[i]
		picked[i] = picked[j]
		picked[j] = tmp
	var out := PackedStringArray()
	for c: CardData in picked:
		out.append(c.id)
	return out


## True while the « Nouvelle partie ? » confirmation is shown.
func is_confirm_open() -> bool:
	return _confirm != null and _confirm.visible


## « Continuer » (ignored without a save).
func press_continue() -> void:
	if has_continue():
		continue_requested.emit()


## « Nouvelle partie »: asks for confirmation when a save exists, else starts at once.
func press_new_game() -> void:
	if _has_save:
		_confirm.visible = true
		_focus_later(_confirm.find_child("Cancel", true, false) as Button)
	else:
		new_game_requested.emit()


## Confirms the new game (the confirmation must be shown).
func confirm_new_game() -> void:
	if is_confirm_open():
		_confirm.visible = false
		new_game_requested.emit()


## Closes the confirmation (Annuler / Échap). True if it was open.
func cancel_confirm() -> bool:
	if not is_confirm_open():
		return false
	_confirm.visible = false
	_focus_later(_new_game_button)
	return true


## « Tutoriel ».
func press_tutorial() -> void:
	tutorial_requested.emit()


## « Options ».
func press_options() -> void:
	options_requested.emit()


## « Quitter ».
func press_quit() -> void:
	quit_requested.emit()


## Gentle pulse of the glow behind the logo (none when animations are off).
func _start_glow() -> void:
	if _glow_tween != null:
		_glow_tween.kill()
		_glow_tween = null
	if _glow == null or not is_inside_tree() or not BattleFxDirector.saved_enabled():
		return
	_glow_tween = create_tween().set_loops()
	_glow_tween.tween_property(_glow, "modulate:a", GLOW_PULSE_ALPHA, GLOW_PULSE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_glow_tween.parallel().tween_property(_glow, "scale", Vector2.ONE * GLOW_PULSE_SCALE, GLOW_PULSE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_glow_tween.tween_property(_glow, "modulate:a", 1.0, GLOW_PULSE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_glow_tween.parallel().tween_property(_glow, "scale", Vector2.ONE, GLOW_PULSE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Blurred copy of `tex` (shrunk by halves to <= BLUR_WIDTH px wide, then scaled back up with cubic filtering); computed
## once per launch. Falls back to `tex` when its pixels cannot be read (e.g. headless dummy renderer).
static func _blurred(tex: Texture2D) -> Texture2D:
	if _blurred_bg != null:
		return _blurred_bg
	var img: Image = tex.get_image() if tex != null else null
	if img == null or img.is_empty():
		return tex
	if img.is_compressed():
		img.decompress()
	var w: int = img.get_width()
	var h: int = img.get_height()
	while img.get_width() > BLUR_WIDTH:
		img.resize(maxi(1, img.get_width() / 2), maxi(1, img.get_height() / 2), Image.INTERPOLATE_BILINEAR)
	var target := Vector2i(mini(w, int(STAGE_SIZE.x * 1.25)), 0)
	target.y = maxi(1, int(float(h) * float(target.x) / float(w)))
	img.resize(target.x / 2, target.y / 2, Image.INTERPOLATE_CUBIC)
	img.resize(target.x, target.y, Image.INTERPOLATE_BILINEAR)
	_blurred_bg = ImageTexture.create_from_image(img)
	return _blurred_bg


func _build() -> void:
	if _built:
		return
	_built = true
	theme = UiStyle.make_theme()
	# Background: the League hall, blurred and darkened (flat fill when missing).
	var fill := ColorRect.new()
	fill.name = "Fill"
	fill.color = UiStyle.BG_DEEP
	fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fill)
	_background = TextureRect.new()
	_background.name = "Background"
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_background.modulate = Color(BACKGROUND_DIM, BACKGROUND_DIM, BACKGROUND_DIM)
	if ResourceLoader.exists(BACKGROUND_PATH):
		_background.texture = _blurred(load(BACKGROUND_PATH) as Texture2D)
	add_child(_background)
	# Stage: the mockup's 1280x720 composition, centred.
	_stage = Control.new()
	_stage.name = "Stage"
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.anchor_left = 0.5
	_stage.anchor_right = 0.5
	_stage.anchor_top = 0.5
	_stage.anchor_bottom = 0.5
	_stage.offset_left = -STAGE_SIZE.x * 0.5
	_stage.offset_right = STAGE_SIZE.x * 0.5
	_stage.offset_top = -STAGE_SIZE.y * 0.5
	_stage.offset_bottom = STAGE_SIZE.y * 0.5
	add_child(_stage)
	_glow = TextureRect.new()
	_glow.name = "Glow"
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow.texture = _radial_texture()
	_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_glow.stretch_mode = TextureRect.STRETCH_SCALE
	_glow.size = GLOW_SIZE
	_glow.position = GLOW_CENTER - GLOW_SIZE * 0.5
	_glow.pivot_offset = GLOW_SIZE * 0.5
	_stage.add_child(_glow)
	_fan = Control.new()
	_fan.name = "CardFan"
	_fan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fan.modulate = FAN_DIM
	_stage.add_child(_fan)
	# Dark gradient towards the bottom (over the fan, under the logo and the menu; the stage covers the screen).
	var shade := TextureRect.new()
	shade.name = "BottomShade"
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.texture = _shade_texture()
	_stage.add_child(shade)
	_build_logo()
	_build_menu()
	_build_confirm()


## Logo centred over the fan (rendered image, label fallback).
func _build_logo() -> void:
	if ResourceLoader.exists(LOGO_PATH):
		var logo := TextureRect.new()
		logo.name = "Logo"
		logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		logo.texture = load(LOGO_PATH) as Texture2D
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var tex_size: Vector2 = logo.texture.get_size()
		logo.size = Vector2(LOGO_WIDTH, LOGO_WIDTH * tex_size.y / tex_size.x)
		logo.position = Vector2((STAGE_SIZE.x - LOGO_WIDTH) * 0.5, LOGO_TOP)
		_stage.add_child(logo)
		_logo = logo
		return
	var logo_box := VBoxContainer.new()
	logo_box.name = "LogoBox"
	logo_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo_box.position = Vector2(0, LOGO_TOP + 60.0)
	logo_box.size = Vector2(STAGE_SIZE.x, 0)
	logo_box.add_theme_constant_override("separation", -6)
	_stage.add_child(logo_box)
	var label := Label.new()
	label.name = "Logo"
	label.text = LOGO_TEXT
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", LOGO_SIZE)
	UiStyle.apply_logo(label, LOGO_OUTLINE)
	logo_box.add_child(label)
	var sub := Label.new()
	sub.text = SUBTITLE
	sub.add_theme_font_override("font", UiStyle.font_title())
	sub.add_theme_font_size_override("font_size", 26)
	sub.add_theme_color_override("font_color", UiStyle.TEXT)
	sub.add_theme_color_override("font_outline_color", UiStyle.LOGO_BLUE)
	sub.add_theme_constant_override("outline_size", 8)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo_box.add_child(sub)
	_logo = logo_box


## Bottom block: the button row (save summary above « Continuer », error line above the row) and the stats line.
func _build_menu() -> void:
	var bottom := VBoxContainer.new()
	bottom.name = "Bottom"
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.anchor_left = 0.0
	bottom.anchor_right = 1.0
	bottom.anchor_top = 1.0
	bottom.anchor_bottom = 1.0
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom.offset_bottom = -MENU_BOTTOM
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.add_theme_constant_override("separation", 10)
	add_child(bottom)
	_error_label = CardView.make_label(16)
	_error_label.name = "SaveError"
	_error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_error_label.add_theme_color_override("font_color", UiStyle.HP_RED)
	_error_label.add_theme_color_override("font_outline_color", UiStyle.OUTLINE)
	_error_label.add_theme_constant_override("outline_size", 5)
	_error_label.visible = false
	bottom.add_child(_error_label)
	_menu = HBoxContainer.new()
	_menu.name = "Menu"
	_menu.alignment = BoxContainer.ALIGNMENT_CENTER
	_menu.add_theme_constant_override("separation", BUTTON_GAP)
	bottom.add_child(_menu)
	_continue_button = _button("Continue", TEXT_CONTINUE, UiStyle.ACCENT_RED, press_continue)
	_new_game_button = _button("NewGame", TEXT_NEW_GAME, UiStyle.ACCENT_BLUE, press_new_game)
	for b: Button in [_continue_button, _new_game_button,
			_button("Tutorial", TEXT_TUTORIAL, UiStyle.ACCENT_BLUE, press_tutorial),
			_button("Options", TEXT_OPTIONS, UiStyle.ACCENT_BLUE, press_options),
			_button("Quit", TEXT_QUIT, UiStyle.TEXT_SUB, press_quit)]:
		_menu.add_child(b)
		_buttons.append(b)
	# Save summary floating just above « Continuer » (does not widen the button).
	_continue_caption = CardView.make_label(16)
	_continue_caption.name = "ContinueCaption"
	_continue_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_continue_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_continue_caption.add_theme_color_override("font_color", UiStyle.CREAM)
	_continue_caption.add_theme_color_override("font_outline_color", UiStyle.OUTLINE)
	_continue_caption.add_theme_constant_override("outline_size", 5)
	_continue_caption.size = Vector2(BUTTON_SIZE.x + 160.0, 24)
	_continue_caption.position = Vector2(-80.0, -30.0)
	_continue_button.add_child(_continue_caption)
	_stats_label = CardView.make_label(16)
	_stats_label.name = "Stats"
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.add_theme_color_override("font_color", UiStyle.TEXT_MUTED)
	_stats_label.add_theme_color_override("font_outline_color", UiStyle.OUTLINE)
	_stats_label.add_theme_constant_override("outline_size", 4)
	bottom.add_child(_stats_label)


## Rebuilds the fan with these card ids (left to right; unknown ids skipped).
func _show_fan(ids: PackedStringArray) -> void:
	for c: Node in _fan.get_children():
		_fan.remove_child(c)
		c.queue_free()
	_fan_ids = PackedStringArray()
	var cards: Array[CardData] = []
	for id: String in ids:
		if _data.has_card(id):
			cards.append(_data.get_card(id))
			_fan_ids.append(id)
	var n: int = cards.size()
	for i: int in n:
		var k: float = float(i) - float(n - 1) * 0.5
		var b := Button.new()
		b.name = "FanCard%d" % i
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.focus_mode = Control.FOCUS_NONE
		var sb := StyleBoxFlat.new()
		sb.bg_color = UiStyle.OUTLINE
		sb.set_corner_radius_all(10)
		for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
			b.add_theme_stylebox_override(state, sb)
		b.size = FAN_CARD_SIZE
		b.pivot_offset = FAN_CARD_SIZE * 0.5
		var center: Vector2 = FAN_CENTER + Vector2(k * FAN_SPREAD, absf(k) * FAN_DROP)
		b.position = center - FAN_CARD_SIZE * 0.5
		b.rotation_degrees = k * FAN_ANGLE_DEG
		CardView.fill_card_content(b, cards[i], _data.get_type_chart(), _data.get_pokemon_info)
		_fan.add_child(b)


## Warm radial glow (transparent at the edge).
static func _radial_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	g.colors = PackedColorArray([GLOW_COLOR, Color(GLOW_COLOR, GLOW_COLOR.a * 0.4), Color(GLOW_COLOR, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 256
	t.height = 256
	return t


## Vertical dark gradient (SHADE_STOPS).
static func _shade_texture() -> GradientTexture2D:
	var g := Gradient.new()
	var offs := PackedFloat32Array()
	var cols := PackedColorArray()
	for st: Vector2 in SHADE_STOPS:
		offs.append(st.x)
		cols.append(Color(SHADE_COLOR, st.y))
	g.offsets = offs
	g.colors = cols
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(0, 1)
	t.width = 4
	t.height = 256
	return t


func _build_confirm() -> void:
	_confirm = Control.new()
	_confirm.name = "NewGameConfirm"
	_confirm.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm.visible = false
	add_child(_confirm)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_confirm.add_child(center)
	var window := PanelContainer.new()
	window.add_theme_stylebox_override("panel", UiStyle.menu_panel(UiStyle.ACCENT_RED, 24.0, 16.0))
	center.add_child(window)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	window.add_child(col)
	var t := CardView.make_label(26)
	t.text = TEXT_CONFIRM_TITLE
	t.add_theme_font_override("font", UiStyle.font_title())
	UiStyle.dark_label(t, UiStyle.LOGO_BLUE)
	col.add_child(t)
	var body := CardView.make_label(18)
	body.text = TEXT_CONFIRM_BODY
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(440, 0)
	UiStyle.dark_label(body, UiStyle.TEXT_DARK)
	col.add_child(body)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)
	var ok := _button("ConfirmNewGame", TEXT_CONFIRM_OK, UiStyle.ACCENT_RED, confirm_new_game)
	ok.custom_minimum_size = Vector2(200, 46)
	row.add_child(ok)
	var cancel := _button("Cancel", TEXT_CANCEL, UiStyle.TEXT_SUB, func() -> void: cancel_confirm())
	cancel.custom_minimum_size = Vector2(150, 46)
	row.add_child(cancel)


func _button(node_name: String, text: String, color: Color, on_press: Callable) -> Button:
	var b := Button.new()
	b.name = node_name
	b.text = text
	b.custom_minimum_size = BUTTON_SIZE
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_override("font", UiStyle.font_title())
	b.add_theme_font_size_override("font_size", BUTTON_FONT)
	UiStyle.apply_button(b, color)
	b.pressed.connect(on_press)
	return b


## Gives `b` the keyboard / gamepad focus at the end of the frame (skipped if it left the tree meanwhile).
func _focus_later(b: Control) -> void:
	(func() -> void:
		if is_instance_valid(b) and b.is_inside_tree() and b.is_visible_in_tree():
			b.grab_focus()).call_deferred()
