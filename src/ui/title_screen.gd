class_name TitleScreen
extends Control
## Story 023 (story-023-menu-options-tutoriel): the title screen shown at launch (real game). The player's painting
## (assets/art/title/title.jpg, cover-fit), the « Pokémon Spire » logo (rendered image assets/art/title/logo.png from tools/art/make_logo.py,
## label fallback), a random Pokémon standing on the path (official HD artwork, gentle bob; chosen by Main), the menu window
## (Continuer — only with a valid save —, Nouvelle partie — confirmation when a save exists —, Tutoriel, Options,
## Quitter) and the statistics window (parties jouées / gagnées / meilleur résultat, PlayerStats). Display only: it emits
## signals and Main acts (resume, new run, tutorial replay, options, quit). Keyboard / gamepad: the buttons take focus.

signal continue_requested
signal new_game_requested
signal tutorial_requested
signal options_requested
signal quit_requested

const BACKGROUND_PATH: String = "res://assets/art/title/title.jpg"
const LOGO_TEXT: String = "Pokémon Spire"
const LOGO_SIZE: int = 92
const LOGO_OUTLINE: int = 18
const SUBTITLE: String = "Roguelike de cartes"
## Rendered logo (tools/art/make_logo.py); the label logo is the fallback.
const LOGO_PATH: String = "res://assets/art/title/logo.png"
const LOGO_WIDTH: float = 560.0
const POKEMON_BOX: Vector2 = Vector2(270, 270)
## Gentle idle bob of the title Pokémon (px, seconds per half cycle).
const BOB_HEIGHT: float = 8.0
const BOB_TIME: float = 1.4
## Feet of the Pokémon, as fractions of the screen (on the painted path).
const POKEMON_ANCHOR: Vector2 = Vector2(0.4, 0.93)
const MENU_WIDTH: float = 330.0
const BUTTON_SIZE: Vector2 = Vector2(290, 50)
const TEXT_CONTINUE: String = "Continuer"
const TEXT_NEW_GAME: String = "Nouvelle partie"
const TEXT_TUTORIAL: String = "Tutoriel"
const TEXT_OPTIONS: String = "Options"
const TEXT_QUIT: String = "Quitter"
const TEXT_STATS_TITLE: String = "Statistiques"
const TEXT_PLAYED: String = "Parties jouées : %d"
const TEXT_WON: String = "Parties gagnées : %d"
const TEXT_BEST: String = "Meilleur résultat : %s"
const TEXT_SAVE_ERROR: String = "Sauvegarde illisible : %s\n(conservée en .bak)"
const TEXT_CONFIRM_TITLE: String = "Nouvelle partie ?"
const TEXT_CONFIRM_BODY: String = "Une partie est en cours. En commencer une nouvelle supprimera sa sauvegarde (elle ne comptera pas dans les statistiques)."
const TEXT_CONFIRM_OK: String = "Nouvelle partie"
const TEXT_CANCEL: String = "Annuler"

var _built: bool = false
var _background: TextureRect
var _logo: Control
## Official artwork of the title Pokémon (HD, smooth), bobbing gently.
var _pokemon: TextureRect
var _bob: Tween
var _menu: VBoxContainer
var _continue_button: Button
var _continue_caption: Label
var _error_label: Label
var _stats_lines: Array[Label] = []
var _confirm: Control
var _has_save: bool = false
var _pokemon_sprite: String = ""


func _init() -> void:
	name = "TitleScreen"
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	_build()


## Fills the screen: `stats` (PlayerStats), `save_summary` ("" = no valid save: no « Continuer »; else the caption under
## it), `save_error` ("" or the reason of an unreadable save), `pokemon_sprite` (still sprite path of the Pokémon shown).
func setup(stats: PlayerStats, save_summary: String, save_error: String, pokemon_sprite: String) -> void:
	_build()
	_has_save = not save_summary.is_empty()
	_continue_button.visible = _has_save
	_continue_caption.visible = _has_save
	_continue_caption.text = save_summary
	_error_label.visible = not save_error.is_empty()
	_error_label.text = TEXT_SAVE_ERROR % save_error if not save_error.is_empty() else ""
	var s: PlayerStats = stats if stats != null else PlayerStats.new()
	_stats_lines[0].text = TEXT_PLAYED % s.runs_played
	_stats_lines[1].text = TEXT_WON % s.runs_won
	_stats_lines[2].text = TEXT_BEST % s.best_result_text()
	_pokemon_sprite = pokemon_sprite
	_pokemon.texture = PokemonArt.texture_for_sprite(pokemon_sprite)
	_start_bob()
	_confirm.visible = false
	_focus_later(_continue_button if _has_save else _menu.get_node("NewGame") as Button)


## True when « Continuer » is offered.
func has_continue() -> bool:
	return _continue_button != null and _continue_button.visible


## The stats lines shown (QA).
func get_stats_lines() -> PackedStringArray:
	var out := PackedStringArray()
	for l: Label in _stats_lines:
		out.append(l.text)
	return out


## Still sprite path of the Pokémon shown (QA).
func get_pokemon_sprite() -> String:
	return _pokemon_sprite


## The visible menu button texts, top to bottom (QA).
func get_button_texts() -> PackedStringArray:
	var out := PackedStringArray()
	for c: Node in _menu.get_children():
		if c is Button and (c as Button).visible:
			out.append((c as Button).text)
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
	_focus_later(_menu.get_node("NewGame") as Button)
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


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _pokemon != null:
		_place_pokemon()


func _place_pokemon() -> void:
	var feet: Vector2 = size * POKEMON_ANCHOR
	_pokemon.size = POKEMON_BOX
	_pokemon.position = Vector2(feet.x - POKEMON_BOX.x * 0.5, feet.y - POKEMON_BOX.y)
	_start_bob()


## Idle bob (skipped when animations are off).
func _start_bob() -> void:
	if _bob != null:
		_bob.kill()
		_bob = null
	if _pokemon == null or not is_inside_tree() or not BattleFxDirector.saved_enabled():
		return
	var y0: float = _pokemon.position.y
	_bob = create_tween().set_loops()
	_bob.tween_property(_pokemon, "position:y", y0 - BOB_HEIGHT, BOB_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bob.tween_property(_pokemon, "position:y", y0, BOB_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _build() -> void:
	if _built:
		return
	_built = true
	theme = UiStyle.make_theme()
	_background = TextureRect.new()
	_background.name = "Background"
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background.texture = load(BACKGROUND_PATH) as Texture2D if ResourceLoader.exists(BACKGROUND_PATH) else null
	add_child(_background)
	if _background.texture == null:
		var fill := ColorRect.new()
		fill.color = UiStyle.BG_DEEP
		fill.set_anchors_preset(Control.PRESET_FULL_RECT)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(fill)
	# Logo, top left over the sky (the spire stays visible on the right).
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
		logo.position = Vector2(36, 14)
		add_child(logo)
		_logo = logo
	else:
		var logo_box := VBoxContainer.new()
		logo_box.name = "LogoBox"
		logo_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		logo_box.position = Vector2(48, 26)
		logo_box.add_theme_constant_override("separation", -6)
		add_child(logo_box)
		var label := Label.new()
		label.name = "Logo"
		label.text = LOGO_TEXT
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
	# The Pokémon on the path.
	_pokemon = TextureRect.new()
	_pokemon.name = "TitlePokemon"
	_pokemon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pokemon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_pokemon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pokemon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_pokemon)
	var shadow := _Shadow.new()
	shadow.name = "PokemonShadow"
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.set_anchors_preset(Control.PRESET_FULL_RECT)
	shadow.target = _pokemon
	add_child(shadow)
	move_child(shadow, _pokemon.get_index())
	_place_pokemon.call_deferred()
	# Menu window, right side over the forest.
	var window := PanelContainer.new()
	window.name = "MenuWindow"
	window.add_theme_stylebox_override("panel", UiStyle.menu_panel(UiStyle.FRAME_BLUE, 20.0, 16.0))
	window.custom_minimum_size = Vector2(MENU_WIDTH, 0)
	window.anchor_left = 1.0
	window.anchor_right = 1.0
	window.anchor_top = 0.5
	window.anchor_bottom = 0.5
	window.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	window.grow_vertical = Control.GROW_DIRECTION_BOTH
	window.offset_right = -56.0
	window.offset_top = 30.0
	add_child(window)
	_menu = VBoxContainer.new()
	_menu.name = "Menu"
	_menu.add_theme_constant_override("separation", 10)
	window.add_child(_menu)
	_continue_button = _button("Continue", TEXT_CONTINUE, UiStyle.ACCENT_RED, press_continue)
	_menu.add_child(_continue_button)
	_continue_caption = CardView.make_label(14)
	_continue_caption.name = "ContinueCaption"
	UiStyle.dark_label(_continue_caption, UiStyle.TEXT_SUB)
	_menu.add_child(_continue_caption)
	_error_label = CardView.make_label(14)
	_error_label.name = "SaveError"
	_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error_label.custom_minimum_size = Vector2(BUTTON_SIZE.x, 0)
	UiStyle.dark_label(_error_label, UiStyle.INK_RED)
	_error_label.visible = false
	_menu.add_child(_error_label)
	_menu.add_child(_button("NewGame", TEXT_NEW_GAME, UiStyle.ACCENT_BLUE, press_new_game))
	_menu.add_child(_button("Tutorial", TEXT_TUTORIAL, UiStyle.ACCENT_BLUE, press_tutorial))
	_menu.add_child(_button("Options", TEXT_OPTIONS, UiStyle.ACCENT_BLUE, press_options))
	_menu.add_child(_button("Quit", TEXT_QUIT, UiStyle.TEXT_SUB, press_quit))
	# Statistics window, bottom left.
	var stats := PanelContainer.new()
	stats.name = "StatsWindow"
	stats.add_theme_stylebox_override("panel", UiStyle.menu_panel(UiStyle.ACCENT_YELLOW.darkened(0.1), 16.0, 8.0))
	stats.anchor_top = 1.0
	stats.anchor_bottom = 1.0
	stats.grow_vertical = Control.GROW_DIRECTION_BEGIN
	stats.offset_left = 40.0
	stats.offset_bottom = -32.0
	add_child(stats)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	stats.add_child(col)
	var st := CardView.make_label(20)
	st.text = TEXT_STATS_TITLE
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	st.add_theme_font_override("font", UiStyle.font_title())
	UiStyle.dark_label(st, UiStyle.LOGO_BLUE)
	col.add_child(st)
	for i: int in 3:
		var l := CardView.make_label(17)
		l.name = "Stat%d" % i
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		UiStyle.dark_label(l, UiStyle.TEXT_DARK)
		col.add_child(l)
		_stats_lines.append(l)
	_build_confirm()


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
	b.add_theme_font_size_override("font_size", 22)
	UiStyle.apply_button(b, color)
	b.pressed.connect(on_press)
	return b


## Soft ground shadow under the title Pokémon (drawn behind it).
class _Shadow extends Control:
	var target: TextureRect

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if target == null or not is_instance_valid(target):
			return
		# Fixed ground point (the Pokémon bobs above it); width from the box.
		var feet: Vector2 = Vector2(target.position.x + target.size.x * 0.5, get_parent_control().size.y * POKEMON_ANCHOR.y - 6.0)
		var w: float = target.size.x * 0.62
		draw_set_transform(feet, 0.0, Vector2(1.0, 0.28))
		draw_circle(Vector2.ZERO, w * 0.5, Color(0, 0, 0, 0.32))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Gives `b` the keyboard / gamepad focus at the end of the frame (skipped if it left the tree meanwhile).
func _focus_later(b: Control) -> void:
	(func() -> void:
		if is_instance_valid(b) and b.is_inside_tree() and b.is_visible_in_tree():
			b.grab_focus()).call_deferred()
