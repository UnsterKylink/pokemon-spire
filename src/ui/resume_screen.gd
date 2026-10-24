class_name ResumeScreen
extends Control
## Story 015 (story-015-sauvegarde): the "Reprendre la partie" screen shown at launch BEFORE the starter choice when a save
## exists. Stand-in for the main menu (story 023), self-contained. Display only: it emits continue_requested /
## new_game_requested and Main acts (load, delete the save, start a run).
## Two modes: setup_valid (summary of the saved run, "Reprendre" + "Nouvelle partie") and setup_error (a clear
## "Sauvegarde illisible : <raison>" message and ONLY "Nouvelle partie"). Mouse only, fits 1280x720.

signal continue_requested
signal new_game_requested

const COLOR_BG: Color = Color(0.12, 0.13, 0.18)
const COLOR_PANEL: Color = Color(0.16, 0.17, 0.23)
const COLOR_PANEL_BORDER: Color = Color(0.38, 0.4, 0.5)
const COLOR_ERROR: Color = Color(0.95, 0.45, 0.4)
const COLOR_CAPTION: Color = Color(0.7, 0.72, 0.82)
const SPRITE_SIZE: Vector2 = Vector2(120, 120)
const PANEL_WIDTH: float = 560.0
const BUTTON_SIZE: Vector2 = Vector2(240, 56)
const TEXT_TITLE: String = "Reprendre la partie"
const TEXT_TITLE_ERROR: String = "Sauvegarde illisible"
const TEXT_ERROR: String = "Sauvegarde illisible : %s"
const TEXT_ERROR_HINT: String = "L'ancien fichier est conservé en .bak. Tu peux commencer une nouvelle partie."
const TEXT_CONTINUE: String = "Reprendre"
const TEXT_NEW_GAME: String = "Nouvelle partie"
const TEXT_FORM: String = "%s (départ : %s)"
const TEXT_ZONE: String = "Zone %d/%d — Arène %s"
const TEXT_LEAGUE: String = "Ligue — combat %d/%d (%d gagnés)"
const TEXT_BADGES: String = "Badges : %d/%d"
const TEXT_HP: String = "PV : %d/%d"
const TEXT_MONEY: String = "P$ : %d"
const TEXT_DECK: String = "Deck : %d cartes"
const TEXT_DATE: String = "Sauvegardé le %s"

var _built: bool = false
var _column: VBoxContainer
var _title: Label
var _message: Label
var _lines: Array[Label] = []
var _continue_button: Button
var _new_button: Button
var _sprite_row: HBoxContainer


func _init() -> void:
	name = "ResumeScreen"
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	_build_ui()


## Shows the summary of the saved `run` (saved_at = the file's date text) with "Reprendre" and "Nouvelle partie".
func setup_valid(data: GameData, run: RunState, saved_at: String) -> void:
	_build_ui()
	_title.text = TEXT_TITLE
	_title.remove_theme_color_override("font_color")
	var s: Dictionary = run.get_summary()
	var base_name: String = String(data.get_pokemon_info(run.base_pokemon_id).get("name", run.base_pokemon_id))
	for child: Node in _sprite_row.get_children():
		_sprite_row.remove_child(child)
		child.queue_free()
	_sprite_row.add_child(_make_sprite(run.sprite_path))
	var info := VBoxContainer.new()
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	var name_label: Label = CardView.make_label(28)
	name_label.name = "PokemonName"
	name_label.text = String(s["name"]) if run.base_pokemon_id == run.starter_pokemon_id \
			else TEXT_FORM % [s["name"], base_name]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(name_label)
	var row: HBoxContainer = CardView.make_type_badge_row(18)
	var types: Array[String] = []
	types.assign(run.type_ids)
	CardView.set_badge_row(row, types, data.get_type_chart())
	info.add_child(row)
	_sprite_row.add_child(info)
	var progress: String = ""
	if run.is_in_league():
		progress = TEXT_LEAGUE % [run.league_stage + 1, run.league.size(), run.league_fights_won]
	else:
		progress = TEXT_ZONE % [int(s["zone"]), int(s["zone_count"]), String(run.current_zone().get("type_name", "?"))]
	var texts: Array[String] = [progress, TEXT_BADGES % [int(s["badges"]), int(s["zone_count"])],
			TEXT_HP % [int(s["hp"]), int(s["max_hp"])], TEXT_MONEY % int(s["money"]), TEXT_DECK % int(s["deck_size"]),
			TEXT_DATE % saved_at]
	_set_lines(texts)
	_message.visible = false
	_sprite_row.visible = true
	_continue_button.visible = true
	_continue_button.grab_focus()


## Shows "Sauvegarde illisible : <reason>" and ONLY "Nouvelle partie".
func setup_error(reason: String) -> void:
	_build_ui()
	_title.text = TEXT_TITLE_ERROR
	_title.add_theme_color_override("font_color", COLOR_ERROR)
	_sprite_row.visible = false
	_set_lines([])
	_message.text = TEXT_ERROR % reason + "\n" + TEXT_ERROR_HINT
	_message.visible = true
	_continue_button.visible = false


## QA / click: "Reprendre" (ignored in error mode).
func press_continue() -> void:
	if _continue_button != null and _continue_button.visible:
		continue_requested.emit()


## QA / click: "Nouvelle partie".
func press_new_game() -> void:
	new_game_requested.emit()


## True if the "Reprendre" button is offered (false in error mode).
func has_continue_button() -> bool:
	return _continue_button != null and _continue_button.visible


## The error text shown ("" outside error mode).
func get_message() -> String:
	return _message.text if _message != null and _message.visible else ""


## The summary lines shown (progress, badges, HP, money, deck, date).
func get_summary_lines() -> Array[String]:
	var out: Array[String] = []
	for l: Label in _lines:
		if l.visible:
			out.append(l.text)
	return out


func _set_lines(texts: Array[String]) -> void:
	for i: int in _lines.size():
		_lines[i].visible = i < texts.size()
		if i < texts.size():
			_lines[i].text = texts[i]


func _make_sprite(path: String) -> TextureRect:
	var sprite := TextureRect.new()
	sprite.name = "Sprite"
	sprite.texture = CardView.cropped_sprite(path)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.custom_minimum_size = SPRITE_SIZE
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return sprite


func _build_ui() -> void:
	if _built:
		return
	_built = true
	var bg := ColorRect.new()
	bg.color = COLOR_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", 24)
	center.add_child(_column)
	_title = CardView.make_label(36)
	_title.name = "Title"
	_column.add_child(_title)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL
	style.border_color = COLOR_PANEL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", style)
	_column.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	_sprite_row = HBoxContainer.new()
	_sprite_row.name = "Identity"
	_sprite_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_sprite_row.add_theme_constant_override("separation", 18)
	box.add_child(_sprite_row)
	for i: int in 6:
		var l: Label = CardView.make_label(22)
		l.name = "Line%d" % i
		box.add_child(l)
		_lines.append(l)
	_message = CardView.make_label(24)
	_message.name = "Message"
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.custom_minimum_size = Vector2(PANEL_WIDTH - 44.0, 0)
	_message.add_theme_color_override("font_color", COLOR_ERROR)
	_message.visible = false
	box.add_child(_message)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	_column.add_child(buttons)
	_continue_button = _make_button("Continue", TEXT_CONTINUE)
	_continue_button.pressed.connect(press_continue)
	buttons.add_child(_continue_button)
	_new_button = _make_button("NewGame", TEXT_NEW_GAME)
	_new_button.pressed.connect(press_new_game)
	buttons.add_child(_new_button)


func _make_button(node_name: String, text: String) -> Button:
	var b := Button.new()
	b.name = node_name
	b.text = text
	b.custom_minimum_size = BUTTON_SIZE
	b.add_theme_font_size_override("font_size", 24)
	return b
